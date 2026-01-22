//
//  ContentView.swift
//  Front Row Recreated
//
//  Created by Zane Kleinberg on 6/28/21.
//

import SwiftUI
import UIKit

private extension Color {
    init?(hexRGBA: String) {
        var s = hexRGBA.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 8, let value = UInt32(s, radix: 16) else { return nil }
        let r = Double((value >> 24) & 0xFF) / 255.0
        let g = Double((value >> 16) & 0xFF) / 255.0
        let b = Double((value >> 8) & 0xFF) / 255.0
        let a = Double(value & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

struct ContentView: View {
    // Settings
    @AppStorage("showHomeOnMacCatalyst") private var showHomeOnMacCatalyst: Bool = false
    @AppStorage("showPhotos") private var showPhotos: Bool = true
    @AppStorage("appBackgroundHex") private var appBackgroundHex: String = "#000000FF"

    private var appBackgroundColor: Color {
        Color(hexRGBA: appBackgroundHex) ?? .black
    }

    // Menu items for Front Row (hide or show "Home" on Mac Catalyst via setting)
    private var menuItems: [String] {
        var base = ["Movies", "TV Shows", "Music", "Podcasts", "Settings", "Sources"]
        if showPhotos {
            // Insert Photos in its original place (before Settings)
            base.insert("Photos", at: min(base.count, 4))
        }
        #if targetEnvironment(macCatalyst)
        if showHomeOnMacCatalyst {
            base.append("Home")
        }
        #else
        base.append("Home")
        #endif
        return base
    }

    @State private var selectedIndex: Int = 0
    // Focus for keyboard, especially on Mac Catalyst
    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                appBackgroundColor.edgesIgnoringSafeArea(.all)
                HStack(spacing: 0) {
                    ZStack {
                        lefthand_view(selectedIndex: selectedIndex, currentItem: currentItem, showPhotos: showPhotos)
                            .frame(width: geometry.size.width/2, height: geometry.size.height)

                        if currentItem == "music" {
                            MusicScreenView()
                                .frame(width: geometry.size.width/2, height: geometry.size.height)
                                .transition(.opacity)
                        } else if currentItem == "settings" {
                            SettingsScreenView()
                                .frame(width: geometry.size.width/2, height: geometry.size.height)
                                .transition(.opacity)
                        } else if currentItem == "photos" {
                            PhotosScreenView()
                                .frame(width: geometry.size.width/2, height: geometry.size.height)
                                .transition(.opacity)
                        } else if currentItem == "sources" {
                            SourcesScreenView()
                                .frame(width: geometry.size.width/2, height: geometry.size.height)
                                .transition(.opacity)
                        }
                    }

                    righthand_view(
                        menuItems: menuItems,
                        selectedIndex: selectedIndex,
                        onSelect: handleSelect
                    )
                    .frame(width: geometry.size.width/2, height: geometry.size.height)
                }

                // Invisible keyboard input handler
                KeyInputView { key in
                    switch key {
                    case .downArrow:
                        selectedIndex = min(selectedIndex + 1, menuItems.count - 1)
                    case .upArrow:
                        selectedIndex = max(selectedIndex - 1, 0)
                    case .enter:
                        handleSelect(selectedIndex)
                    }
                }
                .frame(width: 0, height: 0) // Hidden
                .focused($isFocused)
                .onAppear { isFocused = true }
            }
        }
    }

    private var currentItem: String {
        guard selectedIndex >= 0 && selectedIndex < menuItems.count else { return "" }
        return menuItems[selectedIndex].lowercased()
    }

    private func handleSelect(_ index: Int) {
        selectedIndex = index
        let item = menuItems[index].lowercased()
        if item == "home" {
            goToHomeScreen()
        }
    }

