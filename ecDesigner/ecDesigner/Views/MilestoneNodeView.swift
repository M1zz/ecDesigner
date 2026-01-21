import SwiftUI

struct MilestoneNodeView: View {
    let milestone: Milestone
    let isSelected: Bool
    let fontScale: CGFloat
    let onTap: () -> Void
    let onDoubleClick: () -> Void
    let onDrag: (CGPoint) -> Void
    let onToggleAchieved: () -> Void

    @State private var isDragging = false

    private let nodeSize: CGFloat = 140
    private let tapAreaSize: CGFloat = 200

    var body: some View {
        ZStack {
            // Main Milestone node
            VStack(spacing: 8) {
                // Flag icon with achievement status
                ZStack {
                    // Flag background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(milestone.isAchieved ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(milestone.isAchieved ? Color.green : Color.orange, lineWidth: 3)
                        )
                        .frame(width: nodeSize, height: nodeSize)

                    VStack(spacing: 8) {
                        // Flag icon
                        Image(systemName: "flag.fill")
                            .font(.system(size: 36 * fontScale))
                            .foregroundColor(milestone.isAchieved ? .green : .orange)

                        // Sequence number
                        Text("Milestone #\(milestone.sequenceNumber + 1)")
                            .font(.system(size: 14 * fontScale, weight: .bold))
                            .foregroundColor(.primary)

                        // Title (if exists)
                        if !milestone.title.isEmpty {
                            Text(milestone.title)
                                .font(.system(size: 12 * fontScale, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        // Achievement status icon
                        HStack(spacing: 4) {
                            Image(systemName: milestone.isAchieved ? "checkmark.circle.fill" : "xmark.circle")
                                .font(.system(size: 16 * fontScale))
                                .foregroundColor(milestone.isAchieved ? .green : .gray)

                            Text(milestone.isAchieved ? "Achieved" : "Not Yet")
                                .font(.system(size: 10 * fontScale, weight: .medium))
                                .foregroundColor(milestone.isAchieved ? .green : .gray)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule()
                                .fill(milestone.isAchieved ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                        )
                    }
                }
                .frame(width: nodeSize, height: nodeSize)
                .shadow(color: isSelected ? Color.orange.opacity(0.4) : Color.gray.opacity(0.2), radius: isSelected ? 10 : 5)
            }
            .frame(width: tapAreaSize, height: tapAreaSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(coordinateSpace: .named("canvas"))
                    .onChanged { value in
                        isDragging = true
                        onDrag(value.location)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onTapGesture(count: 2) {
                onDoubleClick()
            }
            .onTapGesture {
                onTap()
            }

            // Quick action button for unachieved milestones
            if !milestone.isAchieved {
                VStack {
                    Spacer()
                    Button(action: {
                        // Will be connected to add EC function
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12 * fontScale))
                            Text("Add EC")
                                .font(.system(size: 10 * fontScale, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .offset(y: 80)
                }
                .frame(width: tapAreaSize, height: tapAreaSize)
            }
        }
        .position(milestone.position)
    }
}

struct MilestoneNodeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)

            HStack(spacing: 100) {
                MilestoneNodeView(
                    milestone: Milestone(
                        title: "First Milestone",
                        sequenceNumber: 0,
                        position: CGPoint(x: 200, y: 200),
                        isAchieved: false
                    ),
                    isSelected: false,
                    fontScale: 1.0,
                    onTap: {},
                    onDoubleClick: {},
                    onDrag: { _ in },
                    onToggleAchieved: {}
                )

                MilestoneNodeView(
                    milestone: Milestone(
                        title: "Completed Goal",
                        sequenceNumber: 1,
                        position: CGPoint(x: 400, y: 200),
                        isAchieved: true
                    ),
                    isSelected: true,
                    fontScale: 1.0,
                    onTap: {},
                    onDoubleClick: {},
                    onDrag: { _ in },
                    onToggleAchieved: {}
                )
            }
        }
        .frame(width: 600, height: 400)
    }
}
