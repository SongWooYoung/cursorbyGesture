from __future__ import annotations

import cv2

from visual_agent.config import AppConfig


class CameraSource:
    def __init__(self, config: AppConfig) -> None:
        self._capture = cv2.VideoCapture(config.camera_index)
        self._capture.set(cv2.CAP_PROP_FRAME_WIDTH, config.frame_width)
        self._capture.set(cv2.CAP_PROP_FRAME_HEIGHT, config.frame_height)

    def read(self):
        ok, frame = self._capture.read()
        if not ok:
            return None
        return frame

    def close(self) -> None:
        self._capture.release()
