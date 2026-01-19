//
//  ContentView.swift
//  Front Row Recreated
//
//  Updated to support Movies, TV Shows, Music, Podcasts, Photos, Settings, and Sources.
//

import SwiftUI
import UIKit
import MediaPlayer

// MARK: - ContentView
struct ContentView: View {
    @AppStorage("showHomeOnMacCatalyst") private var showHomeOnMacCatalyst = false
    @AppStorage("showPhotos") private var showPhotos = true
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled = false

    private var menuItems: [String] {
        var base = ["Movies", "TV Shows", "Music", "Podcasts", "Settings", "Sources"]
        if showPhotos { base.insert("Photos", at: min(base.count, 4)) }
        #if targetEnvironment(macCatalyst)
        if showHomeOnMacCatalyst { base.append("Home") }
        #else
        base.append("Home")
        #endif
        return base
    }

    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                HStack(spacing: 0) {
                    // LEFT: Hero / content area
                    ZStack {
                        lefthand_view(
                            selectedIndex: selectedIndex,
                            currentItem: currentItem
                        )
                        .frame(width: geometry.size.width / 2,
                               height: geometry.size.height)

                        // Display corresponding screen
                        switch currentItem {
                        case "movies":
                            MoviesScreenView()
                        case "tv shows":
                            TVScreenView()
                        case "music":
                            MusicScreenView()
                        case "podcasts":
                            PodcastsScreenView()
                        case "photos":
                            PhotosScreenView()
                        case "sources":
                            SourcesScreenView()
                        case "settings":
                            SettingsScreenView()
                        default:
                            EmptyView()
                        }
                    }
                    .frame(width: geometry.size.width / 2,
                           height: geometry.size.height)

                    // RIGHT: Menu
                    righthand_view(
                        menuItems: menuItems,
                        selectedIndex: selectedIndex,
                        onSelect: handleSelect
                    )
                    .frame(width: geometry.size.width / 2,
                           height: geometry.size.height)
                }

                // Keyboard input support
                KeyInputView { key in
                    if key == .downArrow {
                        selectedIndex = min(selectedIndex + 1, menuItems.count - 1)
                    } else if key == .upArrow {
                        selectedIndex = max(selectedIndex - 1, 0)
                    }
                }
                .frame(width: 0, height: 0)
                .focused($isFocused)
                .onAppear { isFocused = true }
            }
        }
    }

    private var currentItem: String {
        guard selectedIndex < menuItems.count else { return "" }
        return menuItems[selectedIndex].lowercased()
    }

    private func handleSelect(_ index: Int) {
        selectedIndex = index
        if menuItems[index].lowercased() == "home" {
            goToHomeScreen()
        }
    }

    private func goToHomeScreen() {
        let selector = NSSelectorFromString("suspend")
        if UIApplication.shared.responds(to: selector) {
            UIApplication.shared.perform(selector)
        }
    }
}

// MARK: - Right-hand Menu
struct righthand_view: View {
    let menuItems: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) { // spacing for modern buttons
            tv_header()
            Spacer().frame(height: 30)

            ForEach(menuItems.indices, id: \.self) { idx in
                Group {
                    if idx == selectedIndex {
                        selected_item(text: menuItems[idx])
                    } else {
                        unselected_item(text: menuItems[idx])
                    }
                }
                .frame(height: 60)
                .onTapGesture { onSelect(idx) }
            }

            Spacer().frame(height: 100)
        }
    }
}

// MARK: - Header
struct tv_header: View {
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled = false

    var body: some View {
        HStack {
            Spacer()
            Text("Front Row")
                .font(
                    modernStyleEnabled
                    ? .system(size: 72, weight: .semibold)
                    : Font.custom("Lucida Grande Bold", size: 80)
                )
                .foregroundColor(.white)
            Spacer()
        }
    }
}

// MARK: - Classic + Modern Menu Items
struct selected_item: View {
    var text: String
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled = false

