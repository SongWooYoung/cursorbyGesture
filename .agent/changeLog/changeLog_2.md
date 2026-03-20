# changeLog_2

이 문서는 변경 이력을 append 형식으로 기록한다.

--- 변경 파일: Sources/Config/ConfigLoader.swift
목적 : CURSOR_SMOOTHING 값을 .env에 즉시 반영할 수 있도록 환경 파일 갱신 유틸 추가

--- 변경 파일: Sources/Support/EMAFilter.swift
목적 : 커서 EMA 필터의 alpha 값을 앱 실행 중에도 변경할 수 있도록 런타임 갱신 지원 추가

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : UI에서 조정한 커서 스무딩 값을 실시간으로 반영할 수 있도록 런타임 업데이트 경로와 상태 보호 추가

--- 변경 파일: Sources/AppCore/CursorSmoothingPanelController.swift
목적 : CURSOR_SMOOTHING 값을 드래그로 조절하는 AppKit 플로팅 슬라이더 UI 추가

--- 변경 파일: Sources/AppCore/AppCoordinator.swift
목적 : 플로팅 슬라이더 UI를 앱 시작 시 표시하고 조정값을 제스처 엔진과 .env에 즉시 반영하도록 연결

--- 변경 파일: Sources/visualAgent/main.swift
목적 : 콘솔 RunLoop 대신 NSApplicationDelegate 기반 시작 경로로 전환해 AppKit UI를 함께 구동

--- 변경 파일: Sources/Support/EMAFilter.swift
목적 : CURSOR_SMOOTHING 값이 높을수록 떨림 보정이 강해지도록 적응형 smoothing과 dead zone 억제 로직 추가

--- 변경 파일: Sources/AppCore/CursorSmoothingPanelController.swift
목적 : CURSOR_SMOOTHING 슬라이더 UI에 높은 값일수록 안정화가 강해진다는 설명을 추가

--- 변경 파일: Sources/Capture/CameraDeviceSource.swift
목적 : 카메라 탐색 실패 시 AVCaptureSession 설정 상태를 정상 종료하고 부분 구성 상태를 정리하도록 시작 경로 보강

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 두 손가락 수직 이동에 대한 스크롤만 다시 활성화하고 나머지 네비게이션 제스처는 계속 비활성화 상태로 유지

--- 변경 파일: ability.md
목적 : 현재 활성 동작이 커서 이동과 수직 스크롤임을 반영하도록 기능 문서 갱신

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 스크롤만 활성화된 현재 제스처 엔진 동작에 맞춰 테스트 시나리오를 갱신

--- 변경 파일: Tests/GestureTests/GestureEngineTests 2.swift
목적 : 커서 이동 유지와 스크롤 중 커서 이동 억제를 검증하도록 테스트를 분리

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 검지 커서 이동은 유지한 채 검지와 중지 조합에서 수직 스크롤이 함께 동작하도록 제스처 분기 조정

--- 변경 파일: Tests/GestureTests/GestureEngineTests 2.swift
목적 : 두 손가락 스크롤 중에도 커서 이동이 유지되는 현재 동작을 검증하도록 테스트 갱신

--- 변경 파일: ability.md
목적 : 검지 커서 이동과 검지+중지 수직 스크롤이 동시에 활성화된 현재 동작 설명으로 문서 갱신

--- 변경 파일: Sources/VisionPipeline/HandLandmark.swift
목적 : 손목과 각 손가락의 전체 관절 및 skeleton 연결 정보를 표현할 수 있도록 landmark 정의 확장

--- 변경 파일: Sources/VisionPipeline/HandTracker.swift
목적 : Vision hand pose 결과에서 전체 관절 좌표를 추출하도록 추적 포인트 매핑 확장

--- 변경 파일: Sources/Capture/FrameBuffer.swift
목적 : 디버그 프리뷰가 최신 카메라 프레임을 안전하게 읽을 수 있도록 스레드 안전 스냅샷 지원 추가

--- 변경 파일: Sources/AppCore/PipelineState.swift
목적 : 디버그 프리뷰가 최신 손 추적 결과를 안전하게 읽을 수 있도록 스레드 안전 스냅샷 지원 추가

