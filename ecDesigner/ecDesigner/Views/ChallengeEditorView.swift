import SwiftUI

struct ChallengeEditorView: View {
    @Binding var project: Project
    let fontScale: CGFloat
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var showCancelConfirmation = false
    @State private var initialProject: Project?

    private var hasChanges: Bool {
        guard let initial = initialProject else { return false }
        return project.name != initial.name ||
               project.challengeStatement != initial.challengeStatement ||
               project.challengeDescription != initial.challengeDescription ||
               project.targetLearners != initial.targetLearners ||
               project.duration != initial.duration ||
               project.overallSuccessCriteria != initial.overallSuccessCriteria
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Challenge Information")
                .font(.system(size: 22 * fontScale, weight: .bold))

            Text("Define the overall challenge and learning goals")
                .font(.system(size: 12 * fontScale))
                .foregroundColor(.secondary)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Challenge Name
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Challenge Name", systemImage: "star.fill")
                            .font(.system(size: 17 * fontScale, weight: .semibold))
                            .foregroundColor(.blue)

                        TextField("Enter challenge name", text: $project.name)
                            .font(.system(size: 14 * fontScale))
                            .textFieldStyle(.roundedBorder)
                    }

                    // Challenge Statement
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.yellow)
                            Text("Challenge Statement")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("What is the main challenge or problem to solve?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $project.challengeStatement)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 80)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Challenge Description")
                            .font(.system(size: 17 * fontScale, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("Detailed description of the challenge context and goals")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $project.challengeDescription)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 100)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    // Target Learners
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.green)
                            Text("Target Learners")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("Who is this challenge designed for?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $project.targetLearners)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 70)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.orange)
                            Text("Duration")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("Expected timeframe for completing this challenge")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextField("e.g., 3 weeks, 10 days, etc.", text: $project.duration)
                            .font(.system(size: 14 * fontScale))
                            .textFieldStyle(.roundedBorder)
                    }

                    // Overall Success Criteria
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 17 * fontScale))
                                .foregroundColor(.green)
                            Text("Overall Success Criteria")
                                .font(.system(size: 17 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("How will you know the challenge is successfully completed?")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                            .italic()

                        TextEditor(text: $project.overallSuccessCriteria)
                            .font(.system(size: 14 * fontScale))
                            .frame(minHeight: 100)
                            .border(Color.gray.opacity(0.2), width: 1)
                    }

                    Divider()

                    // Info box
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("About Challenges")
                                .font(.system(size: 15 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.blue)
                                Text("A Challenge is the overarching learning experience")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.blue)
                                Text("Milestones break down the challenge into achievable goals")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 11 * fontScale))
                                    .foregroundColor(.blue)
                                Text("ECs are iterative activities to gather knowledge and skills")
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
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 650, height: 800)
        .onAppear {
            initialProject = project
        }
        .alert("Unsaved Changes", isPresented: $showCancelConfirmation) {
            Button("Don't Save", role: .destructive) {
                onCancel()
            }
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                onSave()
            }
        } message: {
            Text("Do you want to save your changes to this Challenge?")
        }
    }
}
