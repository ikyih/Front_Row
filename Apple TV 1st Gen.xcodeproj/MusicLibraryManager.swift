// MusicLibraryManager.swift
import Foundation
import MediaPlayer

@MainActor
final class MusicLibraryManager: ObservableObject {
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var songs: [MPMediaItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func requestAccessIfNeeded() async {
        if authorizationStatus == .authorized {
            return
        }
        let status = await MPMediaLibrary.requestAuthorization()
        authorizationStatus = status
        if status == .authorized {
            await fetchSongs()
        }
    }

    func fetchSongs() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let query = MPMediaQuery.songs()
        let items = query.items ?? []

        // Sort by title for a predictable list
        let sorted = items.sorted { ($0.title ?? "") < ($1.title ?? "") }
        songs = sorted
    }
}
