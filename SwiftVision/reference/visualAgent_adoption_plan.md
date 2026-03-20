# visualAgent Adoption Plan

이 문서는 `reference/gesture_opensource_comparison.md`를 기준으로 현재 저장소에 적용할 방법론의 우선순위와 구현 순서를 고정한 계획서다.

## 목표

- 현재 `visualAgent`를 손동작 기반 입력 실험 코드에서 반복 가능하고 안정적인 gesture engine으로 정리한다.
- 외부 오픈소스의 아이디어는 직접 복사하지 않고, 현재 Swift 구조에 맞는 방식으로 재구성한다.

## 1순위 방법론

### 1. hysteresis threshold

- 출처
  - `gesture_mouse`
- 적용 이유
  - 현재 저장소는 threshold 경계에서 pose가 흔들릴 때 재발동 여지가 크다.
  - activation threshold와 release threshold를 분리하면 click, scroll, future drag 모두 안정화할 수 있다.
- 이번 단계 적용 범위
  - click pinch 경로에 먼저 적용
- 적용 파일
  - `Sources/Config/ThresholdConfig.swift`
  - `Sources/Config/ConfigLoader.swift`
  - `Sources/Gesture/ClickGestureRule.swift`
  - `.env`

### 2. generalized state-change tracker

- 출처
  - `HandGesture`
- 적용 이유
  - gesture를 매 프레임 액션으로 변환하면 중복 event가 쉽게 발생한다.
  - 상태가 바뀐 순간만 이벤트를 발행하는 tracker를 공통 계층으로 두면 click, drag, scroll toggle, zoom 같은 future action까지 재사용 가능하다.
- 이번 단계 적용 범위
  - click one-shot 재발동 제어에 먼저 적용
- 적용 파일
  - `Sources/Gesture/GestureStateTracker.swift`
  - `Sources/Gesture/GestureEngine.swift`

## 구현 순서

1. click pinch 경로에 hysteresis threshold 도입
2. generalized state-change tracker 추가
3. GestureEngine에서 click을 tracker 기반으로 재연결
4. click 회귀 테스트 추가
5. ability 문서와 `.env` 키 설명 정리

## 현재 단계 상태

- 완료
  - click hysteresis 도입
  - generalized state tracker 도입
  - click regression test 보강
- 보류
  - scroll 경로에 hysteresis 적용
  - drag gesture 도입
  - velocity 기반 dynamic gesture 분리

## 다음 구현 순서 고정안

### Phase 2

1. scroll 재활성화 전에 scroll pose에도 hysteresis threshold 적용
2. scroll intent와 click intent를 같은 state tracker 패턴으로 통일
3. scroll enable/disable을 하드코드 대신 설정값으로 분리

### Phase 3

1. velocity 기반 gesture state 추가
2. pinch + low velocity = click, pinch + sustained movement = drag 규칙 도입
3. drag 시작/유지/종료를 state machine으로 분리

### Phase 4

1. finger descriptor 기반 pose scoring 도입
2. binary threshold 기반 `isTwoFingerScrollPose`를 score 기반으로 확장
3. future gesture별 confidence 점수 로그 추가

### Phase 5

1. cursor movement mode를 `absolute`, `relative`, `hybrid`로 분리
2. 필요 시 spline interpolation 계층 추가

## 판단 기준

- 먼저 넣는 기능은 현재 구조를 크게 깨지 않아야 한다.
- 테스트로 재현 가능한 회귀 포인트가 있어야 한다.
- `.env`와 문서로 설명 가능한 설정이어야 한다.

## 메모

- 현재 1순위 두 방법론은 click 안정화에 먼저 적용했다.
- 이후 scroll을 다시 살릴 때 동일한 두 패턴을 그대로 확장하는 것이 가장 안전하다.