//
//  LaunchAtLoginManager.swift
//  Tasker
//
//  Created by Thomas Jackson on 04/06/2025.
//

import Foundation
import ServiceManagement

/// Helper for managing Launch at Login using SMAppService (macOS 13+)
final class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool = false

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        if #available(macOS 13.0, *) {
            isEnabled = (try? SMAppService.mainApp.status == .enabled) ?? false
        } else {
            isEnabled = false
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            isEnabled = enabled
        } catch {
            print("Failed to set launch at login: \(error)")
            isEnabled = false
        }
    }
}
