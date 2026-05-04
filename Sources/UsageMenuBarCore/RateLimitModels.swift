import Foundation

public struct GetAccountRateLimitsResponse: Decodable, Equatable {
    public let rateLimits: RateLimitSnapshot
    public let rateLimitsByLimitId: [String: RateLimitSnapshot]?

    public var codexRateLimits: RateLimitSnapshot {
        rateLimitsByLimitId?["codex"] ?? rateLimits
    }
}

public struct RateLimitSnapshot: Decodable, Equatable {
    public let limitId: String?
    public let limitName: String?
    public let planType: String?
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?
    public let rateLimitReachedType: String?
    public let credits: CreditsSnapshot?
}

public struct CreditsSnapshot: Decodable, Equatable {
    public let balance: String?
    public let hasCredits: Bool
    public let unlimited: Bool
}

public struct RateLimitWindow: Decodable, Equatable {
    public let resetsAt: Int64?
    public let usedPercent: Int
    public let windowDurationMins: Int64?

    public init(resetsAt: Int64?, usedPercent: Int, windowDurationMins: Int64?) {
        self.resetsAt = resetsAt
        self.usedPercent = usedPercent
        self.windowDurationMins = windowDurationMins
    }

    public var resetDate: Date? {
        resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }
}

public struct UsageWindowDisplay: Equatable {
    public let title: String
    public let usedPercent: Int
    public let remainingPercent: Int
    public let countdownLong: String
    public let countdownCompact: String
    public let timeLeftPercent: Int?
    public let status: UsageStatus

    public init(
        title: String,
        usedPercent: Int,
        remainingPercent: Int,
        countdownLong: String,
        countdownCompact: String,
        timeLeftPercent: Int?,
        status: UsageStatus
    ) {
        self.title = title
        self.usedPercent = usedPercent
        self.remainingPercent = remainingPercent
        self.countdownLong = countdownLong
        self.countdownCompact = countdownCompact
        self.timeLeftPercent = timeLeftPercent
        self.status = status
    }
}

public enum UsageStatus: String, Equatable {
    case good = "Good"
    case caution = "Caution"
    case high = "High"

    public static func from(usedPercent: Int) -> UsageStatus {
        switch usedPercent {
        case 0..<60:
            return .good
        case 60..<85:
            return .caution
        default:
            return .high
        }
    }
}
