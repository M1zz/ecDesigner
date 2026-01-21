import Foundation
import AppKit

struct CSVImportResult {
    let milestones: [Milestone]
    let nodes: [ECNode]
    let errors: [String]
}

struct CSVExporter {

    /// Export Exploratory Cycle to CSV format compatible with Numbers
    static func exportToCSV(exploratoryCycle: ExploratoryCycle) -> String {
        var csv = ""

        // Header row
        let headers = [
            "Phase",
            "Day",
            "Learning Objective (오늘 러너들은...)",
            "Milestone",
            "Artifact/Deliverable",
            "Success Criteria",
            "멘토의 할일 (Mentor Tasks)",
            "Mentoring Guidelines",
            "Key GQs (Guiding Questions)",
            "Key GAs (Guiding Activities)",
            "Findings",
            "Synthesis",
            "Duration",
            "EC Number"
        ]
        csv += headers.map { escapeCSVField($0) }.joined(separator: ",") + "\n"

        // Get ordered nodes
        let orderedNodes = exploratoryCycle.getOrderedNodes()
        let milestones = exploratoryCycle.milestones

        // Data rows - one row per EC
        for node in orderedNodes {
            var row: [String] = []

            // Find linked milestone
            let linkedMilestone = milestones.first { $0.id == node.milestoneId }

            // Phase (from milestone)
            row.append(linkedMilestone?.phase?.rawValue ?? "")

            // Day
            row.append(node.day)

            // Learning Objective
            row.append(node.learningObjective)

            // Milestone title
            if let milestone = linkedMilestone {
                let milestoneTitle = milestone.title.isEmpty ? "Milestone #\(milestone.sequenceNumber + 1)" : milestone.title
                row.append(milestoneTitle)
            } else {
                row.append("")
            }

            // Artifact/Deliverable
            row.append(node.artifact)

            // Success Criteria (from milestone)
            row.append(linkedMilestone?.successCriteria ?? "")

            // Mentor Tasks
            row.append(node.mentorTasks)

            // Mentoring Guidelines (from milestone)
            row.append(linkedMilestone?.mentorGuidelines ?? "")

            // Key GQs
            row.append(node.guidingQuestions)

            // Key GAs
            row.append(node.guidingActivities)

            // Findings
            row.append(node.findings)

            // Synthesis
            row.append(node.synthesis)

            // Duration
            row.append(node.duration)

            // EC Number
            row.append("#\(node.sequenceNumber + 1)")

            // Escape and join row
            csv += row.map { escapeCSVField($0) }.joined(separator: ",") + "\n"
        }

        return csv
    }

