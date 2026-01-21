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
            x: center.x + innerRadius * cos(endAngle.radians),
            y: center.y + innerRadius * sin(endAngle.radians)
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
enum ECSection: CaseIterable, Hashable {
    case guidingQuestions    // Q - 12시~3시
    case guidingActivities   // A - 3시~6시
    case findings            // F - 6시~9시
    case synthesis           // S - 9시~12시

    var startAngle: Angle {
        switch self {
        case .guidingQuestions: return .degrees(-90)  // 12시
        case .guidingActivities: return .degrees(0)   // 3시
        case .findings: return .degrees(90)           // 6시
        case .synthesis: return .degrees(180)         // 9시
        }
    }

    var endAngle: Angle {
        switch self {
        case .guidingQuestions: return .degrees(0)    // 3시
        case .guidingActivities: return .degrees(90)  // 6시
        case .findings: return .degrees(180)          // 9시
        case .synthesis: return .degrees(-90)         // 12시
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
        case .guidingQuestions: return "Q"
        case .guidingActivities: return "A"
        case .findings: return "F"
        case .synthesis: return "S"
        }
    }

    var labelPosition: Angle {
        switch self {
        case .guidingQuestions: return .degrees(-45)
        case .guidingActivities: return .degrees(45)
        case .findings: return .degrees(135)
        case .synthesis: return .degrees(-135)
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
