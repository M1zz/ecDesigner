import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()

    private let projectsKey = "SavedProjects"
    private let lastOpenedProjectKey = "LastOpenedProject"

    private init() {}

    // Get file URL for projects
    private func getProjectsFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("ecDesignerProjects.json")
    }

    // Save all projects
    func saveProjects(_ projects: [Project]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(projects)
            try data.write(to: getProjectsFileURL())
            print("✅ Projects saved successfully")
        } catch {
            print("❌ Error saving projects: \(error)")
        }
    }

    // Load all projects
    func loadProjects() -> [Project] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: getProjectsFileURL())
            let projects = try decoder.decode([Project].self, from: data)
            print("✅ Loaded \(projects.count) projects")
            return projects
        } catch {
            print("⚠️ Error loading projects (this is normal on first run): \(error)")
            return []
        }
    }

    // Save last opened project ID
    func saveLastOpenedProjectId(_ projectId: UUID) {
        UserDefaults.standard.set(projectId.uuidString, forKey: lastOpenedProjectKey)
    }

    // Load last opened project ID
    func loadLastOpenedProjectId() -> UUID? {
        guard let idString = UserDefaults.standard.string(forKey: lastOpenedProjectKey) else {
            return nil
        }
        return UUID(uuidString: idString)
    }

    // Quick save a single project (updates it in the list)
    func quickSaveProject(_ project: Project) {
        var projects = loadProjects()

        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }

        saveProjects(projects)
        saveLastOpenedProjectId(project.id)
    }

    // Delete a project
    func deleteProject(_ projectId: UUID) {
        var projects = loadProjects()
        projects.removeAll { $0.id == projectId }
        saveProjects(projects)
    }
}
