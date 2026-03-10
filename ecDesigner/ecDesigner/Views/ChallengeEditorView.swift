import SwiftUI

private struct ChallengeField {
    let id: String
    let label: String
    let icon: String
    let iconColor: Color
}

// "workingDays" is embedded inside "dates" (auto-calculated). "targetLearners" removed from UI.
private let allChallengeFields: [ChallengeField] = [
    ChallengeField(id: "name",                   label: "Challenge Name",               icon: "star.fill",           iconColor: .blue),
    ChallengeField(id: "dates",                  label: "Start & End Dates",            icon: "calendar",            iconColor: .orange),
    ChallengeField(id: "challengeType",          label: "Challenge Type",               icon: "tag.fill",            iconColor: .indigo),
    ChallengeField(id: "participationModel",     label: "Model of Participation",       icon: "person.2.fill",       iconColor: .purple),
    ChallengeField(id: "regulationModel",        label: "Regulation Model",             icon: "dial.medium.fill",    iconColor: .teal),
    ChallengeField(id: "roleInLearningJourney",  label: "Role in the Learning Journey", icon: "map.fill",            iconColor: .yellow),
    ChallengeField(id: "mentoring",              label: "Mentoring",                    icon: "person.fill.badge.plus", iconColor: .purple),
    ChallengeField(id: "ecs",                    label: "Expectations, Constraints & Stakes", icon: "exclamationmark.triangle.fill", iconColor: .red),
    ChallengeField(id: "overallSuccessCriteria", label: "Overall Success Criteria",     icon: "checkmark.seal.fill", iconColor: .green),
]

private let mentoringFocusOptions: [(id: String, label: String)] = [
    ("groupDynamics",    "Group dynamics and decision making"),
    ("coreKnowledge",    "Learning Core knowledge and skills"),
    ("challengeProcess", "The Challenge process and CBL"),
    ("depthOfLearning",  "The depth and quality of learning"),
    ("industryProcess",  "The use of specific industry processes (E.G., Agile)"),
    ("productQuality",   "The quality and viability of the Product"),
]

private let challengeTypeOptions: [(value: String, description: String)] = [
    ("Skills Focused",      "Primarily focused on learning skills, including core and path-focused elective objectives."),
    ("Exploration Focused", "Focused on filling learning gaps, increasing employability potential, testing ideas, and exploring interests."),
    ("App Focused",         "Emphasis is on creating a viable app while learning."),
]

private let regulationModelOptions: [(value: String, description: String)] = [
    ("Senior Learner Regulated",             "Early in the Academy, tighter boundaries to support junior learner integration. Senior learners provide the Engage phase; junior learners begin with Investigation."),
    ("Senior & Junior Learner Co-Regulated", "Learners work together on planning and implementation. Senior learners model process and decision making throughout."),
    ("Junior Learner Regulated",             "Junior learners take responsibility for content and structure, ranging from their own Big Idea to managing the entire Challenge."),
    ("Learner Regulated",                    "Senior learners join junior learners as peers to plan and implement the Challenge."),
]

enum ChallengeEditorTab { case overview, milestones }

struct ChallengeEditorView: View {
    @Binding var project: Project
    let fontScale: CGFloat
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var selectedTab: ChallengeEditorTab = .overview
    @State private var showCancelConfirmation = false
    @State private var initialProject: Project?
    @State private var addedFields: Set<String> = []

    // Holiday picker state
    @State private var showHolidayPicker: Bool = false
    @State private var newHolidayDate: Date = Date()

    private var hasChanges: Bool {
        guard let initial = initialProject else { return false }
        return project.name != initial.name ||
               project.roleInLearningJourney != initial.roleInLearningJourney ||
               project.overallSuccessCriteria != initial.overallSuccessCriteria ||
               project.workingDays != initial.workingDays ||
               project.holidays != initial.holidays ||
               project.participationModel != initial.participationModel ||
               project.startDate != initial.startDate ||
               project.endDate != initial.endDate ||
               project.challengeType != initial.challengeType ||
               project.regulationModel != initial.regulationModel ||
               project.mentoringOrganization != initial.mentoringOrganization ||
               project.mentoringOrganizationTeamCount != initial.mentoringOrganizationTeamCount ||
               project.mentoringOrganizationOther != initial.mentoringOrganizationOther ||
               project.mentoringFocus != initial.mentoringFocus ||
               project.mentoringFocusOther != initial.mentoringFocusOther ||
               project.expectations != initial.expectations ||
               project.constraints != initial.constraints ||
               project.stakes != initial.stakes
    }

