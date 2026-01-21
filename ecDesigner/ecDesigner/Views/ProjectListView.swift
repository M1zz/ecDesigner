import SwiftUI

struct ProjectListView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @Binding var showProjectList: Bool
    @State private var projects: [Project] = []
    @State private var newProjectName: String = ""
    @State private var showNewProjectDialog: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Your Challenges")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Close") {
                    showProjectList = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Project List
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(projects) { project in
                        ProjectRow(
                            project: project,
                            isCurrentProject: project.id == viewModel.currentProject.id,
                            onSelect: {
                                viewModel.loadProject(project)
                                showProjectList = false
                            },
                            onDelete: {
                                deleteProject(project)
                            }
                        )
                    }

                    if projects.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)

                            Text("No challenges yet")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Create your first challenge to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding()
            }

            Divider()

            // Footer with New Project button
            HStack {
                Button(action: {
                    showNewProjectDialog = true
                }) {
                    Label("New Challenge", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadProjects()
        }
        .sheet(isPresented: $showNewProjectDialog) {
            NewProjectDialog(
                projectName: $newProjectName,
                onCreate: {
                    if !newProjectName.isEmpty {
                        viewModel.createNewProject(name: newProjectName)
                        loadProjects()
                        newProjectName = ""
                        showNewProjectDialog = false
                        showProjectList = false
                    }
                },
                onCancel: {
                    newProjectName = ""
                    showNewProjectDialog = false
                }
            )
        }
    }

    private func loadProjects() {
        projects = PersistenceManager.shared.loadProjects()
            .sorted { $0.modifiedDate > $1.modifiedDate }
    }

    private func deleteProject(_ project: Project) {
        PersistenceManager.shared.deleteProject(project.id)
        loadProjects()

        // If deleted current project, switch to another or create new
        if project.id == viewModel.currentProject.id {
            if let firstProject = projects.first {
                viewModel.loadProject(firstProject)
            } else {
                viewModel.createNewProject()
            }
        }
    }
}

struct ProjectRow: View {
    let project: Project
    let isCurrentProject: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(isCurrentProject ? .blue : .primary)

                HStack {
                    Text("Modified: \(project.modifiedDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(project.exploratoryCycle.milestones.count) milestones")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(project.exploratoryCycle.nodes.count) ECs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isCurrentProject {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentProject ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

struct NewProjectDialog: View {
    @Binding var projectName: String
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Challenge")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Challenge Name", text: $projectName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onCreate()
                }

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    onCreate()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(projectName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
