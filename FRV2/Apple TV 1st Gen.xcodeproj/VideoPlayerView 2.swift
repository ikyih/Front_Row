import SwiftUI
import AVKit
import MediaPlayer

struct VideoPlayerView: UIViewControllerRepresentable {
    let item: MPMediaItem

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.showsPlaybackControls = true

        if let url = item.assetURL {
            let avPlayer = AVPlayer(url: url)
            controller.player = avPlayer
        }

        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        // Nothing needed
    }
}
