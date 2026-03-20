# Gesture Open Source Comparison

이 문서는 `opensource/` 아래에 clone한 4개 오픈소스 저장소의 구현 방식을 비교하고, 현재 저장소에 적용 가능한 방법론만 추려 정리한 문서다.

## 대상 저장소

- `opensource/gesture_mouse/`
- `opensource/HandGesture/`
- `opensource/HandVector/`
- `opensource/gesture/`

## clone 원칙

- 외부 저장소는 `opensource/` 아래 컨테이너 폴더에만 clone 한다.
- 현재 저장소의 핵심 구조 문서에서는 `opensource/` 하위 전체를 추적하지 않는다.
- 비교와 적용 메모는 현재 저장소의 `reference/` 아래에 별도 문서로 남긴다.
- 이번 clone은 용량과 작업 범위를 줄이기 위해 `--depth 1` 얕은 clone으로 받았다.

## 저장소별 구현 방식

### 1. `gesture_mouse`

- 언어/플랫폼
  - Python 기반 데스크톱 앱이다.
  - OpenCV, MediaPipe, PySide6를 사용한다.
- 입력 파이프라인
  - 웹캠 영상을 OpenCV로 읽는다.
  - `Demo.py`, `SignalsCalculator.py`, `PnPHeadPose.py`를 중심으로 얼굴 랜드마크와 head pose를 계산한다.
- 추적 방식
  - 손이 아니라 얼굴 랜드마크 기반이다.
  - `KalmanFilter1D.py`로 개별 신호를 안정화한다.
  - `config/mediapipe_default.json`에 신호별 필터와 threshold를 분리해 둔다.
- 커서 제어 방식
  - `Mouse.py`에서 absolute, relative, joystick, hybrid 같은 복수 모드를 제공한다.
  - 단순 절대 좌표 매핑이 아니라 입력 특성에 따라 모드를 바꿀 수 있게 설계되어 있다.
- 제스처 해석 방식
  - `Gesture.py`에서 threshold crossing, hold, delay, hysteresis를 함께 쓴다.
  - 한 프레임만 기준으로 즉시 발동하지 않고 상태 전환 중심으로 본다.
- 시사점
  - 현재 저장소와 직접 같은 손 추적 방식은 아니지만, signal filtering과 hysteresis 설계는 재사용 가치가 높다.

### 2. `HandGesture`

- 언어/플랫폼
  - Swift 기반 visionOS 라이브러리다.
- 입력 파이프라인
  - ARKit hand anchor를 받아 semantic gesture로 해석한다.
  - `Sources/HandGesture/HandGesture.swift`가 중심 진입점이다.
- 추적 방식
  - 손 skeleton joint를 그대로 사용한다.
  - gesture마다 별도 타입과 `update(with:)` 경로를 둔다.
- 제스처 해석 방식
  - `Sources/HandGesture/Gestures/` 아래에 clap, punch, finger gun 같은 gesture 타입이 분리되어 있다.
  - `PunchGesture.swift`는 이전 프레임과 비교해 속도를 계산한다.
  - `HandGesture+onChanged.swift`는 값이 바뀔 때만 callback을 발생시킨다.
- 시사점
  - 현재 저장소도 Swift이므로 구조적 아이디어를 가져오기 좋다.
  - 특히 gesture별 상태 객체 분리와 state change 기반 이벤트 발행 방식이 유용하다.

### 3. `HandVector`

- 언어/플랫폼
  - Swift 기반 visionOS hand pose matching 라이브러리다.
- 입력 파이프라인
  - ARKit hand joint를 vector와 finger shape parameter로 변환한다.
  - `Sources/HandVector/HVHandInfo.swift`, `HVFingerShape.swift`가 핵심이다.
- 추적 방식
  - cosine similarity와 finger curl/spread 값을 사용한다.
  - 포즈를 joint distance 하나로 보지 않고 손가락별 shape descriptor로 바꾼다.
- 제스처 해석 방식
  - built-in pose JSON과 비교하거나 per-finger similarity를 계산한다.
  - temporal gesture보다는 static pose matching에 강하다.
- 시사점
  - 현재 저장소의 `isTwoFingerScrollPose`, pinch 기반 click 판정을 더 풍부한 finger descriptor 방식으로 확장할 수 있다.
  - 포즈를 binary threshold로만 보지 않고 손가락별 score로 보는 접근이 특히 유용하다.

### 4. `gesture`

- 언어/플랫폼
  - iOS 앱, Go desktop server, WebSocket/Web 조합의 다중 구성 저장소다.
- 입력 파이프라인
  - iPhone 쪽에서 손 정보를 추적해 desktop 쪽으로 넘긴다.
  - `desktop/input.go`, `desktop/cursors/`가 데스크톱 제어 핵심이다.
- 추적 방식
  - 3D hand position과 shape classification을 사용한다.
  - right hand를 cursor control에 직접 매핑한다.
- 커서 제어 방식
  - `desktop/cursors/spline.go`와 `desktop/cursors/cursors.go`에서 spline interpolation을 사용한다.
  - discrete sample을 그대로 쓰지 않고 부드러운 trajectory로 보간한다.
- 제스처 해석 방식
  - shape string 기반으로 click state를 만든다.
  - position stream과 shape classification이 분리되어 있다.
- 시사점
  - 현재 저장소는 로컬 카메라 기반이라 네트워크 보간은 필수는 아니지만, spline 기반 path smoothing은 cursor 품질 개선에 참고할 가치가 있다.

## 교차 비교 요약

### 공통적으로 보인 패턴

- 입력 신호를 바로 이벤트로 내보내지 않고 상태를 한 번 더 안정화한다.
- 커서 이동과 gesture classification을 분리한다.
- static pose와 dynamic gesture를 같은 규칙으로 처리하지 않는다.
- 이전 프레임 상태를 저장하고 변화량이나 state transition을 기준으로 판단한다.

