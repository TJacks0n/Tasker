import Cocoa
import Foundation

/// Handles sending bug reports to a backend service.
/// Handles sending bug reports to a backend service.
struct BugReporter {

    // --- Configuration ---
    private let workerURLString: String // Made non-default
    private let session: URLSession // Added session property

    // Internal initializer for testing
    internal init(urlSession: URLSession = .shared, workerURLString: String) {
        self.session = urlSession
        self.workerURLString = workerURLString
    }

    // Default initializer if needed for non-test usage
    init() {
        // Replace with the URL provided by `wrangler deploy`
        self.workerURLString = "https://bug-report-worker.thomasmarkjack.workers.dev"
        self.session = .shared
    }
    
    /// Presents an alert to collect bug report details and then sends them to the backend worker.
    func showReportBugDialog() {
        guard let workerURL = URL(string: workerURLString), workerURLString != "YOUR_CLOUDFLARE_WORKER_URL_HERE" else {
            showErrorAlert(title: "Configuration Error", message: "Cloudflare Worker URL is not configured in BugReporter.swift.")
            return
        }

        // Temporarily activate the app to show the alert.
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Report a Bug"
        alert.informativeText = "Please describe the bug you encountered. This will be sent securely to the developer."
        alert.addButton(withTitle: "Send Report")
        alert.addButton(withTitle: "Cancel")

        // Create a text view for input
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 350, height: 150))
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)

        // Wrap text view in a scroll view
        let scrollview = NSScrollView(frame: NSRect(x: 0, y: 0, width: 350, height: 150))
        scrollview.hasVerticalScroller = true
        scrollview.documentView = textView
        scrollview.borderType = .bezelBorder

        alert.accessoryView = scrollview
        alert.window.initialFirstResponder = textView

        let response = alert.runModal()

        if response == .alertFirstButtonReturn { // "Send Report" clicked
            let bugDescription = textView.string
            if bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showErrorAlert(title: "Empty Report", message: "Please enter a description for the bug report.")
                return
            }
            sendReportToWorker(details: bugDescription, workerURL: workerURL)
        }
    }

    /// Sends the bug report details to the Cloudflare Worker via HTTP POST.
    // Make internal for testing
    internal func sendReportToWorker(details: String, workerURL: URL) {
        // --- Prepare Payload Data ---
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
            // Consider how to handle this in tests - maybe throw or return an error?
            DispatchQueue.main.async {
                self.showErrorAlert(message: "Failed to encode bug report data.")
            }
            return
        }

        // --- Create URLRequest ---
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // --- Send Request ---
        let task = self.session.dataTask(with: request) { data, response, error in
            // Ensure UI updates happen on the main thread
            DispatchQueue.main.async {
                // Handle network errors
                if let error = error {
                    self.showErrorAlert(message: "Failed to send report: \(error.localizedDescription)")
                    return
                }

                // Check HTTP response status
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.showErrorAlert(message: "Invalid response from server.")
                    return
                }

                // Check for successful status codes (e.g., 200 OK, 201 Created)
                guard (200...299).contains(httpResponse.statusCode) else {
                    var errorMessage = "Server returned an error (Status: \(httpResponse.statusCode))."
                    // Optionally try to parse an error message from the response body
                    if let data = data, let serverError = String(data: data, encoding: .utf8) {
                         errorMessage += "\nDetails: \(serverError)"
                    }
                    self.showErrorAlert(message: errorMessage)
                    return
                }

                // Report submitted successfully
                self.showInfoAlert(title: "Report Sent", message: "Thank you! Your bug report has been submitted successfully.")
            }
        }
        task.resume()
    }

    /// Shows a simple informational alert.
    private func showInfoAlert(title: String, message: String) {
        let infoAlert = NSAlert()
        infoAlert.messageText = title
        infoAlert.informativeText = message
        infoAlert.alertStyle = .informational
        infoAlert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true) // Ensure alert is frontmost
        infoAlert.runModal()
    }

    /// Shows a simple error alert.
    private func showErrorAlert(title: String = "Error", message: String) {
        let errorAlert = NSAlert()
        errorAlert.messageText = title
        errorAlert.informativeText = message
        errorAlert.alertStyle = .critical // Use critical for actual errors now
        errorAlert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true) // Ensure alert is frontmost
        errorAlert.runModal()
    }
}

