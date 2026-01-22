import SwiftUI
import AVFoundation
import MediaPlayer

struct SourcesScreenView: View {
    @StateObject private var viewModel = SourcesViewModel()
    @StateObject private var player = OnlineRadioPlayer.shared

    @State private var newName: String = ""
    @State private var newURLString: String = ""

    // Modern style toggle
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .onAppear {
            // Prepare audio session for playback
            player.configureAudioSessionIfNeeded()
        }
    }

    private var header: some View {
        HStack {
            // Title removed
            Spacer()

            if let title = player.currentTitle {
                Text(player.isPlaying ? "Playing: \(title)" : "Paused: \(title)")
                    .font(modernStyleEnabled ? .system(size: 14, weight: .semibold) : Font.custom("Lucida Grande Bold", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
    }

    private var content: some View {
        VStack(spacing: 0) {
            addSourceForm
            Divider().background(Color.white.opacity(0.1))
            sourceList
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }

    private var addSourceForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add Source (Radio or YouTube)")
                .font(modernStyleEnabled ? .system(size: 18, weight: .semibold) : Font.custom("Lucida Grande Bold", size: 18))
                .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 8) {
                TextField("Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                TextField("URL (Radio or YouTube)", text: $newURLString)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addSource()
                } label: {
                    if modernStyleEnabled {
                        Label("Add", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                    } else {
                        Text("Add")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var sourceList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.sources) { source in
                    switch source.type {
                    case .radio:
                        StationRow(
                            station: source,
                            isCurrent: source.id == player.currentStation?.id,
                            isPlaying: player.isPlaying,
                            modernStyleEnabled: modernStyleEnabled
                        ) {
                            player.play(station: source)
                        } onDelete: {
                            viewModel.delete(source)
                            if player.currentStation?.id == source.id {
                                player.stop()
                            }
                        }
                    case .youtube:
                        YouTubeRow(source: source, onDelete: {
                            viewModel.delete(source)
                        })
                    }
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .padding(.top, 8)
        }
    }

    private func addSource() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = newURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let url = URL(string: trimmedURL) else { return }
        let type = Source.detectType(from: url)
        viewModel.addSource(name: trimmedName, url: url, type: type)
        newName = ""
        newURLString = ""
    }
}

private struct StationRow: View {
    let station: Source
    let isCurrent: Bool
    let isPlaying: Bool
    let modernStyleEnabled: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if modernStyleEnabled {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 20, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .foregroundColor(.white)
                    .font(modernStyleEnabled ? .system(size: 18, weight: .semibold) : Font.custom("Lucida Grande Bold", size: 18))
                    .lineLimit(1)
                Text(station.url.absoluteString)
                    .foregroundColor(.white.opacity(0.7))
                    .font(modernStyleEnabled ? .system(size: 12) : .system(size: 12))
                    .lineLimit(1)
            }
            Spacer()
            if modernStyleEnabled {
                Image(systemName: isCurrent ? (isPlaying ? "pause.circle.fill" : "play.circle.fill") : "play.circle")
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
            } else {
                Image(systemName: isCurrent ? (isPlaying ? "pause.circle.fill" : "play.circle.fill") : "play.circle")
                    .foregroundColor(.white)
            }

            if modernStyleEnabled {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .regular))
                }
                .buttonStyle(.borderless)
                .tint(.red)
            } else {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onTapGesture(perform: onTap)
    }
}

private struct YouTubeRow: View {
    let source: Source
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(source.name)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .regular))
                }
                .buttonStyle(.borderless)
                .tint(.red)
            }
            if let embedURL = youtubeEmbedURL() {
                WebView(url: embedURL)
                    .frame(height: 200)
                    .cornerRadius(12)
            } else {
                Text("Invalid YouTube link")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func youtubeEmbedURL() -> URL? {
        guard let videoID = Source.extractYouTubeID(from: source.url) else { return nil }
        return URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1")
    }
}

// MARK: - Source Model & ViewModel

struct Source: Identifiable, Hashable, Codable {
    enum SourceType: String, Codable {
        case radio
        case youtube
    }

    let id: UUID
    var name: String
    var url: URL
    var type: SourceType

    init(id: UUID = UUID(), name: String, url: URL, type: SourceType) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
    }

    static func detectType(from url: URL) -> SourceType {
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtube.com") || host.contains("youtu.be") {
            return .youtube
        }
        return .radio
    }

    static func extractYouTubeID(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtu.be") {
            return url.pathComponents.last
        } else if host.contains("youtube.com") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            return components?.queryItems?.first(where: { $0.name == "v" })?.value
        }
        return nil
    }
}

final class SourcesViewModel: ObservableObject {
    @Published private(set) var sources: [Source] = []

    init() {
        loadDefaults()
    }

    func addSource(name: String, url: URL, type: Source.SourceType) {
        var set = Set(sources)
        let source = Source(name: name, url: url, type: type)
        set.insert(source)
        sources = Array(set).sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
        saveDefaults()
    }

    func delete(_ source: Source) {
        sources.removeAll { $0.id == source.id }
        saveDefaults()
    }

    private let defaultsKey = "OnlineSources"

    private func loadDefaults() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey) {
            if let decoded = try? JSONDecoder().decode([Source].self, from: data) {
                sources = decoded
                return
            }
        }
        // Seed with a couple of radio examples
        sources = [
            Source(name: "BBC World Service (HLS)", url: URL(string: "https://stream.live.vc.bbcmedia.co.uk/bbc_world_service")!, type: .radio),
            Source(name: "KEXP 90.3 FM MP3", url: URL(string: "https://kexp-mp3-128.streamguys1.com/kexp128.mp3")!, type: .radio)
        ]
    }

    private func saveDefaults() {
        if let data = try? JSONEncoder().encode(sources) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}

// MARK: - OnlineRadioPlayer (unchanged, but now works with Source of type .radio)

final class OnlineRadioPlayer: ObservableObject {
    static let shared = OnlineRadioPlayer()

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTitle: String?
    @Published private(set) var currentStation: Source?

    private var player: AVPlayer?

    private init() {}

    func configureAudioSessionIfNeeded() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Handle session errors if needed
        }
        #endif
    }

    func play(station: Source) {
        stop()
        guard station.type == .radio else { return }
        let item = AVPlayerItem(url: station.url)
        observeMetadata(for: item)

        let p = AVPlayer(playerItem: item)
        self.player = p
        self.currentStation = station
        self.currentTitle = station.name

        p.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        isPlaying = false
        currentTitle = nil
        currentStation = nil
    }

    private var metadataObserver: NSKeyValueObservation?
    private var timeObserver: Any?

    private func observeMetadata(for item: AVPlayerItem) {
        metadataObserver = item.observe(\.timedMetadata, options: [.new, .initial]) { [weak self] item, _ in
            guard let self = self else { return }
            if let mdItems = item.timedMetadata, !mdItems.isEmpty {
                // Prefer title/artist if present
                if let title = mdItems.first(where: { $0.commonKey?.rawValue == "title" })?.stringValue {
                    DispatchQueue.main.async { self.currentTitle = title }
                } else if let name = mdItems.first?.stringValue {
                    DispatchQueue.main.async { self.currentTitle = name }
                }
            }
        }
    }
}
