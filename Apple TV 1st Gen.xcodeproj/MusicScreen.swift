// MusicScreen.swift
import SwiftUI
import MediaPlayer

struct MusicScreenView: View {
    @StateObject private var library = MusicLibraryManager()
    @StateObject private var player = MusicPlayer.shared

    // Settings
    @AppStorage("showCurrentSongInMusic") private var showCurrentSongInMusic: Bool = false
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .task {
            // Request access and load songs on appear
            await library.requestAccessIfNeeded()
            if library.authorizationStatus == .authorized && library.songs.isEmpty {
                await library.fetchSongs()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("") // no visible title
                .font(modernStyleEnabled ? .system(size: 28, weight: .bold) : Font.custom("Lucida Grande Bold", size: 28))
                .foregroundColor(.white)
            Spacer()
            if showCurrentSongInMusic, let title = player.currentTitle {
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
                statusText("Access denied. Enable Music access in Privacy.")
            case .denied, .restricted:
                statusText("Access denied. Enable Music access in Settings.")
            case .authorized:
                if library.isLoading {
                    statusText("Loading songs…")
                } else if library.songs.isEmpty {
                    statusText("No local songs found. Sync music to this device or download from Music.")
                } else {
                    songList
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

    private var songList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(library.songs, id: \.persistentID) { item in
                    SongRow(item: item) {
                        MusicPlayer.shared.play(item: item)
                    }
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct SongRow: View {
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
        let artist = item.artist ?? "Unknown Artist"
        let album = item.albumTitle ?? "Unknown Album"
        return "\(artist) — \(album)"
    }
}
