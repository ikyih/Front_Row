import SwiftUI
import Photos

struct PhotosScreenView: View {
    @StateObject private var manager = PhotoLibraryManager()
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false
    @State private var selectedAsset: PHAsset? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                content
            }
            .task {
                await manager.requestAccessIfNeeded()
            }

            // Fullscreen overlay
            if let asset = selectedAsset {
                FullscreenPhotoView(asset: asset) {
                    selectedAsset = nil
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedAsset)
    }

    private var header: some View {
        HStack {
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
                statusText("Requesting access to Photos…")
            case .restricted, .denied:
                statusText("Access denied. Enable Photos access in Settings.")
            case .authorized, .limited:
                if manager.isLoading {
                    statusText("Loading photos…")
                } else if manager.assets.isEmpty {
                    statusText("No photos found.")
                } else {
                    photoGrid
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

    private var photoGrid: some View {
        let corner: CGFloat = 10
        let spacing: CGFloat = 18
        return ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: spacing)], spacing: spacing) {
                ForEach(manager.assets, id: \.localIdentifier) { asset in
                    PhotoThumbnailView(asset: asset, modernStyleEnabled: modernStyleEnabled, corner: corner)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .onTapGesture {
                            selectedAsset = asset
                        }
                }
            }
            .padding(spacing)
        }
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let modernStyleEnabled: Bool
    let corner: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .modifier(PhotoStyleModifier(modern: modernStyleEnabled, corner: corner))
            } else {
                Color.gray.opacity(0.25)
                    .overlay(ProgressView())
                    .modifier(PhotoStyleModifier(modern: modernStyleEnabled, corner: corner))
                    .task {
                        await loadImage()
                    }
            }
        }
    }

    func loadImage() async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        let size = CGSize(width: 300, height: 300)

        await withCheckedContinuation { continuation in
            var didResume = false
            manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { img, info in
                if let img = img {
                    self.image = img
                }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded && !didResume {
                    didResume = true
                    continuation.resume()
                }
            }
        }
    }
}

struct PhotoStyleModifier: ViewModifier {
    let modern: Bool
    let corner: CGFloat

    func body(content: Content) -> some View {
        if modern {
            content
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        } else {
            content
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.50, green: 0.30, blue: 0.15),
                                    Color(red: 0.72, green: 0.53, blue: 0.30),
                                    Color(red: 0.40, green: 0.24, blue: 0.11)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                )
        }
    }
}

// Completely redone FullscreenPhotoView
struct FullscreenPhotoView: View {
    let asset: PHAsset
    let onDismiss: () -> Void
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(Color.black)
                    .onTapGesture { onDismiss() }
                    .transition(.opacity)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .foregroundColor(.white)
            } else {
                VStack {
                    Text("Unable to load image")
                        .foregroundColor(.white)
                        .padding()
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .foregroundColor(.accentColor)
                    .padding(.top, 10)
                }
            }
        }
        .onAppear {
            loadBestImage()
        }
    }

    private func loadBestImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true

        // Attempt to get the best image size for the screen
        let screen = UIScreen.main
        let scale = screen.scale
        let size = CGSize(width: screen.bounds.width * scale, height: screen.bounds.height * scale)

        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { img, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if let img = img, !isDegraded {
                DispatchQueue.main.async {
                    self.image = img
                    self.isLoading = false
                }
            } else if img == nil && !isDegraded {
                // Final callback but no image: show error
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
