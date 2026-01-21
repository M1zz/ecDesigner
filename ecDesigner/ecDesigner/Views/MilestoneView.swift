import SwiftUI

struct MilestoneView: View {
    let milestone: Milestone
    let isSelected: Bool
    let fontScale: CGFloat
    let linkedECCount: Int
    let onTap: () -> Void
    let onDoubleClick: () -> Void
    let onDrag: (CGPoint) -> Void

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with flag icon
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14 * fontScale))
                    .foregroundColor(milestone.phase?.color ?? .orange)

                if !milestone.title.isEmpty {
                    Text(milestone.title)
                        .font(.system(size: 13 * fontScale, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                } else {
                    Text("Milestone #\(milestone.sequenceNumber + 1)")
                        .font(.system(size: 13 * fontScale, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }

            // Phase badge if available
            if let phase = milestone.phase {
                HStack(spacing: 4) {
                    Image(systemName: phase.icon)
                        .font(.system(size: 9 * fontScale))
                    Text(phase.rawValue)
                        .font(.system(size: 9 * fontScale, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(phase.color)
                )
            }

            // Description preview if available
            if !milestone.description.isEmpty {
                Text(milestone.description)
                    .font(.system(size: 10 * fontScale))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Divider()
                .padding(.vertical, 4)

            // EC count indicator
            HStack(spacing: 4) {
                Image(systemName: "circle.grid.3x3.fill")
                    .font(.system(size: 9 * fontScale))
                    .foregroundColor(.blue)
                Text("\(linkedECCount) EC\(linkedECCount != 1 ? "s" : "")")
                    .font(.system(size: 10 * fontScale, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .frame(minWidth: 180, maxWidth: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? Color.orange : milestone.phase?.color.opacity(0.3) ?? Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .position(milestone.position)
        .scaleEffect(isDragging ? 1.05 : 1.0)
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
                    }
                    onDrag(value.location)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}
