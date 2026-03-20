from __future__ import annotations

from dataclasses import dataclass
from math import atan2, degrees, hypot


@dataclass(slots=True)
class HandState:
    wrist: tuple[float, float] | None
    wrist_z: float | None
    thumb_tip: tuple[float, float] | None
    thumb_mcp: tuple[float, float] | None
    index_mcp: tuple[float, float] | None
    index_mcp_z: float | None
    index_tip: tuple[float, float] | None
    index_tip_z: float | None
    index_pip: tuple[float, float] | None
    middle_mcp: tuple[float, float] | None
    middle_tip: tuple[float, float] | None
    middle_pip: tuple[float, float] | None
    ring_tip: tuple[float, float] | None
    ring_pip: tuple[float, float] | None
    pinky_mcp: tuple[float, float] | None
    pinky_tip: tuple[float, float] | None
    pinky_pip: tuple[float, float] | None


@dataclass(slots=True)
class StateChange:
    previous: bool
    current: bool


@dataclass(slots=True)
class AutoClutchState:
    angle_deg: float | None
    delta_deg: float | None
    active: bool
    side: int = 0
    entered: bool = False
    released: bool = False


@dataclass(slots=True)
class TouchClickState:
    metric: float | None
    baseline: float | None
    delta: float | None
    touching: bool
    tap_count: int = 0


class StateTracker:
    def __init__(self, initial: bool = False) -> None:
        self.current = initial

    def update(self, new_value: bool) -> StateChange | None:
        if new_value == self.current:
            return None
        change = StateChange(previous=self.current, current=new_value)
        self.current = new_value
        return change


class DebouncedStateTracker:
    def __init__(self, initial: bool = False, required_frames: int = 1) -> None:
        self.current = initial
        self._required_frames = max(1, required_frames)
        self._pending_value = initial
        self._pending_frames = 0

    def update(self, new_value: bool) -> StateChange | None:
        if new_value == self.current:
            self._pending_value = self.current
            self._pending_frames = 0
            return None

        if new_value != self._pending_value:
            self._pending_value = new_value
            self._pending_frames = 1
            return None

        self._pending_frames += 1
        if self._pending_frames < self._required_frames:
            return None

        change = StateChange(previous=self.current, current=new_value)
        self.current = new_value
        self._pending_value = self.current
        self._pending_frames = 0
        return change


class DoubleTapTracker:
    def __init__(self, max_interval_frames: int) -> None:
        self._max_interval_frames = max(1, max_interval_frames)
        self._tap_count = 0
        self._last_tap_frame: int | None = None

    @property
    def tap_count(self) -> int:
        return self._tap_count

    def register_tap(self, frame_index: int) -> bool:
        if self._last_tap_frame is None or (frame_index - self._last_tap_frame) > self._max_interval_frames:
            self._tap_count = 1
        else:
            self._tap_count += 1

        self._last_tap_frame = frame_index
        if self._tap_count < 2:
            return False

        self.reset()
        return True

    def reset(self) -> None:
        self._tap_count = 0
        self._last_tap_frame = None


