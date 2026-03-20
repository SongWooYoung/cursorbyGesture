# MediaPipe Virtual Mouse Patterns

현재 Python 루트 구현에 바로 반영할 가치가 높은 GitHub 패턴만 추려 정리한다.

## 1. Active Region Mapping

- 참고 저장소
  - `dheerajv1/hand_gesture_control`
  - `ravigithub19/ai-virtual-mouse` 계열 구현 패턴
- 핵심 아이디어
  - 카메라 전체 프레임을 그대로 화면 전체에 매핑하지 않는다.
  - 화면 가장자리 노이즈가 큰 구간을 잘라낸 뒤, 내부 ROI만 다시 0..1 화면 좌표로 보간한다.
- 현재 저장소 적용
  - `CURSOR_ACTIVE_REGION_MARGIN`을 추가했다.
  - 검지 tip 좌표를 margin 안쪽에서만 화면 전체로 매핑한다.
  - 손이 프레임 경계에서 흔들릴 때 커서가 갑자기 튀는 문제를 줄인다.

## 2. Distance-Aware Cursor Damping

- 참고 저장소
  - `Viral-Doshi/Gesture-Controlled-Virtual-Mouse`
- 핵심 아이디어
  - 모든 이동량에 같은 smoothing을 적용하지 않는다.
  - 작은 이동은 강하게 감쇠하고, 큰 이동은 더 빠르게 따라가도록 동적 반응 계수를 만든다.
- 현재 저장소 적용
  - `CURSOR_SMOOTHING`, `CURSOR_DEAD_ZONE`을 추가했다.
  - 작은 흔들림은 dead-zone에서 무시하고, 의미 있는 이동만 EMA 기반으로 반영한다.
  - 이동량이 클수록 alpha를 키워서 빠른 reposition이 가능하도록 했다.

## 3. Frame-Consistency Click Activation

- 참고 저장소
  - `Viral-Doshi/Gesture-Controlled-Virtual-Mouse`
  - 이전 Swift 구현에서 사용한 `MINIMUM_GESTURE_FRAMES` 아이디어
- 핵심 아이디어
  - pinch가 한 프레임만 들어왔다고 바로 클릭하지 않는다.
  - 동일한 click pose가 일정 프레임 연속 유지될 때만 state change를 확정한다.
- 현재 저장소 적용
  - `MINIMUM_CLICK_FRAMES`를 추가했다.
  - hysteresis는 유지하면서, pose 진입 자체는 debounce된 state tracker로 확정한다.
  - 경계값 근처 노이즈로 인한 오클릭을 더 줄인다.

## 적용 우선순위 판단

- 지금 단계에서 가장 큰 체감 개선은 커서 안정화다.
- 그래서 mode switching, drag, scroll보다 먼저 아래 순서로 반영했다.
  - active region mapping
  - distance-aware damping
  - frame-consistency click activation

## 아직 남아 있는 확장 후보

- explicit finger-state classifier
- drag hold gesture
- two-finger scroll mode
- gesture mode arbitration
- preview 상의 richer telemetry 표시