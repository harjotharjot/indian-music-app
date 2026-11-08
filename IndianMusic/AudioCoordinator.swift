import AVFoundation
import Combine
import MediaPlayer

@MainActor
final class AudioCoordinator: ObservableObject {
    @Published var settings: TanpuraSettings {
        didSet {
            let safe = settings.validated()
            if safe != settings { settings = safe }
            if let data = try? JSONEncoder().encode(settings) {
                UserDefaults.standard.set(data, forKey: Self.settingsKey)
            }
            graph?.apply(settings)
            rampGains()
            updateNowPlaying()
        }
    }
    @Published private(set) var isPlaying = false
    @Published private(set) var message: String?
    private static let settingsKey = "tanpura.settings.v1"
    private var graph: TanpuraGraph?
    private var observers: [NSObjectProtocol] = []
    private var commands: [(MPRemoteCommand, Any)] = []
    private var gainTask: Task<Void, Never>?
    private var resumeAfterInterruption = false
    private var interrupted = false

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.settingsKey),
           let saved = try? JSONDecoder().decode(TanpuraSettings.self, from: data) {
            settings = saved.validated()
        } else {
            settings = TanpuraSettings()
        }
        loadGraph()
        observeAudioChanges()
        installRemoteCommands()
    }

    private func loadGraph() {
        do {
            guard let resources = Bundle.main.resourceURL?.appendingPathComponent("Resources") else {
                throw TanpuraGraph.GraphError.invalidResource("bundle")
            }
            graph = try TanpuraGraph(resources: resources)
            graph?.apply(settings)
            message = nil
        } catch {
            graph = nil
            message = error.localizedDescription
        }
    }

    func toggle() { isPlaying ? pause() : play() }

    func play() {
        guard !interrupted else { return }
        if isPlaying { return }
        gainTask?.cancel()
        if graph == nil { loadGraph() }
        guard let graph else { return }
        do {
            // This app owns one session and one engine; no microphone permission needed.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            graph.apply(settings)
            graph.setVolume(0)
            for pattern in TanpuraPattern.allCases {
                graph.setGain(pattern == settings.pattern ? 1 : 0, for: pattern)
            }
            try graph.play()
            isPlaying = true
            message = nil
            rampGains()
            updateNowPlaying()
        } catch {
            graph.stop()
            isPlaying = false
            message = "Playback could not start: \(error.localizedDescription)"
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            updateNowPlaying()
        }
    }

    func pause() {
        resumeAfterInterruption = false
        guard isPlaying else { return }
        isPlaying = false
        rampGains(stopAfter: true)
        updateNowPlaying()
    }

    private func stopImmediately() {
        gainTask?.cancel()
        graph?.setVolume(0)
        graph?.stop()
        isPlaying = false
        updateNowPlaying()
    }

    private func rampGains(stopAfter: Bool = false) {
        gainTask?.cancel()
        guard let graph else { return }
        let startVolume = graph.volume()
        let startPa = graph.gain(for: .pa)
        let startMa = graph.gain(for: .ma)
        let endVolume: Float = isPlaying ? Float(settings.volume) : 0
        let endPa: Float = settings.pattern == .pa ? 1 : 0
        gainTask = Task { @MainActor [weak self, weak graph] in
            // Control-rate ramps use Apple's node gains, not an audio render callback.
            for step in 1...12 {
                guard !Task.isCancelled, let graph else { return }
                let fraction = Float(step) / 12
                graph.setVolume(startVolume + (endVolume - startVolume) * fraction)
                graph.setGain(startPa + (endPa - startPa) * fraction, for: .pa)
                graph.setGain(startMa + (1 - endPa - startMa) * fraction, for: .ma)
                do { try await Task.sleep(nanoseconds: 10_000_000) } catch { return }
            }
            guard !Task.isCancelled, let self else { return }
            if stopAfter && !self.isPlaying {
                self.graph?.stop()
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        }
    }

    private func observeAudioChanges() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification,
                                             object: nil, queue: .main) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
            let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
            Task { @MainActor [weak self] in
                guard let self, let raw = type,
                      let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
                if type == .began {
                    self.interrupted = true
                    self.resumeAfterInterruption = self.isPlaying
                    self.stopImmediately()
                    self.message = "Playback interrupted."
                } else {
                    self.interrupted = false
                    let resume = self.resumeAfterInterruption && AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
                    self.resumeAfterInterruption = false
                    if resume { self.play() }
                }
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification,
                                             object: nil, queue: .main) { [weak self] note in
            let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self else { return }
                if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                    self.resumeAfterInterruption = false
                    self.stopImmediately()
                    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                    self.message = "Audio device disconnected. Tap Play to resume."
                } else {
                    self.recoverStoppedEngine()
                }
            }
        })
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange,
                                             object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.recoverStoppedEngine() }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                             object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let resume = self.isPlaying
                self.interrupted = false
                self.resumeAfterInterruption = false
                self.stopImmediately()
                self.loadGraph()
                if resume { self.play() }
            }
        })
    }

    private func recoverStoppedEngine() {
        guard isPlaying, !interrupted, graph?.engine.isRunning == false else { return }
        stopImmediately()
        play()
    }

    private func installRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        commands.append((center.playCommand, center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.play() }
            return .success
        }))
        commands.append((center.pauseCommand, center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }))
        commands.append((center.togglePlayPauseCommand, center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.toggle() }
            return .success
        }))
        commands.append((center.stopCommand, center.stopCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }))
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false
    }

    private func updateNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Tanpura · \(settings.saName)",
            MPMediaItemPropertyArtist: settings.pattern.description,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }

    deinit {
        gainTask?.cancel()
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        for (command, token) in commands { command.removeTarget(token) }
    }
}
