목적 : Python + MediaPipe 기반으로 카메라 영상을 받아 손 제스처를 인식하고, macOS 입력 제어로 커서 이동과 클릭부터 다시 구축한다.

## 핵심 원칙

- 작업 기능에 따라 반드시 모듈을 분리한다.
- 입력 처리, 손 추적, 제스처 해석, 시스템 제어, 설정 관리는 서로 분리한다.
- 제스처 판정 로직과 macOS 이벤트 발생 로직은 한 모듈에 섞지 않는다.
- 모든 경로 표기는 저장소 루트 기준 상대경로로 유지한다.
- 민감한 정보와 로컬 설정은 `.env`에서 관리한다.
- Python 런타임 의존성은 `requirements.txt`로 관리한다.

## 현재 구현 방향

이 프로젝트의 현재 루트 구현은 **Python 기반 macOS 실험 앱**으로 진행한다.

현재 권장 스택:

- 언어: Python
- 손 추적: MediaPipe Hands
- macOS 제어: Quartz via PyObjC
- 카메라 입력: OpenCV
- 설정 관리: `.env` + Python dataclass

이전 Swift + Vision 구현은 삭제하지 않고 `SwiftVision/` 아래로 이동해 보관한다.

## 입력 방식

1차 입력은 OpenCV 카메라 입력으로 단순화한다.

- `CAMERA_INDEX`로 장치를 고른다.
- iPhone Continuity Camera가 macOS 카메라 장치로 보이면 그대로 사용할 수 있다.
- RTSP는 나중 단계에서 별도 모듈로 다시 붙인다.

## 현재 우선 구현 범위

### 1. 커서 이동

- 검지 tip normalized 좌표를 화면 좌표로 변환한다.
- `MIRROR_CURSOR_HORIZONTALLY`로 좌우 반전 여부를 조절한다.

### 2. 클릭

- 엄지 tip과 검지 tip 사이 거리 기반 pinch로 좌클릭한다.
- `CLICK_PINCH_DISTANCE`로 활성화한다.
- `CLICK_PINCH_RELEASE_DISTANCE`로 release hysteresis를 둔다.
- 상태 변화 시점만 이벤트를 발생시킨다.

### 3. 디버그 프리뷰

- OpenCV 창에 카메라 프레임과 MediaPipe 손 랜드마크를 표시한다.

## 이후 재구현 대상


- 스크롤
- 화면 넘기기
- 창 보기 모드
- 확대/축소
- 양손 영역 캡처

이 기능들은 Python 경로에서 다시 구현한다. 이전 실험 코드는 `SwiftVision/` 아래를 참고한다.

## 모듈 분리 설계

기능별 모듈은 반드시 아래처럼 나눈다.

```text
.
├── app.py
├── src/
│   └── visual_agent/
│       ├── app.py
│       ├── capture.py
│       ├── config.py
│       ├── control.py
│       ├── gestures.py
│       └── hand_tracking.py
├── SwiftVision/
│   ├── Sources/
│   ├── Tests/
│   ├── reference/
│   └── opensource/
└── what2do.md
```

모듈 책임:

- `capture.py`: 카메라 프레임 입력만 담당
- `hand_tracking.py`: MediaPipe 손 랜드마크 추출만 담당
- `gestures.py`: 랜드마크를 gesture 의미로 해석
- `control.py`: macOS 입력 이벤트 발생 담당
- `config.py`: `.env` 기반 설정 로드 담당
- `app.py`: 전체 파이프라인 orchestration 담당

## 제스처 우선순위

동시에 여러 제스처가 겹치지 않도록 우선순위를 고정한다.

1. 양손 영역 캡처
2. 창 보기 모드
3. 확대/축소
4. 화면 넘기기
5. 마우스 클릭
6. 마우스 이동

이 순서를 기준으로 충돌 시 상위 제스처만 실행한다.

현재 루트 구현은 이 우선순위를 다 쓰지 않고, 커서 이동과 클릭부터 다시 쌓는다.

- 키 조합 생성은 `KeyboardController`에서만 담당
- 마우스 관련 이벤트는 `MouseController`에서만 담당
- 캡처 관련 이벤트 흐름은 `ScreenCaptureController`에 분리
- 실제 `CGEvent` 생성은 `CGEventFactory`에 모아서 중복 제거

## 제스처 판정 규칙

오동작 방지를 위해 모든 제스처에 아래 공통 규칙을 적용한다.

- 최소 유지 프레임 수
- 쿨다운 시간
- 이동 평균 또는 EMA smoothing
- 작은 떨림 무시용 dead zone
- 손 검출 손실 시 즉시 안전 정지

추가 규칙:

- 스와이프는 속도 기반으로 판정
- 클릭은 거리 임계값 + 유지 시간으로 판정
- 확대/축소는 연속 거리 변화량으로 판정
- 영역 캡처는 양손 정합 조건이 깨지면 즉시 취소 또는 확정

## 단계별 구현 순서

### 1단계: 입력 파이프라인 구축

- Continuity Camera 입력 연결
- AVFoundation 프레임 수집
- 프레임 화면 표시 또는 로그 확인

### 2단계: 손 추적

- 단일 손 랜드마크 추출
- 양손 동시 검출
- 손 손실 시 상태 초기화

### 3단계: 기본 마우스

- 검지 기반 커서 이동
- 클릭 제스처 분리
- smoothing, dead zone, 클릭 쿨다운 적용

### 4단계: 시스템 제스처

- 좌우 스와이프로 화면 넘기기
- 손 오므리기로 창 보기 모드
- 세 손가락 기반 확대/축소

### 5단계: 양손 캡처

- 양손 정합 상태 검출
- `command + shift + 4` 진입
- 드래그 기반 캡처 영역 제어

### 6단계: 안정화

- 임계값 조정
- false positive 감소
- FPS와 지연 시간 개선

## 테스트 기준

기능 테스트:

- iPhone Continuity Camera 입력이 끊기지 않는지
- 손 1개, 2개 인식이 안정적인지
- 마우스 이동이 과도하게 튀지 않는지
- 클릭이 중복 발생하지 않는지
- 좌우 스와이프가 의도한 화면 전환만 일으키는지
- 오므리기 제스처가 `control + up`으로 정확히 동작하는지
- 세 손가락 거리 변화가 확대/축소로 안정적으로 연결되는지
- 양손 캡처가 실제 영역 선택으로 이어지는지

안전 테스트:

- 손이 사라지면 클릭/드래그 상태가 즉시 해제되는지
- 제스처 충돌 시 우선순위가 지켜지는지
- 입력 권한이 없을 때 안전하게 오류를 안내하는지

## 결정 사항 정리

- 구현 언어: Swift
- 시스템 제어: `CGEvent`
- 기본 입력 소스: iPhone Continuity Camera
- fallback 입력 소스: RTSP 또는 웹 스트림
- 구조 원칙: 기능별 모듈 분리
- 우선 구현 기능: 마우스 이동/클릭 -> 화면 넘기기 -> 창 보기 -> 확대/축소 -> 양손 캡처
