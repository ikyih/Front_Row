import SwiftUI
import MediaPlayer

struct MoviesScreenView: View {
    @StateObject private var manager = VideoLibraryManager()
    @State private var playingItem: MPMediaItem?

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .task {
            await manager.requestAccessIfNeeded()
            if manager.authorizationStatus == .authorized && manager.movies.isEmpty {
                await manager.fetchMovies()
            }
        }
        .sheet(item: $playingItem, content: { item in
            VideoPlayerView(item: item)
                .ignoresSafeArea()
        })
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }

    private var header: some View {
        HStack {
            Text("Movies")
                .font(Font.custom("Lucida Grande Bold", size: 28))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
    }

    private var content: some View {
        Group {
            switch manager.authorizationStatus {
            case .notDetermined:
                statusText("Access not determined. Grant Media access to load Movies.")
            case .denied, .restricted:
                statusText("Access denied. Enable Media access in Settings.")
            case .authorized:
                if manager.isLoadingMovies {
                    statusText("Loading movies…")
                } else if manager.movies.isEmpty {
                    statusText("No local movies found.")
                } else {
                    movieList
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

    private var movieList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(manager.movies, id: \.persistentID) { item in
                    MovieRow(item: item) {
                        playingItem = item
                    }
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct MovieRow: View {
    let item: MPMediaItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                artwork
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title ?? "Unknown Title")
                        .foregroundColor(.white)
                        .font(Font.custom("Lucida Grande Bold", size: 18))
                        .lineLimit(1)
                    Text(item.albumTitle ?? "Movie")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.001))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var artwork: some View {
        let image = item.artwork?.image(at: CGSize(width: 60, height: 60))
        return Group {
            if let ui = image {
                Image(uiImage: ui).resizable().aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: 60, height: 60)
        .clipped()
        .cornerRadius(6)
    }
}
