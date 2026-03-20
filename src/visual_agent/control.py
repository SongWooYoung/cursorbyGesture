from __future__ import annotations

from dataclasses import dataclass
from math import hypot

try:
    from Quartz import (
        CGDisplayBounds,
        CGMainDisplayID,
        CGWarpMouseCursorPosition,
        CGPoint,
        CGEventCreate,
        CGEventGetLocation,
        CGEventCreateMouseEvent,
        CGEventCreateKeyboardEvent,
        CGEventPost,
        CGEventSetFlags,
        CGEventCreateScrollWheelEvent,
        kCGHIDEventTap,
        kCGEventLeftMouseDown,
        kCGEventLeftMouseUp,
        kCGMouseButtonLeft,
        kCGEventFlagMaskControl,
        kCGScrollEventUnitLine,
    )
except ImportError:  # pragma: no cover - fallback on unsupported machines
    CGDisplayBounds = None
    CGMainDisplayID = None
    CGWarpMouseCursorPosition = None
    CGPoint = None
    CGEventCreate = None
    CGEventGetLocation = None
    CGEventCreateMouseEvent = None
    CGEventCreateKeyboardEvent = None
    CGEventPost = None
    CGEventSetFlags = None
    CGEventCreateScrollWheelEvent = None
    kCGHIDEventTap = None
    kCGEventLeftMouseDown = None
    kCGEventLeftMouseUp = None
    kCGMouseButtonLeft = None
    kCGEventFlagMaskControl = None
    kCGScrollEventUnitLine = None


@dataclass(slots=True)
class ScreenBounds:
    width: float
    height: float


@dataclass(slots=True)
class NormalizedPoint:
    x: float
    y: float


def _clamp(value: float, minimum: float, maximum: float) -> float:
    return max(minimum, min(maximum, value))


_KEY_CODE_LEFT_ARROW = 123
_KEY_CODE_RIGHT_ARROW = 124
_KEY_CODE_CONTROL = 59


class CursorClutchMapper:
    def __init__(self, base_offset: NormalizedPoint | None = None) -> None:
        self._base_offset = base_offset or NormalizedPoint(0.0, 0.0)
        self._offset = self._base_offset
        self._last_output: NormalizedPoint | None = None
        self._locked_output: NormalizedPoint | None = None

    @property
    def current_output(self) -> NormalizedPoint | None:
        return self._locked_output or self._last_output

    @property
    def base_offset(self) -> NormalizedPoint:
        return self._base_offset

    def reset(self) -> None:
        self._offset = self._base_offset
        self._last_output = None
        self._locked_output = None

    def set_base_offset(self, offset: NormalizedPoint) -> None:
        self._base_offset = offset
        self.reset()

    def update(self, hand_point: NormalizedPoint) -> NormalizedPoint:
        output = NormalizedPoint(
            x=_clamp(hand_point.x + self._offset.x, 0.0, 1.0),
            y=_clamp(hand_point.y + self._offset.y, 0.0, 1.0),
        )
        self._last_output = output
        return output

    def lock(self) -> None:
        if self._last_output is not None:
            self._locked_output = self._last_output

    def unlock(self, hand_point: NormalizedPoint) -> NormalizedPoint:
        target = self._locked_output or self._last_output or hand_point
        self._offset = NormalizedPoint(
            x=target.x - hand_point.x,
            y=target.y - hand_point.y,
        )
        self._locked_output = None
        self._last_output = target
        return target


