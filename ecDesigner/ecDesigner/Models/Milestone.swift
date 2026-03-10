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
    var duration: String         // e.g. "Week 1–2", "Day 1–5"
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
        duration: String = "",
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
        self.duration = duration
        self.sequenceNumber = sequenceNumber
        self.position = position
        self.isAchieved = isAchieved
    }

    // MARK: - Codable migration
    // Custom decoder so new fields default gracefully when loading old saved data

    enum CodingKeys: String, CodingKey {
        case id, title, description, phase, successCriteria, deliverable
        case artifacts, mentorGuidelines, duration
        case sequenceNumber, position, isAchieved
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self, forKey: .id)
        title            = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        description      = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        phase            = try c.decodeIfPresent(Phase.self, forKey: .phase)
        successCriteria  = try c.decodeIfPresent(String.self, forKey: .successCriteria) ?? ""
        deliverable      = try c.decodeIfPresent(String.self, forKey: .deliverable) ?? ""
        artifacts        = try c.decodeIfPresent(String.self, forKey: .artifacts) ?? ""
        mentorGuidelines = try c.decodeIfPresent(String.self, forKey: .mentorGuidelines) ?? ""
        duration         = try c.decodeIfPresent(String.self, forKey: .duration) ?? ""
        sequenceNumber   = try c.decodeIfPresent(Int.self, forKey: .sequenceNumber) ?? 0
        position         = try c.decodeIfPresent(CGPoint.self, forKey: .position) ?? CGPoint(x: 300, y: 200)
        isAchieved       = try c.decodeIfPresent(Bool.self, forKey: .isAchieved) ?? false
    }

    static func == (lhs: Milestone, rhs: Milestone) -> Bool {
        lhs.id == rhs.id
    }
}
