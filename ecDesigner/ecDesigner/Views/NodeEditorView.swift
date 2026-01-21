import SwiftUI

enum ECEditingTab: String, CaseIterable {
    case metadata = "Info"
    case guidingQuestions = "1. GQ"
    case guidingActivities = "2. GA"
    case findings = "3. Fi"
    case synthesis = "4. Mi"

    var icon: String {
        switch self {
        case .metadata: return "info.circle.fill"
        case .guidingQuestions: return "questionmark.circle.fill"
        case .guidingActivities: return "list.bullet.circle.fill"
        case .findings: return "lightbulb.fill"
        case .synthesis: return "arrow.triangle.merge"
        }
    }

    var color: Color {
        switch self {
        case .metadata: return .gray
        case .guidingQuestions: return .blue
        case .guidingActivities: return .green
        case .findings: return .yellow
        case .synthesis: return .purple
        }
    }
}

struct NodeEditorView: View {
    @Binding var node: ECNode
    let fontScale: CGFloat
    let availableMilestones: [Milestone]
    let availableECs: [ECNode]
    let onSave: (ECNode) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    let onCreateMilestone: () -> Void
    let onCreateEC: () -> Void

    @State private var showCancelConfirmation = false
    @State private var selectedTab: ECEditingTab = .guidingQuestions
    @State private var hasRestoredTab = false

    private var hasContent: Bool {
        !node.guidingQuestions.isEmpty ||
        !node.guidingActivities.isEmpty ||
        !node.findings.isEmpty ||
        !node.synthesis.isEmpty ||
        !node.duration.isEmpty ||
        !node.day.isEmpty ||
        !node.learningObjective.isEmpty ||
        !node.artifact.isEmpty ||
        !node.mentorTasks.isEmpty
    }

    private func isTabCompleted(_ tab: ECEditingTab) -> Bool {
        switch tab {
        case .metadata:
            return !node.duration.isEmpty || node.milestoneId != nil ||
                   !node.day.isEmpty || !node.learningObjective.isEmpty ||
                   !node.artifact.isEmpty || !node.mentorTasks.isEmpty
        case .guidingQuestions:
            return !node.guidingQuestions.isEmpty
        case .guidingActivities:
            return !node.guidingActivities.isEmpty
        case .findings:
            return !node.findings.isEmpty
        case .synthesis:
            return !node.synthesis.isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Exploratory Cycle #\(node.sequenceNumber + 1)")
                    .font(.system(size: 22 * fontScale, weight: .bold))

                Text("EC의 필수 구성 요소를 순서대로 작성하세요")
                    .font(.system(size: 12 * fontScale))
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ECEditingTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                            node.lastSelectedTab = tab.rawValue
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14 * fontScale))
                                    .foregroundColor(selectedTab == tab ? .white : tab.color)