    private var visibleFields: [ChallengeField] {
        allChallengeFields.filter { addedFields.contains($0.id) }
    }

    private var remainingFields: [ChallengeField] {
        allChallengeFields.filter { !addedFields.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Challenge")
                        .font(.system(size: 20 * fontScale, weight: .bold))
                    if selectedTab == .overview {
                        Text("\(visibleFields.count) / \(allChallengeFields.count) fields filled")
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()

            // 탭 바
            HStack(spacing: 0) {
                tabButton("Overview", tab: .overview, icon: "doc.text.fill")
                tabButton("Milestones", tab: .milestones, icon: "flag.fill",
                          badge: project.exploratoryCycle.milestones.count)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if selectedTab == .overview {
                        overviewContent
                    } else {
                        milestonesContent
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    if hasChanges { showCancelConfirmation = true } else { onCancel() }
                }
                .buttonStyle(.bordered)

                Button("Save") { onSave() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasChanges)
            }
            .padding()
        }
        .frame(width: 580, height: 720)
        .onAppear {
            initialProject = project
            if !project.name.isEmpty                    { addedFields.insert("name") }
            if project.startDate != nil || project.endDate != nil { addedFields.insert("dates") }
            if project.challengeType != nil             { addedFields.insert("challengeType") }
            if project.participationModel != nil        { addedFields.insert("participationModel") }
            if project.regulationModel != nil           { addedFields.insert("regulationModel") }
            if !project.roleInLearningJourney.isEmpty   { addedFields.insert("roleInLearningJourney") }
            if project.mentoringOrganization != nil || !project.mentoringFocus.isEmpty {
                addedFields.insert("mentoring")
            }
            if !project.expectations.isEmpty || !project.constraints.isEmpty || !project.stakes.isEmpty {
                addedFields.insert("ecs")
            }
            if !project.overallSuccessCriteria.isEmpty  { addedFields.insert("overallSuccessCriteria") }
        }
        .alert("Unsaved Changes", isPresented: $showCancelConfirmation) {
            Button("Don't Save", role: .destructive) { onCancel() }
            Button("Cancel", role: .cancel) { }
            Button("Save") { onSave() }
        } message: {
            Text("Do you want to save your changes to this Challenge?")
        }
    }

    // MARK: - 탭 버튼

    @ViewBuilder
    private func tabButton(_ label: String, tab: ChallengeEditorTab, icon: String, badge: Int? = nil) -> some View {
        let isSelected = selectedTab == tab
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12 * fontScale))
                Text(label)
                    .font(.system(size: 13 * fontScale, weight: .semibold))
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11 * fontScale, weight: .bold))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.15)))
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Overview 탭

    @ViewBuilder
    private var overviewContent: some View {
        ForEach(visibleFields, id: \.id) { field in
            fieldView(for: field)
        }
        addFieldSection
    }

    // MARK: - Milestones 탭 (Timeline View)

    @ViewBuilder
    private var milestonesContent: some View {
        let milestones = project.exploratoryCycle.milestones
            .sorted { $0.sequenceNumber < $1.sequenceNumber }
        let nodes = project.exploratoryCycle.nodes

        if milestones.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "flag.slash")
                    .font(.system(size: 36 * fontScale))
                    .foregroundColor(.secondary.opacity(0.4))
                Text("No milestones yet")
                    .font(.system(size: 15 * fontScale, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Add milestones on the canvas to see them here")
                    .font(.system(size: 12 * fontScale))
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            // Working days summary bar
            if let start = project.startDate, let end = project.endDate {
                workingDaysSummaryBar(start: start, end: end)
            }

            // Timeline
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(milestones.enumerated()), id: \.element.id) { idx, milestone in
                    let ecCount = nodes.filter { $0.milestoneId == milestone.id }.count
                    let isLast = idx == milestones.count - 1
                    timelineRow(milestone: milestone, ecCount: ecCount, isLast: isLast)
                }
            }
        }
    }

    @ViewBuilder
    private func workingDaysSummaryBar(start: Date, end: Date) -> some View {
        let totalWeekdays = calculateWeekdays(from: start, to: end)
        let effectiveHolidays = countEffectiveHolidays(start: start, end: end)
        let workingDays = totalWeekdays - effectiveHolidays
        let hasGapMilestones = project.exploratoryCycle.milestones.contains { $0.duration.isEmpty }

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(workingDays)")
                            .font(.system(size: 22 * fontScale, weight: .bold))
                            .foregroundColor(.orange)
                        Text("working days")
                            .font(.system(size: 13 * fontScale))
                            .foregroundColor(.secondary)
                    }
                    Text("\(formatShortDate(start)) – \(formatShortDate(end))")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if effectiveHolidays > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(totalWeekdays) weekdays")
                            .font(.system(size: 11 * fontScale))
                            .foregroundColor(.secondary)
                        Text("− \(effectiveHolidays) holidays")
                            .font(.system(size: 11 * fontScale))
                            .foregroundColor(.orange)
                    }
                }
            }

            if hasGapMilestones {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11 * fontScale))
                    Text("Some milestones are missing a period")
                        .font(.system(size: 11 * fontScale, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.15), lineWidth: 1))
        )
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func timelineRow(milestone: Milestone, ecCount: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: dot + connecting line
            VStack(spacing: 0) {
                Circle()
                    .fill(milestone.phase?.color ?? Color.gray)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color(NSColor.windowBackgroundColor), lineWidth: 2))
                    .shadow(color: (milestone.phase?.color ?? Color.gray).opacity(0.4), radius: 3)
                    .padding(.top, 18)

                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, 4)
                }
            }
            .frame(width: 28)

            // Right: card
            timelineMilestoneCard(milestone: milestone, ecCount: ecCount)
                .padding(.leading, 10)
                .padding(.bottom, isLast ? 4 : 20)
        }
    }

    @ViewBuilder
    private func timelineMilestoneCard(milestone: Milestone, ecCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Phase bar accent at top
            if let phase = milestone.phase {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(phase.color)
                        .frame(width: 3, height: 14)
                    Text(phase.rawValue.uppercased())
                        .font(.system(size: 9 * fontScale, weight: .bold))
                        .foregroundColor(phase.color)
                        .padding(.leading, 6)
                    Spacer()
                    if milestone.isAchieved {
                        Label("Achieved", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 10 * fontScale, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }

            // Title + sequence
            HStack(alignment: .top, spacing: 8) {
                Text("#\(milestone.sequenceNumber + 1)")
                    .font(.system(size: 11 * fontScale, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(milestone.phase?.color ?? Color.gray))

                Text(milestone.title.isEmpty ? "Untitled" : milestone.title)
                    .font(.system(size: 14 * fontScale, weight: .semibold))
                    .foregroundColor(milestone.title.isEmpty ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Duration + EC count
            HStack(spacing: 14) {
                if !milestone.duration.isEmpty {
                    Label(milestone.duration, systemImage: "calendar")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary)
                } else {
                    Label("Period not set", systemImage: "calendar.badge.exclamationmark")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.orange)
                }

                Label("\(ecCount) EC\(ecCount == 1 ? "" : "s")", systemImage: "circle.hexagongrid.fill")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(milestone.phase?.color.opacity(0.2) ?? Color.gray.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - 필드 추가 영역

    @ViewBuilder
    private var addFieldSection: some View {
        if !remainingFields.isEmpty {
            VStack(spacing: 8) {
                if !addedFields.isEmpty {
                    Divider().padding(.vertical, 4)
                }
                ForEach(remainingFields, id: \.id) { field in
                    Button(action: { addedFields.insert(field.id) }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(field.iconColor.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: field.icon)
                                    .font(.system(size: 15 * fontScale))
                                    .foregroundColor(field.iconColor)
                            }
                            Text(field.label)
                                .font(.system(size: 14 * fontScale, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 14 * fontScale, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 개별 필드 뷰

    @ViewBuilder
    private func fieldView(for field: ChallengeField) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: field.icon)
                    .font(.system(size: 13 * fontScale))
                    .foregroundColor(field.iconColor)
                    .frame(width: 18)
                Text(field.label)
                    .font(.system(size: 13 * fontScale, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { removeField(field.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            fieldEditor(for: field)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(field.iconColor.opacity(0.15), lineWidth: 1))
        )
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: addedFields)
    }

    @ViewBuilder
    private func fieldEditor(for field: ChallengeField) -> some View {
        switch field.id {
        case "name":
            TextField("Enter challenge name", text: $project.name)
                .font(.system(size: 14 * fontScale))
                .textFieldStyle(.roundedBorder)

        case "dates":
            datesEditor

        case "challengeType":
            optionSelector(options: challengeTypeOptions, selected: $project.challengeType, accentColor: .indigo)

        case "participationModel":
            participationModelEditor

        case "regulationModel":
            optionSelector(options: regulationModelOptions, selected: $project.regulationModel, accentColor: .teal)

        case "roleInLearningJourney":
            VStack(alignment: .leading, spacing: 6) {
                Text("Describe how this Challenge builds on the previous experience and leads to the next. I.E., Why are we doing this Challenge and why are we doing it now?")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                TextEditor(text: $project.roleInLearningJourney)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 80)
                    .border(Color.yellow.opacity(0.3), width: 1)
            }

        case "mentoring":
            mentoringEditor

        case "ecs":
            ecsEditor

        case "overallSuccessCriteria":
            VStack(alignment: .leading, spacing: 6) {
                Text("The parameters for successfully completing the Challenge. Describe what learners should know and be able to do by the end of the Challenge.")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                TextEditor(text: $project.overallSuccessCriteria)
                    .font(.system(size: 14 * fontScale))
                    .frame(minHeight: 80)
                    .border(Color.green.opacity(0.2), width: 1)
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Dates + Working Days Editor

    private var datesEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Start / End date pickers
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.system(size: 11 * fontScale, weight: .medium))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: Binding(
                        get: { project.startDate ?? Date() },
                        set: { project.startDate = $0; recalculateWorkingDays() }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13 * fontScale))

                VStack(alignment: .leading, spacing: 4) {
                    Text("End")
                        .font(.system(size: 11 * fontScale, weight: .medium))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: Binding(
                        get: { project.endDate ?? Date() },
                        set: { project.endDate = $0; recalculateWorkingDays() }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
                Spacer()
            }

            // Auto-calculated working days (shown when both dates are set)
            if let start = project.startDate, let end = project.endDate, start <= end {
                Divider()

                let totalWeekdays = calculateWeekdays(from: start, to: end)
                let effectiveHolidays = countEffectiveHolidays(start: start, end: end)
                let workDays = totalWeekdays - effectiveHolidays

                HStack(spacing: 12) {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18 * fontScale))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(workDays)")
                                .font(.system(size: 20 * fontScale, weight: .bold))
                                .foregroundColor(.orange)
                            Text("working days")
                                .font(.system(size: 13 * fontScale))
                                .foregroundColor(.secondary)
                        }
                        if effectiveHolidays > 0 {
                            Text("\(totalWeekdays) weekdays  −  \(effectiveHolidays) public holidays")
                                .font(.system(size: 11 * fontScale))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Mon – Fri only, weekends excluded")
                                .font(.system(size: 11 * fontScale))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }

                // Holidays section
                holidaysSection(start: start, end: end)
            }
        }
    }

    @ViewBuilder
    private func holidaysSection(start: Date, end: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Public Holidays")
                    .font(.system(size: 12 * fontScale, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showHolidayPicker.toggle() }) {
                    Label("Add Holiday", systemImage: showHolidayPicker ? "xmark" : "plus")
                        .font(.system(size: 11 * fontScale))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if showHolidayPicker {
                HStack(spacing: 8) {
                    DatePicker("", selection: $newHolidayDate,
                               in: start...end,
                               displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)

                    Button("Add") {
                        let day = Calendar.current.startOfDay(for: newHolidayDate)
                        if !project.holidays.contains(where: {
                            Calendar.current.isDate($0, inSameDayAs: day)
                        }) {
                            project.holidays.append(day)
                            project.holidays.sort()
                        }
                        showHolidayPicker = false
                        recalculateWorkingDays()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Cancel") { showHolidayPicker = false }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                )
            }

            if !project.holidays.isEmpty {
                let sortedHolidays = project.holidays.sorted()
                ForEach(sortedHolidays, id: \.self) { holiday in
                    let cal = Calendar.current
                    let weekday = cal.component(.weekday, from: holiday)
                    let isWeekend = weekday == 1 || weekday == 7
                    let inRange = cal.startOfDay(for: holiday) >= cal.startOfDay(for: start) &&
                                  cal.startOfDay(for: holiday) <= cal.startOfDay(for: end)

                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.minus")
                            .foregroundColor(isWeekend ? .secondary : .orange)
                            .font(.system(size: 12 * fontScale))

                        Text(formatHolidayDate(holiday))
                            .font(.system(size: 12 * fontScale))
                            .foregroundColor(isWeekend ? .secondary : .primary)

                        if isWeekend {
                            Text("(weekend – not counted)")
                                .font(.system(size: 10 * fontScale))
                                .foregroundColor(.secondary)
                        } else if !inRange {
                            Text("(outside range)")
                                .font(.system(size: 10 * fontScale))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            project.holidays.removeAll {
                                Calendar.current.isDate($0, inSameDayAs: holiday)
                            }
                            recalculateWorkingDays()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary.opacity(0.5))
                                .font(.system(size: 14 * fontScale))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        )
    }

    private var participationModelEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(ParticipationModel.allCases, id: \.self) { model in
                let isSelected = project.participationModel == model
                Button(action: { project.participationModel = model }) {
                    HStack(spacing: 10) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16 * fontScale))
                            .foregroundColor(isSelected ? .purple : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.rawValue)
                                .font(.system(size: 13 * fontScale, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(model.description)
                                .font(.system(size: 11 * fontScale))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(optionBackground(isSelected: isSelected, accentColor: .purple))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Mentoring Editor

    @ViewBuilder
    private var mentoringEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Describe the structure and focus of the mentoring during the Challenge.")
                .font(.system(size: 11 * fontScale))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Mentoring Organization
            VStack(alignment: .leading, spacing: 8) {
                Text("Mentoring Organization")
                    .font(.system(size: 12 * fontScale, weight: .semibold))
                    .foregroundColor(.primary)
                Text("How will the teams be supported?")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)

                mentoringOrgRow(
                    key: "oneMentor",
                    label: "One Mentor per group",
                    accentColor: .purple
                )
                mentoringOrgRow(
                    key: "twoMentors",
                    label: "2 Mentors per group. Each mentor group will have 2–3 teams.",
                    accentColor: .purple
                )
                mentoringOrgRow(
                    key: "other",
                    label: "Other – please explain.",
                    accentColor: .purple
                )
            }

            Divider()

            // Mentoring Focus
            VStack(alignment: .leading, spacing: 8) {
                Text("Mentoring Focus")
                    .font(.system(size: 12 * fontScale, weight: .semibold))
                    .foregroundColor(.primary)
                Text("What will the mentors' primary focus during this Challenge?")
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)

                ForEach(mentoringFocusOptions, id: \.id) { option in
                    mentoringFocusRow(option: option)
                }

                // Other / Notes
                let hasOther = project.mentoringFocus.contains("other")
                Button(action: {
                    if hasOther {
                        project.mentoringFocus.removeAll { $0 == "other" }
                        project.mentoringFocusOther = nil
                    } else {
                        project.mentoringFocus.append("other")
                    }
                }) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: hasOther ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16 * fontScale))
                            .foregroundColor(hasOther ? .purple : .secondary)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Other / Notes")
                                .font(.system(size: 13 * fontScale, weight: .semibold))
                                .foregroundColor(.primary)
                            if hasOther {
                                TextField("Add notes...", text: Binding(
                                    get: { project.mentoringFocusOther ?? "" },
                                    set: { project.mentoringFocusOther = $0.isEmpty ? nil : $0 }
                                ))
                                .font(.system(size: 13 * fontScale))
                                .textFieldStyle(.roundedBorder)
                                .onTapGesture { } // prevent button swallow
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(mentoringOptionBg(isSelected: hasOther))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func mentoringOrgRow(key: String, label: String, accentColor: Color) -> some View {
        let isSelected = project.mentoringOrganization == key
        Button(action: { project.mentoringOrganization = isSelected ? nil : key }) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16 * fontScale))
                    .foregroundColor(isSelected ? accentColor : .secondary)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 6) {
                    if key == "oneMentor" {
                        // Inline fill-in field for team count
                        HStack(spacing: 4) {
                            Text("One Mentor per group. Each mentor will have")
                                .font(.system(size: 13 * fontScale, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(.primary)
                            TextField("N", text: Binding(
                                get: { project.mentoringOrganizationTeamCount ?? "" },
                                set: { project.mentoringOrganizationTeamCount = $0.isEmpty ? nil : $0 }
                            ))
                            .font(.system(size: 13 * fontScale, weight: .semibold))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 40)
                            .onTapGesture {
                                if !isSelected { project.mentoringOrganization = key }
                            }
                            Text("teams.")
                                .font(.system(size: 13 * fontScale, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(.primary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    } else if key == "other" {
                        Text(label)
                            .font(.system(size: 13 * fontScale, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(.primary)
                        if isSelected {
                            TextField("Please explain...", text: Binding(
                                get: { project.mentoringOrganizationOther ?? "" },
                                set: { project.mentoringOrganizationOther = $0.isEmpty ? nil : $0 }
                            ))
                            .font(.system(size: 13 * fontScale))
                            .textFieldStyle(.roundedBorder)
                            .onTapGesture { }
                        }
                    } else {
                        Text(label)
                            .font(.system(size: 13 * fontScale, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(mentoringOptionBg(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func mentoringFocusRow(option: (id: String, label: String)) -> some View {
        let isSelected = project.mentoringFocus.contains(option.id)
        Button(action: {
            if isSelected {
                project.mentoringFocus.removeAll { $0 == option.id }
            } else {
                project.mentoringFocus.append(option.id)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16 * fontScale))
                    .foregroundColor(isSelected ? .purple : .secondary)
                Text(option.label)
                    .font(.system(size: 13 * fontScale, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(10)
            .background(mentoringOptionBg(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expectations, Constraints & Stakes Editor

    @ViewBuilder
    private var ecsEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Describe any specific inclusions or exclusions for this Challenge. Also what the stakes are for Learners.")
                .font(.system(size: 11 * fontScale))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ecsSection(
                title: "Expectations",
                description: "What needs to be included in the Solution? This can tie to the Success Criteria.",
                placeholder: "e.g. Learn the basic CBL cycle and use it to find solutions.",
                items: $project.expectations,
                accentColor: .blue
            )

            Divider()

            ecsSection(
                title: "Constraints",
                description: "What should they not include or try to do in the Challenge?",
                placeholder: "e.g. No Internet – prototyping with mock data is OK.",
                items: $project.constraints,
                accentColor: .orange
            )

            Divider()

            ecsSection(
                title: "Stakes",
                description: "What are the risks? Who will they be presenting to? What is the expectation for the presentation?",
                placeholder: "e.g. Present apps and processes to members of other teams.",
                items: $project.stakes,
                accentColor: .red
            )
        }
    }

    @ViewBuilder
    private func ecsSection(
        title: String,
        description: String,
        placeholder: String,
        items: Binding<[String]>,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13 * fontScale, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 11 * fontScale))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(items.wrappedValue.indices, id: \.self) { idx in
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5 * fontScale))
                        .foregroundColor(accentColor)

                    TextField(placeholder, text: Binding(
                        get: { items.wrappedValue[idx] },
                        set: { items.wrappedValue[idx] = $0 }
                    ))
                    .font(.system(size: 13 * fontScale))
                    .textFieldStyle(.roundedBorder)

                    Button(action: { items.wrappedValue.remove(at: idx) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14 * fontScale))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: { items.wrappedValue.append("") }) {
                Label("Add item", systemImage: "plus.circle.fill")
                    .font(.system(size: 12 * fontScale, weight: .medium))
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    private func mentoringOptionBg(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.purple.opacity(0.07) : Color.gray.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.purple.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1))
    }

    private func removeField(_ id: String) {
        withAnimation { addedFields.remove(id) }
        switch id {
        case "name":                   project.name = ""
        case "dates":
            project.startDate = nil
            project.endDate = nil
            project.holidays = []
            project.workingDays = nil
        case "challengeType":          project.challengeType = nil
        case "participationModel":     project.participationModel = nil
        case "regulationModel":        project.regulationModel = nil
        case "roleInLearningJourney":  project.roleInLearningJourney = ""
        case "mentoring":
            project.mentoringOrganization = nil
            project.mentoringOrganizationTeamCount = nil
            project.mentoringOrganizationOther = nil
            project.mentoringFocus = []
            project.mentoringFocusOther = nil
        case "ecs":
            project.expectations = []
            project.constraints = []
            project.stakes = []
        case "overallSuccessCriteria": project.overallSuccessCriteria = ""
        default: break
        }
    }

    // MARK: - 옵션 선택기

    @ViewBuilder
    private func optionSelector(
        options: [(value: String, description: String)],
        selected: Binding<String?>,
        accentColor: Color
    ) -> some View {
        let isCustom: Bool = {
            guard let v = selected.wrappedValue else { return false }
            return !options.map(\.value).contains(v)
        }()
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options, id: \.value) { option in
                optionRow(option: option, selected: selected, accentColor: accentColor)
            }
            customRow(isCustom: isCustom, selected: selected, accentColor: accentColor)
        }
    }

    @ViewBuilder
    private func optionRow(
        option: (value: String, description: String),
        selected: Binding<String?>,
        accentColor: Color
    ) -> some View {
        let isSelected = selected.wrappedValue == option.value
        Button(action: { selected.wrappedValue = option.value }) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16 * fontScale))
                    .foregroundColor(isSelected ? accentColor : .secondary)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.value)
                        .font(.system(size: 13 * fontScale, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(option.description)
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(10)
            .background(optionBackground(isSelected: isSelected, accentColor: accentColor))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func customRow(
        isCustom: Bool,
        selected: Binding<String?>,
        accentColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: { if !isCustom { selected.wrappedValue = "" } }) {
                Image(systemName: isCustom ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16 * fontScale))
                    .foregroundColor(isCustom ? accentColor : .secondary)
                    .padding(.top, 8)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 4) {
                Text("Other")
                    .font(.system(size: 13 * fontScale, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                if isCustom {
                    TextField("Enter custom value...", text: Binding(
                        get: { selected.wrappedValue ?? "" },
                        set: { selected.wrappedValue = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: 13 * fontScale))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(10)
        .background(optionBackground(isSelected: isCustom, accentColor: accentColor))
    }

    private func optionBackground(isSelected: Bool, accentColor: Color) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? accentColor.opacity(0.07) : Color.gray.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? accentColor.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Working Days Calculation

    private func calculateWeekdays(from start: Date, to end: Date) -> Int {
        guard start <= end else { return 0 }
        let cal = Calendar.current
        var count = 0
        var current = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        while current <= endDay {
            let weekday = cal.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 { count += 1 }
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        return count
    }

    private func countEffectiveHolidays(start: Date, end: Date) -> Int {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        return project.holidays.filter { h in
            let day = cal.startOfDay(for: h)
            guard day >= startDay && day <= endDay else { return false }
            let weekday = cal.component(.weekday, from: h)
            return weekday != 1 && weekday != 7
        }.count
    }

    private func recalculateWorkingDays() {
        guard let start = project.startDate, let end = project.endDate, start <= end else {
            project.workingDays = nil
            return
        }
        let weekdays = calculateWeekdays(from: start, to: end)
        let holidays = countEffectiveHolidays(start: start, end: end)
        project.workingDays = weekdays - holidays
    }

    // MARK: - 날짜 포맷

    private func formatShortDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d"
        return fmt.string(from: date)
    }

    private func formatHolidayDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }
}
