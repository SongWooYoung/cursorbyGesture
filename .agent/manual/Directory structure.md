# Directory structure

이 문서는 저장소의 폴더 구조를 빠르게 파악하고 필요한 부분만 읽기 위한 인덱스다. 에이전트는 작업 전에 이 문서를 먼저 읽고, 필요한 경로만 선택적으로 탐색한다.

## 현재 기준 핵심 구조

```text
.
├── .agent/
│   ├── agent_manual.md
│   ├── changeLog/
│   │   └── changeLog_1.md
│   ├── manual/
│   │   ├── Directory structure.md
│   │   └── QA.md
│   └── skills/
├── .env
├── .gitignore
├── app.py
├── requirements.txt
├── src/
│   └── visual_agent/
├── SwiftVision/
│   ├── Package.resolved
│   ├── Package.swift
│   ├── Sources/
│   ├── Tests/
│   ├── opensource/
│   └── reference/
└── what2do.md
```

## 폴더 및 파일 역할

- `.agent/`
  - 에이전트가 먼저 읽어야 하는 운영 기준 폴더
  - 작업 방식, 질의응답, 변경 이력을 관리한다
- `.agent/skills/`
  - 향후 스킬 문서나 보조 규칙을 추가하는 위치
  - 현재는 비어 있어도 구조상 유지한다
- `.agent/manual/`
  - 구조 문서, QA 문서 등 운영용 문서를 둔다
- `.agent/changeLog/`
  - 작업 변경 이력을 append 형식으로 기록한다
- `.env`
  - 민감한 정보와 로컬 환경 변수를 관리한다
- `app.py`
  - 루트 Python 실행 진입점
- `requirements.txt`
  - 현재 루트 Python 구현 의존성 문서
- `src/`
  - 현재 Python 애플리케이션 코드 위치
- `SwiftVision/`
  - 이전 Swift + Vision 구현을 보관하는 아카이브 폴더
  - `Sources/`, `Tests/`, `opensource/`, `reference/`가 모두 이 아래로 이동했다
- `what2do.md`
  - 현재 프로젝트의 구현 방향, 제스처 사양, 모듈 분리 원칙을 정리한 문서

## 추적 원칙

- `SwiftVision/reference/`는 존재와 역할만 구조 문서에 명시하고, 하위 세부 내용은 기본 추적 대상에서 제외한다.
- `SwiftVision/opensource/`도 존재와 역할만 구조 문서에 명시하고, clone된 내부 저장소 구조는 기본 추적 대상에서 제외한다.
- `.build/`, `.swiftpm/` 같은 생성 산출물은 작업 결과물이지만 문서의 핵심 구조 인덱스에서는 추적하지 않는다.
- 이 문서는 전체 세부 트리를 보관하기보다, 어디를 먼저 봐야 하는지 빠르게 안내하는 용도로 유지한다.

## 갱신 원칙

- 저장소의 핵심 구조가 바뀌면 이 문서를 갱신한다.
- 경로 표기는 절대경로가 아니라 저장소 루트 기준 상대경로를 사용한다.