                                Text(tab.rawValue)
                                    .font(.system(size: 13 * fontScale, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? .white : .primary)

                                if isTabCompleted(tab) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12 * fontScale))
                                        .foregroundColor(selectedTab == tab ? .white : .green)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == tab ? tab.color : Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .metadata:
                        metadataContent
                    case .guidingQuestions:
                        guidingQuestionsContent
                    case .guidingActivities:
                        guidingActivitiesContent
                    case .findings:
                        findingsContent
                    case .synthesis:
                        synthesisContent
                    }
                }
                .padding()
            }

            Divider()

            // Bottom Action Bar
            HStack {
                Button("Delete EC", role: .destructive) {
                    onDelete()
                }
                .buttonStyle(.bordered)

                Spacer()

                // Navigation buttons
                if selectedTab != .metadata {
                    Button(action: {
                        if let currentIndex = ECEditingTab.allCases.firstIndex(of: selectedTab),
                           currentIndex > 0 {
                            selectedTab = ECEditingTab.allCases[currentIndex - 1]
                            node.lastSelectedTab = selectedTab.rawValue
                        }
                    }) {
                        Label("Previous", systemImage: "chevron.left")
                            .font(.system(size: 13 * fontScale))
                    }
                    .buttonStyle(.bordered)
                }

                if selectedTab != .synthesis {
                    Button(action: {
                        if let currentIndex = ECEditingTab.allCases.firstIndex(of: selectedTab),
                           currentIndex < ECEditingTab.allCases.count - 1 {
                            selectedTab = ECEditingTab.allCases[currentIndex + 1]
                            node.lastSelectedTab = selectedTab.rawValue
                        }
                    }) {
                        Label("Next", systemImage: "chevron.right")
                            .labelStyle(.trailingIcon)
                            .font(.system(size: 13 * fontScale))
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Cancel") {
                    if hasContent {
                        showCancelConfirmation = true
                    } else {
                        onCancel()
                    }
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    onSave(node)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
        .interactiveDismissDisabled()
        .onAppear {
            // Restore last selected tab if available
            if !hasRestoredTab {
                if let lastTabRawValue = node.lastSelectedTab,
                   let lastTab = ECEditingTab(rawValue: lastTabRawValue) {
                    selectedTab = lastTab
                }
                hasRestoredTab = true
            }
        }
        .alert("Unsaved Changes", isPresented: $showCancelConfirmation) {
            Button("Don't Save", role: .destructive) {
                onCancel()
            }
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                onSave(node)
            }
        } message: {
            Text("Do you want to save your changes to this Exploratory Cycle?")
        }
    }

    // MARK: - Tab Content Views

    private var metadataContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18 * fontScale))
                        .foregroundColor(.blue)
                    Text("EC 메타데이터")
                        .font(.system(size: 18 * fontScale, weight: .bold))
                }
                Text("EC의 기본 정보와 연결할 마일스톤을 설정하세요")
                    .font(.system(size: 12 * fontScale))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Day
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 16 * fontScale))
                        .foregroundColor(.orange)
                    Text("Day / Timeline")
                        .font(.system(size: 16 * fontScale, weight: .semibold))
                }

                Text("언제 진행되는 활동인가요? (예: Day 1, Week 2)")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .italic()

                TextField("e.g., Day 1, Week 2", text: $node.day)
                    .font(.system(size: 14 * fontScale))
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.05))
            )

            // Learning Objective
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 16 * fontScale))
                        .foregroundColor(.blue)
                    Text("학습 목표 (Learning Objective)")
                        .font(.system(size: 16 * fontScale, weight: .semibold))
                }

                Text("오늘 러너들은... (이 EC를 통해 학습자가 달성할 구체적 목표)")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .italic()

                TextEditor(text: $node.learningObjective)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 60)
                    .border(Color.blue.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
            )

            // Artifact/Deliverable
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16 * fontScale))
                        .foregroundColor(.green)
                    Text("Artifact / Deliverable")
                        .font(.system(size: 16 * fontScale, weight: .semibold))
                }

                Text("이 EC에서 만들어야 할 구체적인 결과물")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .italic()

                TextEditor(text: $node.artifact)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 60)
                    .border(Color.green.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.05))
            )

            // Mentor Tasks
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 16 * fontScale))
                        .foregroundColor(.purple)
                    Text("멘토의 할일 (Mentor Tasks)")
                        .font(.system(size: 16 * fontScale, weight: .semibold))
                }

                Text("멘토가 이 EC에서 해야 할 구체적인 활동")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .italic()

                TextEditor(text: $node.mentorTasks)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 60)
                    .border(Color.purple.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.05))
            )

            Divider()

            // Target Milestone
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 16 * fontScale))
                        .foregroundColor(.orange)
                    Text("Target Milestone")
                        .font(.system(size: 16 * fontScale, weight: .semibold))
                }

                Text("이 EC가 달성하려는 마일스톤을 선택하세요")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .italic()

                if availableMilestones.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("No milestones available.")
                                .font(.system(size: 12 * fontScale))
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            onCreateMilestone()
                        }) {
                            Label("Create Milestone", systemImage: "flag.circle.fill")
                                .font(.system(size: 13 * fontScale))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Milestone", selection: $node.milestoneId) {
                            Text("None")
                                .tag(nil as UUID?)
                            ForEach(availableMilestones) { milestone in
                                Text(milestone.title.isEmpty ? "Milestone #\(milestone.sequenceNumber + 1)" : milestone.title)
                                    .tag(milestone.id as UUID?)
                            }
                        }
                        .font(.system(size: 14 * fontScale))

                        Button(action: {
                            onCreateMilestone()
                        }) {
                            Label("Create New Milestone", systemImage: "plus.circle.fill")
                                .font(.system(size: 12 * fontScale))
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.orange)

                        if let selectedId = node.milestoneId,
                           let selectedMilestone = availableMilestones.first(where: { $0.id == selectedId }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 11 * fontScale))
                                        .foregroundColor(.orange)
                                    Text(selectedMilestone.title.isEmpty ? "Milestone #\(selectedMilestone.sequenceNumber + 1)" : selectedMilestone.title)
                                        .font(.system(size: 12 * fontScale, weight: .semibold))
                                }

                                if !selectedMilestone.description.isEmpty {
                                    Text(selectedMilestone.description)
                                        .font(.system(size: 11 * fontScale))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )

            // EC Duration
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16 * fontScale))
                        .foregroundColor(.blue)
                    Text("EC Duration")
                        .font(.system(size: 16 * fontScale, weight: .semibold))
                    Spacer()
                    Text("It Depends")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary)
                        .italic()
                }

                Text("Exploratory cycles are as long as necessary and should be laser-focused on the learning necessary to achieve the expected milestone")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)

                TextField("e.g., 2 weeks, 3 days, 1 month", text: $node.duration)
                    .font(.system(size: 14 * fontScale))
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
            )

            // EC Transition - If milestone not achieved
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 16 * fontScale))
                        .foregroundColor(.red)
                    Text("If Milestone Not Achieved")
                        .font(.system(size: 16 * fontScale, weight: .semibold))
                    Spacer()
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14 * fontScale))
                        .foregroundColor(.red)
                }

                Text("마일스톤을 달성하지 못했다면, 다음에 시도할 EC를 선택하거나 생성하세요")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Picker("Next EC to try", selection: $node.nextECId) {
                        Text("None - 선택 안 함")
                            .tag(nil as UUID?)
                        ForEach(availableECs.filter { $0.id != node.id }) { ec in
                            Text("EC #\(ec.sequenceNumber + 1)" + (!ec.guidingQuestions.isEmpty ? " - \(ec.guidingQuestions.prefix(30))..." : ""))
                                .tag(ec.id as UUID?)
                        }
                    }
                    .font(.system(size: 14 * fontScale))

                    Button(action: {
                        onCreateEC()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14 * fontScale))
                            Text("Create New EC")
                                .font(.system(size: 13 * fontScale, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("✅ 달성했다면 이 EC를 완료하고 다음 마일스톤으로 이동합니다")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.1))
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    private var guidingQuestionsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("1️⃣")
                        .font(.system(size: 24 * fontScale, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guiding Questions")
                            .font(.system(size: 20 * fontScale, weight: .bold))
                            .foregroundColor(.blue)
                        Text("What needs to be learned?")
                            .font(.system(size: 14 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Divider()

                Text("탐색하고 답해야 할 핵심 질문들을 작성하세요. 이 질문들이 전체 EC의 방향을 설정합니다.")
                    .font(.system(size: 12 * fontScale))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }

            TextEditor(text: $node.guidingQuestions)
                .font(.system(size: 14 * fontScale))
                .frame(minHeight: 250)
                .border(Color.blue.opacity(0.3), width: 2)
                .cornerRadius(4)

            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("예시: \"사용자들이 이 기능을 어떻게 사용할까?\", \"기술적으로 구현 가능한가?\"")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
    }

    private var guidingActivitiesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("2️⃣")
                        .font(.system(size: 24 * fontScale, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guiding Activities / Resources")
                            .font(.system(size: 20 * fontScale, weight: .bold))
                            .foregroundColor(.green)
                        Text("How will we learn it?")
                            .font(.system(size: 14 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Divider()

                Text("질문에 답하기 위해 수행할 활동이나 필요한 리소스를 작성하세요.")
                    .font(.system(size: 12 * fontScale))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }

            TextEditor(text: $node.guidingActivities)
                .font(.system(size: 14 * fontScale))
                .frame(minHeight: 250)
                .border(Color.green.opacity(0.3), width: 2)
                .cornerRadius(4)

            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("예시: \"사용자 인터뷰 5회\", \"프로토타입 제작\", \"기술 문서 리뷰\"")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
    }

    private var findingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("3️⃣")
                        .font(.system(size: 24 * fontScale, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Findings")
                            .font(.system(size: 20 * fontScale, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("What did we learn?")
                            .font(.system(size: 14 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Divider()

                Text("활동을 통해 발견한 사실과 학습한 내용을 정리하세요.")
                    .font(.system(size: 12 * fontScale))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }

            TextEditor(text: $node.findings)
                .font(.system(size: 14 * fontScale))
                .frame(minHeight: 250)
                .border(Color.yellow.opacity(0.3), width: 2)
                .cornerRadius(4)

            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("예시: \"사용자 80%가 특정 기능 선호\", \"기술 A가 더 적합함\"")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
    }

    private var synthesisContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("4️⃣")
                        .font(.system(size: 24 * fontScale, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synthesis → Milestone")
                            .font(.system(size: 20 * fontScale, weight: .bold))
                            .foregroundColor(.purple)
                        Text("Did we learn enough to address the milestone?")
                            .font(.system(size: 14 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("발견한 내용을 종합하여 마일스톤을 달성할 수 있는지 판단하세요.")
                        .font(.system(size: 12 * fontScale))
                        .foregroundColor(.secondary)
                    Text("The synthesis leads to or represents a milestone")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.orange)
                        .italic()
                }
                .padding(.vertical, 4)
            }

            TextEditor(text: $node.synthesis)
                .font(.system(size: 14 * fontScale))
                .frame(minHeight: 250)
                .border(Color.purple.opacity(0.3), width: 2)
                .cornerRadius(4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("마일스톤 달성 여부")
                        .font(.system(size: 13 * fontScale, weight: .semibold))
                }

                Text("✅ 달성: 다음 마일스톤으로 이동")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                Text("❌ 미달성: 새로운 EC를 생성하여 추가 탐색")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// Custom label style for trailing icon
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}