class ScreenTouchDoubleTapDetector:
    def __init__(
        self,
        press_delta: float,
        release_delta: float,
        baseline_alpha: float,
        press_frames: int,
        release_frames: int,
        max_interval_frames: int,
    ) -> None:
        self._press_delta = max(0.001, press_delta)
        self._release_delta = min(max(0.0, release_delta), self._press_delta * 0.8)
        self._baseline_alpha = min(max(baseline_alpha, 0.01), 0.5)
        self._press_frames = max(1, press_frames)
        self._release_frames = max(1, release_frames)
        self._double_tap_tracker = DoubleTapTracker(max_interval_frames)
        self._filtered_metric: float | None = None
        self._baseline_metric: float | None = None
        self._touching = False
        self._press_count = 0
        self._release_count = 0

    def reset(self) -> None:
        self._filtered_metric = None
        self._baseline_metric = None
        self._touching = False
        self._press_count = 0
        self._release_count = 0
        self._double_tap_tracker.reset()

    def update(self, hand_state: HandState | None, frame_index: int) -> tuple[TouchClickState, bool]:
        if hand_state is None:
            self.reset()
            return TouchClickState(metric=None, baseline=None, delta=None, touching=False), False

        metric = screen_touch_metric(hand_state)
        if metric is None:
            self.reset()
            return TouchClickState(metric=None, baseline=None, delta=None, touching=False), False

        if self._filtered_metric is None:
            self._filtered_metric = metric
        else:
            self._filtered_metric = (self._filtered_metric * 0.65) + (metric * 0.35)

        if self._baseline_metric is None:
            self._baseline_metric = self._filtered_metric

        delta = self._filtered_metric - self._baseline_metric
        index_extended = _is_finger_extended(hand_state.index_tip, hand_state.index_pip, 0.01)
        click_fired = False

        if not index_extended:
            self._press_count = 0
            self._release_count = 0
            self._touching = False
            self._baseline_metric = self._filtered_metric
            self._double_tap_tracker.reset()
            return TouchClickState(
                metric=self._filtered_metric,
                baseline=self._baseline_metric,
                delta=delta,
                touching=False,
                tap_count=self._double_tap_tracker.tap_count,
            ), False

        if not self._touching and delta < (self._press_delta * 0.6):
            self._baseline_metric = (
                (1.0 - self._baseline_alpha) * self._baseline_metric
                + self._baseline_alpha * self._filtered_metric
            )
            delta = self._filtered_metric - self._baseline_metric

        if not self._touching:
            if delta >= self._press_delta:
                self._press_count += 1
                if self._press_count >= self._press_frames:
                    self._touching = True
                    self._press_count = 0
                    self._release_count = 0
            else:
                self._press_count = 0
        else:
            if delta <= self._release_delta:
                self._release_count += 1
                if self._release_count >= self._release_frames:
                    self._touching = False
                    self._release_count = 0
                    self._baseline_metric = self._filtered_metric
                    click_fired = self._double_tap_tracker.register_tap(frame_index)
            else:
                self._release_count = 0

        return TouchClickState(
            metric=self._filtered_metric,
            baseline=self._baseline_metric,
            delta=self._filtered_metric - self._baseline_metric,
            touching=self._touching,
            tap_count=self._double_tap_tracker.tap_count,
        ), click_fired


class AutoClutchController:
    def __init__(
        self,
        neutral_angle_deg: float,
        stop_delta_deg: float,
        resume_delta_deg: float,
        required_frames: int,
    ) -> None:
        self._neutral_angle_deg = neutral_angle_deg
        self._stop_delta_deg = max(3.0, abs(stop_delta_deg))
        self._resume_delta_deg = min(max(1.0, abs(resume_delta_deg)), self._stop_delta_deg - 0.5)
        self._required_frames = max(1, required_frames)
        self._pending_side = 0
        self._pending_frames = 0
        self._active = False
        self._clutch_side = 0
        self._previous_angle_deg: float | None = None

    @property
    def resume_left_angle_deg(self) -> float:
        return self._neutral_angle_deg - self._resume_delta_deg

    @property
    def resume_right_angle_deg(self) -> float:
        return self._neutral_angle_deg + self._resume_delta_deg

    @property
    def stop_left_angle_deg(self) -> float:
        return self._neutral_angle_deg - self._stop_delta_deg

    @property
    def stop_right_angle_deg(self) -> float:
        return self._neutral_angle_deg + self._stop_delta_deg

    def reset(self) -> None:
        self._pending_side = 0
        self._pending_frames = 0
        self._active = False
        self._clutch_side = 0
        self._previous_angle_deg = None

    def update(self, angle_deg: float | None) -> AutoClutchState:
        if angle_deg is None:
            self.reset()
            return AutoClutchState(angle_deg=None, delta_deg=None, active=False)

        delta_deg = _normalize_angle_deg(angle_deg - self._neutral_angle_deg)
        entered = False
        released = False
        side = self._clutch_side if self._active else 0

        if not self._active:
            if abs(delta_deg) >= self._stop_delta_deg:
                side = -1 if delta_deg < 0.0 else 1
                if side != self._pending_side:
                    self._pending_side = side
                    self._pending_frames = 1
                else:
                    self._pending_frames += 1

                if self._pending_frames >= self._required_frames:
                    self._active = True
                    self._clutch_side = side
                    self._pending_side = 0
                    self._pending_frames = 0
                    entered = True
            else:
                self._pending_side = 0
                self._pending_frames = 0
        else:
            side = self._clutch_side
            moving_back = False
            if self._previous_angle_deg is not None:
                if side < 0:
                    moving_back = angle_deg > self._previous_angle_deg + 0.15
                elif side > 0:
                    moving_back = angle_deg < self._previous_angle_deg - 0.15

            recovered = False
            if side < 0:
                recovered = delta_deg >= -self._resume_delta_deg
            elif side > 0:
                recovered = delta_deg <= self._resume_delta_deg

            if recovered and (moving_back or self._previous_angle_deg is None):
                self._active = False
                self._clutch_side = 0
                released = True
                side = 0

        self._previous_angle_deg = angle_deg
        return AutoClutchState(
            angle_deg=angle_deg,
            delta_deg=delta_deg,
            active=self._active,
            side=side,
            entered=entered,
            released=released,
        )


