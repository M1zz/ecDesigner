import SwiftUI

// 도넛의 한 섹션을 그리는 Shape
struct DonutSegmentShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // 외부 호
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        // 끝점에서 내부 호로 선 연결
        let endPoint = CGPoint(
            x: center.x + innerRadius * CGFloat(cos(endAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(endAngle.radians))
        )
        path.addLine(to: endPoint)

        // 내부 호 (역방향)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}

// EC 구성 요소별 섹션 정보
// "The synthesis leads to or represents a milestone"
enum ECSection: CaseIterable, Hashable {
    case guidingQuestions    // GQ - 9시~12시 (What needs to be learned?)
    case guidingActivities   // GA - 12시~3시 (How will we learn it?)
    case findings            // Fi - 3시~6시 (What did we learn?)
    case synthesis           // Mi - 6시~9시 (Synthesis → Milestone)

    var startAngle: Angle {
        switch self {
        case .guidingQuestions: return .degrees(180)  // 9시
        case .guidingActivities: return .degrees(-90) // 12시
        case .findings: return .degrees(0)            // 3시
        case .synthesis: return .degrees(90)          // 6시
        }
    }

    var endAngle: Angle {
        switch self {
        case .guidingQuestions: return .degrees(-90)  // 12시
        case .guidingActivities: return .degrees(0)   // 3시
        case .findings: return .degrees(90)           // 6시
        case .synthesis: return .degrees(180)         // 9시
        }
    }

    var color: Color {
        switch self {
        case .guidingQuestions: return .blue
        case .guidingActivities: return .green
        case .findings: return .yellow
        case .synthesis: return .purple
        }
    }

    var label: String {
        switch self {
        case .guidingQuestions: return "GQ"
        case .guidingActivities: return "GA"
        case .findings: return "Fi"
        case .synthesis: return "Mi"  // Synthesis leads to/represents Milestone
        }
    }

    var labelPosition: Angle {
        switch self {
        case .guidingQuestions: return .degrees(-135)  // 9시~12시 중앙
        case .guidingActivities: return .degrees(-45)  // 12시~3시 중앙
        case .findings: return .degrees(45)            // 3시~6시 중앙
        case .synthesis: return .degrees(135)          // 6시~9시 중앙
        }
    }

    func isFilled(for node: ECNode) -> Bool {
        switch self {
        case .guidingQuestions: return !node.guidingQuestions.isEmpty
        case .guidingActivities: return !node.guidingActivities.isEmpty
        case .findings: return !node.findings.isEmpty
        case .synthesis: return !node.synthesis.isEmpty
        }
    }
}

struct ConnectionAnchor: View {
    let direction: AnchorDirection
    let isActive: Bool
    let onDragStart: () -> Void
    let onDragChanged: (CGPoint) -> Void
    let onDragEnd: (CGPoint) -> Void

    var body: some View {
        Circle()
            .fill(isActive ? Color.blue : Color.gray)
            .frame(width: 12, height: 12)
            .overlay(
                Image(systemName: arrowIcon)
                    .font(.system(size: 6))
                    .foregroundColor(.white)
            )
            .offset(anchorOffset)
            .gesture(
                DragGesture(coordinateSpace: .named("canvas"))
                    .onChanged { value in
                        if !isActive {
                            onDragStart()
                        }
                        onDragChanged(value.location)
                    }
                    .onEnded { value in
                        onDragEnd(value.location)
                    }
            )
    }

    private var arrowIcon: String {
        switch direction {
        case .top: return "arrow.up"
        case .bottom: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }

    private var anchorOffset: CGSize {
        switch direction {
        case .top: return CGSize(width: 0, height: -70)
        case .bottom: return CGSize(width: 0, height: 70)
        case .left: return CGSize(width: -70, height: 0)
        case .right: return CGSize(width: 70, height: 0)
        }
    }
}

struct NodeView: View {
    let node: ECNode
    let isSelected: Bool
    let isConnectionMode: Bool
    let fontScale: CGFloat
    let onTap: () -> Void
    let onDoubleClick: () -> Void
    let onDrag: (CGPoint) -> Void
    let onConnectionStart: (AnchorDirection) -> Void
    let onConnectionDrag: (CGPoint) -> Void
    let onConnectionEnd: (CGPoint) -> Void

    @State private var isDragging = false

    private let donutSize: CGFloat = 120
    private let tapAreaSize: CGFloat = 200  // Much larger tap area for easier selection
    private let innerRadiusRatio: CGFloat = 0.5
    private let outerRadiusRatio: CGFloat = 0.9

    var body: some View {
        ZStack {
            // 도넛 모양의 EC 노드
            ZStack {
                // 배경 원 (선택 표시용)
                Circle()
                    .fill(Color.clear)
                    .frame(width: donutSize, height: donutSize)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )

                // 4개의 도넛 섹션
                ForEach(ECSection.allCases, id: \.self) { section in
                    DonutSegmentShape(
                        startAngle: section.startAngle,
                        endAngle: section.endAngle,
                        innerRadius: donutSize * innerRadiusRatio / 2,
                        outerRadius: donutSize * outerRadiusRatio / 2
                    )
                    .fill(section.isFilled(for: node) ? section.color : Color.gray.opacity(0.2))
                    .overlay(
                        DonutSegmentShape(
                            startAngle: section.startAngle,
                            endAngle: section.endAngle,
                            innerRadius: donutSize * innerRadiusRatio / 2,
                            outerRadius: donutSize * outerRadiusRatio / 2
                        )
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }

                // 중앙에 시퀀스 번호 및 기간
                VStack(spacing: 2) {
                    Text("EC")
                        .font(.system(size: 10 * fontScale))
                        .foregroundColor(.secondary)
                    Text("#\(node.sequenceNumber + 1)")
                        .font(.system(size: 16 * fontScale, weight: .bold))
                        .foregroundColor(.primary)

                    if !node.duration.isEmpty {
                        Text(node.duration)
                            .font(.system(size: 8 * fontScale))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Show target icon if linked to milestone
                    if node.milestoneId != nil {
                        Image(systemName: "target")
                            .font(.system(size: 10 * fontScale))
                            .foregroundColor(.orange)
                    }
                }

                // 각 섹션 라벨
                ForEach(ECSection.allCases, id: \.self) { section in
                    Text(section.label)
                        .font(.system(size: 12 * fontScale, weight: .bold))
                        .foregroundColor(.white)
                        .offset(labelOffset(for: section))
                }
            }
            .frame(width: donutSize, height: donutSize)
            .shadow(color: isSelected ? .blue.opacity(0.3) : .gray.opacity(0.2), radius: isSelected ? 8 : 4)
            .frame(width: tapAreaSize, height: tapAreaSize)
            .contentShape(Circle())
            .gesture(
                isConnectionMode ? nil : DragGesture(coordinateSpace: .named("canvas"))
                    .onChanged { value in
                        isDragging = true
                        onDrag(value.location)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onTapGesture(count: 2) {
                // 더블클릭으로 편집
                if !isConnectionMode {
                    onDoubleClick()
                }
            }
            .onTapGesture {
                if !isConnectionMode {
                    onTap()
                }
            }

            // 연결 모드일 때만 표시되는 네 방향 화살표
            if isConnectionMode {
                ForEach([AnchorDirection.top, .bottom, .left, .right], id: \.self) { direction in
                    ConnectionAnchor(
                        direction: direction,
                        isActive: false,
                        onDragStart: {
                            onConnectionStart(direction)
                        },
                        onDragChanged: { location in
                            onConnectionDrag(location)
                        },
                        onDragEnd: { location in
                            onConnectionEnd(location)
                        }
                    )
                }
            }
        }
        .position(node.position)
    }

    private func labelOffset(for section: ECSection) -> CGSize {
        let angle = section.labelPosition.radians
        let radius = donutSize * 0.7 / 2
        return CGSize(
            width: radius * CGFloat(cos(angle)),
            height: radius * CGFloat(sin(angle))
        )
    }
}

struct NodeView_Previews: PreviewProvider {
    static var previews: some View {
        NodeView(
            node: ECNode(
                position: CGPoint(x: 200, y: 200),
                sequenceNumber: 0,
                guidingQuestions: "Test question",
                guidingActivities: "Test activities",
                findings: "Test findings"
            ),
            isSelected: false,
            isConnectionMode: false,
            fontScale: 1.0,
            onTap: {},
            onDoubleClick: {},
            onDrag: { _ in },
            onConnectionStart: { _ in },
            onConnectionDrag: { _ in },
            onConnectionEnd: { _ in }
        )
        .frame(width: 400, height: 400)
        .background(Color.gray.opacity(0.1))
    }
}