    private func goToHomeScreen() {
        // Immediately send app to background (no prompt).
        // Warning: uses a private selector; not App Store safe.
        let selector = NSSelectorFromString("suspend")
        if UIApplication.shared.responds(to: selector) {
            UIApplication.shared.perform(selector)
            return
        }

        // Fallback: open Settings to leave the app if suspend not available.
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Right-hand Menu
struct righthand_view: View {
    let menuItems: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                tv_header()
                Spacer().frame(height: 30)
                ForEach(menuItems.indices, id: \.self) { idx in
                    Group {
                        if idx == selectedIndex {
                            selected_item(text: menuItems[idx])
                                .frame(height: 60)
                                .padding([.leading, .trailing], 40)
                                .onTapGesture { onSelect(idx) } // tap activates
                        } else {
                            unselected_item(text: menuItems[idx])
                                .frame(height: 60)
                                .padding([.leading, .trailing], 40)
                                .onTapGesture { onSelect(idx) } // tap activates
                        }
                    }
                }
                Spacer().frame(height: 100)
            }
        }
    }
}

// MARK: - Header
struct tv_header: View {
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            Spacer()
            ZStack {}
            Text("Front Row")
                .font(modernStyleEnabled ? .system(size: 80, weight: .bold) : Font.custom("Lucida Grande Bold", size: 80))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

// MARK: - Menu Items
struct selected_item: View {
    var text: String
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(Color(red: 43/255, green: 75/255, blue: 121/255))
                Rectangle().fill(Color.black)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .border(Color(red: 38/255, green: 79/255, blue: 142/255), width: 2)
                    .glow(color: Color(red: 43/255, green: 75/255, blue: 121/255).opacity(0.5), radius: 30)
                VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [
                        .init(color: Color(red: 116/255, green: 115/255, blue: 112/255), location: 0),
                        .init(color: Color(red: 53/255, green: 53/255, blue: 53/255), location: 1)
                    ]), startPoint: .top, endPoint: .bottom))
                        .frame(width: geometry.size.width-4, height: geometry.size.height/2.5)
                        .cornerRadiusSpecific(radius: 4, corners: [.bottomLeft, .bottomRight])
                        .padding([.top], 2)
                    Spacer()
                }
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [
                        .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0),
                        .init(color: Color(red: 25/255, green: 25/255, blue: 25/255), location: 1)
                    ]), startPoint: .bottom, endPoint: .top))
                        .frame(width: geometry.size.width-4, height: geometry.size.height/6.5)
                        .cornerRadiusSpecific(radius: 4, corners: [.topLeft, .topRight])
                        .padding([.bottom], 2)
                }
                HStack {
                    Text(text)
                        .font(Font.custom("Lucida Grande Bold", size: 30))
                        .foregroundColor(.white)
                        .padding(.leading, 20)
                    Spacer()
                    ZStack {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                            .blur(radius: 5)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                    }
                }
            }
        }
    }
}

struct unselected_item: View {
    var text: String
    var body: some View {
        ZStack {
            HStack {
                Text(text)
                    .font(Font.custom("Lucida Grande Bold", size: 30))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 25, weight: .heavy))
                    .foregroundColor(Color(red: 133/255, green: 133/255, blue: 133/255))
                    .padding(.trailing, 20)
            }
        }
    }
}

// MARK: - Left-hand Graphics
struct lefthand_view: View {
    var selectedIndex: Int
    var currentItem: String
    var showPhotos: Bool

    @AppStorage("iconRotationEnabled") private var iconRotationEnabled: Bool = true
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false

    // rotation degrees when selected
    private let selectedRotation: Double = 10

    private var rotationDegrees: Double {
        iconRotationEnabled ? selectedRotation : 0
    }

    // Categories we support for icons, in menu order (Photos included based on showPhotos)
    private var categories: [Category] {
        var base: [Category] = [.movies, .tv, .music, .podcasts, .settings, .sources, .home]
        if showPhotos {
            // insert Photos before Settings to mirror menu insertion
            if let idx = base.firstIndex(of: .settings) {
                base.insert(.photos, at: idx)
            } else {
                base.append(.photos)
            }
        }
        return base
    }

    // Determine the selected category based on currentItem
    private var selectedCategory: Category? {
        categories.first(where: { $0.matches(currentItem: currentItem) })
    }

    // Choose which categories go to each slot
    private var slotMapping: (rightLarge: Category, upperLeft: Category, lowerLeft: Category) {
        // Fallback order if selected not recognized
        let defaultOrder = categories
        let selected = selectedCategory ?? defaultOrder.first ?? .movies

        // Place selected in rightLarge
        var remaining = defaultOrder.filter { $0 != selected }

        // Fill upperLeft and lowerLeft with next two in order
        let upper = remaining.first ?? selected
        remaining = remaining.dropFirst().map { $0 }
        let lower = remaining.first ?? selected

        return (rightLarge: selected, upperLeft: upper, lowerLeft: lower)
    }

