from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


def _as_bool(value: str | None, default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


@dataclass(slots=True)
class AppConfig:
    camera_index: int = 0
    frame_width: int = 1280
    frame_height: int = 720
    max_num_hands: int = 1
    min_detection_confidence: float = 0.6
    min_tracking_confidence: float = 0.6
    show_debug_preview: bool = True
    draw_landmarks: bool = True
    log_hand_summary: bool = False
    cursor_control_enabled: bool = True
    click_control_enabled: bool = False
    scroll_control_enabled: bool = False
    auto_clutch_enabled: bool = True
    freeze_pose_enabled: bool = True
    direct_index_tip_cursor: bool = False
    mirror_cursor_horizontally: bool = False
    mirror_cursor_vertically: bool = False
    cursor_smoothing: float = 0.85
    cursor_dead_zone: float = 0.012
    cursor_active_region_margin: float = 0.08
    cursor_alignment_offset_x: float = 0.0
    cursor_alignment_offset_y: float = 0.0
    calibration_countdown_seconds: int = 3
    calibration_capture_seconds: int = 5
    clutch_neutral_angle_deg: float = 0.0
    clutch_stop_delta_deg: float = 18.0
    clutch_resume_delta_deg: float = 10.0
    clutch_activation_frames: int = 2
    freeze_pose_margin: float = 0.015
    minimum_freeze_pose_frames: int = 2
    minimum_click_frames: int = 2
    minimum_click_release_frames: int = 2
    click_touch_press_delta: float = 0.030
    click_touch_release_delta: float = 0.014
    click_touch_baseline_alpha: float = 0.08
    click_index_fold_margin: float = 0.012
    click_double_tap_max_frames: int = 18
    scroll_sensitivity: float = 180.0
    scroll_dead_zone: float = 0.008
    scroll_navigation_threshold: float = 0.06
    scroll_navigation_cooldown_frames: int = 12
    minimum_scroll_frames: int = 2


def load_config(env_path: str | os.PathLike[str] = ".env") -> AppConfig:
    load_dotenv(Path(env_path))
    return AppConfig(
        camera_index=int(os.getenv("CAMERA_INDEX", "0")),
        frame_width=int(os.getenv("FRAME_WIDTH", "1280")),
        frame_height=int(os.getenv("FRAME_HEIGHT", "720")),
        max_num_hands=int(os.getenv("MAX_NUM_HANDS", "1")),
        min_detection_confidence=float(os.getenv("MIN_DETECTION_CONFIDENCE", "0.6")),
        min_tracking_confidence=float(os.getenv("MIN_TRACKING_CONFIDENCE", "0.6")),
        show_debug_preview=_as_bool(os.getenv("SHOW_DEBUG_PREVIEW"), True),
        draw_landmarks=_as_bool(os.getenv("DRAW_LANDMARKS"), True),
        log_hand_summary=_as_bool(os.getenv("LOG_HAND_SUMMARY"), False),
        cursor_control_enabled=_as_bool(os.getenv("CURSOR_CONTROL_ENABLED"), True),
        click_control_enabled=_as_bool(os.getenv("CLICK_CONTROL_ENABLED"), False),
        scroll_control_enabled=_as_bool(os.getenv("SCROLL_CONTROL_ENABLED"), False),
        auto_clutch_enabled=_as_bool(os.getenv("AUTO_CLUTCH_ENABLED"), True),
        freeze_pose_enabled=_as_bool(os.getenv("FREEZE_POSE_ENABLED"), True),
        direct_index_tip_cursor=_as_bool(os.getenv("DIRECT_INDEX_TIP_CURSOR"), False),
        mirror_cursor_horizontally=_as_bool(os.getenv("MIRROR_CURSOR_HORIZONTALLY"), False),
        mirror_cursor_vertically=_as_bool(os.getenv("MIRROR_CURSOR_VERTICALLY"), False),
        cursor_smoothing=float(os.getenv("CURSOR_SMOOTHING", "0.85")),
        cursor_dead_zone=float(os.getenv("CURSOR_DEAD_ZONE", "0.012")),
        cursor_active_region_margin=float(os.getenv("CURSOR_ACTIVE_REGION_MARGIN", "0.08")),
        cursor_alignment_offset_x=float(os.getenv("CURSOR_ALIGNMENT_OFFSET_X", "0.0")),
        cursor_alignment_offset_y=float(os.getenv("CURSOR_ALIGNMENT_OFFSET_Y", "0.0")),
        calibration_countdown_seconds=int(os.getenv("CALIBRATION_COUNTDOWN_SECONDS", "3")),
        calibration_capture_seconds=int(os.getenv("CALIBRATION_CAPTURE_SECONDS", "5")),
        clutch_neutral_angle_deg=float(os.getenv("CLUTCH_NEUTRAL_ANGLE_DEG", "0.0")),
        clutch_stop_delta_deg=float(os.getenv("CLUTCH_STOP_DELTA_DEG", "18.0")),
        clutch_resume_delta_deg=float(os.getenv("CLUTCH_RESUME_DELTA_DEG", "10.0")),
        clutch_activation_frames=int(os.getenv("CLUTCH_ACTIVATION_FRAMES", "2")),
        freeze_pose_margin=float(os.getenv("FREEZE_POSE_MARGIN", "0.015")),
        minimum_freeze_pose_frames=int(os.getenv("MINIMUM_FREEZE_POSE_FRAMES", "2")),
        minimum_click_frames=int(os.getenv("MINIMUM_CLICK_FRAMES", "2")),
        minimum_click_release_frames=int(os.getenv("MINIMUM_CLICK_RELEASE_FRAMES", "2")),
        click_touch_press_delta=float(os.getenv("CLICK_TOUCH_PRESS_DELTA", "0.030")),
        click_touch_release_delta=float(os.getenv("CLICK_TOUCH_RELEASE_DELTA", "0.014")),
        click_touch_baseline_alpha=float(os.getenv("CLICK_TOUCH_BASELINE_ALPHA", "0.08")),
        click_index_fold_margin=float(os.getenv("CLICK_INDEX_FOLD_MARGIN", "0.012")),
        click_double_tap_max_frames=int(os.getenv("CLICK_DOUBLE_TAP_MAX_FRAMES", "18")),
        scroll_sensitivity=float(os.getenv("SCROLL_SENSITIVITY", "180.0")),
        scroll_dead_zone=float(os.getenv("SCROLL_DEAD_ZONE", "0.008")),
        scroll_navigation_threshold=float(os.getenv("SCROLL_NAVIGATION_THRESHOLD", "0.06")),
        scroll_navigation_cooldown_frames=int(os.getenv("SCROLL_NAVIGATION_COOLDOWN_FRAMES", "12")),
        minimum_scroll_frames=int(os.getenv("MINIMUM_SCROLL_FRAMES", "2")),
    )


def persist_env_updates(env_path: str | os.PathLike[str], updates: dict[str, str]) -> None:
    path = Path(env_path)
    existing_lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    seen_keys: set[str] = set()
    new_lines: list[str] = []

    for line in existing_lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in line:
            new_lines.append(line)
            continue

        key, _, _ = line.partition("=")
        if key in updates:
            new_lines.append(f"{key}={updates[key]}")
            seen_keys.add(key)
        else:
            new_lines.append(line)

    for key, value in updates.items():
        if key not in seen_keys:
            new_lines.append(f"{key}={value}")

    path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