    var body: some View {
        if modernStyleEnabled {
            modern_selected_item(text: text)
        } else {
            GeometryReader { _ in
                ZStack {
                    Rectangle().fill(Color(red: 43/255, green: 75/255, blue: 121/255))
                    Rectangle()
                        .fill(Color.black)
                        .border(Color(red: 38/255, green: 79/255, blue: 142/255), width: 2)
                        .glow(color: Color(red: 43/255, green: 75/255, blue: 121/255).opacity(0.5), radius: 30)

                    HStack {
                        Text(text)
                            .font(Font.custom("Lucida Grande Bold", size: 30))
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                        Spacer()
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
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled = false

    var body: some View {
        if modernStyleEnabled {
            modern_unselected_item(text: text)
        } else {
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

// MARK: - Modern Menu Items
struct modern_selected_item: View {
    var text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 20)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .padding(.trailing, 20)
        }
        .frame(height: 60)
        .background(Color(red: 39/255, green: 86/255, blue: 160/255)) // dark blue
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }
}

struct modern_unselected_item: View {
    var text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 20)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(white: 0.7))
                .padding(.trailing, 20)
        }
        .frame(height: 60)
        .background(Color(red: 18/255, green: 18/255, blue: 18/255)) // dark gray/black
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }
}

// MARK: - Left-hand Hero Icon
struct lefthand_view: View {
    var selectedIndex: Int
    var currentItem: String

    @AppStorage("iconRotationEnabled") private var iconRotationEnabled = true
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled = false

    private var rotation: Double {
        iconRotationEnabled ? 10 : 0
    }

    var body: some View {
        ZStack {
            Color.black

            if modernStyleEnabled {
                Image(heroIconName)
                    .scaleEffect(0.6)
                    .rotationEffect(.degrees(rotation))
                    .animation(.easeInOut(duration: 0.35), value: currentItem)
            } else {
                ZStack {
                    Image(heroIconName)
                        .blur(radius: 25)
                        .opacity(0.9)
                        .rotationEffect(.degrees(rotation))

                    Image(heroIconName)
                        .scaleEffect(1.05)
                        .rotationEffect(.degrees(rotation))

                    Image(heroIconName)
                        .rotationEffect(.degrees(-180))
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .offset(y: 420)
                        .opacity(0.2)
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(0.55)
                .animation(.easeInOut(duration: 0.35), value: currentItem)
            }
        }
    }

    private var heroIconName: String {
        let base: String
        switch currentItem {
        case "home": base = "Home"
        case "movies": base = "Movies"
        case "tv shows": base = "TV"
        case "music": base = "Music"
        case "photos": base = "Photos"
        case "podcasts": base = "Podcasts"
        case "settings": base = "Settings"
        case "sources": base = "Sources"
        default: base = "Movies"
        }
        return modernStyleEnabled ? "\(base)M" : "\(base)Icon"
    }
}

// MARK: - Glow Extension
extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

// MARK: - Key Input
struct KeyInputView: UIViewRepresentable {
    var onKey: (Key) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onKey: onKey)
    }

    class Coordinator: UIView {
        var onKey: ((Key) -> Void)?

        init(onKey: ((Key) -> Void)?) {
            self.onKey = onKey
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { super.init(coder: coder) }

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            becomeFirstResponder()
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
                guard let key = press.key else { continue }
                if key.keyCode == .keyboardDownArrow {
                    onKey?(.downArrow)
                } else if key.keyCode == .keyboardUpArrow {
                    onKey?(.upArrow)
                }
            }
        }
    }

    func makeUIView(context: Context) -> Coordinator {
        let view = context.coordinator
        DispatchQueue.main.async { view.becomeFirstResponder() }
        return view
    }

    func updateUIView(_ uiView: Coordinator, context: Context) {}

    enum Key {
        case upArrow, downArrow
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
