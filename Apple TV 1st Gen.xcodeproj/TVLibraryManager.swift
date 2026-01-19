import Foundation
import MediaPlayer

@MainActor
final class TVLibraryManager: ObservableObject {
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var shows: [MPMediaItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func requestAccessIfNeeded() async {
        if authorizationStatus == .authorized {
            return
        }
        let status = await MPMediaLibrary.requestAuthorization()
        authorizationStatus = status
        if status == .authorized {
            await fetchShows()
        }
    }

    func fetchShows() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let query = MPMediaQuery()
        let predicate = MPMediaPropertyPredicate(
            value: MPMediaType.tvShow.rawValue,
            forProperty: MPMediaItemPropertyMediaType
        )
        query.addFilterPredicate(predicate)

        let items = query.items ?? []

        let sorted = items.sorted { ($0.title ?? "") < ($1.title ?? "") }
        shows = sorted
    }
}
