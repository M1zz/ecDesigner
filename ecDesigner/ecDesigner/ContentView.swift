import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CanvasViewModel()
    @State private var editingNode: ECNode?
    @State private var editingMilestone: Milestone?
    @State private var showProjectList: Bool = false
    @State private var showChallengeEditor: Bool = false
    @State private var keyEventMonitor: Any?
    @State private var showDeleteConfirmation: Bool = false
    @State private var milestoneWindows: [UUID: NSWindow] = [:]
    @State private var nodeWindows: [UUID: NSWindow] = [:]

    var body: some View {
        NavigationSplitView {
            // 사이드바
            VStack(alignment: .leading, spacing: 16) {
                // 헤더: 챌린지 이름 (클릭하여 다른 챌린지 선택)
                HStack {
                    Button(action: {
                        showProjectList = true
                    }) {
                        HStack(spacing: 6) {
                            Text(viewModel.currentProject.name)
                                .font(.system(size: 17 * viewModel.fontScale, weight: .semibold))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12 * viewModel.fontScale))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("다른 챌린지 선택")

                    Spacer()

                    // 엘립시스 메뉴 (모든 기능 통합)
                    Menu {
                        Button(action: { showChallengeEditor = true }) {
                            Label("챌린지 정보 수정", systemImage: "info.circle")
                        }

                        Divider()

                        Menu("Import") {
                            Button("Import from CSV") {
                                CSVExporter.importCSVFile { result in
                                    if let result = result {
                                        viewModel.importFromCSV(result: result)
                                    }
                                }
                            }
                            Button("Load Demo Data") {
                                viewModel.populateWithDummyData()
                            }
                        }

                        Menu("Export") {
                            Button("Export as CSV") {
                                CSVExporter.saveCSVFile(
                                    exploratoryCycle: viewModel.exploratoryCycle,
                                    projectName: viewModel.currentProject.name
                                )
                            }
                            Button("Export as Numbers") {
                                CSVExporter.saveNumbersFile(
                                    exploratoryCycle: viewModel.exploratoryCycle,
                                    projectName: viewModel.currentProject.name
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18 * viewModel.fontScale))
                    }
                    .menuStyle(.borderlessButton)
                    .help("더보기")
                }
                .padding(.horizontal)

                Divider()

                // 계층 구조 (Milestone > EC)
                List {
                    // 마일스톤별 EC 계층 구조
                    ForEach(viewModel.exploratoryCycle.getOrderedMilestones()) { milestone in
                        let linkedECs = viewModel.exploratoryCycle.nodes
                            .filter { $0.milestoneId == milestone.id }
                            .sorted { $0.sequenceNumber < $1.sequenceNumber }

                        DisclosureGroup {
                            // 해당 마일스톤에 연결된 EC들
                            ForEach(linkedECs) { node in
                                ecRowView(node: node)
                                    .padding(.leading, 8)
                            }

                            // EC가 없을 경우 안내 메시지
                            if linkedECs.isEmpty {
                                Text("연결된 EC가 없습니다")
                                    .font(.system(size: 11 * viewModel.fontScale))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)
                                    .padding(.vertical, 4)
                            }
                        } label: {
                            Button(action: {
                                openMilestoneWindow(milestone: milestone)
                            }) {
                                HStack {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 12 * viewModel.fontScale))
                                        .foregroundColor(milestone.phase?.color ?? .orange)

                                    VStack(alignment: .leading) {
                                        if !milestone.title.isEmpty {
                                            Text(milestone.title)
                                                .font(.system(size: 12 * viewModel.fontScale, weight: .semibold))
                                                .lineLimit(1)
                                        } else {
                                            Text("Milestone #\(milestone.sequenceNumber + 1)")
                                                .font(.system(size: 12 * viewModel.fontScale))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    // EC 카운트 표시
                                    if !linkedECs.isEmpty {
                                        Text("\(linkedECs.count)")
                                            .font(.system(size: 10 * viewModel.fontScale))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.7))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 연결되지 않은 EC들 (Unlinked)
                    let unlinkedECs = viewModel.exploratoryCycle.nodes
                        .filter { $0.milestoneId == nil }
                        .sorted { $0.sequenceNumber < $1.sequenceNumber }

                    if !unlinkedECs.isEmpty {
                        Section("미연결 EC") {
                            ForEach(unlinkedECs) { node in
                                ecRowView(node: node)
                            }
                        }
                    }
                }

                // 선택된 항목 정보 및 연결 모드 상태
                if viewModel.isConnectionMode || viewModel.selectedNodeId != nil || viewModel.selectedMilestoneId != nil {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        // 연결 모드 상태 표시
                        if viewModel.isConnectionMode {
                            HStack {
                                Label("연결 모드", systemImage: "link.circle.fill")
                                    .font(.system(size: 12 * viewModel.fontScale))
                                    .foregroundColor(.blue)
                                Spacer()
                                if viewModel.isConnecting {
                                    Button("취소") {
                                        viewModel.cancelConnection()
                                    }
                                    .font(.system(size: 11 * viewModel.fontScale))
                                    .foregroundColor(.red)
                                }
                            }
                        }

                        // 선택된 노드 정보
                        if let selectedId = viewModel.selectedNodeId,
                           let node = viewModel.getNode(by: selectedId) {
                            HStack {
                                Text("선택: EC #\(node.sequenceNumber + 1)")
                                    .font(.system(size: 12 * viewModel.fontScale))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("수정") {
                                    openNodeWindow(node: node)
                                }
                                .font(.system(size: 11 * viewModel.fontScale))
                            }
                        }

                        // 선택된 마일스톤 정보
                        if let selectedId = viewModel.selectedMilestoneId,
                           let milestone = viewModel.getMilestone(by: selectedId) {
                            HStack {
                                Text("선택: \(milestone.title.isEmpty ? "Milestone #\(milestone.sequenceNumber + 1)" : milestone.title)")
                                    .font(.system(size: 12 * viewModel.fontScale))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Button("수정") {
                                    openMilestoneWindow(milestone: milestone)
                                }
                                .font(.system(size: 11 * viewModel.fontScale))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                Spacer()
            }
            .contextMenu {
                Button(action: {
                    viewModel.addMilestone()
                    if let newMilestone = viewModel.exploratoryCycle.milestones.last {
                        openMilestoneWindow(milestone: newMilestone)
                    }
                }) {
                    Label("마일스톤 추가", systemImage: "flag.circle")
                }

                Button(action: {
                    viewModel.addNode(at: CGPoint(x: 300, y: 300))
                }) {
                    Label("EC 추가", systemImage: "plus.circle")
                }
            }
            .frame(minWidth: 350, idealWidth: 400, maxWidth: 500)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .trailing
            )
        } detail: {
            // 메인 캔버스
            CanvasView(
                viewModel: viewModel,
                onNodeEdit: { node in
                    openNodeWindow(node: node)
                },
                onMilestoneEdit: { milestone in
                    openMilestoneWindow(milestone: milestone)
                }
            )
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        // Canvas controls
                        HStack(spacing: 8) {
                            Button(action: { viewModel.resetCanvasPosition() }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14 * viewModel.fontScale))
                            }
                            .help("Reset canvas position")
                        }

                        Divider()

                        // 폰트 크기 조절 컨트롤
                        HStack(spacing: 8) {
                            Button(action: { viewModel.zoomOut() }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.system(size: 14 * viewModel.fontScale))
                            }
                            .help("Decrease font size (⌘-)")

                            Text("\(Int(viewModel.fontScale * 100))%")
                                .font(.system(size: 12 * viewModel.fontScale))
                                .frame(minWidth: 40)

                            Button(action: { viewModel.zoomIn() }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.system(size: 14 * viewModel.fontScale))
                            }
                            .help("Increase font size (⌘+)")

                            Button(action: { viewModel.resetZoom() }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14 * viewModel.fontScale))
                            }
                            .help("Reset font size (⌘0)")
                        }
                    }
                }
        }
        .sheet(item: $editingMilestone) { milestone in
            if let index = viewModel.exploratoryCycle.milestones.firstIndex(where: { $0.id == milestone.id }) {
                MilestoneEditorView(
                    milestone: $viewModel.exploratoryCycle.milestones[index],
                    fontScale: viewModel.fontScale,
                    onSave: { updatedMilestone in
                        viewModel.updateMilestone(updatedMilestone)
                        editingMilestone = nil
                    },
                    onDelete: {
                        viewModel.deleteMilestone(milestone.id)
                        editingMilestone = nil
                    },
                    onCancel: {
                        editingMilestone = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showProjectList) {
            ProjectListView(viewModel: viewModel, showProjectList: $showProjectList)
        }
        .sheet(isPresented: $showChallengeEditor) {
            ChallengeEditorView(
                project: $viewModel.currentProject,
                fontScale: viewModel.fontScale,
                onSave: {
                    viewModel.saveCurrentProject()
                    showChallengeEditor = false
                },
                onCancel: {
                    showChallengeEditor = false
                }
            )
        }
        .alert(viewModel.selectedMilestoneId != nil ? "Delete Milestone?" : "Delete EC?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let selectedId = viewModel.selectedNodeId {
                    viewModel.deleteNode(selectedId)
                } else if let selectedId = viewModel.selectedMilestoneId {
                    viewModel.deleteMilestone(selectedId)
                }
            }
        } message: {
            if let selectedId = viewModel.selectedNodeId,
               let node = viewModel.getNode(by: selectedId) {
                Text("Are you sure you want to delete Exploratory Cycle #\(node.sequenceNumber + 1)?")
            } else if let selectedId = viewModel.selectedMilestoneId,
                      let milestone = viewModel.getMilestone(by: selectedId) {
                let title = milestone.title.isEmpty ? "Milestone #\(milestone.sequenceNumber + 1)" : milestone.title
                Text("Are you sure you want to delete '\(title)'?")
            } else {
                Text("Are you sure you want to delete this item?")
            }
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
        .onDisappear {
            if let monitor = keyEventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }

    @ViewBuilder
    private func ecRowView(node: ECNode) -> some View {
        Button(action: {
            openNodeWindow(node: node)
        }) {
            HStack {
                Text("#\(node.sequenceNumber + 1)")
                    .font(.system(size: 10 * viewModel.fontScale, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Color.blue)
                    .cornerRadius(3)

                VStack(alignment: .leading, spacing: 1) {
                    if !node.guidingQuestions.isEmpty {
                        Text(node.guidingQuestions)
                            .font(.system(size: 11 * viewModel.fontScale))
                            .lineLimit(1)
                    } else {
                        Text("Empty EC")
                            .font(.system(size: 11 * viewModel.fontScale))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if viewModel.selectedNodeId == node.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12 * viewModel.fontScale))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openMilestoneWindow(milestone: Milestone) {
        // Close existing window if open
        if let existingWindow = milestoneWindows[milestone.id] {
            existingWindow.close()
        }

        // Get binding to the milestone in the array
        guard let index = viewModel.exploratoryCycle.milestones.firstIndex(where: { $0.id == milestone.id }) else {
            return
        }

        let contentView = MilestoneEditorView(
            milestone: $viewModel.exploratoryCycle.milestones[index],
            fontScale: viewModel.fontScale,
            onSave: { updatedMilestone in
                viewModel.updateMilestone(updatedMilestone)
                milestoneWindows[milestone.id]?.close()
                milestoneWindows[milestone.id] = nil
            },
            onDelete: {
                viewModel.deleteMilestone(milestone.id)
                milestoneWindows[milestone.id]?.close()
                milestoneWindows[milestone.id] = nil
            },
            onCancel: {
                milestoneWindows[milestone.id]?.close()
                milestoneWindows[milestone.id] = nil
            }
        )

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Milestone #\(milestone.sequenceNumber + 1)"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false

        // Handle window close
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            milestoneWindows[milestone.id] = nil
        }

        milestoneWindows[milestone.id] = window
        window.makeKeyAndOrderFront(nil)
    }

    private func openNodeWindow(node: ECNode) {
        // Close existing window if open
        if let existingWindow = nodeWindows[node.id] {
            existingWindow.close()
        }

        // Get binding to the node in the array
        guard let index = viewModel.exploratoryCycle.nodes.firstIndex(where: { $0.id == node.id }) else {
            return
        }

        let contentView = NodeEditorView(
            node: $viewModel.exploratoryCycle.nodes[index],
            fontScale: viewModel.fontScale,
            availableMilestones: viewModel.exploratoryCycle.getOrderedMilestones(),
            availableECs: viewModel.exploratoryCycle.getOrderedNodes(),
            onSave: { updatedNode in
                viewModel.updateNode(updatedNode)
                nodeWindows[node.id]?.close()
                nodeWindows[node.id] = nil
            },
            onDelete: {
                viewModel.deleteNode(node.id)
                nodeWindows[node.id]?.close()
                nodeWindows[node.id] = nil
            },
            onCancel: {
                nodeWindows[node.id]?.close()
                nodeWindows[node.id] = nil
            },
            onCreateMilestone: {
                viewModel.addMilestone()
                if let newMilestone = viewModel.exploratoryCycle.milestones.last {
                    openMilestoneWindow(milestone: newMilestone)
                }
            },
            onCreateEC: {
                viewModel.addNode(at: CGPoint(x: 400, y: 300))
            }
        )

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 750),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "EC #\(node.sequenceNumber + 1)"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false

        // Handle window close
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            nodeWindows[node.id] = nil
        }

        nodeWindows[node.id] = window
        window.makeKeyAndOrderFront(nil)
    }

    private func setupKeyboardShortcuts() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Command + Z (되돌리기)
            if event.modifierFlags.contains(.command) &&
               event.charactersIgnoringModifiers == "z" {
                viewModel.undo()
                return nil
            }
            // Command + = 또는 Command + Plus (확대)
            else if event.modifierFlags.contains(.command) &&
               (event.charactersIgnoringModifiers == "=" || event.charactersIgnoringModifiers == "+") {
                viewModel.zoomIn()
                return nil
            }
            // Command + - (축소)
            else if event.modifierFlags.contains(.command) &&
                    event.charactersIgnoringModifiers == "-" {
                viewModel.zoomOut()
                return nil
            }
            // Command + 0 (리셋)
            else if event.modifierFlags.contains(.command) &&
                    event.charactersIgnoringModifiers == "0" {
                viewModel.resetZoom()
                return nil
            }
            // Backspace/Delete (노드 또는 마일스톤 삭제)
            else if event.keyCode == 51 || event.keyCode == 117 { // Delete or Forward Delete
                if viewModel.selectedNodeId != nil || viewModel.selectedMilestoneId != nil {
                    showDeleteConfirmation = true
                    return nil
                }
            }
            return event
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
