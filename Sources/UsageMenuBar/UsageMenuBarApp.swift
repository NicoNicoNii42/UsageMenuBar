import SwiftUI

@main
struct UsageMenuBarApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView()
                .environmentObject(store)
                .frame(width: 390)
                .onAppear {
                    store.start()
                }
        } label: {
            Text(store.menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
