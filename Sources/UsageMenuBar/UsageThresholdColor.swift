import SwiftUI

enum UsageThresholdColor {
    static func color(for remainingPercent: Int?) -> Color {
        guard let remainingPercent else {
            return .primary
        }

        switch remainingPercent {
        case ..<10:
            return .red
        case ..<33:
            return .orange
        default:
            return .mint
        }
    }
}
