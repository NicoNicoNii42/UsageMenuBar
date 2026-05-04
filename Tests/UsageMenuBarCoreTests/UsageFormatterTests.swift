import Foundation
import Testing
@testable import UsageMenuBarCore

@Test func timeLeftPercentUsesResetAndWindowDuration() {
    let now = Date(timeIntervalSince1970: 1_000)
    let window = RateLimitWindow(
        resetsAt: 1_000 + (3 * 3_600),
        usedPercent: 42,
        windowDurationMins: 300
    )

    #expect(UsageFormatter.timeLeftPercent(window: window, now: now) == 60)
}

@Test func timePerPercentFormatsWindowDuration() {
    let fiveHourWindow = RateLimitWindow(resetsAt: nil, usedPercent: 42, windowDurationMins: 300)
    let weeklyWindow = RateLimitWindow(resetsAt: nil, usedPercent: 42, windowDurationMins: 10_080)

    #expect(UsageFormatter.timePerPercent(window: fiveHourWindow) == "3m")
    #expect(UsageFormatter.timePerPercent(window: weeklyWindow) == "1h 40m 48s")
}

@Test func countdownFormatsDaysHoursAndCompactHoursMinutes() {
    let now = Date(timeIntervalSince1970: 0)
    let reset = Date(timeIntervalSince1970: 93_600)

    #expect(UsageFormatter.countdown(to: reset, now: now, compact: false) == "1d 2h")
    #expect(UsageFormatter.countdown(to: reset, now: now, compact: true) == "1d2h")
}

@Test func displayInvertsUsageIntoRemainingPercent() {
    let display = UsageFormatter.display(
        title: "7-Day Usage",
        window: RateLimitWindow(resetsAt: nil, usedPercent: 67, windowDurationMins: nil)
    )

    #expect(display.usedPercent == 67)
    #expect(display.remainingPercent == 33)
    #expect(display.timePerPercent == nil)
}

@Test func menuBarTitleUsesWeeklyUsageLeftAndTimeLeft() {
    let display = UsageWindowDisplay(
        title: "7-Day Usage",
        usedPercent: 67,
        remainingPercent: 33,
        countdownLong: "1h 47m",
        countdownCompact: "1h47m",
        timeLeftPercent: 36,
        status: .good
    )

    #expect(UsageFormatter.menuBarTitle(weekly: display) == "33% | T36%")
}

@Test func rateLimitResponsePrefersCodexBucket() throws {
    let json = """
    {
      "rateLimits": {
        "limitId": "default",
        "planType": "prolite",
        "primary": { "usedPercent": 99, "resetsAt": 1777901886, "windowDurationMins": 300 },
        "secondary": { "usedPercent": 88, "resetsAt": 1777972600, "windowDurationMins": 10080 }
      },
      "rateLimitsByLimitId": {
        "codex": {
          "limitId": "codex",
          "limitName": "Codex",
          "planType": "prolite",
          "primary": { "usedPercent": 3, "resetsAt": 1777901886, "windowDurationMins": 300 },
          "secondary": { "usedPercent": 59, "resetsAt": 1777972600, "windowDurationMins": 10080 }
        }
      }
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder().decode(GetAccountRateLimitsResponse.self, from: json)

    #expect(response.codexRateLimits.limitId == "codex")
    #expect(response.codexRateLimits.primary?.usedPercent == 3)
    #expect(response.codexRateLimits.secondary?.usedPercent == 59)
}
