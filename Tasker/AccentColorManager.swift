import Cocoa

class AccentColorManager {
    static let shared = AccentColorManager()
    private let accentColorKey = "AppAccentColor"

    var accentColor: NSColor {
        get {
            if let data = UserDefaults.standard.data(forKey: accentColorKey),
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
                return color
            }
            return NSColor.controlAccentColor // Default
        }
        set {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: accentColorKey)
            NotificationCenter.default.post(name: .accentColorChanged, object: newValue)
        }
    }
}