class CursorMapper:
    def __init__(self, smoothing: float, dead_zone: float, active_region_margin: float) -> None:
        self._smoothing = _clamp(smoothing, 0.0, 0.98)
        self._dead_zone = _clamp(dead_zone, 0.0, 0.25)
        self._margin = _clamp(active_region_margin, 0.0, 0.45)
        self._last_output: NormalizedPoint | None = None

    @property
    def active_region(self) -> tuple[float, float, float, float]:
        left = self._margin
        top = self._margin
        right = 1.0 - self._margin
        bottom = 1.0 - self._margin
        return left, top, right, bottom

    def reset(self) -> None:
        self._last_output = None

    def project(self, normalized_x: float, normalized_y: float) -> NormalizedPoint:
        return self._map_to_active_region(normalized_x, normalized_y)

    def update(self, normalized_x: float, normalized_y: float) -> NormalizedPoint:
        mapped = self.project(normalized_x, normalized_y)
        if self._last_output is None:
            self._last_output = mapped
            return mapped

        delta_x = mapped.x - self._last_output.x
        delta_y = mapped.y - self._last_output.y
        distance = hypot(delta_x, delta_y)
        if distance <= self._dead_zone:
            return self._last_output

        base_alpha = max(0.02, 1.0 - self._smoothing)
        distance_boost = min(0.75, distance * 2.5)
        alpha = min(1.0, base_alpha + distance_boost)

        smoothed = NormalizedPoint(
            x=_clamp(self._last_output.x + delta_x * alpha, 0.0, 1.0),
            y=_clamp(self._last_output.y + delta_y * alpha, 0.0, 1.0),
        )
        self._last_output = smoothed
        return smoothed

    def _map_to_active_region(self, normalized_x: float, normalized_y: float) -> NormalizedPoint:
        left, top, right, bottom = self.active_region
        width = max(0.01, right - left)
        height = max(0.01, bottom - top)
        clamped_x = _clamp(normalized_x, left, right)
        clamped_y = _clamp(normalized_y, top, bottom)
        return NormalizedPoint(
            x=(clamped_x - left) / width,
            y=(clamped_y - top) / height,
        )


class MacOSController:
    def __init__(self, enabled: bool = True) -> None:
        self._enabled = enabled and CGDisplayBounds is not None
        self._screen_bounds = self._read_screen_bounds()

    def move_cursor(self, normalized_x: float, normalized_y: float, mirror_x: bool, mirror_y: bool) -> None:
        if not self._enabled:
            return

        screen_x = 1.0 - normalized_x if mirror_x else normalized_x
        screen_y = 1.0 - normalized_y if mirror_y else normalized_y
        point = CGPoint(
            screen_x * self._screen_bounds.width,
            screen_y * self._screen_bounds.height,
        )
        CGWarpMouseCursorPosition(point)

    def left_click(self) -> None:
        if not self._enabled:
            return

        current = CGEventGetLocation(CGEventCreate(None))
        down = CGEventCreateMouseEvent(None, kCGEventLeftMouseDown, current, kCGMouseButtonLeft)
        up = CGEventCreateMouseEvent(None, kCGEventLeftMouseUp, current, kCGMouseButtonLeft)
        CGEventPost(kCGHIDEventTap, down)
        CGEventPost(kCGHIDEventTap, up)

    def scroll_vertical(self, delta: int) -> None:
        if not self._enabled or delta == 0 or CGEventCreateScrollWheelEvent is None:
            return

        event = CGEventCreateScrollWheelEvent(None, kCGScrollEventUnitLine, 1, delta)
        CGEventPost(kCGHIDEventTap, event)

    def send_control_arrow(self, direction: str) -> None:
        if not self._enabled or CGEventCreateKeyboardEvent is None or CGEventSetFlags is None:
            return

        key_code = _KEY_CODE_RIGHT_ARROW if direction == "right" else _KEY_CODE_LEFT_ARROW
        control_down = CGEventCreateKeyboardEvent(None, _KEY_CODE_CONTROL, True)
        arrow_down = CGEventCreateKeyboardEvent(None, key_code, True)
        arrow_up = CGEventCreateKeyboardEvent(None, key_code, False)
        control_up = CGEventCreateKeyboardEvent(None, _KEY_CODE_CONTROL, False)

        CGEventSetFlags(arrow_down, kCGEventFlagMaskControl)
        CGEventSetFlags(arrow_up, kCGEventFlagMaskControl)

        CGEventPost(kCGHIDEventTap, control_down)
        CGEventPost(kCGHIDEventTap, arrow_down)
        CGEventPost(kCGHIDEventTap, arrow_up)
        CGEventPost(kCGHIDEventTap, control_up)

    def read_normalized_cursor(self, mirror_x: bool, mirror_y: bool) -> NormalizedPoint | None:
        if not self._enabled or CGEventCreate is None or CGEventGetLocation is None:
            return None

        current = CGEventGetLocation(CGEventCreate(None))
        normalized_x = current.x / max(1.0, self._screen_bounds.width)
        normalized_y = current.y / max(1.0, self._screen_bounds.height)
        return NormalizedPoint(
            x=1.0 - normalized_x if mirror_x else normalized_x,
            y=1.0 - normalized_y if mirror_y else normalized_y,
        )

    def _read_screen_bounds(self) -> ScreenBounds:
        if CGDisplayBounds is None:
            return ScreenBounds(width=1920, height=1080)
        bounds = CGDisplayBounds(CGMainDisplayID())
        return ScreenBounds(width=bounds.size.width, height=bounds.size.height)
