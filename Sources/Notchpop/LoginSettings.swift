import AppKit
import ServiceManagement
import SwiftUI

struct LoginSettings: View {
    @State private var status = SMAppService.mainApp.status
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Launch at login", isOn: Binding(
                get: { status == .enabled || status == .requiresApproval },
                set: { enabled in
                    error = nil
                    do {
                        if enabled { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                    } catch {
                        self.error = "Couldn’t update launch at login: \(error.localizedDescription)"
                    }
                    status = SMAppService.mainApp.status
                }
            ))
            if status == .requiresApproval {
                Text("Allow Notchpop in Login Items to finish enabling automatic launch.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if status == .requiresApproval || error != nil {
                Button("Open Login Items Settings") { SMAppService.openSystemSettingsLoginItems() }
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .onAppear { status = SMAppService.mainApp.status }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            status = SMAppService.mainApp.status
        }
    }
}