--- 변경 파일: Sources/AppCore/HandDebugPreviewPanelController.swift
목적 : 카메라 프레임 위에 손 관절 점과 skeleton 선을 오버레이하는 디버그 프리뷰 창 추가

--- 변경 파일: Sources/AppCore/AppCoordinator.swift
목적 : 앱 시작 시 손 관절 디버그 프리뷰 창을 함께 표시하도록 연결

--- 변경 파일: ability.md
목적 : 전체 관절 추적과 hand debug preview 지원 상태를 기능 문서에 반영

--- 변경 파일: Sources/AppCore/HandDebugPreviewPanelController.swift
목적 : 디버그 프리뷰에서 카메라 프레임과 landmark overlay가 같은 좌표계와 aspect-fit 영역을 사용하도록 보정해 상하 뒤집힘 문제 수정

--- 변경 파일: Sources/Config/ThresholdConfig.swift
목적 : 스크롤 속도를 설정값으로 다룰 수 있도록 SCROLL_STEP 임계값 추가

--- 변경 파일: Sources/Config/ConfigLoader.swift
목적 : SCROLL_STEP 환경 변수 로드와 .env 갱신을 지원하도록 설정 로더 확장

--- 변경 파일: Sources/Gesture/TwoFingerNavigationRule.swift
목적 : 두 손가락 수직 스크롤 delta가 SCROLL_STEP 설정값을 따르도록 조정

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 스크롤 속도를 앱 실행 중에도 업데이트할 수 있도록 런타임 설정 갱신 경로 추가

--- 변경 파일: Sources/AppCore/CursorSmoothingPanelController.swift
목적 : CURSOR_SMOOTHING과 SCROLL_STEP을 함께 조절하는 플로팅 제어 패널로 UI 확장

--- 변경 파일: Sources/AppCore/AppCoordinator.swift
목적 : 스크롤 속도 슬라이더 값을 제스처 엔진과 .env에 즉시 반영하도록 연결

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 설정한 SCROLL_STEP 값이 실제 scroll action delta에 반영되는지 검증하도록 테스트 보강

--- 변경 파일: .env
목적 : SCROLL_STEP 환경 변수 기본 템플릿 추가

--- 변경 파일: ability.md
목적 : 제어 패널에서 cursor smoothing과 scroll speed를 함께 조절할 수 있는 현재 상태를 기능 문서에 반영

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 스크롤 후 손가락을 원위치로 되돌릴 때 역스크롤이 발생하지 않도록 방향 잠금과 정지 기반 재무장 로직 추가

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 스크롤 후 손가락 복귀 동작에서 즉시 반대 방향 스크롤이 발생하지 않음을 검증하는 회귀 테스트 추가

--- 변경 파일: Sources/VisionPipeline/HandLandmark.swift
목적 : 검지와 중지만 편 스크롤 포즈를 판정할 수 있도록 손가락 펼침/접힘 헬퍼 추가

--- 변경 파일: Sources/Gesture/TwoFingerNavigationRule.swift
목적 : 스크롤 동작을 두 손가락 tip 이동이 아니라 스크롤 포즈에서의 손목 수직 이동으로 재정의

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 손목 기반 스크롤 포즈와 수직 이동에 맞춰 스크롤 테스트 시나리오 갱신

--- 변경 파일: Tests/GestureTests/GestureEngineTests 2.swift
목적 : 손목 기반 스크롤 포즈에서도 커서 이동이 유지되는 현재 동작을 검증하도록 테스트 데이터 갱신

--- 변경 파일: ability.md
목적 : 스크롤을 검지와 중지만 편 포즈에서의 손목 수직 이동으로 해석하는 현재 동작을 기능 문서에 반영

--- 변경 파일: Sources/VisionPipeline/HandLandmark.swift
목적 : wrist가 누락되어도 MCP 기반 palm anchor fallback으로 스크롤 포즈를 판정할 수 있도록 보강

--- 변경 파일: Sources/Gesture/TwoFingerNavigationRule.swift
목적 : 스크롤 기준점을 raw wrist 대신 palm anchor로 사용하도록 보강

