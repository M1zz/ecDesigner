import SwiftUI

struct MilestoneEditorView: View {
    @Binding var milestone: Milestone
    let fontScale: CGFloat
    let onSave: (Milestone) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var showCancelConfirmation = false
    @State private var initialMilestone: Milestone?

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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestone #\(milestone.sequenceNumber + 1)")
                .font(.system(size: 22 * fontScale, weight: .bold))

            Text("Define the goal and expected outcomes")
                .font(.system(size: 12 * fontScale))
                .foregroundColor(.secondary)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Milestone Title", systemImage: "flag.fill")
                            .font(.system(size: 17 * fontScale, weight: .semibold))
                            .foregroundColor(.orange)

                        TextField("Enter milestone title", text: $milestone.title)
                            .font(.system(size: 14 * fontScale))
                            .textFieldStyle(.roundedBorder)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.system(size: 17 * fontScale, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("What is this milestone about?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $milestone.description)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 80)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    // Phase
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: milestone.phase?.icon ?? "circle.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(milestone.phase?.color ?? .gray)
                            Text("Phase")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("Which phase does this milestone belong to?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        Picker("Phase", selection: $milestone.phase) {
                            Text("None")
                                .tag(nil as Phase?)
                            ForEach(Phase.allCases, id: \.self) { phase in
                                Text(phase.rawValue)
                                    .tag(phase as Phase?)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let phase = milestone.phase {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(phase.color)
                                Text(phase.description)
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(phase.color.opacity(0.1))
                            )
                        }
                    }

                    // Success Criteria
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.green)
                            Text("Success Criteria")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("How will you know this milestone has been achieved?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $milestone.successCriteria)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 80)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    Divider()

                    // Deliverable
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.blue)
                            Text("Deliverable")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("What will be delivered at this milestone?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $milestone.deliverable)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 70)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    // Artifacts
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.green)
                            Text("Artifacts")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("Tangible outputs or evidence of completion")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $milestone.artifacts)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 70)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    Divider()

                    // Mentor Guidelines
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "person.fill.badge.plus")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.purple)
                            Text("Mentoring Guidelines")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("How should mentors support learners in achieving this milestone?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $milestone.mentorGuidelines)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 80)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    Divider()

                    // Info box
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("About Milestones")
                                .font(.system(size: 15 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.blue)
                                Text("Milestones represent significant achievements in your challenge")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.blue)
                                Text("Each milestone should have clear deliverables and artifacts")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.blue)
                                Text("Create Exploratory Cycles to achieve each milestone")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.vertical)
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
            }
        }
        .padding()
        .frame(width: 650, height: 800)
        .interactiveDismissDisabled()
        .onAppear {
            initialMilestone = milestone
        }
        .alert("Unsaved Changes", isPresented: $showCancelConfirmation) {
            Button("Don't Save", role: .destructive) {
                onCancel()
            }
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                onSave(milestone)
            }
        } message: {
            Text("Do you want to save your changes to this Milestone?")
        }
    }
}
