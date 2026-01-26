import SwiftUI

struct MilestoneView: View {
    let milestone: Milestone
    let linkedECs: [ECNode]
    let isSelected: Bool
    let selectedNodeId: UUID?
    let fontScale: CGFloat
    let onTap: () -> Void
    let onDoubleClick: () -> Void
    let onDrag: (CGPoint) -> Void
    let onNodeTap: (ECNode) -> Void
    let onNodeDoubleClick: (ECNode) -> Void
    let onNodeDrag: (ECNode, CGPoint) -> Void

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero

    // EC 노드 크기 상수
    private let ecNodeSize: CGFloat = 80
    private let ecSpacing: CGFloat = 24
    private let headerHeight: CGFloat = 90
    private let containerPadding: CGFloat = 20

    // 컨테이너 크기 계산
    private var containerWidth: CGFloat {
        let ecCount = max(linkedECs.count, 1)
        let columns = min(ecCount, 3) // 최대 3열
        return max(340, CGFloat(columns) * (ecNodeSize + ecSpacing) + containerPadding * 2)
    }

    private var containerHeight: CGFloat {
        let ecCount = linkedECs.count
        if ecCount == 0 {
            return headerHeight + 80 // 빈 상태 높이
        }
        let rows = ceil(Double(ecCount) / 3.0)
        return headerHeight + CGFloat(rows) * (ecNodeSize + ecSpacing) + containerPadding + 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더 영역
            milestoneHeader
                .padding(.horizontal, containerPadding)
                .padding(.top, containerPadding)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, containerPadding)

            // EC 노드들이 포함되는 영역
            ecContainer
                .padding(containerPadding)
        }
        .frame(width: containerWidth, height: containerHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(milestone.phase?.color.opacity(0.05) ?? Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Color.orange : milestone.phase?.color.opacity(0.4) ?? Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .position(milestone.position)
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
        .onTapGesture {
            onTap()
        }
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
        .gesture(
            DragGesture(coordinateSpace: .named("canvas"))
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        // 드래그 시작 시 마우스와 객체 중심 간의 오프셋 저장
                        dragOffset = CGSize(
                            width: value.startLocation.x - milestone.position.x,
                            height: value.startLocation.y - milestone.position.y
                        )
                    }
                    // 오프셋을 적용하여 객체가 점프하지 않도록 함
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
        )
    }

    private var milestoneHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // 순서 번호
                Text("#\(milestone.sequenceNumber + 1)")
                    .font(.system(size: 11 * fontScale, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(milestone.phase?.color ?? .orange)
                    )

                // Phase 뱃지
                if let phase = milestone.phase {
                    HStack(spacing: 3) {
                        Image(systemName: phase.icon)
                            .font(.system(size: 9 * fontScale))
                        Text(phase.rawValue)
                            .font(.system(size: 9 * fontScale, weight: .medium))
                    }
                    .foregroundColor(phase.color)
                }

                Spacer()

                // EC 카운트
                Text("\(linkedECs.count) EC")
                    .font(.system(size: 10 * fontScale, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // 타이틀
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14 * fontScale))
                    .foregroundColor(milestone.phase?.color ?? .orange)

                if !milestone.title.isEmpty {
                    Text(milestone.title)
                        .font(.system(size: 14 * fontScale, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                } else {
                    Text("Milestone")
                        .font(.system(size: 14 * fontScale, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var ecContainer: some View {
        Group {
            if linkedECs.isEmpty {
                // 빈 상태
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 24 * fontScale))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("더블클릭하여 EC 추가")
                        .font(.system(size: 11 * fontScale))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // EC 노드들을 그리드로 배치 (3열)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: ecSpacing),
                    GridItem(.flexible(), spacing: ecSpacing),
                    GridItem(.flexible(), spacing: ecSpacing)
                ], spacing: ecSpacing) {
                    ForEach(linkedECs.sorted { $0.sequenceNumber < $1.sequenceNumber }) { node in
                        MiniECNodeView(
                            node: node,
                            isSelected: selectedNodeId == node.id,
                            fontScale: fontScale,
                            onTap: { onNodeTap(node) },
                            onDoubleClick: { onNodeDoubleClick(node) }
                        )
                    }
                }
            }
        }
    }
}

// 마일스톤 내부에 표시되는 작은 도넛 모양 EC 노드 뷰
struct MiniECNodeView: View {
    let node: ECNode
    let isSelected: Bool
    let fontScale: CGFloat
    let onTap: () -> Void
    let onDoubleClick: () -> Void

    private let donutSize: CGFloat = 72
    private let innerRadiusRatio: CGFloat = 0.5
    private let outerRadiusRatio: CGFloat = 0.9

    var body: some View {
        ZStack {
            // 배경 원 (선택 표시용)
            Circle()
                .fill(Color.white)
                .frame(width: donutSize, height: donutSize)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.orange : Color.gray.opacity(0.2), lineWidth: isSelected ? 3 : 1)
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
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                )
            }

            // 중앙에 시퀀스 번호
            VStack(spacing: 0) {
                Text("#\(node.sequenceNumber + 1)")
                    .font(.system(size: 11 * fontScale, weight: .bold))
                    .foregroundColor(.primary)

                if !node.day.isEmpty {
                    Text(node.day)
                        .font(.system(size: 7 * fontScale))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: donutSize, height: donutSize)
        .shadow(color: isSelected ? .orange.opacity(0.3) : .gray.opacity(0.2), radius: isSelected ? 6 : 3)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.2), value: isSelected)
        .onTapGesture {
            onTap()
        }
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
        .help(node.guidingQuestions.isEmpty ? "EC #\(node.sequenceNumber + 1)" : node.guidingQuestions)
    }
}
