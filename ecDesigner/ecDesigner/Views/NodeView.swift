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
    let onDelete: () -> Void

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero

    private let donutSize: CGFloat = 120
    private let tapAreaSize: CGFloat = 200  // Much larger tap area for easier selection
    private let innerRadiusRatio: CGFloat = 0.5
    private let outerRadiusRatio: CGFloat = 0.9

    var body: some View {
        ZStack {
            donutNodeView
                .gesture(dragGesture)
                .onTapGesture(count: 2, perform: handleDoubleTap)
                .onTapGesture(perform: handleTap)

            if isConnectionMode {
                connectionAnchors
            }
        }
        .contextMenu {
            Button(action: onDoubleClick) {
                Label("Edit EC", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete EC", systemImage: "trash")
            }
        }
        .position(node.position)
    }

    private var donutNodeView: some View {
        ZStack {
            backgroundCircle
            donutSegments
            centerLabel
            sectionLabels
        }
        .frame(width: donutSize, height: donutSize)
        .shadow(color: shadowColor, radius: shadowRadius)
        .frame(width: tapAreaSize, height: tapAreaSize)
        .contentShape(Circle())
    }

    private var backgroundCircle: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: donutSize, height: donutSize)
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
    }

    private var donutSegments: some View {
        ForEach(ECSection.allCases, id: \.self) { section in
            let fillColor = section.isFilled(for: node) ? section.color : Color.gray.opacity(0.2)
            let innerR = donutSize * innerRadiusRatio / 2
            let outerR = donutSize * outerRadiusRatio / 2

            DonutSegmentShape(
                startAngle: section.startAngle,
                endAngle: section.endAngle,
                innerRadius: innerR,
                outerRadius: outerR
            )
            .fill(fillColor)
            .overlay(
                DonutSegmentShape(
                    startAngle: section.startAngle,
                    endAngle: section.endAngle,
                    innerRadius: innerR,
                    outerRadius: outerR
                )
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var centerLabel: some View {
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

            if node.milestoneId != nil {
                Image(systemName: "target")
                    .font(.system(size: 10 * fontScale))
                    .foregroundColor(.orange)
            }
        }
    }

    private var sectionLabels: some View {
        ForEach(ECSection.allCases, id: \.self) { section in
            Text(section.label)
                .font(.system(size: 12 * fontScale, weight: .bold))
                .foregroundColor(.white)
                .offset(labelOffset(for: section))
        }
    }

    private var connectionAnchors: some View {
        ForEach([AnchorDirection.top, .bottom, .left, .right], id: \.self) { direction in
            ConnectionAnchor(
                direction: direction,
                isActive: false,
                onDragStart: { onConnectionStart(direction) },
                onDragChanged: { location in onConnectionDrag(location) },
                onDragEnd: { location in onConnectionEnd(location) }
            )
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragOffset = CGSize(
                        width: value.startLocation.x - node.position.x,
                        height: value.startLocation.y - node.position.y
                    )
                }
                let newPosition = CGPoint(
                    x: value.location.x - dragOffset.width,
                    y: value.location.y - dragOffset.height
                )
                onDrag(newPosition)
            }
            .onEnded { _ in
                isDragging = false
                dragOffset = .zero
            }
    }

    private var strokeColor: Color {
        isSelected ? Color.blue : Color.gray.opacity(0.3)
    }

    private var strokeWidth: CGFloat {
        isSelected ? 3 : 1
    }

    private var shadowColor: Color {
        isSelected ? .blue.opacity(0.3) : .gray.opacity(0.2)
    }

    private var shadowRadius: CGFloat {
        isSelected ? 8 : 4
    }

    private func handleDoubleTap() {
        if !isConnectionMode {
            onDoubleClick()
        }
    }

    private func handleTap() {
        if !isConnectionMode {
            onTap()
        }
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
            onConnectionEnd: { _ in },
            onDelete: {}
        )
        .frame(width: 400, height: 400)
        .background(Color.gray.opacity(0.1))
    }
}
