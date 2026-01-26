import Foundation
import SwiftUI
import Combine

class CanvasViewModel: ObservableObject {
    @Published var currentProject: Project {
        didSet {
            autoSave()
        }
    }
    @Published var selectedNodeId: UUID?
    @Published var selectedMilestoneId: UUID?
    @Published var canvasOffset: CGSize = .zero
    @Published var canvasScale: CGFloat = 1.0
    @Published var fontScale: CGFloat = 1.0
    @Published var isConnectionMode: Bool = false
    @Published var isConnecting: Bool = false
    @Published var connectionStartNodeId: UUID?
    @Published var connectionStartDirection: AnchorDirection?
    @Published var connectionEndPoint: CGPoint?

    // 스냅그리드 설정 (8pt 단위)
    let snapGridSize: CGFloat = 8.0

    private var autoSaveTimer: Timer?

    // MARK: - Undo System
    private var undoStack: [UndoAction] = []
    private let maxUndoStackSize = 50
    private var isUndoing = false  // Flag to prevent recording undo actions during undo

    var exploratoryCycle: ExploratoryCycle {
        get { currentProject.exploratoryCycle }
        set {
            currentProject.exploratoryCycle = newValue
            currentProject.modifiedDate = Date()
        }
    }

    enum UndoAction {
        case addNode(ECNode)
        case deleteNode(ECNode)
        case addMilestone(Milestone)
        case deleteMilestone(Milestone)
        case moveNode(nodeId: UUID, oldPosition: CGPoint, newPosition: CGPoint)
        case moveMilestone(milestoneId: UUID, oldPosition: CGPoint, newPosition: CGPoint)
    }

    init(project: Project? = nil) {
        if let project = project {
            self.currentProject = project
        } else {
            // Try to load last opened project
            let projects = PersistenceManager.shared.loadProjects()
            if let lastProjectId = PersistenceManager.shared.loadLastOpenedProjectId(),
               let lastProject = projects.first(where: { $0.id == lastProjectId }) {
                self.currentProject = lastProject
            } else if let firstProject = projects.first {
                self.currentProject = firstProject
            } else {
                // Create new project if none exist
                self.currentProject = Project()
            }
        }
    }

    func addNode(at position: CGPoint) {
        let sequenceNumber = exploratoryCycle.nodes.count
        let newNode = ECNode(
            position: position,
            sequenceNumber: sequenceNumber
        )
        exploratoryCycle.addNode(newNode)
        selectedNodeId = newNode.id

        // Record undo action
        recordUndo(.addNode(newNode))
    }

    func updateNode(_ node: ECNode) {
        exploratoryCycle.updateNode(node)
    }

    func deleteNode(_ nodeId: UUID) {
        // Get node before deleting for undo
        if let node = exploratoryCycle.nodes.first(where: { $0.id == nodeId }) {
            recordUndo(.deleteNode(node))
        }

        exploratoryCycle.removeNode(nodeId)
        if selectedNodeId == nodeId {
            selectedNodeId = nil
        }
    }

    func moveNode(_ nodeId: UUID, to position: CGPoint) {
        if let index = exploratoryCycle.nodes.firstIndex(where: { $0.id == nodeId }) {
            let oldPosition = exploratoryCycle.nodes[index].position
            let snappedPosition = snapToGrid(position)
            exploratoryCycle.nodes[index].position = snappedPosition

            // Record undo action (only if position actually changed)
            if oldPosition != snappedPosition {
                recordUndo(.moveNode(nodeId: nodeId, oldPosition: oldPosition, newPosition: snappedPosition))
            }
        }
    }

