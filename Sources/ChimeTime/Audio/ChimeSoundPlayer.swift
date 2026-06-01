import AVFoundation
import Foundation

final class ChimeSoundPlayer {
    private let validSounds: Set<String> = ["gentle", "tick", "wood", "silent"]
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioPlayer: AVAudioPlayer?

    func isValidSound(_ name: String) -> Bool {
        validSounds.contains(name)
    }

    func play(sound: String) {
        guard isValidSound(sound), sound != "silent" else { return }

        let sampleRate: Double = 44100
        let params: (frequency: Double, duration: Double, decayRate: Double, pitchDrop: Double)

        switch sound {
        case "gentle":
            params = (880, 0.3, 5.0, 0)
        case "tick":
            params = (1200, 0.05, 40.0, 0)
        case "wood":
            params = (440, 0.2, 8.0, 20.0)
        default:
            return
        }

        let frameCount = AVAudioFrameCount(sampleRate * params.duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData?[0] else { return }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let freq = params.frequency - params.pitchDrop * t
            let envelope = exp(-params.decayRate * t)
            let sample = sin(2.0 * .pi * freq * t) * envelope
            data[i] = Float(sample)
        }

        let audioEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)

        do {
            try audioEngine.start()
            player.scheduleBuffer(buffer) {
                DispatchQueue.main.async {
                    audioEngine.stop()
                }
            }
            player.play()
            // Keep references alive until playback completes
            self.engine = audioEngine
            self.playerNode = player
        } catch {
            // Audio playback failed silently
        }
    }

    /// Play a sound repeated `count` times with `interval` seconds between each
    func playRepeated(sound: String, count: Int, interval: Double = 0.4) {
        guard count > 0 else { return }
        play(sound: sound)
        guard count > 1 else { return }
        for i in 1..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) { [weak self] in
                self?.play(sound: sound)
            }
        }
    }

    /// Play a custom sound file from a URL
    func playCustomSound(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player
        } catch {
            // Custom sound playback failed
        }
    }
}
