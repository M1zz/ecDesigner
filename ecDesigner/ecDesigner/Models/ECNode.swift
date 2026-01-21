import Foundation
import SwiftUI

struct ECNode: Identifiable, Codable, Equatable {
    let id: UUID
    var position: CGPoint
    var sequenceNumber: Int

    // 커리큘럼 구조 필드
    var day: String  // Day number or date (e.g., "Day 1", "Week 2")
    var learningObjective: String  // "오늘 러너들은..." - What learners will achieve
    var artifact: String  // Specific deliverable/output for this EC
    var mentorTasks: String  // What mentors need to do for this EC

    // Exploratory Cycle 필수 구성 요소 (순서대로)
    // 1. Guiding Questions (What needs to be learned?)
    var guidingQuestions: String
    // 2. Guiding Activities/Resources (How will we learn it?)
    var guidingActivities: String
    // 3. Findings (What did we learn?)
    var findings: String
    // 4. Synthesis (Did we learn enough to address the milestone?)
    var synthesis: String

    // EC 메타데이터
    var duration: String  // "It Depends - as long as necessary and laser-focused"
    var milestoneId: UUID?  // Reference to target Milestone

    // EC 전환 (If milestone not achieved, go to next EC)
    var nextECId: UUID?  // Next EC to try if this EC doesn't achieve the milestone

    // UI state - remember last selected tab
    var lastSelectedTab: String?  // Store the last selected tab when editing

    init(
        id: UUID = UUID(),
        position: CGPoint = .zero,
        sequenceNumber: Int = 0,
        day: String = "",
        learningObjective: String = "",
        artifact: String = "",
        mentorTasks: String = "",
        guidingQuestions: String = "",
        guidingActivities: String = "",
        findings: String = "",
        synthesis: String = "",
        duration: String = "",
        milestoneId: UUID? = nil,
        nextECId: UUID? = nil,
        lastSelectedTab: String? = nil
    ) {
        self.id = id
        self.position = position
        self.sequenceNumber = sequenceNumber
        self.day = day
        self.learningObjective = learningObjective
        self.artifact = artifact
        self.mentorTasks = mentorTasks
        self.guidingQuestions = guidingQuestions
        self.guidingActivities = guidingActivities
        self.findings = findings
        self.synthesis = synthesis
        self.duration = duration
        self.milestoneId = milestoneId
        self.nextECId = nextECId
        self.lastSelectedTab = lastSelectedTab
    }

    static func == (lhs: ECNode, rhs: ECNode) -> Bool {
        lhs.id == rhs.id
    }
}

enum AnchorDirection: String, Codable {
    case top, bottom, left, right

    var offset: CGSize {
        switch self {
        case .top: return CGSize(width: 0, height: -50)
        case .bottom: return CGSize(width: 0, height: 50)
        case .left: return CGSize(width: -50, height: 0)
        case .right: return CGSize(width: 50, height: 0)
        }
    }
}

struct NodeConnection: Identifiable, Codable {
    let id: UUID
    let fromNodeId: UUID
    let toNodeId: UUID
    let fromDirection: AnchorDirection
    let toDirection: AnchorDirection

    init(
        id: UUID = UUID(),
        fromNodeId: UUID,
        toNodeId: UUID,
        fromDirection: AnchorDirection,
        toDirection: AnchorDirection
    ) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.fromDirection = fromDirection
        self.toDirection = toDirection
    }
}
