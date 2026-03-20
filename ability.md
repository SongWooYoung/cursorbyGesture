# visualAgent Ability

현재 루트 구현은 Python + MediaPipe 전환 기준으로 정리한다.

## 현재 지원 동작

- Python 실행 진입점
  - `app.py`에서 루트 실행을 시작한다
  - 실제 구현 코드는 `src/visual_agent/` 아래에 둔다

- 카메라 입력
  - OpenCV `VideoCapture`로 macOS 카메라 입력을 연다
  - `.env`에서 카메라 인덱스와 프레임 크기를 조절한다

- 손 추적
  - MediaPipe Hands로 손 랜드마크를 추적한다
  - 현재는 첫 번째 손의 검지, 중지, 약지, 엄지 랜드마크를 사용해 cursor, click, scroll을 판정한다

- 디버그 프리뷰
  - OpenCV preview 창에서 카메라 프레임과 랜드마크를 함께 표시한다
  - `SHOW_DEBUG_PREVIEW`, `DRAW_LANDMARKS`로 on/off 할 수 있다

- 커서 이동
  - 검지 tip normalized 좌표를 macOS 화면 좌표로 변환해 커서를 이동한다
  - `DIRECT_INDEX_TIP_CURSOR=true`로 바꾸면 hand landmark의 검지 tip 좌표를 active region, smoothing, clutch, alignment offset 없이 바로 cursor로 보낼 수 있다
  - `MIRROR_CURSOR_HORIZONTALLY`, `MIRROR_CURSOR_VERTICALLY`로 좌우/상하 방향을 조절한다
  - `CURSOR_ACTIVE_REGION_MARGIN`으로 프레임 가장자리 노이즈 구간을 잘라낸 뒤 내부 영역만 화면 전체로 다시 매핑한다
  - `CURSOR_SMOOTHING`, `CURSOR_DEAD_ZONE`으로 작은 떨림을 줄이고 큰 이동은 더 빠르게 따라가게 한다
  - preview에서 `c`를 누르면 `3 2 1` countdown 뒤 현재 커서 타깃과 검지 포인트를 맞추는 calibration을 실행하고, 계산된 `CURSOR_ALIGNMENT_OFFSET_X/Y`와 neutral angle을 `.env`에 직접 저장한다
  - calibration은 이전의 좌/우 평균각도 균형 학습이 아니라 현재 pointing 자세를 기준으로 cursor offset과 neutral wrist angle만 다시 잡는다
  - 손 각도가 neutral 기준 가동범위를 넘으면 auto clutch로 커서를 잠시 멈추고, 복귀 시 현재 손 위치를 새 기준점으로 다시 잡아 re-anchor한다
  - freeze pose도 함께 지원해 auto clutch와 수동 clutch를 비교할 수 있다
  - preview에서 현재 손 각도, clutch 상태, 좌/우 resume/stop threshold, 현재 cursor offset을 함께 표시한다

- 클릭
  - 검지 tip의 `z` 깊이가 손가락 기준선보다 앞으로 두 번 튀어나오는 double touch motion을 좌클릭으로 사용한다
  - `CLICK_TOUCH_PRESS_DELTA`, `CLICK_TOUCH_RELEASE_DELTA`로 touch down/up hysteresis를 조절한다
  - `MINIMUM_CLICK_FRAMES`, `MINIMUM_CLICK_RELEASE_FRAMES`로 press/release 최소 유지 프레임을 조절한다
  - `CLICK_TOUCH_BASELINE_ALPHA`로 평상시 pointing 자세 baseline 적응 속도를 조절한다
  - `CLICK_DOUBLE_TAP_MAX_FRAMES` 안에서 두 번째 touch release가 들어와야 click이 발생한다

- 스크롤
  - 검지와 중지를 서로 가까이 모은 상태를 scroll pose로 사용한다
  - scroll pose 동안 두 손가락의 평균 y 이동량을 macOS vertical wheel event로 변환한다
  - 같은 pose에서 평균 x가 충분히 오른쪽/왼쪽으로 이동하면 각각 `Ctrl+Right`, `Ctrl+Left` 키 입력을 보낸다
  - `SCROLL_CONTROL_ENABLED`, `SCROLL_SENSITIVITY`, `SCROLL_DEAD_ZONE`, `SCROLL_NAVIGATION_THRESHOLD`, `SCROLL_NAVIGATION_COOLDOWN_FRAMES`, `MINIMUM_SCROLL_FRAMES`로 조절한다
  - scroll pose가 활성화되면 cursor 이동보다 scroll/navigation을 우선한다

## 현재 비활성화 또는 미이식 동작

- 화면 넘기기
- 창 보기 모드
- 확대/축소
- 영역 캡처
- 별도 제어 패널 UI
- RTSP 입력

## 보관된 이전 구현

- 기존 Swift + Vision 구현은 `SwiftVision/` 아래로 이동해 보관한다
- 이전 `Sources/`, `Tests/`, `Package.swift`, 외부 clone, reference 문서는 모두 `SwiftVision/` 아래에 있다

## 현재 제한 사항

- 현재 Python 구현은 1차 이식 골격이다
- macOS 입력 제어는 접근성 권한이 필요하다
- MediaPipe 결과를 기준으로 cursor 이동은 활성화되어 있고 click은 현재 비활성화, scroll/navigation은 검지+중지 close pose 기준으로 활성화 상태다
- cursor는 active region/damping 외에 auto clutch, freeze pose, re-anchor를 지원한다
- 현재 `.env` 기준 기본 런타임은 direct mode가 꺼져 있으므로 active region, smoothing, alignment offset, auto clutch 경로가 다시 사용된다
- cursor calibration은 preview에서 `c`로 실행하며 cursor alignment offset과 neutral angle을 `.env`에 저장해 사용한다
- click은 index fold pose가 아니라 검지 tip z-depth 기반 double touch motion으로 동작한다
- GitHub virtual mouse 예제의 active region, movement damping, frame-consistency click 로직을 1차 반영했다
- 제스처 우선순위, zoom, area capture는 아직 Python 경로에 다시 구현하지 않았다
