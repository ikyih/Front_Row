import SwiftUI
import AVKit
import MediaPlayer

struct VideoPlayerView: UIViewControllerRepresentable {
    let item: MPMediaItem

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = true
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        guard let url = item.assetURL else {
            uiViewController.player = nil
            return
        }
        if uiViewController.player == nil || (uiViewController.player?.currentItem?.asset as? AVURLAsset)?.url != url {
            uiViewController.player = AVPlayer(url: url)
        }
    }
}
