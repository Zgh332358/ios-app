import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings

    private let storage: KeyValueStorage

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    init(storage: KeyValueStorage = UserDefaultsStorage()) {
        self.storage = storage
        if let data = storage.data(forKey: WebAppConfiguration.settingsKey),
           let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = savedSettings
        } else {
            self.settings = .default
        }
    }

    func setEndpoint(_ endpoint: String?) {
        let trimmed = endpoint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        settings.endpoint = trimmed.isEmpty ? nil : trimmed
        if let data = try? JSONEncoder().encode(settings) {
            storage.set(data, forKey: WebAppConfiguration.settingsKey)
        }
    }
}
