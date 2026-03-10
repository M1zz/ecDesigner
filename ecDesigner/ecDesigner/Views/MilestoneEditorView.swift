import SwiftUI

// 필드 정의 - 표시 순서가 곧 고정 순서
private struct MilestoneField {
    let id: String
    let label: String
    let icon: String
    let iconColor: Color
}

private let allMilestoneFields: [MilestoneField] = [
    MilestoneField(id: "title",            label: "Title",                icon: "flag.fill",              iconColor: .orange),
    MilestoneField(id: "duration",         label: "Period",               icon: "calendar",               iconColor: .orange),
    MilestoneField(id: "phase",            label: "Phase",                icon: "circle.grid.2x2",        iconColor: .gray),
    MilestoneField(id: "description",      label: "Description",          icon: "text.alignleft",         iconColor: .secondary),
    MilestoneField(id: "successCriteria",  label: "Success Criteria",     icon: "checkmark.seal.fill",    iconColor: .green),
    MilestoneField(id: "deliverable",      label: "Deliverable",          icon: "shippingbox.fill",       iconColor: .blue),
    MilestoneField(id: "artifacts",        label: "Artifacts",            icon: "doc.on.doc.fill",        iconColor: .teal),
    MilestoneField(id: "mentorGuidelines", label: "Mentoring Guidelines", icon: "person.fill.badge.plus", iconColor: .purple),
]

struct MilestoneEditorView: View {
    @Binding var milestone: Milestone
    let fontScale: CGFloat
    let onSave: (Milestone) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var showCancelConfirmation = false
    @State private var initialMilestone: Milestone?
    // 추가된 필드 ID (순서는 allMilestoneFields 기준으로 정렬)
    @State private var addedFields: Set<String> = []

    private var hasChanges: Bool {
        guard let initial = initialMilestone else { return false }
        return milestone.title != initial.title ||
               milestone.description != initial.description ||
               milestone.successCriteria != initial.successCriteria ||
               milestone.deliverable != initial.deliverable ||
               milestone.artifacts != initial.artifacts ||
               milestone.mentorGuidelines != initial.mentorGuidelines ||
               milestone.phase != initial.phase
    }

    // 추가된 필드를 고정 순서대로 반환
    private var visibleFields: [MilestoneField] {
        allMilestoneFields.filter { addedFields.contains($0.id) }
    }

    // 아직 추가되지 않은 필드
    private var remainingFields: [MilestoneField] {
        allMilestoneFields.filter { !addedFields.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Milestone #\(milestone.sequenceNumber + 1)")
                        .font(.system(size: 20 * fontScale, weight: .bold))
                    Text("\(visibleFields.count) / \(allMilestoneFields.count) 항목 작성됨")
                        .font(.system(size: 12 * fontScale))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // 추가된 필드들 (고정 순서)
                    ForEach(visibleFields, id: \.id) { field in
                        fieldView(for: field)
                    }

                    // 추가 가능한 필드 카드들
                    addFieldButton
                }
                .padding()
            }

            Divider()

