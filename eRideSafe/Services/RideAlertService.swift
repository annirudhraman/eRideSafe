import AVFoundation
import CoreHaptics
import SwiftUI
import UIKit

enum RideAlertEvent {
    case zoneChange
    case speedLimit
    case suddenMotion
    case preview

    fileprivate var hapticPulses: [(time: TimeInterval, intensity: Float, sharpness: Float)] {
        switch self {
        case .zoneChange:
            [(0, 0.55, 0.45), (0.18, 0.7, 0.6)]
        case .speedLimit:
            [(0, 1, 0.9), (0.17, 1, 0.9), (0.34, 1, 0.9)]
        case .suddenMotion:
            [(0, 0.85, 0.8), (0.13, 0.95, 0.9)]
        case .preview:
            [(0, 0.7, 0.55), (0.18, 0.9, 0.75)]
        }
    }
}

@MainActor
final class RideAlertService: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let audioPlayer = AVAudioPlayerNode()
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var hapticEngine: CHHapticEngine?

    init() {
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: audioFormat)
        prepareHaptics()
    }

    func play(_ event: RideAlertEvent, mode: RideAlertMode, sound: RideAlertSound) {
        if mode.usesHaptics {
            playHaptics(for: event)
        }
        if mode.usesSound {
            playSound(sound)
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            hapticEngine = nil
        }
    }

    private func playHaptics(for event: RideAlertEvent) {
        guard let hapticEngine else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        let events = event.hapticPulses.map { pulse in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: pulse.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: pulse.sharpness)
                ],
                relativeTime: pulse.time
            )
        }

        do {
            try hapticEngine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try hapticEngine.makePlayer(with: pattern).start(atTime: 0)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    private func playSound(_ sound: RideAlertSound) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            if !audioEngine.isRunning {
                try audioEngine.start()
            }

            audioPlayer.stop()
            audioPlayer.scheduleBuffer(makeBuffer(for: sound), at: nil, options: .interrupts)
            audioPlayer.play()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    private func makeBuffer(for sound: RideAlertSound) -> AVAudioPCMBuffer {
        let tones: [(frequency: Double, duration: Double, gap: Double)]
        switch sound {
        case .chime:
            tones = [(659, 0.14, 0.04), (988, 0.24, 0)]
        case .pulse:
            tones = [(440, 0.1, 0.08), (440, 0.1, 0.08), (660, 0.14, 0)]
        case .urgent:
            tones = [(880, 0.11, 0.05), (740, 0.11, 0.05), (880, 0.18, 0)]
        }

        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(tones.reduce(0) { $0 + $1.duration + $1.gap } * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let samples = buffer.floatChannelData?[0] else { return buffer }
        for frame in 0..<Int(frameCount) {
            samples[frame] = 0
        }

        var startFrame = 0
        for tone in tones {
            let toneFrames = Int(tone.duration * sampleRate)
            let attackFrames = max(1, Int(min(0.02, tone.duration * 0.25) * sampleRate))
            let releaseFrames = max(1, Int(min(0.07, tone.duration * 0.35) * sampleRate))

            for frame in 0..<toneFrames {
                let time = Double(frame) / sampleRate
                let attack = min(1, Double(frame) / Double(attackFrames))
                let framesRemaining = toneFrames - frame
                let release = min(1, Double(framesRemaining) / Double(releaseFrames))
                let envelope = min(attack, release)
                let fundamental = sin(2 * .pi * tone.frequency * time)
                let harmonic = 0.18 * sin(2 * .pi * tone.frequency * 2 * time)
                samples[startFrame + frame] = Float((fundamental + harmonic) * envelope * 0.2)
            }

            startFrame += toneFrames + Int(tone.gap * sampleRate)
        }

        return buffer
    }
}
