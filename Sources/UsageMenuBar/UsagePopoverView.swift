import SwiftUI
import UsageMenuBarCore

struct UsagePopoverView: View {
    @EnvironmentObject private var store: UsageStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 10) {
                if let primary = store.primary {
                    UsageCard(display: primary, tint: .mint, icon: "clock.fill")
                } else {
                    PlaceholderCard(title: "5-Hour Usage")
                }

                if let secondary = store.secondary {
                    UsageCard(display: secondary, tint: .orange, icon: "calendar")
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
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text("CUStats")
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
        if let planType = store.planType {
            return "\(planType) · \(store.stateText)"
        }
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
    let tint: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
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
                Text("\(display.usedPercent)%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }

            ProgressView(value: Double(display.usedPercent), total: 100)
                .tint(tint)

            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundStyle(.secondary)
                Text("Resets in \(display.countdownLong)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timeLeftText)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
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

    private var timeLeftText: String {
        display.timeLeftPercent.map { "T\($0)%" } ?? "T--"
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
        switch status {
        case .good:
            return .mint
        case .caution:
            return .orange
        case .high:
            return .red
        }
    }
}