            HStack {
                Button("Delete Milestone", role: .destructive) {
                    onDelete()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Cancel") {
                    if hasChanges {
                        showCancelConfirmation = true
                    } else {
                        onCancel()
                    }
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    onSave(milestone)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasChanges)
            }
            .padding()
        }
        .frame(width: 540, height: 680)
        .interactiveDismissDisabled()
        .onAppear {
            initialMilestone = milestone
            // 이미 내용이 있는 필드는 자동으로 추가
            if !milestone.title.isEmpty            { addedFields.insert("title") }
            if !milestone.duration.isEmpty         { addedFields.insert("duration") }
            if milestone.phase != nil              { addedFields.insert("phase") }
            if !milestone.description.isEmpty      { addedFields.insert("description") }
            if !milestone.successCriteria.isEmpty  { addedFields.insert("successCriteria") }
            if !milestone.deliverable.isEmpty      { addedFields.insert("deliverable") }
            if !milestone.artifacts.isEmpty        { addedFields.insert("artifacts") }
            if !milestone.mentorGuidelines.isEmpty { addedFields.insert("mentorGuidelines") }
        }
        .alert("Unsaved Changes", isPresented: $showCancelConfirmation) {
            Button("Don't Save", role: .destructive) { onCancel() }
            Button("Cancel", role: .cancel) { }
            Button("Save") { onSave(milestone) }
        } message: {
            Text("Do you want to save your changes to this Milestone?")
        }
    }

    // MARK: - 추가 가능한 필드 카드들

    private var addFieldButton: some View {
        VStack(spacing: 8) {
            if !addedFields.isEmpty {
                Divider()
                    .padding(.vertical, 4)
            }

            ForEach(remainingFields, id: \.id) { field in
                Button(action: {
                    withAnimation(Animation.spring(response: 0.38, dampingFraction: 0.78)) {
                        _ = addedFields.insert(field.id)
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(field.iconColor.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: field.icon)
                                .font(.system(size: 15 * fontScale))
                                .foregroundColor(field.iconColor)
                        }

                        Text(field.label)
                            .font(.system(size: 14 * fontScale, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "plus")
                            .font(.system(size: 14 * fontScale, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
    }

    // MARK: - 개별 필드 뷰

    @ViewBuilder
    private func fieldView(for field: MilestoneField) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 필드 헤더
            HStack(spacing: 8) {
                Image(systemName: field.icon)
                    .font(.system(size: 13 * fontScale))
                    .foregroundColor(field.iconColor)
                    .frame(width: 18)
                Text(field.label)
                    .font(.system(size: 13 * fontScale, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                // 제거 버튼
                Button(action: { removeField(field.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("\(field.label) 제거")
            }

            // 필드 에디터
            switch field.id {
            case "title":
                TextField("Enter milestone title", text: $milestone.title)
                    .font(.system(size: 14 * fontScale))
                    .textFieldStyle(.roundedBorder)

            case "duration":
                TextField("e.g. Week 1–2, Day 1–5", text: $milestone.duration)
                    .font(.system(size: 14 * fontScale))
                    .textFieldStyle(.roundedBorder)

            case "phase":
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Phase", selection: $milestone.phase) {
                        Text("None").tag(nil as Phase?)
                        ForEach(Phase.allCases, id: \.self) { phase in
                            Text(phase.rawValue).tag(phase as Phase?)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let phase = milestone.phase {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(phase.color)
                                .font(.system(size: 11 * fontScale))
                            Text(phase.description)
                                .font(.system(size: 11 * fontScale))
                                .foregroundColor(.secondary)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(Animation.spring(response: 0.32, dampingFraction: 0.82), value: milestone.phase)

            case "description":
                TextEditor(text: $milestone.description)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 80)
                    .border(Color.gray.opacity(0.2), width: 1)

            case "successCriteria":
                TextEditor(text: $milestone.successCriteria)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 80)
                    .border(Color.green.opacity(0.2), width: 1)

            case "deliverable":
                TextEditor(text: $milestone.deliverable)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 70)
                    .border(Color.blue.opacity(0.2), width: 1)

            case "artifacts":
                TextEditor(text: $milestone.artifacts)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 70)
                    .border(Color.teal.opacity(0.2), width: 1)

            case "mentorGuidelines":
                TextEditor(text: $milestone.mentorGuidelines)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 80)
                    .border(Color.purple.opacity(0.2), width: 1)

            default:
                EmptyView()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(field.iconColor.opacity(0.15), lineWidth: 1)
                )
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: addedFields)
    }

    private func removeField(_ id: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            addedFields.remove(id)
        }
        // 제거 시 해당 필드 내용 초기화
        switch id {
        case "title":            milestone.title = ""
        case "duration":         milestone.duration = ""
        case "phase":            milestone.phase = nil
        case "description":      milestone.description = ""
        case "successCriteria":  milestone.successCriteria = ""
        case "deliverable":      milestone.deliverable = ""
        case "artifacts":        milestone.artifacts = ""
        case "mentorGuidelines": milestone.mentorGuidelines = ""
        default: break
        }
    }
}