--- 변경 파일: Sources/AppCore/AppCoordinator.swift
목적 : 디버그 로그에 raw wrist 또는 palm fallback anchor 사용 여부를 함께 표시하도록 개선

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : wrist가 없을 때도 palm fallback으로 스크롤이 동작하는지 검증하는 회귀 테스트 추가

--- 변경 파일: Sources/Config/ThresholdConfig.swift
목적 : 스크롤 발동 임계값과 포즈 판정 임계값을 설정값으로 다룰 수 있도록 스크롤 민감도 필드 추가

--- 변경 파일: Sources/Config/ConfigLoader.swift
목적 : SCROLL_ACTIVATION_THRESHOLD와 스크롤 포즈 임계값 환경 변수 로드 지원 추가

--- 변경 파일: Sources/VisionPipeline/HandLandmark.swift
목적 : 스크롤 포즈 판정에 사용되는 손가락 펼침/접힘 임계값을 런타임 설정으로 주입할 수 있도록 개선

--- 변경 파일: Sources/Gesture/TwoFingerNavigationRule.swift
목적 : 스크롤 발동 임계값과 포즈 임계값이 설정값을 따르도록 규칙 연결

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 스크롤 민감도 임계값을 앱 실행 중에도 갱신할 수 있도록 런타임 업데이트 경로 추가

--- 변경 파일: Sources/AppCore/CursorSmoothingPanelController.swift
목적 : 스크롤 발동 및 포즈 민감도까지 포함하는 확장 제어 패널 UI 추가

--- 변경 파일: Sources/AppCore/AppCoordinator.swift
목적 : 추가된 스크롤 민감도 슬라이더 값을 제스처 엔진과 .env에 즉시 반영하도록 연결

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 스크롤 민감도 임계값을 완화했을 때 더 느슨한 포즈와 작은 이동도 스크롤로 인정되는지 검증

--- 변경 파일: .env
목적 : SCROLL_ACTIVATION_THRESHOLD와 스크롤 포즈 임계값 환경 변수 템플릿 추가

--- 변경 파일: ability.md
목적 : 제어 패널에서 스크롤 발동 및 포즈 민감도까지 조절 가능한 현재 상태를 기능 문서에 반영

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 스크롤 후 반대 방향 입력을 무시하던 방향 잠금 로직을 제거해 연속 반대 방향 스크롤도 바로 처리하도록 조정

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 반대 방향 복귀 움직임이 즉시 역스크롤로 처리되는 현재 동작을 검증하도록 회귀 테스트 기대값 갱신

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : GitHub hand-gesture mouse 프로젝트들에서 흔히 쓰는 프레임 일관성 디바운스 방법을 적용해 스크롤 포즈가 일정 프레임 연속 확인될 때만 발동하도록 조정

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 최소 연속 프레임 수를 만족해야 스크롤이 발동하는 안정화 동작을 검증하고 기존 테스트는 즉시 발동 조건으로 유지하도록 설정 보강

--- 변경 파일: Tests/GestureTests/GestureEngineTests 2.swift
목적 : 스크롤 디바운스 추가 후에도 기존 커서+스크롤 테스트가 즉시 발동 조건으로 유지되도록 설정 보강

--- 변경 파일: ability.md
목적 : 스크롤 발동 전에 MINIMUM_GESTURE_FRAMES 기반 안정화 확인이 추가된 현재 동작을 문서에 반영

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 스크롤을 임시 비활성화하고 pinch 클릭을 다시 활성화해 좌클릭이 포즈 진입 시 한 번만 발생하도록 조정

--- 변경 파일: .env
목적 : MIRROR_CURSOR_HORIZONTALLY 값을 뒤집어 커서 좌우 이동 방향을 기존과 반대로 적용

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 스크롤 임시 비활성화 상태에서 어떤 스크롤 포즈도 scroll action을 내지 않음을 검증하도록 테스트 기대값 갱신

--- 변경 파일: Tests/GestureTests/GestureEngineTests 2.swift
목적 : 좌우 반전 설정과 pinch 단발 좌클릭 동작을 검증하는 테스트로 현재 제어 동작을 갱신

--- 변경 파일: ability.md
목적 : 현재 활성 동작이 좌우 반전된 커서 이동과 pinch 좌클릭이며 스크롤은 잠시 비활성화된 상태임을 문서에 반영