### 저장소별 강점

- `gesture_mouse`
  - filtering, hysteresis, configurable threshold 구조가 가장 강하다.
- `HandGesture`
  - Swift 코드 구조와 state change callback 패턴이 가장 깔끔하다.
- `HandVector`
  - 손가락별 shape descriptor와 score 기반 포즈 판정이 강하다.
- `gesture`
  - cursor path interpolation과 실제 pointer animation 계층이 분리되어 있다.

## 현재 저장소에 바로 적용 가능한 방법론

### 1. hysteresis threshold 도입

- 참고 소스
  - `opensource/gesture_mouse/Gesture.py`
  - `opensource/gesture_mouse/config/mediapipe_default.json`
- 현재 저장소 적용 위치
  - `Sources/Gesture/ClickGestureRule.swift`
  - `Sources/Gesture/TwoFingerNavigationRule.swift`
  - `Sources/Config/ThresholdConfig.swift`
- 적용 이유
  - 현재는 activation threshold 하나로 처리하는 구간이 많아 경계 근처에서 튀기 쉽다.
  - activation과 release threshold를 분리하면 click, scroll pose, future drag에 모두 도움이 된다.

### 2. state change 기반 이벤트 발행

- 참고 소스
  - `opensource/HandGesture/Sources/HandGesture/HandGesture+onChanged.swift`
- 현재 저장소 적용 위치
  - `Sources/Gesture/GestureEngine.swift`
- 적용 이유
  - 지금도 click은 one-shot으로 바꿨지만 gesture별로 일반화된 state tracker는 아직 없다.
  - click, drag, scroll on/off, future zoom까지 같은 패턴으로 관리할 수 있다.

### 3. velocity 기반 동적 gesture 분리

- 참고 소스
  - `opensource/HandGesture/Sources/HandGesture/Gestures/PunchGesture.swift`
- 현재 저장소 적용 위치
  - `Sources/Gesture/GestureEngine.swift`
  - `Sources/VisionPipeline/HandLandmark.swift`
  - future dynamic gesture rules
- 적용 이유
  - static pose와 moving pose를 분리해야 오작동이 줄어든다.
  - 예를 들어 pinch + low velocity는 click, pinch + sustained movement는 drag 같은 해석이 가능해진다.

### 4. finger descriptor 기반 포즈 점수화

- 참고 소스
  - `opensource/HandVector/Sources/HandVector/HVFingerShape.swift`
  - `opensource/HandVector/Sources/HandVector/HVHandInfo+CosineSimilary.swift`
- 현재 저장소 적용 위치
  - `Sources/VisionPipeline/HandLandmark.swift`
  - `Sources/Gesture/ClickGestureRule.swift`
  - `Sources/Gesture/TwoFingerNavigationRule.swift`
- 적용 이유
  - 현재는 extended/folded binary threshold 위주라 환경 변화에 약하다.
  - 손가락별 curl/spread score를 계산하면 포즈 판정을 더 유연하게 만들 수 있다.

### 5. cursor movement mode 분리

- 참고 소스
  - `opensource/gesture_mouse/Mouse.py`
- 현재 저장소 적용 위치
  - `Sources/Gesture/CursorGestureRule.swift`
  - `Sources/Config/AppConfig.swift`
  - `Sources/Config/ConfigLoader.swift`
- 적용 이유
  - absolute mapping만으로는 사용자마다 체감이 크게 다르다.
  - `absolute`, `relative`, `hybrid` 같은 모드를 두면 손 떨림과 큰 이동 문제를 따로 다룰 수 있다.

### 6. spline interpolation 기반 cursor smoothing

- 참고 소스
  - `opensource/gesture/desktop/cursors/spline.go`
  - `opensource/gesture/desktop/cursors/cursors.go`
- 현재 저장소 적용 위치
  - `Sources/Support/EMAFilter.swift`
  - 또는 신규 `Sources/Support/SplineInterpolator.swift`
- 적용 이유
  - 현재 EMA만으로는 급격한 방향 전환과 세밀한 이동을 동시에 만족시키기 어렵다.
  - 보간 계층을 분리하면 RTSP 입력이나 프레임 드롭 상황에도 유리하다.

## 현재 저장소 기준 우선순위

### 바로 적용 추천

1. hysteresis threshold
2. generalized state change tracker
3. velocity 기반 click/drag 분리

### 중기 적용 추천

1. finger descriptor 기반 pose scoring
2. cursor movement mode 분리

### 나중 적용 추천

1. spline interpolation
2. network-aware interpolation

## 현재 저장소와의 연결 메모

- 현재 저장소는 `Vision` 기반 2D landmark와 AppKit event dispatch 구조를 쓰므로, visionOS 전용 API 의존 부분은 직접 이식 대상이 아니다.
- 대신 아래 두 방향이 가장 현실적이다.
  - `gesture_mouse`의 filtering/hysteresis/state machine 철학을 가져온다.
  - `HandGesture`, `HandVector`의 Swift 쪽 gesture abstraction과 pose scoring 방식을 현재 `GestureEngine` 구조에 맞게 재구성한다.

## 결론

- 가장 직접적으로 도움이 되는 저장소는 `gesture_mouse`와 `HandGesture`다.
- `gesture_mouse`는 안정화와 threshold 설계가 강하고,
- `HandGesture`는 Swift 쪽 이벤트 구조와 gesture abstraction이 좋다.
- `HandVector`는 이후 포즈 인식 정교화 단계에서 가치가 크고,
- `gesture`는 remote transport보다 cursor interpolation 계층 설계 참고용으로 보는 것이 맞다.