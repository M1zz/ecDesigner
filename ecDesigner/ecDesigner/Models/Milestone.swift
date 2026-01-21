import Foundation
import SwiftUI

struct Milestone: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var phase: Phase?        // Engage, Investigate, or Act
    var successCriteria: String  // How to know if milestone is achieved
    var deliverable: String  // What will be delivered
    var artifacts: String    // Tangible outputs/artifacts
    var mentorGuidelines: String  // How mentors should support learners
    var sequenceNumber: Int  // Order in the challenge
    var position: CGPoint    // Position on canvas
    var isAchieved: Bool     // Whether this milestone has been achieved

    init(
        id: UUID = UUID(),
        title: String = "",
        description: String = "",
        phase: Phase? = nil,
        successCriteria: String = "",
        deliverable: String = "",
        artifacts: String = "",
        mentorGuidelines: String = "",
        sequenceNumber: Int = 0,
        position: CGPoint = CGPoint(x: 300, y: 200),
        isAchieved: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.phase = phase
        self.successCriteria = successCriteria
        self.deliverable = deliverable
        self.artifacts = artifacts
        self.mentorGuidelines = mentorGuidelines
        self.sequenceNumber = sequenceNumber
        self.position = position
        self.isAchieved = isAchieved
    }

    static func == (lhs: Milestone, rhs: Milestone) -> Bool {
        lhs.id == rhs.id
    }
}
