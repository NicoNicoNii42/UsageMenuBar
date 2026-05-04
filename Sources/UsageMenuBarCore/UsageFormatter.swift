import Foundation

public enum UsageFormatter {
    public static func display(
        title: String,
        window: RateLimitWindow,
        now: Date = Date()
    ) -> UsageWindowDisplay {
        UsageWindowDisplay(
            title: title,
            usedPercent: clampedPercent(window.usedPercent),
            countdownLong: countdown(to: window.resetDate, now: now, compact: false),
            countdownCompact: countdown(to: window.resetDate, now: now, compact: true),
            timeLeftPercent: timeLeftPercent(window: window, now: now),
            status: .from(usedPercent: window.usedPercent)
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

    public static func menuBarTitle(primary: UsageWindowDisplay?) -> String {
        guard let primary else {
            return "Codex --"
        }

        let timePart = primary.timeLeftPercent.map { "T\($0)%" } ?? "T--"
        return "\(primary.usedPercent)% · \(primary.countdownCompact) · \(timePart)"
    }

    private static func clampedPercent(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
