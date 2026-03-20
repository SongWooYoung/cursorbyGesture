# changeLog_3

이 문서는 변경 이력을 append 형식으로 기록한다.

--- 변경 파일: reference/gesture_opensource_comparison.md
목적 : opensource 폴더에 clone한 4개 gesture 관련 오픈소스의 구현 방식을 비교하고 현재 저장소에 적용 가능한 방법론을 정리한 참고 문서 추가

--- 변경 파일: Sources/Config/ThresholdConfig.swift
목적 : click hysteresis를 위한 release threshold 설정값을 추가해 activation과 release 기준을 분리

--- 변경 파일: Sources/Config/ConfigLoader.swift
목적 : CLICK_PINCH_RELEASE_DISTANCE 환경 변수를 로드하도록 확장

--- 변경 파일: Sources/Gesture/ClickGestureRule.swift
목적 : click pinch 판정에 hysteresis threshold를 적용해 경계값 근처 흔들림에서도 포즈가 안정적으로 유지되도록 조정

--- 변경 파일: Sources/Gesture/GestureStateTracker.swift
목적 : gesture state 변화 시점만 감지하는 generalized state-change tracker를 추가

--- 변경 파일: Sources/Gesture/GestureEngine.swift
목적 : click 경로를 generalized state tracker 기반으로 재구성하고 scroll 상태 리셋과 click 상태 리셋을 분리

--- 변경 파일: Tests/GestureTests/GestureEngineTests 2.swift
목적 : click hold 재발동 방지와 hysteresis rearm 동작을 검증하는 회귀 테스트 추가

--- 변경 파일: .env
목적 : CLICK_PINCH_RELEASE_DISTANCE 기본값을 추가해 click hysteresis 설정을 노출

--- 변경 파일: ability.md
목적 : click이 activation/release hysteresis와 state-change tracker 기반으로 동작하는 현재 상태를 문서에 반영

--- 변경 파일: reference/visualAgent_adoption_plan.md
목적 : 오픈소스 비교 결과를 바탕으로 visualAgent에 적용할 1순위 방법론과 이후 구현 순서를 고정한 계획서 추가

--- 변경 파일: src/visual_agent/control.py
목적 : GitHub MediaPipe virtual mouse 구현 패턴을 반영해 active region 기반 좌표 보간과 이동량 기반 cursor damping을 추가

--- 변경 파일: src/visual_agent/gestures.py
목적 : click pose가 일정 프레임 연속 유지될 때만 상태 전환을 확정하는 debounced state tracker를 추가

--- 변경 파일: src/visual_agent/app.py
목적 : 새 cursor mapper와 debounced click tracker를 메인 루프에 연결하고 preview에 active region 및 cursor telemetry를 표시

--- 변경 파일: src/visual_agent/config.py
목적 : Python MediaPipe 런타임에서 cursor smoothing, dead-zone, active region, minimum click frames 설정을 읽도록 확장

--- 변경 파일: .env
목적 : Python 루트 기준으로 환경 변수를 정리하고 cursor stabilization 및 click debounce 설정을 추가

--- 변경 파일: ability.md
목적 : 현재 Python 구현에 반영된 GitHub-inspired cursor stabilization 및 click debounce 동작을 문서에 반영

--- 변경 파일: mediapipe_github_patterns.md
목적 : 조사한 GitHub virtual mouse 구현 패턴 중 실제로 현재 루트 코드에 적용한 항목과 남은 확장 후보를 정리

--- 변경 파일: requirements.txt
목적 : MediaPipe Solutions API를 안정적으로 사용하기 위해 mediapipe 버전을 0.10.14로 고정

--- 변경 파일: src/visual_agent/control.py
목적 : 커서의 상하 축도 설정으로 반전할 수 있도록 vertical mirror 옵션을 추가

--- 변경 파일: src/visual_agent/config.py
목적 : MIRROR_CURSOR_VERTICALLY 환경 변수를 읽어 cursor y축 방향을 제어하도록 확장

--- 변경 파일: src/visual_agent/app.py
목적 : main loop에서 vertical mirror 설정을 cursor 이동 경로에 전달

--- 변경 파일: .env
목적 : 현재 요청에 맞춰 커서 상하 방향을 반전한 기본 설정을 추가

--- 변경 파일: ability.md
목적 : 현재 Python 루트 구현에서 상하 방향 반전 설정이 가능하다는 점을 문서에 반영

--- 변경 파일: src/visual_agent/hand_tracking.py
목적 : two-finger scroll pose 판정을 위해 index, middle, ring finger landmark 좌표를 추가로 추출

--- 변경 파일: src/visual_agent/gestures.py
목적 : scroll pose 판정과 scroll anchor 계산 로직을 추가

--- 변경 파일: src/visual_agent/control.py
목적 : macOS vertical scroll wheel event 전송 경로를 추가

