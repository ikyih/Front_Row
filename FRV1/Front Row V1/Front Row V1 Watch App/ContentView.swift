import SwiftUI
import WatchConnectivity
import Combine

// MARK: - Data Models
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

struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let labelImageName: String
}

// MARK: - ViewModel
class WatchMediaViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var photoThumbnails: [PhotoThumbnail] = []
    @Published var songInfos: [SongInfo] = []
    @Published var showingPhotoList = false
    @Published var showingSongList = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Receive messages from iOS
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        decodeIncomingData(message)
    }
    
    // MARK: - Receive application context from iOS
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        decodeIncomingData(applicationContext)
    }
    
    private func decodeIncomingData(_ data: [String: Any]) {
        let decoder = JSONDecoder()
        if let photoData = data["photoThumbnails"] as? Data,
           let songData = data["songInfos"] as? Data {
            if let photos = try? decoder.decode([PhotoThumbnail].self, from: photoData),
               let songs = try? decoder.decode([SongInfo].self, from: songData) {
                DispatchQueue.main.async {
                    self.photoThumbnails = photos
                    self.songInfos = songs
                }
            }
        }
    }
    
    // Required stubs
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}

// MARK: - Main ContentView
struct ContentView: View {
    @StateObject private var viewModel = WatchMediaViewModel()
    
    let menuItems: [MenuItem] = [
        MenuItem(name: "Music", imageName: "MusicIcon", labelImageName: "MusicLable"),
        MenuItem(name: "Photos", imageName: "PhotosIcon", labelImageName: "PhotosLable"),
        MenuItem(name: "Podcasts", imageName: "PodcastsIcon", labelImageName: "PodcastsLable"),
        MenuItem(name: "Settings", imageName: "SettingsIcon", labelImageName: "SettingsLable")
    ]
    
    @State private var selectedIndex: Double = 0
    @FocusState private var scrollFocused: Bool
    
    let labelHeight: CGFloat = 16
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Previous icon (top)
                if let previous = previousItem {
                    Image(previous.imageName)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .scaleEffect(x: 1, y: -1) // flipped
                        .opacity(0.7)
                        .padding(.top, 8)
                } else {
                    Spacer(minLength: 48)
                }
                
                Spacer()
                
                // Invisible scrollable zone for Digital Crown
                Color.clear
                    .frame(height: 60)
                    .focusable(true)
                    .focused($scrollFocused)
                    .digitalCrownRotation(
                        $selectedIndex,
                        from: 0,
                        through: Double(menuItems.count - 1),
                        by: 1,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )
                    .onAppear { scrollFocused = true }
                
                Spacer()
                
                // Selected icon + label
                Button {
                    handleSelection(for: currentItem)
                } label: {
                    VStack(spacing: 4) {
                        Image(currentItem.imageName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .shadow(color: .white.opacity(0.3), radius: 8)
                        
                        Image(currentItem.labelImageName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(height: labelHeight)
                            .padding(.bottom, 8)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $viewModel.showingPhotoList) {
            PhotoListView(photos: viewModel.photoThumbnails)
        }
        .sheet(isPresented: $viewModel.showingSongList) {
            SongListView(songs: viewModel.songInfos)
        }
    }
    
    // MARK: - Selection Handling
    private func handleSelection(for item: MenuItem) {
        switch item.name {
        case "Music":
            viewModel.showingSongList = true
        case "Photos":
            viewModel.showingPhotoList = true
        default:
            break
        }
    }
    
    private var currentIntIndex: Int {
        min(max(Int(selectedIndex.rounded()), 0), menuItems.count - 1)
    }
    
    private var currentItem: MenuItem {
        menuItems[currentIntIndex]
    }
    
    private var previousItem: MenuItem? {
        guard currentIntIndex > 0 else { return nil }
        return menuItems[currentIntIndex - 1]
    }
}

// MARK: - Photo List
struct PhotoListView: View {
    let photos: [PhotoThumbnail]
    var body: some View {
        ScrollView {
            VStack {
                ForEach(photos) { photo in
                    if let image = UIImage(data: photo.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

// MARK: - Song List
struct SongListView: View {
    let songs: [SongInfo]
    var body: some View {
        List(songs) { song in
            HStack {
                if let data = song.artworkData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                }
                VStack(alignment: .leading) {
                    Text(song.title).font(.headline)
                    Text(song.artist).font(.caption)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
