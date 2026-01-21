# ecDesigner - Exploratory Cycle Designer

Exploratory Cycle을 설계하고 시각화하는 macOS 앱입니다.

## Exploratory Cycle (EC)이란?

> **"An Exploratory Cycle consists of a focused round of Guiding Questions and associated Guiding Activities/Resources, resulting in findings and a synthesis that drives learning and progress through the phases of the Challenge."**

각 노드는 **하나의 완전한 Exploratory Cycle**을 나타내며, 다음 4가지 필수 구성 요소를 순서대로 포함합니다:

1. **Guiding Questions** - 무엇을 학습해야 하는가?
2. **Guiding Activities/Resources** - 어떻게 학습할 것인가?
3. **Findings** - 무엇을 학습했는가?
4. **Synthesis** - 마일스톤을 달성하기에 충분히 학습했는가?

## 기능

- **캔버스 기반 EC 편집**: 드래그 앤 드롭으로 EC를 자유롭게 배치
- **시간 순서 관리**: EC는 시퀀스 번호로 시간 순서를 추적
- **네 방향 연결 시스템**: EC의 상하좌우에서 드래그 앤 드롭으로 연결
- **연결 모드**: 우측 하단 버튼으로 연결 모드 활성화/비활성화
- **순서가 있는 EC 구성**: 4가지 필수 요소를 순서대로 작성
- **마일스톤 표시**: EC가 마일스톤을 달성했는지 표시

## 프로젝트 열기

1. Xcode에서 `ecDesigner/ecDesigner.xcodeproj` 파일을 엽니다
2. 또는 터미널에서:
   ```bash
   cd ecDesigner
   open ecDesigner.xcodeproj
   ```

## 빌드 및 실행

1. Xcode에서 프로젝트를 엽니다
2. 타겟이 "ecDesigner"로 설정되어 있는지 확인합니다
3. ⌘R (Command + R)을 눌러 앱을 빌드하고 실행합니다

## 사용 방법

### EC 추가
- 캔버스를 더블클릭하여 새 EC를 추가합니다
- 또는 왼쪽 사이드바의 "Add EC" 버튼을 클릭합니다

### EC 편집
1. EC를 선택합니다
2. 사이드바의 "Edit EC" 버튼을 클릭합니다
3. **EC의 필수 구성 요소를 순서대로 작성**합니다:
   - 1️⃣ **Guiding Questions**: What needs to be learned?
   - 2️⃣ **Guiding Activities/Resources**: How will we learn it?
   - 3️⃣ **Findings**: What did we learn?
   - 4️⃣ **Synthesis**: Did we learn enough to address the milestone?
4. 필요한 경우 "This EC represents a Milestone"을 체크하고 마일스톤 설명을 작성합니다

### EC 연결
1. **우측 하단의 "연결 모드" 버튼**을 클릭하여 연결 모드를 활성화합니다
2. 연결 모드가 활성화되면 각 EC의 **네 방향(상/하/좌/우)에 작은 화살표**가 나타납니다
3. 시작 EC의 화살표를 **드래그**하여 대상 EC 근처에 **드롭**합니다
4. 자동으로 가장 가까운 방향의 화살표에 연결됩니다
5. 연결 작업이 끝나면 다시 "연결 모드" 버튼을 눌러 비활성화합니다

### EC 이동
- **연결 모드가 비활성화된 상태**에서 EC를 드래그하여 원하는 위치로 이동합니다
- 연결 모드 중에는 EC 이동이 불가능합니다

### EC 삭제
1. EC를 선택합니다
2. 사이드바의 "Delete EC" 버튼을 클릭합니다

## EC 진행 상태 표시

각 EC는 완료된 구성 요소에 따라 다음 아이콘으로 상태를 표시합니다:

- 🔵 **Q** - Guiding Questions 작성됨
- 🟢 **A** - Guiding Activities/Resources 작성됨
- 🟡 **F** - Findings 작성됨
- 🟣 **S** - Synthesis 작성됨
- 🟠 **M** - Milestone 달성됨

## 프로젝트 구조

```
ecDesigner/
├── ecDesigner/
│   ├── ecDesignerApp.swift        # 앱 진입점
│   ├── ContentView.swift           # 메인 뷰
│   ├── Models/
│   │   ├── ECNode.swift            # EC 데이터 모델
│   │   └── ExploratoryCycle.swift  # Exploratory Cycle 모델
│   ├── Views/
│   │   ├── CanvasView.swift        # 캔버스 뷰
│   │   ├── NodeView.swift          # EC 뷰
│   │   ├── ConnectionView.swift    # 연결선 뷰
│   │   └── NodeEditorView.swift    # EC 편집기
│   └── ViewModels/
│       └── CanvasViewModel.swift   # 뷰 모델
└── ecDesigner.xcodeproj/           # Xcode 프로젝트 파일

```

## 시스템 요구사항

- macOS 13.0 이상
- Xcode 15.0 이상
- Swift 5.9 이상

## 라이선스

MIT License