    /// Escape CSV field (handle quotes, commas, newlines)
    private static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Save CSV to file using save panel
    static func saveCSVFile(exploratoryCycle: ExploratoryCycle, projectName: String) {
        let csv = exportToCSV(exploratoryCycle: exploratoryCycle)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "\(projectName)_Curriculum.csv"
        savePanel.title = "Export Curriculum to CSV"
        savePanel.message = "Choose where to save the curriculum data"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try csv.write(to: url, atomically: true, encoding: .utf8)

                    // Show success notification
                    let alert = NSAlert()
                    alert.messageText = "Export Successful"
                    alert.informativeText = "Curriculum data has been exported to:\n\(url.path)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.addButton(withTitle: "Open File")

                    let response = alert.runModal()
                    if response == .alertSecondButtonReturn {
                        NSWorkspace.shared.open(url)
                    }
                } catch {
                    // Show error
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = "Failed to save CSV file: \(error.localizedDescription)"
                    alert.alertStyle = .critical
                    alert.runModal()
                }
            }
        }
    }

    /// Save as Numbers file using AppleScript
    static func saveNumbersFile(exploratoryCycle: ExploratoryCycle, projectName: String) {
        // First create CSV in temp location
        let tempDir = FileManager.default.temporaryDirectory
        let csvURL = tempDir.appendingPathComponent("temp_export.csv")
        let csv = exportToCSV(exploratoryCycle: exploratoryCycle)

        do {
            try csv.write(to: csvURL, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = "Failed to create temporary CSV file: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.runModal()
            return
        }

        // Show save panel for Numbers file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "numbers")!]
        savePanel.nameFieldStringValue = "\(projectName)_Curriculum.numbers"
        savePanel.title = "Export Curriculum to Numbers"
        savePanel.message = "Choose where to save the Numbers document"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                // Use AppleScript to create Numbers document from CSV
                let script = """
                tell application "Numbers"
                    set theDoc to make new document
                    tell theDoc
                        tell active sheet
                            delete (every table whose name is not "")
                            set theTable to make new table with properties {name:"Curriculum"}
                        end tell
                    end tell

                    -- Import CSV data
                    set importedDoc to open POSIX file "\(csvURL.path)"
                    tell importedDoc
                        set theSheet to active sheet
                        set sourceTable to first table of theSheet
                        copy sourceTable
                    end tell
                    close importedDoc saving no

                    tell theDoc
                        tell active sheet
                            delete theTable
                            paste
                        end tell
                        save theDoc in POSIX file "\(url.path)"
                    end tell

                    close theDoc
                end tell
                """

                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: script) {
                    scriptObject.executeAndReturnError(&error)

                    // Clean up temp CSV
                    try? FileManager.default.removeItem(at: csvURL)

                    if let error = error {
                        let alert = NSAlert()
                        alert.messageText = "Export Failed"
                        alert.informativeText = "Failed to create Numbers file. Please make sure Numbers app is installed.\n\nError: \(error)"
                        alert.alertStyle = .critical
                        alert.runModal()
                    } else {
                        // Success
                        let alert = NSAlert()
                        alert.messageText = "Export Successful"
                        alert.informativeText = "Curriculum data has been exported to:\n\(url.path)"
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.addButton(withTitle: "Open File")

                        let response = alert.runModal()
                        if response == .alertSecondButtonReturn {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            } else {
                // User cancelled, clean up temp file
                try? FileManager.default.removeItem(at: csvURL)
            }
        }
    }

    // MARK: - CSV Import

    /// Import CSV file and create Milestones and ECNodes
    /// Supports row-based format where milestones appear as column headers
    static func importFromCSV(fileURL: URL) -> CSVImportResult {
        var milestones: [String: Milestone] = [:] // Key: milestone title
        var milestoneOrder: [String] = [] // Track milestone order
        var nodes: [ECNode] = []
        var errors: [String] = []

        do {
            let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines)

            guard lines.count > 1 else {
                errors.append("CSV file is empty or has no data rows")
                return CSVImportResult(milestones: [], nodes: [], errors: errors)
            }

            // Parse header row to identify columns
            let headerFields = parseCSVLine(lines[0])
            NSLog("📋 Header row has \(headerFields.count) columns")
            NSLog("📋 Headers: \(headerFields)")

            // Standard column names we expect (case-insensitive matching)
            let standardColumns = [
                "phase", "day", "learning objective", "오늘 러너들은",
                "milestone", "artifact", "deliverable", "success criteria",
                "mentor tasks", "멘토의 할일", "mentoring guidelines",
                "key gqs", "guiding questions", "key gas", "guiding activities",
                "findings", "synthesis", "duration", "ec number"
            ]

            // Map column indices to their types
            var columnMap: [Int: String] = [:] // Index -> Column type
            var milestoneColumns: [Int: String] = [:] // Index -> Milestone name

            for (index, header) in headerFields.enumerated() {
                let normalizedHeader = header.trimmingCharacters(in: .whitespaces).lowercased()

                // Check if this is a standard column
                var isStandard = false
                for stdCol in standardColumns {
                    if normalizedHeader.contains(stdCol) || stdCol.contains(normalizedHeader) {
                        columnMap[index] = stdCol
                        isStandard = true
                        break
                    }
                }

                // If not a standard column and not empty, treat as milestone
                if !isStandard && !header.trimmingCharacters(in: .whitespaces).isEmpty {
                    let milestoneName = header.trimmingCharacters(in: .whitespaces)
                    milestoneColumns[index] = milestoneName
                    NSLog("🎯 Found milestone column at index \(index): \(milestoneName)")
                }
            }

            NSLog("📊 Identified \(milestoneColumns.count) milestone columns")

            // Create milestones from column headers
            let sortedMilestoneIndices = milestoneColumns.keys.sorted()
            for (sequenceNum, colIndex) in sortedMilestoneIndices.enumerated() {
                if let milestoneName = milestoneColumns[colIndex] {
                    let milestone = Milestone(
                        title: milestoneName,
                        description: "",
                        phase: nil,
                        successCriteria: "",
                        deliverable: "",
                        artifacts: "",
                        mentorGuidelines: "",
                        sequenceNumber: sequenceNum,
                        position: CGPoint(x: 200, y: 200 + CGFloat(sequenceNum) * 300)
                    )
                    milestones[milestoneName] = milestone
                    milestoneOrder.append(milestoneName)
                    NSLog("✅ Created milestone: \(milestoneName)")
                }
            }

            // Helper to find column index by type
            func findColumn(_ type: String) -> Int? {
                for (index, colType) in columnMap {
                    if colType.contains(type) || type.contains(colType) {
                        return index
                    }
                }
                return nil
            }

            // Parse data rows
            let dataLines = lines.dropFirst().filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            NSLog("📝 Processing \(dataLines.count) data rows")

            for (rowIndex, line) in dataLines.enumerated() {
                let fields = parseCSVLine(line)

                // Helper to safely get field value
                func getField(_ index: Int?) -> String {
                    guard let index = index, index < fields.count else { return "" }
                    return fields[index].trimmingCharacters(in: .whitespaces)
                }

                // Extract standard fields
                let phaseString = getField(findColumn("phase"))
                let day = getField(findColumn("day"))
                let learningObjective = getField(findColumn("learning objective")) + getField(findColumn("오늘 러너들은"))
                let artifact = getField(findColumn("artifact")) + getField(findColumn("deliverable"))
                let successCriteria = getField(findColumn("success criteria"))
                let mentorTasks = getField(findColumn("mentor tasks")) + getField(findColumn("멘토의 할일"))
                let mentorGuidelines = getField(findColumn("mentoring guidelines"))
                let guidingQuestions = getField(findColumn("key gqs")) + getField(findColumn("guiding questions"))
                let guidingActivities = getField(findColumn("key gas")) + getField(findColumn("guiding activities"))
                let findings = getField(findColumn("findings"))
                let synthesis = getField(findColumn("synthesis"))
                let duration = getField(findColumn("duration"))

                // Parse phase
                let phase: Phase? = {
                    guard !phaseString.isEmpty else { return nil }
                    return Phase(rawValue: phaseString)
                }()

                // Determine which milestone this EC belongs to
                // Check milestone columns for non-empty data
                var linkedMilestone: Milestone?
                for (colIndex, milestoneName) in milestoneColumns {
                    if colIndex < fields.count {
                        let cellValue = fields[colIndex].trimmingCharacters(in: .whitespaces)
                        if !cellValue.isEmpty {
                            linkedMilestone = milestones[milestoneName]
                            NSLog("🔗 Row \(rowIndex + 2) linked to milestone: \(milestoneName)")

                            // Update milestone with row data if available
                            if var milestone = linkedMilestone,
                               milestone.successCriteria.isEmpty && !successCriteria.isEmpty {
                                milestone.successCriteria = successCriteria
                                milestone.mentorGuidelines = mentorGuidelines
                                milestone.phase = phase
                                milestones[milestoneName] = milestone
                            }
                            break
                        }
                    }
                }

                // Create ECNode
                let node = ECNode(
                    position: CGPoint(x: 400 + CGFloat(rowIndex) * 100, y: 300),
                    sequenceNumber: rowIndex,
                    day: day,
                    learningObjective: learningObjective,
                    artifact: artifact,
                    mentorTasks: mentorTasks,
                    guidingQuestions: guidingQuestions,
                    guidingActivities: guidingActivities,
                    findings: findings,
                    synthesis: synthesis,
                    duration: duration,
                    milestoneId: linkedMilestone?.id
                )
                nodes.append(node)
            }

            NSLog("✅ Import complete: \(milestones.count) milestones, \(nodes.count) ECs")

        } catch {
            errors.append("Failed to read CSV file: \(error.localizedDescription)")
        }

        return CSVImportResult(
            milestones: milestoneOrder.compactMap { milestones[$0] },
            nodes: nodes,
            errors: errors
        )
    }

    /// Parse a single CSV line, handling quoted fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        fields.append(currentField)

        // Remove surrounding quotes and unescape doubled quotes
        return fields.map { field in
            var cleaned = field
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                cleaned = String(cleaned.dropFirst().dropLast())
            }
            return cleaned.replacingOccurrences(of: "\"\"", with: "\"")
        }
    }

    /// Check if we have permission to control Numbers
    private static func checkAutomationPermission() -> Bool {
        let script = """
        tell application "System Events"
            return name
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }

    /// Convert Numbers file to CSV using AppleScript
    private static func convertNumbersToCSV(numbersURL: URL) -> (url: URL?, errorMessage: String?) {
        let tempDir = FileManager.default.temporaryDirectory
        let csvURL = tempDir.appendingPathComponent("temp_import.csv")

        // Remove existing temp file if any
        try? FileManager.default.removeItem(at: csvURL)

        // Escape the path properly for AppleScript
        let numbersPath = numbersURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        let csvPath = csvURL.path.replacingOccurrences(of: "\"", with: "\\\"")

        // Improved AppleScript with better error handling
        let script = """
        try
            tell application "Finder"
                if not (exists application file id "com.apple.iWork.Numbers") then
                    error "Numbers app is not installed"
                end if
            end tell

            tell application "Numbers"
                activate

                -- Open the Numbers file
                set theDoc to open POSIX file "\(numbersPath)"
                delay 1

                -- Get the first sheet
                tell theDoc
                    if (count of sheets) is 0 then
                        close saving no
                        error "Document has no sheets"
                    end if

                    set theSheet to sheet 1

                    -- Check if sheet has tables
                    tell theSheet
                        if (count of tables) is 0 then
                            close theDoc saving no
                            error "First sheet has no tables"
                        end if
                    end tell
                end tell

                -- Export to CSV
                export theDoc to POSIX file "\(csvPath)" as CSV

                -- Close without saving
                close theDoc saving no

                return "success"
            end tell
        on error errMsg number errNum
            return "Error " & errNum & ": " & errMsg
        end try
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)

            if let error = error {
                let errorMsg = error["NSAppleScriptErrorMessage"] as? String ?? error.description
                NSLog("AppleScript Error: \(errorMsg)")
                NSLog("Full error: \(error)")
                return (nil, errorMsg)
            }

            // Check the result
            if let resultString = result.stringValue {
                if resultString.lowercased().contains("error") {
                    NSLog("AppleScript returned error: \(resultString)")
                    return (nil, resultString)
                }
            }

            // Check if CSV file was created
            if FileManager.default.fileExists(atPath: csvURL.path) {
                NSLog("CSV file created successfully at: \(csvURL.path)")
                return (csvURL, nil)
            } else {
                NSLog("CSV file was not created at expected path: \(csvURL.path)")
                return (nil, "CSV file was not created")
            }
        }

        return (nil, "Failed to create AppleScript object")
    }

    /// Open file picker and import CSV or Numbers file
    static func importCSVFile(completion: @escaping (CSVImportResult?) -> Void) {
        let openPanel = NSOpenPanel()

        // Allow both CSV and Numbers files
        openPanel.allowedContentTypes = [
            .commaSeparatedText,
            .init(filenameExtension: "numbers")!
        ]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.title = "Import Curriculum"
        openPanel.message = "Select a CSV or Numbers file to import"

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                var fileToImport = url
                var isTemporaryFile = false

                // Check if it's a Numbers file
                if url.pathExtension.lowercased() == "numbers" {
                    // This won't block because we're converting in the background
                    DispatchQueue.global(qos: .userInitiated).async {
                        let conversionResult = convertNumbersToCSV(numbersURL: url)

                        if let csvURL = conversionResult.url {
                            fileToImport = csvURL
                            isTemporaryFile = true

                            // Import the converted CSV
                            DispatchQueue.main.async {
                                let result = importFromCSV(fileURL: fileToImport)

                                // Clean up temporary file
                                if isTemporaryFile {
                                    try? FileManager.default.removeItem(at: fileToImport)
                                }

                                // Show results
                                showImportResults(result: result)
                                completion(result)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let errorAlert = NSAlert()

                                // Check if it's a permission issue
                                if let errorMsg = conversionResult.errorMessage,
                                   errorMsg.contains("-1743") || errorMsg.lowercased().contains("not authorized") {
                                    // Permission issue - show helpful guide
                                    errorAlert.messageText = "권한 설정 필요"
                                    errorAlert.informativeText = """
                                    macOS가 이 앱이 Numbers를 제어하는 것을 차단했습니다.

                                    ✅ 해결 방법:
                                    1. 시스템 설정 열기
                                    2. '개인정보 보호 및 보안' 클릭
                                    3. 왼쪽 메뉴에서 '자동화' 선택
                                    4. 'ecDesigner' 앱 찾기
                                    5. 'Numbers' 체크박스 활성화 ✅

                                    또는

                                    Numbers에서 직접 CSV로 내보내기:
                                    1. Numbers에서 파일 열기
                                    2. 파일 → 내보내기 → CSV
                                    3. CSV 파일을 앱에서 Import
                                    """
                                    errorAlert.alertStyle = .warning

                                    // Add button to open System Preferences
                                    errorAlert.addButton(withTitle: "시스템 설정 열기")
                                    errorAlert.addButton(withTitle: "취소")

                                    let response = errorAlert.runModal()
                                    if response == .alertFirstButtonReturn {
                                        // Open System Preferences to Privacy settings
                                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                } else {
                                    // Other error
                                    errorAlert.messageText = "Conversion Failed"

                                    var detailedMessage = "Failed to convert Numbers file to CSV.\n\n"
                                    if let errorMsg = conversionResult.errorMessage {
                                        detailedMessage += "Error details:\n\(errorMsg)\n\n"
                                    }
                                    detailedMessage += "Please make sure:\n"
                                    detailedMessage += "1. Numbers app is installed and can be launched\n"
                                    detailedMessage += "2. The file is a valid Numbers document\n"
                                    detailedMessage += "3. The first sheet contains a table\n"
                                    detailedMessage += "4. The file is not corrupted\n\n"
                                    detailedMessage += "File path: \(url.path)"

                                    errorAlert.informativeText = detailedMessage
                                    errorAlert.alertStyle = .critical
                                    errorAlert.runModal()
                                }
                                completion(nil)
                            }
                        }
                    }
                } else {
                    // Direct CSV import
                    let result = importFromCSV(fileURL: fileToImport)
                    showImportResults(result: result)
                    completion(result)
                }
            } else {
                completion(nil)
            }
        }
    }

    /// Show import results in an alert
    private static func showImportResults(result: CSVImportResult) {
        if !result.errors.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Import Completed"

            // Show summary instead of all errors
            let errorCount = result.errors.count
            var message = "✅ Successfully imported:\n"
            message += "   • \(result.nodes.count) Exploratory Cycles\n"
            message += "   • \(result.milestones.count) Milestones\n\n"

            if errorCount <= 3 {
                // Show all errors if there are only a few
                message += "⚠️ Warnings:\n"
                for (index, error) in result.errors.enumerated() {
                    message += "\(index + 1). \(error)\n"
                }
            } else {
                // Show summary for many errors
                message += "⚠️ \(errorCount) warnings (showing first 3):\n"
                for (index, error) in result.errors.prefix(3).enumerated() {
                    message += "\(index + 1). \(error)\n"
                }
                message += "\n... and \(errorCount - 3) more warnings"
            }

            alert.informativeText = message
            alert.alertStyle = .warning
            alert.runModal()
        } else {
            let alert = NSAlert()
            alert.messageText = "Import Successful"
            alert.informativeText = "✅ Successfully imported:\n   • \(result.nodes.count) Exploratory Cycles\n   • \(result.milestones.count) Milestones"
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}
