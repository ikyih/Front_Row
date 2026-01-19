import SwiftUI
import Photos

@MainActor
final class PhotoLibraryManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var assets: [PHAsset] = []
    @Published var isLoading: Bool = false

    // Limit to latest N photos
    private let limitCount = 100

    func requestAccessIfNeeded() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            authorizationStatus = newStatus
        } else {
            authorizationStatus = status
        }
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            await fetchPhotos()
        }
    }

    func fetchPhotos() async {
        isLoading = true
        defer { isLoading = false }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limitCount

        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        // Directly convert only the limited set to array
        var fetchedAssets = [PHAsset]()
        fetchedAssets.reserveCapacity(result.count)
        for i in 0..<result.count {
            fetchedAssets.append(result.object(at: i))
        }

        print("PhotoLibraryManager: Loaded \(fetchedAssets.count) photo assets.")
        assets = fetchedAssets
    }
}
