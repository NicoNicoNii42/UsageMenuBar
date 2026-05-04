import AppKit
import Foundation
import UsageMenuBarCore

@MainActor
final class UsageStore: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case refreshing
        case loaded(Date)
        case failed(String)
        case loginRequired(String)
    }

    @Published private(set) var primary: UsageWindowDisplay?
    @Published private(set) var secondary: UsageWindowDisplay?
    @Published private(set) var planType: String?
    @Published private(set) var state: LoadState = .idle

    private let client = CodexAppServerClient()
    private var pollingTask: Task<Void, Never>?

    var menuBarTitle: String {
        UsageFormatter.menuBarTitle(weekly: secondary)
    }

    var stateText: String {
        switch state {
        case .idle:
            return "Idle"
        case .refreshing:
            return "Refreshing"
        case .loaded(let date):
            return "Updated \(date.formatted(date: .omitted, time: .shortened))"
        case .failed:
            return "Needs attention"
        case .loginRequired:
            return "Login required"
        }
    }

    var errorMessage: String? {
        switch state {
        case .failed(let message), .loginRequired(let message):
            return message
        default:
            return nil
        }
    }

    func start() {
        guard pollingTask == nil else {
            return
        }

        pollingTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await self?.refresh()
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        client.stop()
    }

    func refresh() async {
        state = .refreshing

        do {
            let response = try await client.readRateLimits()
            apply(snapshot: response.codexRateLimits, now: Date())
            state = .loaded(Date())
        } catch {
            let message = error.localizedDescription
            if message.localizedCaseInsensitiveContains("auth") || message.localizedCaseInsensitiveContains("login") {
                state = .loginRequired(message)
            } else {
                state = .failed(message)
            }
        }
    }

    func openCodexLogin() async {
        do {
            let response = try await client.startChatGPTLogin()
            if let authUrl = response.authUrl, let url = URL(string: authUrl) {
                NSWorkspace.shared.open(url)
                state = .loginRequired("Complete the Codex login in your browser, then refresh.")
            } else if let verificationUrl = response.verificationUrl, let url = URL(string: verificationUrl) {
                NSWorkspace.shared.open(url)
                state = .loginRequired("Enter code \(response.userCode ?? "") in your browser, then refresh.")
            } else {
                state = .loginRequired("Codex login started. Complete login, then refresh.")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func apply(snapshot: RateLimitSnapshot, now: Date) {
        planType = snapshot.planType
        primary = snapshot.primary.map {
            UsageFormatter.display(title: "5-Hour Usage", window: $0, now: now)
        }
        secondary = snapshot.secondary.map {
            UsageFormatter.display(title: "7-Day Usage", window: $0, now: now)
        }
    }
}
