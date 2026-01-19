// MusicPlayer.swift
import Foundation
import MediaPlayer

@MainActor
final class MusicPlayer: ObservableObject {

    static let shared = MusicPlayer()

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTitle: String?

    private let player: MPMusicPlayerController

    private init() {
        // Using applicationMusicPlayer so we can enqueue local library items
        self.player = MPMusicPlayerController.applicationMusicPlayer

        // Observe playback state and now-playing item changes to keep UI in sync
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )

        player.beginGeneratingPlaybackNotifications()

        // Initialize published properties from current player state
        syncFromPlayer()
    }

    deinit {
        player.endGeneratingPlaybackNotifications()
        NotificationCenter.default.removeObserver(self)
    }

    func play(item: MPMediaItem) {
        // Build a queue with just this item and start playback
        let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: [item]))
        player.setQueue(with: descriptor)
        player.nowPlayingItem = item
        player.play()

        // Update UI state immediately
        currentTitle = item.title
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            player.play()
            isPlaying = true
        }
    }

    @objc
    private func handlePlaybackStateChanged(_ notification: Notification) {
        switch player.playbackState {
        case .playing:
            isPlaying = true
        case .paused, .stopped, .interrupted:
            isPlaying = false
        default:
            break
        }
    }

    @objc
    private func handleNowPlayingItemChanged(_ notification: Notification) {
        currentTitle = player.nowPlayingItem?.title
    }

    private func syncFromPlayer() {
        currentTitle = player.nowPlayingItem?.title
        isPlaying = (player.playbackState == .playing)
    }
}