def is_index_double_tap_pose(hand_state: HandState, fold_margin: float) -> bool:
    index_folded = _is_finger_folded(hand_state.index_tip, hand_state.index_pip, fold_margin)
    middle_extended = _is_finger_extended(hand_state.middle_tip, hand_state.middle_pip, 0.015)
    ring_extended = _is_finger_extended(hand_state.ring_tip, hand_state.ring_pip, 0.015)
    return index_folded and not middle_extended and not ring_extended


def screen_touch_metric(hand_state: HandState) -> float | None:
    if hand_state.index_tip_z is None or hand_state.index_mcp_z is None:
        return None
    return hand_state.index_tip_z - hand_state.index_mcp_z


def hand_orientation_angle_deg(hand_state: HandState) -> float | None:
    if hand_state.wrist is None or hand_state.middle_mcp is None:
        return None
    delta_x = hand_state.middle_mcp[0] - hand_state.wrist[0]
    delta_y = hand_state.wrist[1] - hand_state.middle_mcp[1]
    if delta_x == 0.0 and delta_y == 0.0:
        return None
    return degrees(atan2(delta_x, delta_y))


def is_freeze_pose(hand_state: HandState, extension_margin: float, thumb_margin: float) -> bool:
    index_extended = _is_finger_extended(hand_state.index_tip, hand_state.index_pip, extension_margin)
    middle_extended = _is_finger_extended(hand_state.middle_tip, hand_state.middle_pip, extension_margin)
    ring_extended = _is_finger_extended(hand_state.ring_tip, hand_state.ring_pip, extension_margin)
    pinky_extended = _is_finger_extended(hand_state.pinky_tip, hand_state.pinky_pip, extension_margin)
    thumb_folded = _is_thumb_folded(hand_state, thumb_margin)
    return index_extended and middle_extended and ring_extended and pinky_extended and thumb_folded


def is_scroll_pose(hand_state: HandState, extension_margin: float = 0.015) -> bool:
    index_extended = _is_finger_extended(hand_state.index_tip, hand_state.index_pip, extension_margin)
    middle_extended = _is_finger_extended(hand_state.middle_tip, hand_state.middle_pip, extension_margin)
    fingers_close = _finger_distance(hand_state.index_tip, hand_state.middle_tip) <= 0.055
    return index_extended and middle_extended and fingers_close


def scroll_anchor_y(hand_state: HandState) -> float | None:
    if hand_state.index_tip is None or hand_state.middle_tip is None:
        return None
    return (hand_state.index_tip[1] + hand_state.middle_tip[1]) / 2.0


def scroll_anchor_x(hand_state: HandState) -> float | None:
    if hand_state.index_tip is None or hand_state.middle_tip is None:
        return None
    return (hand_state.index_tip[0] + hand_state.middle_tip[0]) / 2.0


def _finger_distance(
    first: tuple[float, float] | None,
    second: tuple[float, float] | None,
) -> float:
    if first is None or second is None:
        return 1.0
    return hypot(first[0] - second[0], first[1] - second[1])


def _is_finger_extended(
    tip: tuple[float, float] | None,
    pip: tuple[float, float] | None,
    margin: float,
) -> bool:
    if tip is None or pip is None:
        return False
    return tip[1] < (pip[1] - margin)


def _is_finger_folded(
    tip: tuple[float, float] | None,
    pip: tuple[float, float] | None,
    margin: float,
) -> bool:
    if tip is None or pip is None:
        return False
    return tip[1] > (pip[1] + margin)


def _is_thumb_folded(hand_state: HandState, margin: float) -> bool:
    if hand_state.thumb_tip is None or hand_state.index_mcp is None or hand_state.middle_mcp is None or hand_state.pinky_mcp is None:
        return False
    palm_knuckle_y = (hand_state.index_mcp[1] + hand_state.middle_mcp[1] + hand_state.pinky_mcp[1]) / 3.0
    return hand_state.thumb_tip[1] > (palm_knuckle_y - margin)


def _normalize_angle_deg(angle_deg: float) -> float:
    normalized = angle_deg
    while normalized <= -180.0:
        normalized += 360.0
    while normalized > 180.0:
        normalized -= 360.0
    return normalized
