import SwiftUI
import MediaPlayer

struct PodcastsScreenView: View {
    @StateObject private var library = PodcastsLibraryManager()
    @StateObject private var player = MusicPlayer.shared // Reuse for podcasts

    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .task {
            await library.requestAccessIfNeeded()
            if library.authorizationStatus == .authorized && library.podcasts.isEmpty {
                await library.fetchPodcasts()
            }
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
        Group {
            switch library.authorizationStatus {
            case .notDetermined:
                statusText("Access denied. Enable Podcasts access in Privacy.")
            case .denied, .restricted:
                statusText("Access denied. Enable Podcasts access in Settings.")
            case .authorized:
                if library.isLoading {
                    statusText("Loading podcasts…")
                } else if library.podcasts.isEmpty {
                    statusText("No local podcasts found. Download podcasts to this device.")
                } else {
                    podcastList
                }
            @unknown default:
                statusText("Unknown authorization state.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.white.opacity(0.9))
            .padding()
    }

    private var podcastList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(library.podcasts, id: \.persistentID) { item in
                    PodcastRow(item: item) {
                        MusicPlayer.shared.play(item: item)
                    }
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct PodcastRow: View {
    let item: MPMediaItem
    let onTap: () -> Void
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title ?? "Unknown Title")
                        .foregroundColor(.white)
                        .font(modernStyleEnabled ? .system(size: 18, weight: .semibold) : Font.custom("Lucida Grande Bold", size: 18))
                        .lineLimit(1)
                    Text(subtitle)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.001))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var subtitle: String {
        let artist = item.podcastTitle ?? item.artist ?? "Unknown Podcast"
        let album = item.albumTitle ?? ""
        return album.isEmpty ? artist : "\(artist) — \(album)"
    }
}

