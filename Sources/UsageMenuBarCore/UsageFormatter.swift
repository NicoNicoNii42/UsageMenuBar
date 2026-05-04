import Foundation

public enum UsageFormatter {
    public static func display(
        title: String,
        window: RateLimitWindow,
        now: Date = Date()
    ) -> UsageWindowDisplay {
        let usedPercent = clampedPercent(window.usedPercent)
        return UsageWindowDisplay(
            title: title,
            usedPercent: usedPercent,
            remainingPercent: remainingPercent(usedPercent: usedPercent),
            countdownLong: countdown(to: window.resetDate, now: now, compact: false),
            countdownCompact: countdown(to: window.resetDate, now: now, compact: true),
            timeLeftPercent: timeLeftPercent(window: window, now: now),
            timePerPercent: timePerPercent(window: window),
            status: .from(usedPercent: usedPercent)
        )
    }

    public static func timeLeftPercent(window: RateLimitWindow, now: Date = Date()) -> Int? {
        guard
            let resetDate = window.resetDate,
            let durationMinutes = window.windowDurationMins,
            durationMinutes > 0
        else {
            return nil
        }

        let secondsLeft = resetDate.timeIntervalSince(now)
        let windowSeconds = TimeInterval(durationMinutes * 60)
        let percent = (secondsLeft / windowSeconds) * 100
        return clampedPercent(Int(percent.rounded()))
    }

    public static func timePerPercent(window: RateLimitWindow) -> String? {
        guard
            let durationMinutes = window.windowDurationMins,
            durationMinutes > 0
        else {
            return nil
        }

        let seconds = Int((Double(durationMinutes) * 60 / 100).rounded())
        return duration(seconds)
    }

    public static func countdown(to resetDate: Date?, now: Date = Date(), compact: Bool) -> String {
        guard let resetDate else {
            return compact ? "--" : "Unknown"
        }

        let seconds = max(0, Int(resetDate.timeIntervalSince(now).rounded()))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        if days > 0 {
            return compact ? "\(days)d\(hours)h" : "\(days)d \(hours)h"
        }

        if hours > 0 {
            return compact ? "\(hours)h\(minutes)m" : "\(hours)h \(minutes)m"
        }

        return compact ? "\(minutes)m" : "\(minutes)m"
    }

    private static func duration(_ seconds: Int) -> String {
        let seconds = max(0, seconds)
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60
        var parts: [String] = []

        if days > 0 {
            parts.append("\(days)d")
        }

        if hours > 0 {
            parts.append("\(hours)h")
        }

        if minutes > 0 {
            parts.append("\(minutes)m")
        }

        if remainingSeconds > 0 || parts.isEmpty {
            parts.append("\(remainingSeconds)s")
        }

        return parts.joined(separator: " ")
    }

    public static func remainingPercent(usedPercent: Int) -> Int {
        clampedPercent(100 - usedPercent)
    }

    public static func menuBarTitle(weekly: UsageWindowDisplay?) -> String {
        guard let weekly else {
            return "--% | T--"
        }

        let timePart = weekly.timeLeftPercent.map { "T\($0)%" } ?? "T--"
        return "\(weekly.remainingPercent)% | \(timePart)"
    }

    private static func clampedPercent(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