    // 스냅그리드에 맞춰 위치 조정
    private func snapToGrid(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: round(point.x / snapGridSize) * snapGridSize,
            y: round(point.y / snapGridSize) * snapGridSize
        )
    }

    func toggleConnectionMode() {
        isConnectionMode.toggle()
        if !isConnectionMode {
            cancelConnection()
        }
    }

    func startConnection(from nodeId: UUID, direction: AnchorDirection) {
        isConnecting = true
        connectionStartNodeId = nodeId
        connectionStartDirection = direction
    }

    func updateConnectionEndPoint(_ point: CGPoint) {
        connectionEndPoint = point
    }

    func finishConnection(at point: CGPoint) {
        guard let startNodeId = connectionStartNodeId,
              let startDirection = connectionStartDirection else {
            cancelConnection()
            return
        }

        // 끝점에 있는 노드 찾기
        if let targetNode = findNodeAt(point: point), targetNode.id != startNodeId {
            // 가장 가까운 방향 찾기
            let endDirection = findClosestDirection(from: point, to: targetNode.position)

            // 연결 추가
            let connection = NodeConnection(
                fromNodeId: startNodeId,
                toNodeId: targetNode.id,
                fromDirection: startDirection,
                toDirection: endDirection
            )
            exploratoryCycle.connections.append(connection)
            exploratoryCycle.modifiedDate = Date()
        }

        cancelConnection()
    }

    func cancelConnection() {
        isConnecting = false
        connectionStartNodeId = nil
        connectionStartDirection = nil
        connectionEndPoint = nil
    }

    func getNode(by id: UUID) -> ECNode? {
        exploratoryCycle.nodes.first { $0.id == id }
    }

    func getConnections(for nodeId: UUID) -> [NodeConnection] {
        exploratoryCycle.connections.filter { $0.fromNodeId == nodeId || $0.toNodeId == nodeId }
    }

    func reorderNodes() {
        for (index, node) in exploratoryCycle.getOrderedNodes().enumerated() {
            if let nodeIndex = exploratoryCycle.nodes.firstIndex(where: { $0.id == node.id }) {
                exploratoryCycle.nodes[nodeIndex].sequenceNumber = index
            }
        }
    }

    func deleteConnection(_ connectionId: UUID) {
        exploratoryCycle.removeConnection(connectionId)
    }

    // Helper: 포인트에 있는 노드 찾기
    private func findNodeAt(point: CGPoint) -> ECNode? {
        let threshold: CGFloat = 50
        return exploratoryCycle.nodes.first { node in
            let distance = sqrt(pow(node.position.x - point.x, 2) + pow(node.position.y - point.y, 2))
            return distance < threshold
        }
    }

    // Helper: 가장 가까운 방향 찾기
    private func findClosestDirection(from point: CGPoint, to nodePosition: CGPoint) -> AnchorDirection {
        let dx = point.x - nodePosition.x
        let dy = point.y - nodePosition.y

        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        } else {
            return dy > 0 ? .bottom : .top
        }
    }

    // Helper: 연결선의 앵커 포인트 계산
    func getAnchorPoint(for nodeId: UUID, direction: AnchorDirection) -> CGPoint? {
        guard let node = getNode(by: nodeId) else { return nil }
        let offset = direction.offset
        return CGPoint(
            x: node.position.x + offset.width,
            y: node.position.y + offset.height
        )
    }

    // 폰트 크기 조절
    func zoomIn() {
        fontScale = min(fontScale + 0.1, 3.0)
    }

    func zoomOut() {
        fontScale = max(fontScale - 0.1, 0.5)
    }

    func resetZoom() {
        fontScale = 1.0
    }

    // Canvas position control
    func resetCanvasPosition() {
        canvasOffset = .zero
    }

    // Milestone management
    func addMilestone(at position: CGPoint? = nil) {
        let sequenceNumber = exploratoryCycle.milestones.count
        // Position milestones in a vertical line on the left side by default
        let defaultPosition = CGPoint(
            x: 200,
            y: 200 + CGFloat(sequenceNumber) * 300
        )
        let newMilestone = Milestone(
            title: "",
            sequenceNumber: sequenceNumber,
            position: position ?? defaultPosition
        )
        exploratoryCycle.addMilestone(newMilestone)
        selectedMilestoneId = newMilestone.id

        // Record undo action
        recordUndo(.addMilestone(newMilestone))
    }

    func updateMilestone(_ milestone: Milestone) {
        exploratoryCycle.updateMilestone(milestone)
    }

    func deleteMilestone(_ milestoneId: UUID) {
        // Get milestone before deleting for undo
        if let milestone = exploratoryCycle.milestones.first(where: { $0.id == milestoneId }) {
            recordUndo(.deleteMilestone(milestone))
        }

        exploratoryCycle.removeMilestone(milestoneId)
        if selectedMilestoneId == milestoneId {
            selectedMilestoneId = nil
        }
    }

    func getMilestone(by id: UUID) -> Milestone? {
        exploratoryCycle.milestones.first { $0.id == id }
    }

    func moveMilestone(_ milestoneId: UUID, to position: CGPoint) {
        if let index = exploratoryCycle.milestones.firstIndex(where: { $0.id == milestoneId }) {
            let oldPosition = exploratoryCycle.milestones[index].position
            let snappedPosition = snapToGrid(position)
            exploratoryCycle.milestones[index].position = snappedPosition

            // Record undo action (only if position actually changed)
            if oldPosition != snappedPosition {
                recordUndo(.moveMilestone(milestoneId: milestoneId, oldPosition: oldPosition, newPosition: snappedPosition))
            }
        }
    }

    func toggleMilestoneAchieved(_ milestoneId: UUID) {
        if let index = exploratoryCycle.milestones.firstIndex(where: { $0.id == milestoneId }) {
            exploratoryCycle.milestones[index].isAchieved.toggle()
        }
    }

    // Auto-save with debouncing
    private func autoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.saveCurrentProject()
        }
    }

    func saveCurrentProject() {
        currentProject.modifiedDate = Date()
        PersistenceManager.shared.quickSaveProject(currentProject)
    }

    // MARK: - Undo/Redo

    private func recordUndo(_ action: UndoAction) {
        guard !isUndoing else { return }
        undoStack.append(action)
        if undoStack.count > maxUndoStackSize {
            undoStack.removeFirst()
        }
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        isUndoing = true
        defer { isUndoing = false }

        let action = undoStack.removeLast()

        switch action {
        case .addNode(let node):
            // Undo node addition by removing it
            exploratoryCycle.nodes.removeAll { $0.id == node.id }

        case .deleteNode(let node):
            // Undo node deletion by adding it back
            exploratoryCycle.addNode(node)

        case .addMilestone(let milestone):
            // Undo milestone addition by removing it
            exploratoryCycle.milestones.removeAll { $0.id == milestone.id }

        case .deleteMilestone(let milestone):
            // Undo milestone deletion by adding it back
            exploratoryCycle.addMilestone(milestone)

        case .moveNode(let nodeId, let oldPosition, _):
            // Undo node movement by restoring old position
            if let index = exploratoryCycle.nodes.firstIndex(where: { $0.id == nodeId }) {
                exploratoryCycle.nodes[index].position = oldPosition
            }

        case .moveMilestone(let milestoneId, let oldPosition, _):
            // Undo milestone movement by restoring old position
            if let index = exploratoryCycle.milestones.firstIndex(where: { $0.id == milestoneId }) {
                exploratoryCycle.milestones[index].position = oldPosition
            }
        }
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    // MARK: - Auto Layout

    func autoLayoutNodes() {
        // Temporarily disable undo recording during auto-layout
        isUndoing = true
        defer { isUndoing = false }

        let orderedMilestones = exploratoryCycle.getOrderedMilestones()

        for milestone in orderedMilestones {
            // Get all nodes linked to this milestone
            let linkedNodes = exploratoryCycle.nodes
                .filter { $0.milestoneId == milestone.id }
                .sorted { $0.sequenceNumber < $1.sequenceNumber }

            // Position nodes horizontally to the right of the milestone
            for (index, node) in linkedNodes.enumerated() {
                let nodePosition = CGPoint(
                    x: milestone.position.x + 350 + CGFloat(index) * 220,
                    y: milestone.position.y
                )
                moveNode(node.id, to: nodePosition)
            }
        }
    }

    func loadProject(_ project: Project) {
        currentProject = project
        selectedNodeId = nil
        // Clear undo stack when loading a new project
        undoStack.removeAll()
        autoLayoutNodes()
    }

    func createNewProject(name: String = "New Challenge") {
        let newProject = Project(name: name)
        currentProject = newProject
        saveCurrentProject()
    }

    func renameCurrentProject(_ newName: String) {
        currentProject.name = newName
        currentProject.modifiedDate = Date()
    }

    // MARK: - Import from CSV

    func importFromCSV(result: CSVImportResult) {
        // Clear existing nodes and milestones
        exploratoryCycle.nodes.removeAll()
        exploratoryCycle.milestones.removeAll()
        exploratoryCycle.connections.removeAll()

        // Clear undo stack when importing
        undoStack.removeAll()

        // Temporarily disable undo during import
        isUndoing = true
        defer { isUndoing = false }

        // Add imported milestones
        for milestone in result.milestones {
            exploratoryCycle.addMilestone(milestone)
        }

        // Add imported nodes
        for node in result.nodes {
            exploratoryCycle.addNode(node)
        }

        // Auto-layout nodes next to their milestones (isUndoing flag will be reset after this)
        isUndoing = false
        autoLayoutNodes()
        isUndoing = true

        // Deselect any selected nodes
        selectedNodeId = nil

        // Save the updated project
        saveCurrentProject()
    }

    // MARK: - Dummy Data Generation

    func populateWithDummyData() {
        // Clear existing data
        exploratoryCycle.nodes.removeAll()
        exploratoryCycle.milestones.removeAll()

        // Clear undo stack when populating dummy data
        undoStack.removeAll()

        // Temporarily disable undo during data population
        isUndoing = true
        defer { isUndoing = false }

        // Create milestones
        let milestonesData: [(title: String, phase: Phase?, description: String, criteria: String)] = [
            (
                "Apple Technology Goldenbell",
                .engage,
                "Learn about Apple's ecosystem and development tools",
                "Complete technology quiz with 80% accuracy"
            ),
            (
                "기술 선택",
                .engage,
                "Choose the appropriate technology stack for the project",
                "Document technology choices with justification"
            ),
            (
                "Challenge Statement / Team building",
                .engage,
                "Define the challenge and form development teams",
                "Written challenge statement and team roles defined"
            ),
            (
                "Deep understanding of technology",
                .investigate,
                "Gain comprehensive knowledge of chosen technologies",
                "Create technical documentation and proof of concept"
            ),
            (
                "Use Cases",
                .investigate,
                "Identify and document user scenarios",
                "Minimum 5 detailed use cases documented"
            ),
            (
                "Solution Concept",
                .investigate,
                "Design the solution architecture",
                "Architecture diagram and technical specification"
            ),
            (
                "Feature List",
                .act,
                "Define all features to be implemented",
                "Prioritized feature list with acceptance criteria"
            ),
            (
                "1st Sprint Review",
                .act,
                "Review progress of first development sprint",
                "Working demo of core features"
            ),
            (
                "2nd Sprint Review",
                .act,
                "Review progress of second development sprint",
                "Integration of major features completed"
            ),
            (
                "Final Review",
                .act,
                "Final project presentation and review",
                "Complete product demo and documentation"
            )
        ]

        var createdMilestones: [Milestone] = []
        for (index, data) in milestonesData.enumerated() {
            let milestone = Milestone(
                title: data.title,
                description: data.description,
                phase: data.phase,
                successCriteria: data.criteria,
                deliverable: "Deliverable for \(data.title)",
                artifacts: "Artifacts and evidence of completion",
                mentorGuidelines: "Mentors should guide learners through \(data.title.lowercased()) and provide feedback on their progress.",
                sequenceNumber: index,
                position: CGPoint(x: 200, y: 200 + CGFloat(index) * 300)
            )
            exploratoryCycle.addMilestone(milestone)
            createdMilestones.append(milestone)
        }

        // Create EC nodes
        let ecData: [(day: String, objective: String, milestone: Int, gq: String, ga: String)] = [
            ("Day 1", "오늘 러너들은 Apple 생태계의 기본 개념을 이해합니다", 0,
             "What makes Apple's ecosystem unique?",
             "Explore Xcode and create first Hello World app"),
            ("Day 2", "오늘 러너들은 Swift 프로그래밍의 기초를 배웁니다", 0,
             "How does Swift differ from other programming languages?",
             "Complete Swift playground exercises"),
            ("Day 3", "오늘 러너들은 개발 도구와 프레임워크를 선택합니다", 1,
             "Which frameworks best suit our project needs?",
             "Research and compare different Apple frameworks"),
            ("Day 4", "오늘 러너들은 팀을 구성하고 역할을 정의합니다", 2,
             "What are our team's strengths and how can we leverage them?",
             "Team building activities and role assignment"),
            ("Day 5", "오늘 러너들은 도전 과제를 명확히 정의합니다", 2,
             "What problem are we solving and for whom?",
             "Write challenge statement and user personas"),
            ("Day 6", "오늘 러너들은 선택한 기술에 대해 깊이 학습합니다", 3,
             "How do we implement core features using our chosen technology?",
             "Build technical prototypes and experiments"),
            ("Day 7", "오늘 러너들은 사용자 시나리오를 작성합니다", 4,
             "How will users interact with our solution?",
             "Create user journey maps and scenarios"),
            ("Day 8", "오늘 러너들은 솔루션 아키텍처를 설계합니다", 5,
             "How should we structure our application?",
             "Design system architecture and data flow"),
            ("Day 9", "오늘 러너들은 구현할 기능 목록을 작성합니다", 6,
             "What features are essential vs. nice-to-have?",
             "Create and prioritize product backlog"),
            ("Day 10", "오늘 러너들은 첫 번째 스프린트를 시작합니다", 7,
             "What can we achieve in this sprint?",
             "Sprint planning and task breakdown"),
            ("Day 11", "오늘 러너들은 코어 기능을 구현합니다", 7,
             "How do we ensure code quality?",
             "Implement features with unit tests"),
            ("Day 12", "오늘 러너들은 두 번째 스프린트를 진행합니다", 8,
             "How do we integrate different components?",
             "Feature integration and system testing"),
            ("Day 13", "오늘 러너들은 UI/UX를 개선합니다", 8,
             "How can we make the user experience better?",
             "User testing and interface refinement"),
            ("Day 14", "오늘 러너들은 최종 발표를 준비합니다", 9,
             "How do we effectively demonstrate our solution?",
             "Prepare presentation and demo"),
            ("Day 15", "오늘 러너들은 프로젝트를 마무리하고 회고합니다", 9,
             "What did we learn and how can we improve?",
             "Final review and retrospective")
        ]

        for (index, data) in ecData.enumerated() {
            let linkedMilestone = createdMilestones[data.milestone]
            let node = ECNode(
                position: CGPoint(x: 400 + CGFloat(index % 5) * 250, y: 300 + CGFloat(index / 5) * 200),
                sequenceNumber: index,
                day: data.day,
                learningObjective: data.objective,
                artifact: "Artifact for \(data.day)",
                mentorTasks: "Guide learners through activities and provide feedback",
                guidingQuestions: data.gq,
                guidingActivities: data.ga,
                findings: "Key discoveries and insights from today's activities",
                synthesis: "Summary of learning outcomes and connections to previous knowledge",
                duration: "90 minutes",
                milestoneId: linkedMilestone.id
            )
            exploratoryCycle.addNode(node)
        }

        // Auto-layout nodes next to their milestones
        autoLayoutNodes()

        // Deselect any selected nodes
        selectedNodeId = nil
        selectedMilestoneId = nil

        // Save the updated project
        saveCurrentProject()
    }
}
