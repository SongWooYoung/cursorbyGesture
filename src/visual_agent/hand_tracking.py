from __future__ import annotations

from dataclasses import dataclass

import cv2
import mediapipe as mp

from visual_agent.config import AppConfig
from visual_agent.gestures import HandState


@dataclass(slots=True)
class TrackingFrame:
    hand_state: HandState | None
    rgb_frame: object
    raw_results: object


class HandTracker:
    def __init__(self, config: AppConfig) -> None:
        if not hasattr(mp, "solutions"):
            version = getattr(mp, "__version__", "unknown")
            raise RuntimeError(
                "This project currently requires MediaPipe Solutions API, but the installed "
                f"mediapipe {version} build does not expose mp.solutions. "
                "Recreate the virtual environment with Python 3.11 or 3.12, then reinstall requirements."
            )
        self._mp_hands = mp.solutions.hands
        self._drawing = mp.solutions.drawing_utils
        self._connections = self._mp_hands.HAND_CONNECTIONS
        self._hands = self._mp_hands.Hands(
            max_num_hands=config.max_num_hands,
            min_detection_confidence=config.min_detection_confidence,
            min_tracking_confidence=config.min_tracking_confidence,
        )

    def process(self, frame) -> TrackingFrame:
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        rgb_frame.flags.writeable = False
        results = self._hands.process(rgb_frame)
        rgb_frame.flags.writeable = True

        if not results.multi_hand_landmarks:
            return TrackingFrame(hand_state=None, rgb_frame=rgb_frame, raw_results=results)

        landmarks = results.multi_hand_landmarks[0].landmark
        wrist = landmarks[self._mp_hands.HandLandmark.WRIST]
        thumb_tip = landmarks[self._mp_hands.HandLandmark.THUMB_TIP]
        thumb_mcp = landmarks[self._mp_hands.HandLandmark.THUMB_MCP]
        index_mcp = landmarks[self._mp_hands.HandLandmark.INDEX_FINGER_MCP]
        index_tip = landmarks[self._mp_hands.HandLandmark.INDEX_FINGER_TIP]
        index_pip = landmarks[self._mp_hands.HandLandmark.INDEX_FINGER_PIP]
        middle_mcp = landmarks[self._mp_hands.HandLandmark.MIDDLE_FINGER_MCP]
        middle_tip = landmarks[self._mp_hands.HandLandmark.MIDDLE_FINGER_TIP]
        middle_pip = landmarks[self._mp_hands.HandLandmark.MIDDLE_FINGER_PIP]
        ring_tip = landmarks[self._mp_hands.HandLandmark.RING_FINGER_TIP]
        ring_pip = landmarks[self._mp_hands.HandLandmark.RING_FINGER_PIP]
        pinky_mcp = landmarks[self._mp_hands.HandLandmark.PINKY_MCP]
        pinky_tip = landmarks[self._mp_hands.HandLandmark.PINKY_TIP]
        pinky_pip = landmarks[self._mp_hands.HandLandmark.PINKY_PIP]

        return TrackingFrame(
            hand_state=HandState(
                wrist=(wrist.x, wrist.y),
                wrist_z=wrist.z,
                thumb_tip=(thumb_tip.x, thumb_tip.y),
                thumb_mcp=(thumb_mcp.x, thumb_mcp.y),
                index_mcp=(index_mcp.x, index_mcp.y),
                index_mcp_z=index_mcp.z,
                index_tip=(index_tip.x, index_tip.y),
                index_tip_z=index_tip.z,
                index_pip=(index_pip.x, index_pip.y),
                middle_mcp=(middle_mcp.x, middle_mcp.y),
                middle_tip=(middle_tip.x, middle_tip.y),
                middle_pip=(middle_pip.x, middle_pip.y),
                ring_tip=(ring_tip.x, ring_tip.y),
                ring_pip=(ring_pip.x, ring_pip.y),
                pinky_mcp=(pinky_mcp.x, pinky_mcp.y),
                pinky_tip=(pinky_tip.x, pinky_tip.y),
                pinky_pip=(pinky_pip.x, pinky_pip.y),
            ),
            rgb_frame=rgb_frame,
            raw_results=results,
        )

    def draw(self, frame, tracking_frame: TrackingFrame) -> None:
        if not tracking_frame.raw_results.multi_hand_landmarks:
            return
        for hand_landmarks in tracking_frame.raw_results.multi_hand_landmarks:
            self._drawing.draw_landmarks(frame, hand_landmarks, self._connections)

    def close(self) -> None:
        self._hands.close()
