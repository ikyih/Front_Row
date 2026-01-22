// MusicPlayer.swift
import Foundation
import AVFoundation
import MediaPlayer

final class MusicPlayer: ObservableObject {
    static let shared = MusicPlayer()

    private let player = AVPlayer()
    @Published var isPlaying: Bool = false
    @Published var currentTitle: String?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    @objc private func itemDidFinish() {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }

    func play(item: MPMediaItem) {
        guard let url = item.assetURL else {
            // Cannot play iCloud-only or DRM-restricted content
            return
        }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        currentTitle = item.title
        player.play()
        isPlaying = true
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        currentTitle = nil
    }
}
