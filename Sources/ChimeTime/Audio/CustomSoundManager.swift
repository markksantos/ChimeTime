import Foundation
import AppKit

final class CustomSoundManager: ObservableObject {
    @Published private(set) var soundNames: [String] = []

    private let settingsManager: SettingsManager

    private var soundsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ChimeTime/CustomSounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        loadSoundNames()
    }

    /// Show an open panel to pick audio files, then copy them to App Support
    func addSound(completion: @escaping (Bool) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose an audio file to add as a custom chime sound"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self = self else {
                completion(false)
                return
            }
            let name = url.deletingPathExtension().lastPathComponent
            let dest = self.soundsDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: url, to: dest)
                DispatchQueue.main.async {
                    self.soundNames.append(name)
                    self.settingsManager.customSoundNames = self.soundNames
                    completion(true)
                }
            } catch {
                completion(false)
            }
        }
    }

    /// Remove a custom sound by name
    func removeSound(named name: String) {
        // Find and delete the file
        if let files = try? FileManager.default.contentsOfDirectory(at: soundsDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                if file.deletingPathExtension().lastPathComponent == name {
                    try? FileManager.default.removeItem(at: file)
                    break
                }
            }
        }
        soundNames.removeAll { $0 == name }
        settingsManager.customSoundNames = soundNames
        if settingsManager.selectedCustomSound == name {
            settingsManager.selectedCustomSound = ""
        }
    }

    /// Get the file URL for a custom sound by name
    func soundURL(for name: String) -> URL? {
        guard let files = try? FileManager.default.contentsOfDirectory(at: soundsDirectory, includingPropertiesForKeys: nil) else {
            return nil
        }
        return files.first { $0.deletingPathExtension().lastPathComponent == name }
    }

    private func loadSoundNames() {
        soundNames = settingsManager.customSoundNames
    }
}
