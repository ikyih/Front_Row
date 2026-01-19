import SwiftUI
import MediaPlayer

struct MoviesScreenView: View {
    @StateObject private var library = MoviesLibraryManager()
    @State private var selectedItem: MPMediaItem?
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                content
            }
            if let item = selectedItem {
                VideoPlayerView(item: item)
                    .edgesIgnoringSafeArea(.all)
                    .onDisappear {
                        selectedItem = nil
                    }
            }
        }
        .task {
            await library.requestAccessIfNeeded()
            if library.authorizationStatus == .authorized && library.movies.isEmpty {
                await library.fetchMovies()
            }
        }
    }

    private var header: some View {
        HStack {
            // Title removed
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
    }

    private var content: some View {
        Group {
            switch library.authorizationStatus {
            case .notDetermined:
                statusText("Requesting access to the media library…")
            case .denied, .restricted:
                statusText("Access denied. Enable Movies access in Settings.")
            case .authorized:
                if library.isLoading {
                    statusText("Loading movies…")
                } else if library.movies.isEmpty {
                    statusText("No local movies found.")
                } else {
                    moviesList
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

    private var moviesList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(library.movies, id: \.persistentID) { item in
                    MovieRow(item: item) {
                        selectedItem = item
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
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title ?? "Unknown Title")
                        .foregroundColor(.white)
                        .font(modernStyleEnabled ? .system(size: 18, weight: .semibold) : Font.custom("Lucida Grande Bold", size: 18))
                        .lineLimit(1)
                    Text(item.albumTitle ?? "Movie")
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
}
