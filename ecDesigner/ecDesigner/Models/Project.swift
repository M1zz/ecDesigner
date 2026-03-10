import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var roleInLearningJourney: String
    var targetLearners: String
    var duration: String
    var overallSuccessCriteria: String
    var workingDays: Int?
    var holidays: [Date]
    var participationModel: ParticipationModel?
    var startDate: Date?
    var endDate: Date?
    var challengeType: String?
    var regulationModel: String?
    var exploratoryCycle: ExploratoryCycle
    var createdDate: Date
    var modifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String = "New Challenge",
        roleInLearningJourney: String = "",
        targetLearners: String = "",
        duration: String = "",
        overallSuccessCriteria: String = "",
        workingDays: Int? = nil,
        holidays: [Date] = [],
        participationModel: ParticipationModel? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        challengeType: String? = nil,
        regulationModel: String? = nil,
        exploratoryCycle: ExploratoryCycle = ExploratoryCycle(),
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.roleInLearningJourney = roleInLearningJourney
        self.targetLearners = targetLearners
        self.duration = duration
        self.overallSuccessCriteria = overallSuccessCriteria
        self.workingDays = workingDays
        self.holidays = holidays
        self.participationModel = participationModel
        self.startDate = startDate
        self.endDate = endDate
        self.challengeType = challengeType
        self.regulationModel = regulationModel
        self.exploratoryCycle = exploratoryCycle
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }

    // MARK: - Codable migration
    // Handles backward compatibility when model fields are renamed or added

    enum CodingKeys: String, CodingKey {
        case id, name, targetLearners, duration, overallSuccessCriteria
        case roleInLearningJourney
        case workingDays, holidays, participationModel, startDate, endDate
        case challengeType, regulationModel
        case exploratoryCycle, createdDate, modifiedDate
        // Legacy keys (old field names)
        case challengeStatement   // was renamed to roleInLearningJourney
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id                   = try c.decode(UUID.self, forKey: .id)
        name                 = try c.decodeIfPresent(String.self, forKey: .name) ?? "New Challenge"
        targetLearners       = try c.decodeIfPresent(String.self, forKey: .targetLearners) ?? ""
        duration             = try c.decodeIfPresent(String.self, forKey: .duration) ?? ""
        overallSuccessCriteria = try c.decodeIfPresent(String.self, forKey: .overallSuccessCriteria) ?? ""
        workingDays          = try c.decodeIfPresent(Int.self, forKey: .workingDays)
        holidays             = try c.decodeIfPresent([Date].self, forKey: .holidays) ?? []
        participationModel   = try c.decodeIfPresent(ParticipationModel.self, forKey: .participationModel)
        startDate            = try c.decodeIfPresent(Date.self, forKey: .startDate)
        endDate              = try c.decodeIfPresent(Date.self, forKey: .endDate)
        challengeType        = try c.decodeIfPresent(String.self, forKey: .challengeType)
        regulationModel      = try c.decodeIfPresent(String.self, forKey: .regulationModel)
        exploratoryCycle     = try c.decodeIfPresent(ExploratoryCycle.self, forKey: .exploratoryCycle) ?? ExploratoryCycle()
        createdDate          = try c.decodeIfPresent(Date.self, forKey: .createdDate) ?? Date()
        modifiedDate         = try c.decodeIfPresent(Date.self, forKey: .modifiedDate) ?? Date()

        // Migration: roleInLearningJourney was previously challengeStatement
        if let newValue = try c.decodeIfPresent(String.self, forKey: .roleInLearningJourney) {
            roleInLearningJourney = newValue
        } else if let legacyValue = try c.decodeIfPresent(String.self, forKey: .challengeStatement) {
            roleInLearningJourney = legacyValue
        } else {
            roleInLearningJourney = ""
        }
        // Note: challengeDescription (old field) is intentionally ignored during decode
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(roleInLearningJourney, forKey: .roleInLearningJourney)
        try c.encode(targetLearners, forKey: .targetLearners)
        try c.encode(duration, forKey: .duration)
        try c.encode(overallSuccessCriteria, forKey: .overallSuccessCriteria)
        try c.encodeIfPresent(workingDays, forKey: .workingDays)
        try c.encode(holidays, forKey: .holidays)
        try c.encodeIfPresent(participationModel, forKey: .participationModel)
        try c.encodeIfPresent(startDate, forKey: .startDate)
        try c.encodeIfPresent(endDate, forKey: .endDate)
        try c.encodeIfPresent(challengeType, forKey: .challengeType)
        try c.encodeIfPresent(regulationModel, forKey: .regulationModel)
        try c.encode(exploratoryCycle, forKey: .exploratoryCycle)
        try c.encode(createdDate, forKey: .createdDate)
        try c.encode(modifiedDate, forKey: .modifiedDate)
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}
