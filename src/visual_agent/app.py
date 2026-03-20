from __future__ import annotations

from dataclasses import dataclass
from math import ceil
from statistics import mean, median
from time import monotonic

import cv2

from visual_agent.capture import CameraSource
from visual_agent.config import load_config, persist_env_updates
from visual_agent.control import CursorClutchMapper, CursorMapper, MacOSController, NormalizedPoint
from visual_agent.gestures import (
    AutoClutchController,
    AutoClutchState,
    DebouncedStateTracker,
    hand_orientation_angle_deg,
    is_freeze_pose,
    is_scroll_pose,
    ScreenTouchDoubleTapDetector,
    scroll_anchor_x,
    scroll_anchor_y,
    TouchClickState,
)
from visual_agent.hand_tracking import HandTracker


@dataclass(slots=True)
class CursorCalibrationResult:
    offset_x: float
    offset_y: float
    neutral_angle_deg: float


def main() -> int:
    config = load_config()
    camera = CameraSource(config)
    tracker = HandTracker(config)

    controller = MacOSController(
        enabled=config.cursor_control_enabled or config.click_control_enabled or config.scroll_control_enabled
    )
    cursor_mapper = CursorMapper(
        smoothing=config.cursor_smoothing,
        dead_zone=config.cursor_dead_zone,
        active_region_margin=config.cursor_active_region_margin,
    )
    clutch_mapper = CursorClutchMapper(
        base_offset=NormalizedPoint(
            x=config.cursor_alignment_offset_x,
            y=config.cursor_alignment_offset_y,
        )
    )
    auto_clutch_controller = AutoClutchController(
        neutral_angle_deg=config.clutch_neutral_angle_deg,
        stop_delta_deg=config.clutch_stop_delta_deg,
        resume_delta_deg=config.clutch_resume_delta_deg,
        required_frames=config.clutch_activation_frames,
    )
    freeze_pose_tracker = DebouncedStateTracker(False, required_frames=config.minimum_freeze_pose_frames)
    click_detector = ScreenTouchDoubleTapDetector(
        press_delta=config.click_touch_press_delta,
        release_delta=config.click_touch_release_delta,
        baseline_alpha=config.click_touch_baseline_alpha,
        press_frames=config.minimum_click_frames,
        release_frames=config.minimum_click_release_frames,
        max_interval_frames=config.click_double_tap_max_frames,
    )
    scroll_tracker = DebouncedStateTracker(False, required_frames=config.minimum_scroll_frames)
    previous_scroll_anchor: float | None = None
    scroll_origin_x: float | None = None
    scroll_navigation_cooldown = 0
    frame_index = 0
    previous_cursor_locked = False

    try:
        while True:
            frame = camera.read()
            if frame is None:
                continue
            frame_index += 1
            if scroll_navigation_cooldown > 0:
                scroll_navigation_cooldown -= 1

            tracking_frame = tracker.process(frame)
            hand_state = tracking_frame.hand_state
            raw_cursor_point: NormalizedPoint | None = None
            mapped_cursor: NormalizedPoint | None = clutch_mapper.current_output
            scroll_pose_active = False
            freeze_pose_active = False
            clutch_reason = "OFF"
            auto_clutch_state = AutoClutchState(angle_deg=None, delta_deg=None, active=False)
            click_state = TouchClickState(metric=None, baseline=None, delta=None, touching=False)
            direct_cursor_mode = config.direct_index_tip_cursor

            if hand_state and config.auto_clutch_enabled and not direct_cursor_mode:
                auto_clutch_state = auto_clutch_controller.update(hand_orientation_angle_deg(hand_state))
            elif hand_state:
                auto_clutch_state = AutoClutchState(
                    angle_deg=hand_orientation_angle_deg(hand_state),
                    delta_deg=0.0,
                    active=False,
                )
            else:
                auto_clutch_controller.reset()

            if hand_state and config.freeze_pose_enabled and not direct_cursor_mode:
                freeze_pose_active = is_freeze_pose(
                    hand_state=hand_state,
                    extension_margin=config.freeze_pose_margin,
                    thumb_margin=config.freeze_pose_margin,
                )
                freeze_pose_tracker.update(freeze_pose_active)
            else:
                freeze_pose_tracker.update(False)

            cursor_locked = False if direct_cursor_mode else (auto_clutch_state.active or freeze_pose_tracker.current)
            if auto_clutch_state.active and freeze_pose_tracker.current:
                clutch_reason = "AUTO+POSE"
            elif auto_clutch_state.active:
                clutch_reason = "AUTO"
            elif freeze_pose_tracker.current:
                clutch_reason = "POSE"
            elif direct_cursor_mode:
                clutch_reason = "DIRECT"

            if hand_state and config.scroll_control_enabled:
                scroll_pose_active = is_scroll_pose(hand_state)
                scroll_change = scroll_tracker.update(scroll_pose_active)
                current_anchor = scroll_anchor_y(hand_state)
                current_anchor_x = scroll_anchor_x(hand_state)
                if scroll_tracker.current and current_anchor is not None:
                    if scroll_change and scroll_change.current:
                        previous_scroll_anchor = current_anchor
                        scroll_origin_x = current_anchor_x
                    if previous_scroll_anchor is not None:
                        delta = previous_scroll_anchor - current_anchor
                        if abs(delta) >= config.scroll_dead_zone:
                            scroll_amount = int(round(delta * config.scroll_sensitivity))
                            controller.scroll_vertical(scroll_amount)
                    previous_scroll_anchor = current_anchor
                    if scroll_origin_x is not None and current_anchor_x is not None:
                        horizontal_delta = current_anchor_x - scroll_origin_x
                        if abs(horizontal_delta) >= config.scroll_navigation_threshold and scroll_navigation_cooldown == 0:
                            controller.send_control_arrow("right" if horizontal_delta > 0.0 else "left")
                            scroll_navigation_cooldown = config.scroll_navigation_cooldown_frames
                            scroll_origin_x = current_anchor_x
                else:
                    previous_scroll_anchor = current_anchor if scroll_change and scroll_change.current else None
                    scroll_origin_x = current_anchor_x if scroll_change and scroll_change.current else None
            else:
                scroll_tracker.update(False)
                previous_scroll_anchor = None
                scroll_origin_x = None

            if hand_state and hand_state.index_tip and config.cursor_control_enabled and not scroll_tracker.current:
                if direct_cursor_mode:
                    raw_cursor_point = NormalizedPoint(
                        x=hand_state.index_tip[0],
                        y=hand_state.index_tip[1],
                    )
                    mapped_cursor = raw_cursor_point
                    controller.move_cursor(
                        normalized_x=mapped_cursor.x,
                        normalized_y=mapped_cursor.y,
                        mirror_x=config.mirror_cursor_horizontally,
                        mirror_y=config.mirror_cursor_vertically,
                    )
                else:
                    raw_cursor_point = cursor_mapper.update(
                        normalized_x=hand_state.index_tip[0],
                        normalized_y=hand_state.index_tip[1],
                    )
                    if cursor_locked and not previous_cursor_locked:
                        clutch_mapper.lock()
                    elif not cursor_locked and previous_cursor_locked and raw_cursor_point is not None:
                        mapped_cursor = clutch_mapper.unlock(raw_cursor_point)

                    if not cursor_locked and raw_cursor_point is not None:
                        mapped_cursor = clutch_mapper.update(raw_cursor_point)
                        controller.move_cursor(
                            normalized_x=mapped_cursor.x,
                            normalized_y=mapped_cursor.y,
                            mirror_x=config.mirror_cursor_horizontally,
                            mirror_y=config.mirror_cursor_vertically,
                        )
                    else:
                        mapped_cursor = clutch_mapper.current_output
            elif not hand_state:
                cursor_mapper.reset()
                clutch_mapper.reset()
                auto_clutch_controller.reset()
                freeze_pose_tracker.update(False)
                previous_cursor_locked = False
                clutch_reason = "OFF"

            if hand_state and config.click_control_enabled and not scroll_tracker.current:
                click_state, click_fired = click_detector.update(hand_state, frame_index)
                if click_fired:
                    controller.left_click()
            else:
                click_detector.reset()

            if config.show_debug_preview:
                preview = frame.copy()
                if config.draw_landmarks:
                    tracker.draw(preview, tracking_frame)
                _draw_active_region(preview, cursor_mapper)
                _draw_status(
                    preview,
                    hand_state,
                    mapped_cursor,
                    click_state,
                    scroll_tracker.current,
                    auto_clutch_state,
                    freeze_pose_tracker.current,
                    clutch_reason,
                    auto_clutch_controller.resume_left_angle_deg,
                    auto_clutch_controller.resume_right_angle_deg,
                    auto_clutch_controller.stop_left_angle_deg,
                    auto_clutch_controller.stop_right_angle_deg,
                    clutch_mapper.base_offset,
                    direct_cursor_mode,
                )
                cv2.imshow("visualAgent Python", preview)
                key = cv2.waitKey(1) & 0xFF
                if key in {ord("c"), ord("C"), 32} and config.cursor_control_enabled and not direct_cursor_mode:
                    calibration = _run_cursor_alignment_calibration(
                        camera=camera,
                        tracker=tracker,
                        controller=controller,
                        cursor_mapper=cursor_mapper,
                        config=config,
                    )
                    if calibration is not None:
                        persist_env_updates(
                            ".env",
                            {
                                "CURSOR_ALIGNMENT_OFFSET_X": f"{calibration.offset_x:.4f}",
                                "CURSOR_ALIGNMENT_OFFSET_Y": f"{calibration.offset_y:.4f}",
                                "CLUTCH_NEUTRAL_ANGLE_DEG": f"{calibration.neutral_angle_deg:.3f}",
                            },
                        )
                        config.cursor_alignment_offset_x = calibration.offset_x
                        config.cursor_alignment_offset_y = calibration.offset_y
                        config.clutch_neutral_angle_deg = calibration.neutral_angle_deg
                        clutch_mapper = CursorClutchMapper(
                            base_offset=NormalizedPoint(
                                x=config.cursor_alignment_offset_x,
                                y=config.cursor_alignment_offset_y,
                            )
                        )
                        auto_clutch_controller = AutoClutchController(
                            neutral_angle_deg=config.clutch_neutral_angle_deg,
                            stop_delta_deg=config.clutch_stop_delta_deg,
                            resume_delta_deg=config.clutch_resume_delta_deg,
                            required_frames=config.clutch_activation_frames,
                        )
                        cursor_mapper.reset()
                        previous_cursor_locked = False
                    continue
                if key in {27, ord("q")}:
                    break
            previous_cursor_locked = cursor_locked
    finally:
        tracker.close()
        camera.close()
        if config.show_debug_preview:
            cv2.destroyAllWindows()

    return 0


