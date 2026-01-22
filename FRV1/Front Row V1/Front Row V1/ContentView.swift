//
//  ContentView.swift
//  FRV1 Import Tool
//

import SwiftUI
import Photos
import MediaPlayer
import WatchConnectivity
internal import Combine

// MARK: - Models
struct PhotoThumbnail: Identifiable, Codable {
    let id: String
    let imageData: Data
}

struct SongInfo: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let artworkData: Data?
}

// MARK: - Watch Sync Manager
class WatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
//    var objectWillChange: ObservableObjectPublisher

    static let shared = WatchSyncManager()
    let session = WCSession.default
    
    @Published var alertMessage: String = ""
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func syncToWatch(photos: [PhotoThumbnail], songs: [SongInfo]) {
        do {
            let encoder = JSONEncoder()
            let photosData = try encoder.encode(photos)
            let songsData = try encoder.encode(songs)
            
            guard session.isPaired && session.isWatchAppInstalled else {
                alertMessage = "Watch not paired or app not installed."
                return
            }
            
            try session.updateApplicationContext([
                "photoThumbnails": photosData,
                "songInfos": songsData
            ])
            alertMessage = "Sync complete! Sent \(photos.count) photos and \(songs.count) songs."
        } catch {
            alertMessage = "Sync failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - WCSessionDelegate stubs
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    func sessionWatchStateDidChange(_ session: WCSession) {}
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}

// MARK: - ContentView
struct ContentView: View {
    @State private var photoPermissionGranted = false
    @State private var mediaPermissionGranted = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @StateObject private var syncManager = WatchSyncManager.shared
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Media & Photo Sync")
                .font(.title2)
                .bold()
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: photoPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(photoPermissionGranted ? .green : .red)
                    Text("Photo Library Access")
                }
                
                HStack {
                    Image(systemName: mediaPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(mediaPermissionGranted ? .green : .red)
                    Text("Media Library Access")
                }
            }
            
            Button("Request Permissions") {
                requestPermissions()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            
            Button("Sync to Watch") {
                Task {
                    await performSync()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background((photoPermissionGranted && mediaPermissionGranted) ? Color.green : Color.gray)
            .cornerRadius(12)
            .disabled(!photoPermissionGranted || !mediaPermissionGranted)
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Permissions
    private func requestPermissions() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                photoPermissionGranted = (status == .authorized || status == .limited)
                if !photoPermissionGranted {
                    alertMessage = "Photo Library access denied."
                    showAlert = true
                }
            }
        }
        
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                mediaPermissionGranted = (status == .authorized)
                if !mediaPermissionGranted {
                    alertMessage = "Media Library access denied."
                    showAlert = true
                }
            }
        }
    }
    
    // MARK: - Perform Sync
    private func performSync() async {
        do {
            let photos = try await fetchPhotoThumbnails(limit: 50)
            let songs = fetchSongs(limit: 3)
            
            syncManager.syncToWatch(photos: photos, songs: songs)
            
            alertMessage = syncManager.alertMessage
            showAlert = true
        } catch {
            alertMessage = "Error fetching data: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // MARK: - Fetch Photos
    private func fetchPhotoThumbnails(limit: Int) async throws -> [PhotoThumbnail] {
        var thumbnails: [PhotoThumbnail] = []
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        assets.enumerateObjects { asset, _, _ in
            let size = CGSize(width: 60, height: 60)
            imageManager.requestImage(for: asset,
                                      targetSize: size,
                                      contentMode: .aspectFill,
                                      options: requestOptions) { image, _ in
                if let img = image, let data = img.pngData() {
                    thumbnails.append(PhotoThumbnail(id: asset.localIdentifier, imageData: data))
                }
            }
        }
        
        return thumbnails
    }
    
    // MARK: - Fetch Songs
    private func fetchSongs(limit: Int) -> [SongInfo] {
        let query = MPMediaQuery.songs()
        let items = query.items?.sorted(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() }) ?? []
        
        return items.prefix(limit).map { item in
            var artworkData: Data? = nil
            if let artwork = item.artwork?.image(at: CGSize(width: 60, height: 60)) {
                artworkData = artwork.pngData()
            }
            return SongInfo(
                id: "\(item.persistentID)",
                title: item.title ?? "Unknown",
                artist: item.artist ?? "Unknown",
                artworkData: artworkData
            )
        }
    }
}

#Preview {
    ContentView()
}
