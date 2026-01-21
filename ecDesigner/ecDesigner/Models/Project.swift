import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var challengeStatement: String
    var challengeDescription: String
    var targetLearners: String
    var duration: String
    var overallSuccessCriteria: String
    var exploratoryCycle: ExploratoryCycle
    var createdDate: Date
    var modifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String = "New Challenge",
        challengeStatement: String = "",
        challengeDescription: String = "",
        targetLearners: String = "",
        duration: String = "",
        overallSuccessCriteria: String = "",
        exploratoryCycle: ExploratoryCycle = ExploratoryCycle(),
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.challengeStatement = challengeStatement
        self.challengeDescription = challengeDescription
        self.targetLearners = targetLearners
        self.duration = duration
        self.overallSuccessCriteria = overallSuccessCriteria
        self.exploratoryCycle = exploratoryCycle
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}