    var body: some View {
        ZStack {
            // Slot B (upper-left small)
            VStack {
                ZStack {
                    iconView(for: slotMapping.upperLeft, slot: .upperLeft)
                }
                .scaleEffect(0.40)
                .padding(.top, 115)
                .padding(.trailing, 280)
                Spacer()
            }

            // Slot C (lower-left small)
            VStack {
                HStack {
                    ZStack {
                        iconView(for: slotMapping.lowerLeft, slot: .lowerLeft)
                    }
                    .scaleEffect(0.30)
                    .padding(.top, 75)
                    .offset(x: -165)
                    Spacer()
                }
                Spacer()
            }
            .clipped()

            // Slot A (right large)
            HStack {
                Spacer()
                ZStack {
                    iconView(for: slotMapping.rightLarge, slot: .rightLarge)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentItem)
    }

    private enum Slot { case rightLarge, upperLeft, lowerLeft }

    private enum Category: Equatable {
        case movies, tv, music, photos, podcasts, settings, sources, home

        func matches(currentItem: String) -> Bool {
            switch self {
            case .movies: return currentItem == "movies"
            case .tv: return currentItem == "tv shows"
            case .music: return currentItem == "music"
            case .photos: return currentItem == "photos"
            case .podcasts: return currentItem == "podcasts"
            case .settings: return currentItem == "settings"
            case .sources: return currentItem == "sources"
            case .home: return currentItem == "home"
            }
        }
    }

    @ViewBuilder
    private func iconView(for category: Category, slot: Slot) -> some View {
        // Modern: SF Symbols; Classic: image assets (with blurred variants by slot)
        if modernStyleEnabled {
            symbolView(for: category, slot: slot)
        } else {
            classicImageView(for: category, slot: slot)
        }
    }

    // MARK: Modern symbols
    @ViewBuilder
    private func symbolView(for category: Category, slot: Slot) -> some View {
        let name: String = {
            switch category {
            case .movies: return "film"
            case .tv: return "tv"
            case .music: return "music.note"
            case .photos: return "photo"
            case .podcasts: return "dot.radiowaves.left.and.right"
            case .settings: return "gear"
            case .sources: return "externaldrive"
            case .home: return "iphone.gen1"
            }
        }()

        Image(systemName: name)
            .foregroundColor(.white)
            .font(.system(size: slot == .rightLarge ? 220 : 140, weight: .regular))
            .rotationEffect(.degrees(isSelected(category) ? rotationDegrees : 0))
            .animation(.easeInOut(duration: 0.35), value: isSelected(category))
            .opacity(0.95)
    }

    // MARK: Classic assets
    @ViewBuilder
    private func classicImageView(for category: Category, slot: Slot) -> some View {
        let useBlurred: Bool = {
            switch slot {
            case .rightLarge:
                return false
            case .upperLeft:
                return true
            case .lowerLeft:
                return false
            }
        }()

        switch category {
        case .movies:
            ZStack {
                Image(useBlurred ? "BlurredMoviesIcon" : "MoviesIcon")
                    .rotationEffect(.degrees(isSelected(.movies) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.movies))

                Image(useBlurred ? "BlurredMoviesIcon" : "MoviesIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.25)
                    .rotationEffect(.degrees(isSelected(.movies) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.movies))
            }

        case .tv:
            ZStack {
                Image(useBlurred ? "BlurredTVIcon" : "TvIcon")
                    .rotationEffect(.degrees(isSelected(.tv) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.tv))

                Image(useBlurred ? "BlurredTVIcon" : "TvIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.25)
                    .rotationEffect(.degrees(isSelected(.tv) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.tv))
            }

        case .music:
            ZStack {
                Image(useBlurred ? "BlurredMusicIcon" : "MusicIcon")
                    .rotationEffect(.degrees(isSelected(.music) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.music))

                Image(useBlurred ? "BlurredMusicIcon" : "MusicIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.05)
                    .rotationEffect(.degrees(isSelected(.music) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.music))
            }

        case .photos:
            ZStack {
                Image(useBlurred ? "BlurredPhotosIcon" : "PhotosIcon")
                    .rotationEffect(.degrees(isSelected(.photos) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.photos))

                Image(useBlurred ? "BlurredPhotosIcon" : "PhotosIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.25)
                    .rotationEffect(.degrees(isSelected(.photos) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.photos))
            }

        case .podcasts:
            ZStack {
                Image(useBlurred ? "BlurredPodcastsIcon" : "PodcastsIcon")
                    .rotationEffect(.degrees(isSelected(.podcasts) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.podcasts))

                Image(useBlurred ? "BlurredPodcastsIcon" : "PodcastsIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.25)
                    .rotationEffect(.degrees(isSelected(.podcasts) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.podcasts))
            }

        case .settings:
            ZStack {
                Image(useBlurred ? "BlurredSettingsIcon" : "SettingsIcon")
                    .rotationEffect(.degrees(isSelected(.settings) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.settings))

                Image(useBlurred ? "BlurredSettingsIcon" : "SettingsIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.25)
                    .rotationEffect(.degrees(isSelected(.settings) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.settings))
            }

        case .sources:
            ZStack {
                Image(useBlurred ? "BlurredSourcesIcon" : "SourcesIcon")
                    .rotationEffect(.degrees(isSelected(.sources) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.sources))

                Image(useBlurred ? "BlurredSourcesIcon" : "SourcesIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.25)
                    .rotationEffect(.degrees(isSelected(.sources) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.sources))
                
            }
        case .home:
            ZStack {
                Image(useBlurred ? "BlurredHomeIcon" : "HomeIcon")
                    .rotationEffect(.degrees(isSelected(.home) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.home))

                Image(useBlurred ? "BlurredHomeIcon" : "HomeIcon")
                    .rotationEffect(.degrees(-180))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .offset(y: -110 + 512)
                    .opacity(0.25)
                    .rotationEffect(.degrees(isSelected(.home) ? rotationDegrees : 0))
                    .animation(.easeInOut(duration: 0.35), value: isSelected(.home))
            }
        }
    }

    private func isSelected(_ cat: Category) -> Bool {
        switch cat {
        case .movies: return currentItem == "movies"
        case .tv: return currentItem == "tv shows"
        case .music: return currentItem == "music"
        case .photos: return currentItem == "photos"
        case .podcasts: return currentItem == "podcasts"
        case .settings: return currentItem == "settings"
        case .sources: return currentItem == "sources"
        case .home: return currentItem == "home"
        }
    }
}

//** MARK: Extensions

struct CornerRadiusStyle: ViewModifier {
    var radius: CGFloat
    var corners: UIRectCorner

    struct CornerRadiusShape: Shape {
        var radius = CGFloat.infinity
        var corners = UIRectCorner.allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }

    func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

extension View {
    func cornerRadiusSpecific(radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyle(radius: radius, corners: corners))
    }
}

extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

// MARK: - Key Input Bridge for iOS and Mac Catalyst
/// A UIViewRepresentable that captures up/down/enter key events and calls a closure
struct KeyInputView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(onKey: onKey)
    }

    var onKey: (KeyInputView.Key) -> Void

    class Coordinator: UIView {
        var onKey: ((KeyInputView.Key) -> Void)?

        init(onKey: ((KeyInputView.Key) -> Void)?) {
            self.onKey = onKey
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            self.becomeFirstResponder()
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
                guard let key = press.key else { continue }
                switch key.keyCode {
                case .keyboardDownArrow:
                    onKey?(.downArrow)
                case .keyboardUpArrow:
                    onKey?(.upArrow)
                case .keyboardReturnOrEnter:
                    onKey?(.enter)
                default:
                    break
                }
            }
        }
    }

    func makeUIView(context: Context) -> Coordinator {
        let view = context.coordinator
        view.onKey = onKey
        DispatchQueue.main.async {
            view.becomeFirstResponder()
        }
        return view
    }

    func updateUIView(_ uiView: Coordinator, context: Context) {}

    enum Key {
        case upArrow, downArrow, enter
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
