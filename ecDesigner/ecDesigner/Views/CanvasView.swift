import SwiftUI

struct CanvasView: View {
    @ObservedObject var viewModel: CanvasViewModel
    let onNodeEdit: (ECNode) -> Void
    let onMilestoneEdit: (Milestone) -> Void
    @State private var mouseLocation: CGPoint = .zero
    @State private var isPanning: Bool = false
    @State private var panStartOffset: CGSize = .zero
    @State private var dragStartLocation: CGPoint = .zero
    @State private var isDraggingNode: Bool = false
    @State private var scrollEventMonitor: Any?

    @State private var showTips: Bool = true

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    canvasLayer
                    buttonLayer
                }

                // 하단 Tips 영역
                if showTips {
                    tipsView
                }
            }
        }
    }

    private var tipsView: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 14 * viewModel.fontScale))

            if viewModel.isConnectionMode {
                Text("연결 모드: EC 화살표를 드래그하여 연결하세요")
            } else {
                Text("더블클릭으로 EC 추가 • 2손가락 스크롤로 이동 • 드래그로 노드 이동")
            }

            Spacer()

            Button(action: { showTips = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12 * viewModel.fontScale))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Tips 닫기")
        }
        .font(.system(size: 12 * viewModel.fontScale))
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .top
        )
    }

    private var canvasLayer: some View {
        canvasWithGestures
    }

    private var buttonLayer: some View {
        connectionModeButton
    }

    private var canvasWithGestures: some View {
        Group {
            canvasContent
                .coordinateSpace(name: "canvas")
                .background(Color(NSColor.controlBackgroundColor))
                .gesture(canvasDragGesture)
                .onTapGesture(count: 2, perform: {
                    handleDoubleTap(location: mouseLocation)
                })
                .onTapGesture(count: 1, perform: handleSingleTap)
                .onContinuousHover(perform: handleHover)
                .onAppear(perform: setupScrollEventMonitor)
                .onDisappear(perform: cleanupScrollEventMonitor)
                .contextMenu {
                    Button(action: {
                        let adjustedLocation = CGPoint(
                            x: mouseLocation.x - viewModel.canvasOffset.width,
                            y: mouseLocation.y - viewModel.canvasOffset.height
                        )
                        viewModel.addMilestone(at: adjustedLocation)
                    }) {
                        Label("마일스톤 추가", systemImage: "flag.circle")
                    }

                    Button(action: {
                        let adjustedLocation = CGPoint(
                            x: mouseLocation.x - viewModel.canvasOffset.width,
                            y: mouseLocation.y - viewModel.canvasOffset.height
                        )
                        viewModel.addNode(at: adjustedLocation)
                    }) {
                        Label("EC 추가", systemImage: "plus.circle")
                    }

                    Divider()

                    Button(action: {
                        viewModel.toggleConnectionMode()
                    }) {
                        Label(viewModel.isConnectionMode ? "연결 모드 해제" : "연결 모드", systemImage: "link.circle")
                    }
                }
        }
    }

    @ViewBuilder
    private var connectionModeButton: some View {
        Button(action: { viewModel.toggleConnectionMode() }) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isConnectionMode ? "link.circle.fill" : "link.circle")
                    .font(.system(size: 22 * viewModel.fontScale))
                Text(viewModel.isConnectionMode ? "연결 모드 활성화됨" : "연결 모드")
                    .font(.system(size: 12 * viewModel.fontScale))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.isConnectionMode ? Color.blue : Color(NSColor.controlBackgroundColor))
                    .shadow(color: .gray.opacity(0.3), radius: 4)
            )
            .foregroundColor(viewModel.isConnectionMode ? .white : .primary)
        }
        .buttonStyle(.plain)
        .padding(20)
    }

    private var canvasDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged(handleDragChanged)
            .onEnded(handleDragEnded)
    }

    private func handleDoubleTap(location: CGPoint) {
        guard !viewModel.isConnectionMode && !viewModel.isConnecting else { return }
        let adjustedLocation = CGPoint(
            x: location.x - viewModel.canvasOffset.width,
            y: location.y - viewModel.canvasOffset.height
        )
        viewModel.addNode(at: adjustedLocation)
    }

    private func handleSingleTap() {
        if viewModel.isConnecting {
            viewModel.cancelConnection()
        } else if !viewModel.isConnectionMode {
            viewModel.selectedNodeId = nil
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        mouseLocation = value.location

        guard !isDraggingNode && !viewModel.isConnecting else { return }

        let threshold: CGFloat = 50
        let adjustedLocation = CGPoint(
            x: value.location.x - viewModel.canvasOffset.width,
            y: value.location.y - viewModel.canvasOffset.height
        )

        // Check if over any node
        let isOverNode = viewModel.exploratoryCycle.nodes.contains { node in
            let distance = sqrt(
                pow(node.position.x - adjustedLocation.x, 2) +
                pow(node.position.y - adjustedLocation.y, 2)
            )
            return distance < threshold
        }

        guard !isOverNode else { return }

        // Start panning if moved enough
        if !isPanning {
            let dragDistance = sqrt(
                pow(value.location.x - dragStartLocation.x, 2) +
                pow(value.location.y - dragStartLocation.y, 2)
            )
            if dragDistance > 5 {
                isPanning = true
                panStartOffset = viewModel.canvasOffset
            }
        }

        if isPanning {
            viewModel.canvasOffset = CGSize(
                width: panStartOffset.width + (value.location.x - dragStartLocation.x),
                height: panStartOffset.height + (value.location.y - dragStartLocation.y)
            )
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        isPanning = false
        isDraggingNode = false
    }

    private func handleHover(phase: HoverPhase) {
        switch phase {
        case .active(let location):
            if !isPanning {
                dragStartLocation = location
            }
        case .ended:
            break
        }
    }

    private func cleanupScrollEventMonitor() {
        if let monitor = scrollEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Canvas Content
    @ViewBuilder
    private var canvasContent: some View {
        ZStack {
            // 배경 그리드 (고정 - 캔버스 이동 시 안움직임)
            GridBackground()

            // 연결선들
            connectionLinesView

            // 챌린지 인포 카드
            challengeInfoCard

            // 마일스톤들
            milestonesView

            // 노드들
            nodesView
        }
    }

    @ViewBuilder
    private var challengeInfoCard: some View {
        let challengePosition = CGPoint(x: 100, y: 100)

        ChallengeInfoCardView(
            project: viewModel.currentProject,
            fontScale: viewModel.fontScale,
            onEdit: {
                // This will be handled by parent ContentView
            }
        )
        .position(
            x: challengePosition.x + viewModel.canvasOffset.width,
            y: challengePosition.y + viewModel.canvasOffset.height
        )
    }

    @ViewBuilder
    private var connectionLinesView: some View {
        let orderedMilestones = viewModel.exploratoryCycle.getOrderedMilestones()

        // 챌린지 인포에서 첫 번째 마일스톤으로 연결선
        if let firstMilestone = orderedMilestones.first {
            challengeToMilestoneConnection(to: firstMilestone)
        }

        // 마일스톤 간 연결선들 (순서에 따라)
        ForEach(0..<max(0, orderedMilestones.count - 1), id: \.self) { index in
            milestoneConnectionLine(from: orderedMilestones[index], to: orderedMilestones[index + 1])
        }

        // 마일스톤-EC 연결선들 및 같은 마일스톤 내 EC 간 연결
        ForEach(viewModel.exploratoryCycle.milestones) { milestone in
            ecConnectionLines(for: milestone)
        }
    }

    @ViewBuilder
    private func challengeToMilestoneConnection(to milestone: Milestone) -> some View {
        let challengePosition = CGPoint(x: 100, y: 100)

        Path { path in
            // 챌린지 카드 우측 하단 (280 width, 약 150 height)
            let startPoint = CGPoint(
                x: challengePosition.x + 140 + viewModel.canvasOffset.width,
                y: challengePosition.y + 75 + viewModel.canvasOffset.height
            )
            let endPoint = CGPoint(
                x: milestone.position.x + viewModel.canvasOffset.width,
                y: milestone.position.y - 20 + viewModel.canvasOffset.height
            )

            path.move(to: startPoint)

            // Curved line
            let controlPoint1 = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * 0.3,
                y: startPoint.y
            )
            let controlPoint2 = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * 0.7,
                y: endPoint.y
            )

            path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(
            Color.yellow.opacity(0.6),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )

        // Arrow head
        Path { path in
            let arrowSize: CGFloat = 10
            let arrowEndPoint = CGPoint(
                x: milestone.position.x + viewModel.canvasOffset.width,
                y: milestone.position.y - 20 + viewModel.canvasOffset.height
            )

            path.move(to: arrowEndPoint)
            path.addLine(to: CGPoint(x: arrowEndPoint.x - arrowSize, y: arrowEndPoint.y - arrowSize))
            path.move(to: arrowEndPoint)
            path.addLine(to: CGPoint(x: arrowEndPoint.x + arrowSize, y: arrowEndPoint.y - arrowSize))
        }
        .stroke(
            Color.yellow.opacity(0.6),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    @ViewBuilder
    private func milestoneConnectionLine(from: Milestone, to: Milestone) -> some View {
        Path { path in
            let startPoint = CGPoint(
                x: from.position.x + viewModel.canvasOffset.width,
                y: from.position.y + 50 + viewModel.canvasOffset.height
            )
            let endPoint = CGPoint(
                x: to.position.x + viewModel.canvasOffset.width,
                y: to.position.y - 20 + viewModel.canvasOffset.height
            )

            path.move(to: startPoint)

            let controlPoint1 = CGPoint(
                x: startPoint.x,
                y: startPoint.y + (endPoint.y - startPoint.y) * 0.3
            )
            let controlPoint2 = CGPoint(
                x: endPoint.x,
                y: startPoint.y + (endPoint.y - startPoint.y) * 0.7
            )

            path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(
            from.phase?.color ?? Color.orange,
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )

        // Arrow head
        Path { path in
            let arrowSize: CGFloat = 10
            let arrowEndPoint = CGPoint(
                x: to.position.x + viewModel.canvasOffset.width,
                y: to.position.y - 20 + viewModel.canvasOffset.height
            )

            path.move(to: arrowEndPoint)
            path.addLine(to: CGPoint(x: arrowEndPoint.x - arrowSize, y: arrowEndPoint.y - arrowSize))
            path.move(to: arrowEndPoint)
            path.addLine(to: CGPoint(x: arrowEndPoint.x + arrowSize, y: arrowEndPoint.y - arrowSize))
        }
        .stroke(
            from.phase?.color ?? Color.orange,
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    @ViewBuilder
    private func ecConnectionLines(for milestone: Milestone) -> some View {
        let linkedECs = viewModel.exploratoryCycle.nodes
            .filter { $0.milestoneId == milestone.id }
            .sorted { $0.sequenceNumber < $1.sequenceNumber }

        // EC 간 연결선 (같은 마일스톤 내)
        if linkedECs.count > 1 {
            ForEach(0..<linkedECs.count - 1, id: \.self) { index in
                Path { path in
                    let startPoint = CGPoint(
                        x: linkedECs[index].position.x + viewModel.canvasOffset.width,
                        y: linkedECs[index].position.y + viewModel.canvasOffset.height
                    )
                    let endPoint = CGPoint(
                        x: linkedECs[index + 1].position.x + viewModel.canvasOffset.width,
                        y: linkedECs[index + 1].position.y + viewModel.canvasOffset.height
                    )

                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(
                    milestone.phase?.color.opacity(0.5) ?? Color.blue.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, dash: [3, 3])
                )
            }
        }

        // 마일스톤에서 EC로의 연결선 (첫 번째 EC만)
        // EC들이 서로 연결되어 있으면, 마일스톤은 첫 번째 EC하고만 연결
        if let firstEC = linkedECs.first {
            Path { path in
                let startPoint = CGPoint(
                    x: milestone.position.x + 110 + viewModel.canvasOffset.width,
                    y: milestone.position.y + viewModel.canvasOffset.height
                )
                let endPoint = CGPoint(
                    x: firstEC.position.x + viewModel.canvasOffset.width,
                    y: firstEC.position.y + viewModel.canvasOffset.height
                )

                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(
                milestone.phase?.color.opacity(0.2) ?? Color.orange.opacity(0.2),
                style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
            )
        }
    }

    @ViewBuilder
    private var milestonesView: some View {
        ForEach(viewModel.exploratoryCycle.milestones) { milestone in
            let linkedECCount = viewModel.exploratoryCycle.nodes.filter { $0.milestoneId == milestone.id }.count
            MilestoneView(
                milestone: milestone,
                isSelected: viewModel.selectedMilestoneId == milestone.id,
                fontScale: viewModel.fontScale,
                linkedECCount: linkedECCount,
                onTap: {
                    viewModel.selectedMilestoneId = milestone.id
                    viewModel.selectedNodeId = nil
                },
                onDoubleClick: {
                    onMilestoneEdit(milestone)
                },
                onDrag: { location in
                    let adjustedLocation = CGPoint(
                        x: location.x - viewModel.canvasOffset.width,
                        y: location.y - viewModel.canvasOffset.height
                    )
                    viewModel.moveMilestone(milestone.id, to: adjustedLocation)
                }
            )
            .offset(x: viewModel.canvasOffset.width, y: viewModel.canvasOffset.height)
        }
    }

    @ViewBuilder
    private var nodesView: some View {
        ForEach(viewModel.exploratoryCycle.nodes) { node in
            NodeView(
                node: node,
                isSelected: viewModel.selectedNodeId == node.id,
                isConnectionMode: viewModel.isConnectionMode,
                fontScale: viewModel.fontScale,
                onTap: {
                    viewModel.selectedNodeId = node.id
                    viewModel.selectedMilestoneId = nil
                },
                onDoubleClick: {
                    onNodeEdit(node)
                },
                onDrag: { location in
                    let adjustedLocation = CGPoint(
                        x: location.x - viewModel.canvasOffset.width,
                        y: location.y - viewModel.canvasOffset.height
                    )
                    viewModel.moveNode(node.id, to: adjustedLocation)
                },
                onConnectionStart: { direction in
                    viewModel.startConnection(from: node.id, direction: direction)
                },
                onConnectionDrag: { location in
                    viewModel.updateConnectionEndPoint(location)
                },
                onConnectionEnd: { location in
                    viewModel.finishConnection(at: location)
                }
            )
            .offset(x: viewModel.canvasOffset.width, y: viewModel.canvasOffset.height)
        }
    }

    // MARK: - Event Handlers
    private func setupScrollEventMonitor() {
        scrollEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            // 다른 창이 열려있으면 스크롤 모니터 비활성화
            // Count visible windows (excluding sheets)
            let visibleWindows = NSApp.windows.filter { $0.isVisible && !$0.isSheet }

            // If there are multiple windows, don't handle scroll events at all
            // This allows other windows to scroll normally
            if visibleWindows.count > 1 {
                return event  // Pass through - let other windows handle scroll
            }

            // Two-finger trackpad scroll (only when main window is alone)
            if event.phase == .began || event.phase == .changed {
                // Invert scroll direction for natural scrolling feel
                viewModel.canvasOffset = CGSize(
                    width: viewModel.canvasOffset.width + event.scrollingDeltaX,
                    height: viewModel.canvasOffset.height + event.scrollingDeltaY
                )
                return nil
            }
            return event
        }
    }
}

struct GridBackground: View {
    var body: some View {
        // 깔끔한 흰 배경 (그리드 제거, 스냅 기능은 ViewModel에서 처리)
        Color.white
    }
}

struct ChallengeInfoCardView: View {
    let project: Project
    let fontScale: CGFloat
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 20 * fontScale))
                    .foregroundColor(.yellow)

                Text("Challenge")
                    .font(.system(size: 16 * fontScale, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18 * fontScale))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Edit Challenge Info")
            }

            Divider()

            // Challenge Name
            Text(project.name)
                .font(.system(size: 18 * fontScale, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)

            // Challenge Statement (if available)
            if !project.challengeStatement.isEmpty {
                Text(project.challengeStatement)
                    .font(.system(size: 12 * fontScale))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            // Duration (if available)
            if !project.duration.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12 * fontScale))
                        .foregroundColor(.orange)
                    Text(project.duration)
                        .font(.system(size: 12 * fontScale))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
        )
    }
}
