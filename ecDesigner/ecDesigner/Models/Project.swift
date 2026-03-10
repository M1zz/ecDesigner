import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var roleInLearningJourney: String
    var targetLearners: String      // kept for backward compat, no longer shown in UI
    var duration: String
    var overallSuccessCriteria: String
    var workingDays: Int?
    var holidays: [Date]
    var participationModel: ParticipationModel?
    var startDate: Date?
    var endDate: Date?
    var challengeType: String?
    var regulationModel: String?
    // Mentoring
    var mentoringOrganization: String?      // "oneMentor" | "twoMentors" | "other"
    var mentoringOrganizationTeamCount: String?   // fill-in for oneMentor option
    var mentoringOrganizationOther: String?       // explanation for other option
    var mentoringFocus: [String]            // selected focus area IDs
    var mentoringFocusOther: String?        // free text for Other/Notes
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
        mentoringOrganization: String? = nil,
        mentoringOrganizationTeamCount: String? = nil,
        mentoringOrganizationOther: String? = nil,
        mentoringFocus: [String] = [],
        mentoringFocusOther: String? = nil,
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
        self.mentoringOrganization = mentoringOrganization
        self.mentoringOrganizationTeamCount = mentoringOrganizationTeamCount
        self.mentoringOrganizationOther = mentoringOrganizationOther
        self.mentoringFocus = mentoringFocus
        self.mentoringFocusOther = mentoringFocusOther
        self.exploratoryCycle = exploratoryCycle
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }

    // MARK: - Codable migration

    enum CodingKeys: String, CodingKey {
        case id, name, targetLearners, duration, overallSuccessCriteria
        case roleInLearningJourney
        case workingDays, holidays, participationModel, startDate, endDate
        case challengeType, regulationModel
        case mentoringOrganization, mentoringOrganizationTeamCount, mentoringOrganizationOther
        case mentoringFocus, mentoringFocusOther
        case exploratoryCycle, createdDate, modifiedDate
        // Legacy keys
        case challengeStatement
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
        mentoringOrganization          = try c.decodeIfPresent(String.self, forKey: .mentoringOrganization)
        mentoringOrganizationTeamCount = try c.decodeIfPresent(String.self, forKey: .mentoringOrganizationTeamCount)
        mentoringOrganizationOther     = try c.decodeIfPresent(String.self, forKey: .mentoringOrganizationOther)
        mentoringFocus       = try c.decodeIfPresent([String].self, forKey: .mentoringFocus) ?? []
        mentoringFocusOther  = try c.decodeIfPresent(String.self, forKey: .mentoringFocusOther)
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
        try c.encodeIfPresent(mentoringOrganization, forKey: .mentoringOrganization)
        try c.encodeIfPresent(mentoringOrganizationTeamCount, forKey: .mentoringOrganizationTeamCount)
        try c.encodeIfPresent(mentoringOrganizationOther, forKey: .mentoringOrganizationOther)
        try c.encode(mentoringFocus, forKey: .mentoringFocus)
        try c.encodeIfPresent(mentoringFocusOther, forKey: .mentoringFocusOther)
        try c.encode(exploratoryCycle, forKey: .exploratoryCycle)
        try c.encode(createdDate, forKey: .createdDate)
        try c.encode(modifiedDate, forKey: .modifiedDate)
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}
