# changeLog_1

이 문서는 변경 이력을 append 형식으로 기록한다.

기록 규칙:

- 각 항목은 상대경로를 사용한다.
- 각 파일에는 최대 20개 항목까지만 기록한다.
- 20개를 넘기면 `changeLog_2.md`를 생성해 이어서 기록한다.

초기 기록:

--- 변경 파일: .agent/agent_manual.md
목적 : 에이전트의 탐색 순서, 기록 규칙, 환경 관리 기준을 정의

--- 변경 파일: .agent/manual/Directory structure.md
목적 : 저장소 구조를 빠르게 파악하기 위한 인덱스 문서 생성

--- 변경 파일: .agent/manual/QA.md
목적 : 정보 부족 시 질문과 답변을 누적 기록하는 기준 문서 생성

--- 변경 파일: .agent/changeLog/changeLog_1.md
목적 : 변경 이력 append 기록의 시작 파일 생성 및 초기 항목 기록

--- 변경 파일: .agent/skills/.gitkeep
목적 : 향후 스킬 문서 저장 위치를 유지하기 위한 초기 파일 추가

--- 변경 파일: reference/.gitkeep
목적 : 사용자 도메인 문서 저장 폴더를 초기 구조에 포함

--- 변경 파일: opensource/.gitkeep
목적 : 외부 저장소 clone 컨테이너 폴더를 초기 구조에 포함

--- 변경 파일: .gitignore
목적 : 민감 정보와 opensource 내부 clone 결과물의 Git 추적 제외 규칙 추가

--- 변경 파일: .env
목적 : 민감한 환경 변수 관리를 위한 초기 파일 생성

--- 변경 파일: requirements.txt
목적 : 의존성 관리를 위한 기준 파일 생성

--- 변경 파일: .gitignore
목적 : opensource 1단계 컨테이너 폴더는 추적하고 그 하위 clone 결과만 제외하도록 규칙 보정

--- 변경 파일: .agent/what2do.md
목적 : 손 제스처 기반 macOS 제어 프로젝트의 전체 구현 방식과 단계별 전략을 구체화

--- 변경 파일: what2do.md
목적 : Swift CGEvent 기반 제어, 확정 제스처 사양, 입력 스트리밍 방식을 반영해 구현 문서를 재정리

--- 변경 파일: Package.swift
목적 : Swift 패키지 타깃과 테스트 의존성을 정의하고 모듈 단위 구조를 구성

--- 변경 파일: Sources/
목적 : Capture, VisionPipeline, Gesture, Control, AppCore 등 기능별 모듈 분리 구조로 macOS 제스처 제어 앱 구현

--- 변경 파일: Tests/GestureTests/GestureEngineTests.swift
목적 : 제스처 엔진의 스와이프 및 클릭 동작을 검증하는 테스트 추가

--- 변경 파일: .env
목적 : 입력 소스와 제스처 임계값을 조정할 수 있는 환경 변수 템플릿 추가

--- 변경 파일: .agent/manual/Directory structure.md
목적 : 실제 Swift 패키지 구조와 핵심 코드 위치를 반영하도록 저장소 인덱스 문서 갱신

--- 변경 파일: Sources/Capture/CameraDeviceSource.swift
목적 : 실행 시 AVFoundation이 인식한 전체 카메라 장치와 필터된 장치 목록을 로그로 출력하도록 디버그 정보 추가

--- 변경 파일: Sources/Config/ConfigLoader.swift
목적 : .env의 빈 CAMERA_UNIQUE_ID와 RTSP_URL 값을 미설정으로 처리해 카메라 선택 실패를 방지

--- 변경 파일: Sources/Gesture/
목적 : 검지 중심 커서 이동과 검지+중지 기반 스크롤 및 화면 넘기기 규칙을 반영하도록 제스처 로직 확장

--- 변경 파일: Sources/AppCore/AppCoordinator.swift
목적 : 현재 인식된 손과 손가락 조합이 바뀔 때 터미널 로그로 출력하도록 디버그 정보 추가

--- 변경 파일: Sources/Control/
목적 : 스크롤 이벤트를 CGEvent로 전송할 수 있도록 입력 제어 계층 확장

--- 변경 파일: ability.md
목적 : 현재 구현 기준으로 지원하는 입력, 제스처, 로그, 제한 사항을 문서화

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : 손가락 상태 검증을 위해 커서 이동만 남기고 나머지 제스처 액션을 임시 비활성화

--- 변경 파일: ability.md
목적 : 현재 활성 기능은 커서 이동만 남고 나머지 ability 동작은 임시 비활성화 상태임을 반영