--- 변경 파일: src/visual_agent/app.py
목적 : scroll pose가 유지될 때 두 손가락 평균 y 이동량을 기반으로 vertical scroll을 발생시키고 cursor보다 scroll을 우선하도록 조정

--- 변경 파일: src/visual_agent/config.py
목적 : scroll on/off, sensitivity, dead-zone, minimum frames 및 커서 좌우/상하 반전 기본값 변경을 반영

--- 변경 파일: .env
목적 : 현재 요청에 맞춰 좌우/상하 축 반전 값을 다시 바꾸고 scroll 관련 기본 설정을 활성화

--- 변경 파일: ability.md
목적 : Python 루트에서 basic two-finger vertical scroll이 활성화되었음을 문서에 반영

--- 변경 파일: .env
목적 : 현재 요청에 맞춰 좌우 반전만 다시 원래 방향으로 되돌림

--- 변경 파일: src/visual_agent/config.py
목적 : 수평 반전 기본값을 다시 false로 조정해 현재 .env 설정과 기본 동작을 일치시킴

--- 변경 파일: src/visual_agent/gestures.py
목적 : pinch click 대신 검지 double-tap click을 위한 tap pose 판정과 double-tap tracker를 추가

--- 변경 파일: src/visual_agent/app.py
목적 : click 경로를 pinch 기반에서 index double-tap 기반으로 교체하고 preview 상태 표시를 갱신

--- 변경 파일: src/visual_agent/hand_tracking.py
목적 : click 경로에서 더 이상 쓰지 않는 pinch 계산과 thumb 좌표 저장을 제거

--- 변경 파일: src/visual_agent/config.py
목적 : pinch threshold를 제거하고 index fold margin 및 double-tap frame window 설정을 추가

--- 변경 파일: .env
목적 : pinch click 설정을 제거하고 index double-tap click 설정으로 교체

--- 변경 파일: ability.md
목적 : 현재 click 제스처가 pinch가 아니라 index double-tap이라는 점을 문서에 반영

--- 변경 파일: .env
목적 : 현재 요청에 맞춰 click과 scroll 런타임 토글을 모두 비활성화

--- 변경 파일: src/visual_agent/config.py
목적 : click과 scroll 기본 활성값을 false로 바꿔 현재 런타임 설정과 기본 동작을 일치시킴

--- 변경 파일: ability.md
목적 : 현재 루트에서 click과 scroll이 비활성화 상태라는 점을 문서에 반영

--- 변경 파일: src/visual_agent/hand_tracking.py
목적 : auto clutch와 freeze pose 판정을 위해 wrist, MCP, pinky, thumb 관련 랜드마크를 추가 추출

--- 변경 파일: src/visual_agent/gestures.py
목적 : 손 각도 계산, auto clutch 상태기계, freeze pose 판정 로직을 추가

--- 변경 파일: src/visual_agent/control.py
목적 : clutch 상태에서 커서를 고정하고 해제 시 현재 손 위치를 새 기준점으로 재연결하는 re-anchor mapper를 추가

--- 변경 파일: src/visual_agent/app.py
목적 : auto clutch와 freeze pose를 cursor 이동 경로에 통합하고 preview에 angle/clutch telemetry를 표시

--- 변경 파일: src/visual_agent/config.py
목적 : auto clutch 및 freeze pose 관련 runtime 설정을 추가

--- 변경 파일: .env
목적 : auto clutch, freeze pose, clutch activation/resume threshold 기본값을 노출

--- 변경 파일: ability.md
목적 : cursor 섹션에 auto clutch, freeze pose, preview telemetry 기능을 간단히 명시

--- 변경 파일: src/visual_agent/app.py
목적 : startup clutch calibration countdown, 좌우 angle sampling, .env 저장, calibration overlay를 추가

--- 변경 파일: src/visual_agent/config.py
목적 : calibration 관련 runtime 설정과 .env 업데이트 헬퍼를 추가

--- 변경 파일: src/visual_agent/gestures.py
목적 : auto clutch를 대칭 threshold가 아닌 calibration된 neutral/left/right angle 기준으로 동작하도록 변경

--- 변경 파일: .env
목적 : startup clutch calibration과 calibration 결과 저장용 neutral/left/right angle 환경 변수를 추가

--- 변경 파일: ability.md
목적 : cursor calibration과 좌우 평균각도 .env 저장 흐름을 문서에 반영

--- 변경 파일: src/visual_agent/app.py
목적 : startup calibration을 제거하고 preview에서 `c` 키를 눌렀을 때만 clutch calibration이 실행되도록 변경

--- 변경 파일: src/visual_agent/config.py
목적 : 더 이상 사용하지 않는 startup calibration 설정을 제거

