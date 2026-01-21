import SwiftUI

struct ConnectionView: View {
    let from: CGPoint
    let to: CGPoint
    let isTemporary: Bool
    let transitionQuestion: String?
    let fontScale: CGFloat

    init(from: CGPoint, to: CGPoint, isTemporary: Bool, transitionQuestion: String? = nil, fontScale: CGFloat = 1.0) {
        self.from = from
        self.to = to
        self.isTemporary = isTemporary
        self.transitionQuestion = transitionQuestion
        self.fontScale = fontScale
    }

    var body: some View {
        ZStack {
        Path { path in
            path.move(to: from)

            // 베지어 곡선으로 연결
            let controlPoint1 = CGPoint(
                x: from.x + (to.x - from.x) * 0.5,
                y: from.y
            )
            let controlPoint2 = CGPoint(
                x: from.x + (to.x - from.x) * 0.5,
                y: to.y
            )

            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(
            isTemporary ? Color.blue.opacity(0.5) : Color.gray,
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round,
                dash: isTemporary ? [5, 5] : []
            )
        )

            // 화살표
            if !isTemporary {
                arrowHead(at: to, from: from)
            }

            // "What if?" transition question label
            if let question = transitionQuestion, !question.isEmpty {
                let midPoint = CGPoint(
                    x: (from.x + to.x) / 2,
                    y: (from.y + to.y) / 2
                )

                Text(question)
                    .font(.system(size: 10 * fontScale))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                    )
                    .position(midPoint)
            }
        }
    }

    private func arrowHead(at point: CGPoint, from startPoint: CGPoint) -> some View {
        let angle = atan2(point.y - startPoint.y, point.x - startPoint.x)
        let arrowLength: CGFloat = 10
        let arrowAngle: CGFloat = .pi / 6

        return Path { path in
            let point1 = CGPoint(
                x: point.x - arrowLength * cos(angle - arrowAngle),
                y: point.y - arrowLength * sin(angle - arrowAngle)
            )
            let point2 = CGPoint(
                x: point.x - arrowLength * cos(angle + arrowAngle),
                y: point.y - arrowLength * sin(angle + arrowAngle)
            )

            path.move(to: point1)
            path.addLine(to: point)
            path.addLine(to: point2)
        }
        .stroke(Color.gray, lineWidth: 2)
    }
}
