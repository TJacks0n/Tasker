import Cocoa
import Foundation

/// Handles sending bug reports to a backend service.
struct BugReporter {

    // --- Configuration ---
    private let workerURLString: String
    private let session: URLSession

    // Internal initializer for testing
    internal init(urlSession: URLSession = .shared, workerURLString: String) {
        self.session = urlSession
        self.workerURLString = workerURLString
    }

    // Default initializer if needed for non-test usage
    init() {
        // IMPORTANT: Replace with your actual Cloudflare Worker URL
        self.workerURLString = "https://bug-report-worker.thomasmarkjack.workers.dev"
        self.session = .shared
    }

    /// Presents an alert modally to collect bug report details and then sends them.
    /// Assumes it's called from the main thread (e.g., menu action).
    func showReportBugDialog() {
        NSApp.activate(ignoringOtherApps: true)

        guard let workerURL = URL(string: workerURLString), workerURLString != "YOUR_CLOUDFLARE_WORKER_URL_HERE" else {
            self.showErrorAlert(title: "Configuration Error", message: "Cloudflare Worker URL is not configured in BugReporter.swift.")
            return
        }

        let alert = NSAlert()
        alert.messageText = "Report a Bug"
        alert.informativeText = "Please describe the bug you encountered. This will be sent securely to the developer."
        alert.addButton(withTitle: "Send Report")
        alert.addButton(withTitle: "Cancel")

        // --- Text View Setup ---
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 350, height: 150))
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.setAccessibilityIdentifier("bugDescriptionTextView")

        // Style the text view for translucency and rounded corners
        textView.drawsBackground = true // Need to draw background to show the color
        textView.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.7) // Translucent background
        textView.insertionPointColor = NSColor.textColor // Ensure cursor is visible
        textView.wantsLayer = true // Enable layer for rounded corners
        textView.layer?.cornerRadius = 6.0 // Set corner radius
        textView.layer?.masksToBounds = true // Clip content to rounded corners

        // --- Scroll View Setup ---
        let scrollview = NSScrollView(frame: NSRect(x: 0, y: 0, width: 350, height: 150))
        scrollview.hasVerticalScroller = true
        scrollview.documentView = textView
        scrollview.borderType = .noBorder // Remove the scroll view's border
        scrollview.drawsBackground = false // Keep scroll view background clear

        alert.accessoryView = scrollview
        alert.window.initialFirstResponder = textView

        // *** Explicitly set the accessibility identifier for the alert's window ***
        alert.window.setAccessibilityIdentifier("Report a Bug") // Match UI test identifier

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let bugDescription = textView.string
            if bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.showErrorAlert(title: "Empty Report", message: "Please enter a description for the bug report.")
            } else {
                self.sendReportToWorker(details: bugDescription, workerURL: workerURL)
            }
        }
    }

    /// Sends the bug report details to the Cloudflare Worker via HTTP POST.
    internal func sendReportToWorker(details: String, workerURL: URL) {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Tasker"
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let buildString = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "N/A"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        let payload: [String: String] = [
            "description": details,
            "appName": appName,
            "appVersion": versionString,
            "buildNumber": buildString,
            "osVersion": osVersion
        ]

        guard let jsonData = try? JSONEncoder().encode(payload) else {
            self.showErrorAlert(title: "Encoding Error", message: "Failed to encode bug report data.")
            return
        }

        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = self.session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showErrorAlert(title: "Network Error", message: "Failed to send report: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.showErrorAlert(title: "Server Response Error", message: "Invalid response from server.")
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    var errorMessage = "Server returned an error (Status: \(httpResponse.statusCode))."
                    if let data = data, let serverError = String(data: data, encoding: .utf8) {
                         errorMessage += "\nDetails: \(serverError)"
                    }
                    self.showErrorAlert(title: "Server Error", message: errorMessage)
                    return
                }

                self.showInfoAlert(title: "Report Sent", message: "Thank you! Your bug report has been submitted successfully.")
            }
        }
        task.resume()
    }

    /// Shows a simple informational alert modally. Ensures it runs on the main thread.
    private func showInfoAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let infoAlert = NSAlert()
            infoAlert.messageText = title
            infoAlert.informativeText = message
            infoAlert.alertStyle = .informational
            infoAlert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)

            // *** Explicitly set the accessibility identifier for the alert's window ***
            infoAlert.window.setAccessibilityIdentifier("Report Sent") // Match UI test identifier

            infoAlert.runModal()
        }
    }

    /// Shows a simple error alert modally. Ensures it runs on the main thread.
    private func showErrorAlert(title: String = "Error", message: String) {
        DispatchQueue.main.async {
            let errorAlert = NSAlert()
            errorAlert.messageText = title
            errorAlert.informativeText = message
            errorAlert.alertStyle = .critical
            errorAlert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)

            // *** Explicitly set the accessibility identifier for the alert's window ***
            // Use a generic identifier unless specific error types need differentiation
            errorAlert.window.setAccessibilityIdentifier("Error") // Match UI test identifier

            errorAlert.runModal()
        }
    }
}
