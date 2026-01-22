import Foundation
import MediaPlayer

@MainActor
final class PodcastsLibraryManager: ObservableObject {
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var podcasts: [MPMediaItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func requestAccessIfNeeded() async {
        if authorizationStatus == .authorized {
            return
        }
        let status = await MPMediaLibrary.requestAuthorization()
        authorizationStatus = status
        if status == .authorized {
            await fetchPodcasts()
        }
    }

    func fetchPodcasts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let query = MPMediaQuery.podcasts()
        let items = query.items ?? []

        let sorted = items.sorted { ($0.title ?? "") < ($1.title ?? "") }
        podcasts = sorted
    }
}