--- 변경 파일: .env
목적 : startup calibration 토글을 제거하고 manual `c` calibration 흐름에 맞게 정리

--- 변경 파일: ability.md
목적 : calibration 진입 방식이 startup이 아니라 preview의 `c` 키라는 점을 문서에 반영

--- 변경 파일: src/visual_agent/control.py
목적 : cursor alignment calibration 결과를 base offset으로 유지할 수 있도록 clutch mapper와 현재 cursor 위치 읽기 경로를 확장

--- 변경 파일: src/visual_agent/gestures.py
목적 : auto clutch를 좌우 평균각도 기반이 아니라 neutral angle과 고정 stop/resume delta 기반으로 단순화

--- 변경 파일: src/visual_agent/config.py
목적 : cursor alignment offset과 단순화된 clutch delta 설정을 `.env`에서 읽도록 재구성

--- 변경 파일: src/visual_agent/app.py
목적 : preview의 `c` calibration을 좌우 각도 균형 수집 대신 frozen cursor target과 검지 포인트 정렬 + neutral angle 저장 흐름으로 재정의

--- 변경 파일: .env
목적 : 좌우 평균각도 calibration 값을 제거하고 cursor alignment offset 및 clutch delta 설정으로 교체

--- 변경 파일: ability.md
목적 : calibration 목적이 좌우 밸런스 학습이 아니라 cursor와 검지 alignment라는 점을 문서에 반영

--- 변경 파일: src/visual_agent/config.py
목적 : hand landmark의 index tip을 바로 cursor로 보내는 direct cursor 모드를 `.env`에서 제어할 수 있도록 추가

--- 변경 파일: src/visual_agent/app.py
목적 : direct cursor 모드에서는 active region, smoothing, clutch, alignment offset을 우회하고 index tip landmark를 그대로 cursor에 매핑하도록 변경

--- 변경 파일: .env
목적 : 현재 런타임 기본 모드를 direct index tip cursor로 전환

--- 변경 파일: ability.md
목적 : 현재 기본 cursor 경로가 direct index tip mode라는 점과 calibration/auto clutch가 우회된다는 점을 문서에 반영

--- 변경 파일: src/visual_agent/config.py
목적 : direct index tip cursor 모드 기본값을 다시 false로 되돌려 기존 mapped/smoothed cursor 경로를 기본 동작으로 복원

--- 변경 파일: .env
목적 : 현재 요청에 맞춰 direct index tip cursor 모드를 비활성화

--- 변경 파일: ability.md
목적 : direct mode가 옵션이며 현재 기본 런타임은 mapped/smoothed cursor 경로라는 점을 문서에 반영

--- 변경 파일: src/visual_agent/hand_tracking.py
목적 : screen-touch click 판정을 위해 index tip과 MCP의 z-depth를 함께 추출

--- 변경 파일: src/visual_agent/gestures.py
목적 : index fold 기반 click을 대체할 z-depth 기반 screen-touch double tap detector를 추가

--- 변경 파일: src/visual_agent/config.py
목적 : depth-based click의 press/release delta, baseline alpha, release frames 설정을 추가

--- 변경 파일: src/visual_agent/app.py
목적 : click 경로를 screen-touch double tap detector로 교체하고 preview에 touch depth telemetry를 표시

--- 변경 파일: .env
목적 : click을 다시 활성화하고 depth-based double touch click 기본 설정을 노출

--- 변경 파일: ability.md
목적 : click 방식이 index fold가 아니라 z-depth 기반 double touch motion이라는 점을 문서에 반영

--- 변경 파일: src/visual_agent/control.py
목적 : scroll pose의 좌우 이동에 대응해 `Ctrl+Left/Right` 키 입력을 보낼 수 있도록 keyboard event 경로를 추가

--- 변경 파일: src/visual_agent/gestures.py
목적 : scroll pose를 검지/중지 close gesture로 재정의하고 평균 x anchor 계산을 추가

--- 변경 파일: src/visual_agent/config.py
목적 : horizontal scroll navigation threshold와 cooldown 설정을 추가

--- 변경 파일: src/visual_agent/app.py
목적 : 클릭을 비활성화한 상태에서 scroll pose의 세로 이동은 wheel scroll, 가로 이동은 `Ctrl+Left/Right` 입력으로 연결

--- 변경 파일: .env
목적 : click을 끄고 scroll/navigation을 활성화하며 새 horizontal navigation 설정을 노출

--- 변경 파일: ability.md
목적 : 스크롤 제스처가 검지/중지 close pose 기반 vertical scroll + horizontal ctrl-arrow navigation이라는 점을 문서에 반영

--- 변경 파일: .gitignore
목적 : `SwiftVision/opensource/`와 `SwiftVision/opensource_root/` 전체를 Git 추적 대상에서 제외하도록 수정