import Foundation

struct ExploratoryCycle: Identifiable, Codable {
    let id: UUID
    var name: String
    var milestones: [Milestone]
    var nodes: [ECNode]
    var connections: [NodeConnection]
    var createdDate: Date
    var modifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String = "New Exploratory Cycle",
        milestones: [Milestone] = [],
        nodes: [ECNode] = [],
        connections: [NodeConnection] = [],
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.milestones = milestones
        self.nodes = nodes
        self.connections = connections
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }

    mutating func addNode(_ node: ECNode) {
        nodes.append(node)
        modifiedDate = Date()
    }

    mutating func updateNode(_ node: ECNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
            modifiedDate = Date()
        }
    }

    mutating func removeNode(_ nodeId: UUID) {
        nodes.removeAll { $0.id == nodeId }
        connections.removeAll { $0.fromNodeId == nodeId || $0.toNodeId == nodeId }
        modifiedDate = Date()
    }

    mutating func addConnection(from: UUID, to: UUID, fromDirection: AnchorDirection, toDirection: AnchorDirection) {
        let connection = NodeConnection(
            fromNodeId: from,
            toNodeId: to,
            fromDirection: fromDirection,
            toDirection: toDirection
        )
        connections.append(connection)
        modifiedDate = Date()
    }

    mutating func removeConnection(_ connectionId: UUID) {
        connections.removeAll { $0.id == connectionId }
        modifiedDate = Date()
    }

    func getOrderedNodes() -> [ECNode] {
        return nodes.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }

    // Milestone management
    mutating func addMilestone(_ milestone: Milestone) {
        milestones.append(milestone)
        modifiedDate = Date()
    }

    mutating func updateMilestone(_ milestone: Milestone) {
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index] = milestone
            modifiedDate = Date()
        }
    }

    mutating func removeMilestone(_ milestoneId: UUID) {
        milestones.removeAll { $0.id == milestoneId }
        modifiedDate = Date()
    }

    func getOrderedMilestones() -> [Milestone] {
        return milestones.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }
}
