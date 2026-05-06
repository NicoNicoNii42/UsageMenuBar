import SwiftUI
import UsageMenuBarCore

struct UsagePopoverView: View {
    @EnvironmentObject private var store: UsageStore
    @Environment(\.openURL) private var openURL
    private let usageDetailsURL = URL(string: "https://chatgpt.com/codex/cloud/settings/analytics")!

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 10) {
                if let primary = store.primary {
                    UsageCard(display: primary, icon: "clock.fill")
                } else {
                    PlaceholderCard(title: "5-Hour Usage")
                }

                if let secondary = store.secondary {
                    UsageCard(display: secondary, icon: "chart.bar.fill")
                } else {
                    PlaceholderCard(title: "7-Day Usage")
                }
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            footer
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.18))
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text("Codex usage")
                    .font(.system(size: 21, weight: .bold))
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(headerSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                openURL(usageDetailsURL)
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.bordered)
            .help("View detailed usage information")
            .accessibilityLabel("View detailed usage information")
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                Task { await store.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Spacer()

            if case .loginRequired = store.state {
                Button {
                    Task { await store.openCodexLogin() }
                } label: {
                    Label("Login", systemImage: "person.crop.circle.badge.exclamationmark")
                }
                .buttonStyle(.borderedProminent)
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.bordered)
        }
    }

    private var headerSubtitle: String {
        return store.stateText
    }

    private var statusColor: Color {
        switch store.state {
        case .loaded:
            return .mint
        case .refreshing:
            return .blue
        case .failed, .loginRequired:
            return .orange
        case .idle:
            return .secondary
        }
    }
}

private struct UsageCard: View {
    let display: UsageWindowDisplay
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(usageColor)
                Text(sectionTitle)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline) {
                Text(display.title)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(1)
                Spacer()
                StatusPill(status: display.status)
                Text("\(display.remainingPercent)% left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(usageColor)
                    .monospacedDigit()
            }

            ProgressView(value: Double(display.remainingPercent), total: 100)
                .tint(usageColor)

            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundStyle(.secondary)
                Text("Resets in \(display.countdownLong)")
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    if let timePerPercentText {
                        Text(timePerPercentText)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                    Text(timeLeftText)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            .font(.subheadline)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var sectionTitle: String {
        display.title.contains("7-Day") ? "Weekly Limits" : "Current Session"
    }

    private var usageColor: Color {
        guard display.title.contains("7-Day") else {
            return display.status.color
        }

        return UsageThresholdColor.color(for: display.remainingPercent)
    }

    private var timeLeftText: String {
        display.timeLeftPercent.map { "T\($0)%" } ?? "T--"
    }

    private var timePerPercentText: String? {
        display.timePerPercent.map { "1%=\($0)" }
    }
}

private struct PlaceholderCard: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            ProgressView()
                .controlSize(.small)
            Text("Waiting for Codex rate limits")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct StatusPill: View {
    let status: UsageStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var color: Color {
        status.color
    }
}

private extension UsageStatus {
    var color: Color {
        switch self {
        case .good:
            return .mint
        case .caution:
            return .orange
        case .high:
            return .red
        }
    }
}