def _draw_status(
    frame,
    hand_state,
    mapped_cursor: NormalizedPoint | None,
    click_state: TouchClickState,
    scroll_active: bool,
    auto_clutch_state: AutoClutchState,
    freeze_pose_active: bool,
    clutch_reason: str,
    clutch_resume_left_angle_deg: float,
    clutch_resume_right_angle_deg: float,
    clutch_stop_left_angle_deg: float,
    clutch_stop_right_angle_deg: float,
    cursor_offset: NormalizedPoint,
    direct_cursor_mode: bool,
) -> None:
    if not hand_state:
        cv2.putText(frame, "No hand", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 255), 2)
        return

    click_text = "ON" if click_state.touching else "OFF"
    click_delta_text = "n/a" if click_state.delta is None else f"{click_state.delta:+.3f}"
    cv2.putText(frame, f"Touch click: {click_text}  d={click_delta_text}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.86, (255, 200, 0), 2)
    scroll_text = "ON" if scroll_active else "OFF"
    cv2.putText(frame, f"Scroll: {scroll_text}", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 128, 255), 2)
    freeze_text = "ON" if freeze_pose_active else "OFF"
    cv2.putText(frame, f"Freeze pose: {freeze_text}", (20, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 220, 220), 2)

    angle_text = "n/a"
    if auto_clutch_state.angle_deg is not None and auto_clutch_state.delta_deg is not None:
        angle_text = f"{auto_clutch_state.angle_deg:.1f} ({auto_clutch_state.delta_deg:+.1f})"
    cv2.putText(frame, f"Angle: {angle_text}", (20, 160), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
    cv2.putText(frame, f"Clutch: {clutch_reason}", (20, 200), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (100, 220, 255), 2)
    cv2.putText(
        frame,
        f"Resume L/R: {clutch_resume_left_angle_deg:.0f} / {clutch_resume_right_angle_deg:.0f}",
        (20, 240),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.62,
        (180, 255, 180),
        2,
    )
    cv2.putText(
        frame,
        f"Stop L/R: {clutch_stop_left_angle_deg:.0f} / {clutch_stop_right_angle_deg:.0f}",
        (20, 280),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.75,
        (180, 220, 255),
        2,
    )
    cv2.putText(
        frame,
        f"Cursor offset: {cursor_offset.x:+.3f} / {cursor_offset.y:+.3f}   taps={click_state.tap_count}",
        (20, 320),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.72,
        (255, 220, 180),
        2,
    )
    cv2.putText(
        frame,
        "Direct tip mode" if direct_cursor_mode else "Click preview window, then press C or Space to calibrate",
        (20, 360),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.68,
        (180, 255, 180),
        2,
    )

    if mapped_cursor is not None:
        frame_height, frame_width = frame.shape[:2]
        cursor_x = int(mapped_cursor.x * frame_width)
        cursor_y = int(mapped_cursor.y * frame_height)
        cv2.circle(frame, (cursor_x, cursor_y), 10, (0, 255, 255), 2)


def _draw_active_region(frame, cursor_mapper: CursorMapper) -> None:
    left, top, right, bottom = cursor_mapper.active_region
    frame_height, frame_width = frame.shape[:2]
    start = (int(left * frame_width), int(top * frame_height))
    end = (int(right * frame_width), int(bottom * frame_height))
    cv2.rectangle(frame, start, end, (255, 128, 0), 2)


def _run_cursor_alignment_calibration(
    camera: CameraSource,
    tracker: HandTracker,
    controller: MacOSController,
    cursor_mapper: CursorMapper,
    config,
) -> CursorCalibrationResult | None:
    countdown_seconds = max(1, config.calibration_countdown_seconds)
    capture_seconds = max(2, config.calibration_capture_seconds)
    target_cursor = controller.read_normalized_cursor(
        mirror_x=config.mirror_cursor_horizontally,
        mirror_y=config.mirror_cursor_vertically,
    )
    if target_cursor is None:
        return None

    start_time = monotonic()
    raw_cursor_samples: list[NormalizedPoint] = []
    angle_samples: list[float] = []

    while True:
        frame = camera.read()
        if frame is None:
            continue

        tracking_frame = tracker.process(frame)
        hand_state = tracking_frame.hand_state
        angle_deg = hand_orientation_angle_deg(hand_state) if hand_state else None
        elapsed = monotonic() - start_time
        live_cursor_point: NormalizedPoint | None = None
        if hand_state and hand_state.index_tip:
            live_cursor_point = cursor_mapper.project(
                normalized_x=hand_state.index_tip[0],
                normalized_y=hand_state.index_tip[1],
            )

        preview = frame.copy()
        if config.draw_landmarks:
            tracker.draw(preview, tracking_frame)
        _draw_active_region(preview, cursor_mapper)
        _draw_calibration_target(preview, target_cursor, (80, 220, 255), 2)
        if live_cursor_point is not None:
            _draw_calibration_target(preview, live_cursor_point, (0, 255, 255), 1)

        if elapsed < countdown_seconds:
            countdown_value = max(1, ceil(countdown_seconds - elapsed))
            _draw_calibration_overlay(
                preview,
                headline=str(countdown_value),
                subline="Align your index tip with the frozen cursor target",
                angle_deg=angle_deg,
                sample_count=len(raw_cursor_samples),
                color=(0, 255, 255),
            )
        elif elapsed < countdown_seconds + capture_seconds:
            if live_cursor_point is not None:
                raw_cursor_samples.append(live_cursor_point)
            if angle_deg is not None:
                angle_samples.append(angle_deg)
            remaining = max(0, ceil((countdown_seconds + capture_seconds) - elapsed))
            _draw_calibration_overlay(
                preview,
                headline="Calibrating",
                subline=f"Hold the fingertip on the target  {remaining}s",
                angle_deg=angle_deg,
                sample_count=len(raw_cursor_samples),
                color=(0, 220, 120),
            )
        else:
            break

        cv2.imshow("visualAgent Python", preview)
        key = cv2.waitKey(1) & 0xFF
        if key in {27, ord("q")}:
            return None

    calibration = _calculate_cursor_calibration(target_cursor, raw_cursor_samples, angle_samples, config)
    if calibration is None:
        return None

    confirmation = camera.read()
    if confirmation is not None:
        preview = confirmation.copy()
        _draw_calibration_overlay(
            preview,
            headline="Calibration Saved",
            subline=(
                f"offset {calibration.offset_x:+.3f}, {calibration.offset_y:+.3f} / "
                f"neutral {calibration.neutral_angle_deg:.1f}"
            ),
            angle_deg=calibration.neutral_angle_deg,
            sample_count=len(raw_cursor_samples),
            color=(120, 255, 120),
        )
        _draw_calibration_target(preview, target_cursor, (120, 255, 120), 2)
        cv2.imshow("visualAgent Python", preview)
        cv2.waitKey(700)

    return calibration


def _calculate_cursor_calibration(
    target_cursor: NormalizedPoint,
    raw_cursor_samples: list[NormalizedPoint],
    angle_samples: list[float],
    config,
) -> CursorCalibrationResult | None:
    if len(raw_cursor_samples) < 15:
        return None

    average_raw_x = mean(sample.x for sample in raw_cursor_samples)
    average_raw_y = mean(sample.y for sample in raw_cursor_samples)
    neutral_angle_deg = median(angle_samples) if angle_samples else config.clutch_neutral_angle_deg

    return CursorCalibrationResult(
        offset_x=_clamp_offset(target_cursor.x - average_raw_x),
        offset_y=_clamp_offset(target_cursor.y - average_raw_y),
        neutral_angle_deg=neutral_angle_deg,
    )


def _clamp_offset(value: float) -> float:
    return max(-1.0, min(1.0, value))


def _draw_calibration_target(
    frame,
    normalized_point: NormalizedPoint,
    color: tuple[int, int, int],
    thickness: int,
) -> None:
    frame_height, frame_width = frame.shape[:2]
    point = (int(normalized_point.x * frame_width), int(normalized_point.y * frame_height))
    cv2.circle(frame, point, 18, color, thickness)
    cv2.line(frame, (point[0] - 10, point[1]), (point[0] + 10, point[1]), color, thickness)
    cv2.line(frame, (point[0], point[1] - 10), (point[0], point[1] + 10), color, thickness)


def _draw_calibration_overlay(
    frame,
    headline: str,
    subline: str,
    angle_deg: float | None,
    sample_count: int,
    color: tuple[int, int, int],
) -> None:
    frame_height, frame_width = frame.shape[:2]
    cv2.rectangle(frame, (40, 40), (frame_width - 40, 220), (20, 20, 20), -1)
    cv2.putText(frame, headline, (60, 115), cv2.FONT_HERSHEY_SIMPLEX, 2.0, color, 4)
    cv2.putText(frame, subline, (60, 160), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (240, 240, 240), 2)
    angle_text = "n/a" if angle_deg is None else f"{angle_deg:.1f} deg"
    cv2.putText(frame, f"Angle: {angle_text}", (60, 195), cv2.FONT_HERSHEY_SIMPLEX, 0.75, (200, 220, 255), 2)
    cv2.putText(frame, f"Samples: {sample_count}", (300, 195), cv2.FONT_HERSHEY_SIMPLEX, 0.75, (200, 220, 255), 2)