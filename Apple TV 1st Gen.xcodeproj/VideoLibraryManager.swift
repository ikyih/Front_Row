import Foundation
import MediaPlayer

@MainActor
final class VideoLibraryManager: ObservableObject {
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var movies: [MPMediaItem] = []
    @Published var tvEpisodes: [MPMediaItem] = []
    @Published var isLoadingMovies: Bool = false
    @Published var isLoadingTV: Bool = false
    @Published var errorMessage: String?

    func requestAccessIfNeeded() async {
        if authorizationStatus == .authorized { return }
        let status = await MPMediaLibrary.requestAuthorization()
        authorizationStatus = status
        if status == .authorized {
            await fetchMovies()
            await fetchTVShows()
        }
    }

    func fetchMovies() async {
        isLoadingMovies = true
        defer { isLoadingMovies = false }
        let query = MPMediaQuery.movies()
        // Keep only locally available items (assetURL != nil)
        let items = (query.items ?? []).filter { $0.assetURL != nil }
        // Sort by title
        movies = items.sorted { ($0.title ?? "") < ($1.title ?? "") }
    }

    func fetchTVShows() async {
        isLoadingTV = true
        defer { isLoadingTV = false }
        let query = MPMediaQuery.tvShows()
        // Keep only locally available items (assetURL != nil)
        let items = (query.items ?? []).filter { $0.assetURL != nil }
        // Sort by series name then season/episode then title
        tvEpisodes = items.sorted {
            let lhsSeries = $0.albumTitle ?? $0.seriesName ?? ""
            let rhsSeries = $1.albumTitle ?? $1.seriesName ?? ""
            if lhsSeries != rhsSeries { return lhsSeries < rhsSeries }
            let lhsSeason = $0.albumTrackCount
            let rhsSeason = $1.albumTrackCount
            if lhsSeason != rhsSeason { return lhsSeason < rhsSeason }
            let lhsEpisode = $0.albumTrackNumber
            let rhsEpisode = $1.albumTrackNumber
            if lhsEpisode != rhsEpisode { return lhsEpisode < rhsEpisode }
            return ($0.title ?? "") < ($1.title ?? "")
        }
    }
}

private extension MPMediaItem {
    var seriesName: String? {
        // Some TV metadata uses "show title" in albumArtist or podcastTitle fields; fallback chain
        if let show = self.tvShowTitle { return show }
        if let albumArtist = self.albumArtist, !albumArtist.isEmpty { return albumArtist }
        if let podcastTitle = self.podcastTitle, !podcastTitle.isEmpty { return podcastTitle }
        return nil
    }

    var tvShowTitle: String? {
        // There isn't a direct tvShowTitle API on iOS; albumTitle often holds series or season.
        // We leave this as nil and rely on seriesName heuristic above.
        return nil
    }
}
