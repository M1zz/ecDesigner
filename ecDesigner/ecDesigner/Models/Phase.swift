import Foundation
import SwiftUI

enum Phase: String, Codable, CaseIterable {
    case engage = "Engage"
    case investigate = "Investigate"
    case act = "Act"

    var color: Color {
        switch self {
        case .engage:
            return .blue
        case .investigate:
            return .orange
        case .act:
            return .green
        }
    }

    var icon: String {
        switch self {
        case .engage:
            return "lightbulb.fill"
        case .investigate:
            return "magnifyingglass.circle.fill"
        case .act:
            return "bolt.fill"
        }
    }

    var description: String {
        switch self {
        case .engage:
            return "문제 정의 및 탐색 시작"
        case .investigate:
            return "깊이 있는 조사 및 학습"
        case .act:
            return "실행 및 결과물 생성"
        }
    }
}
