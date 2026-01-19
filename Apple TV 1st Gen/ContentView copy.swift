//
//  ContentView.swift
//  Front Row Recreated
//
//  Created by Zane Kleinberg on 6/28/21.
//

import SwiftUI
import UIKit

struct ContentView: View {
    // Settings
    @AppStorage("showHomeOnMacCatalyst") private var showHomeOnMacCatalyst: Bool = false
    @AppStorage("showPhotos") private var showPhotos: Bool = true

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
                Color.black.edgesIgnoringSafeArea(.all)
                HStack(spacing: 0) {
                    ZStack {
                        lefthand_view(selectedIndex: selectedIndex, currentItem: currentItem)
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
                    if key == .downArrow {
                        selectedIndex = min(selectedIndex + 1, menuItems.count - 1)
                    } else if key == .upArrow {
                        selectedIndex = max(selectedIndex - 1, 0)
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
                                .onTapGesture { onSelect(idx) }
                        } else {
                            unselected_item(text: menuItems[idx])
                                .frame(height: 60)
                                .padding([.leading, .trailing], 40)
                                .onTapGesture { onSelect(idx) }
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
    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            Spacer()
            ZStack {}
            Text("Front Row")
                .font(Font.custom("Lucida Grande Bold", size: 80))
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

    @AppStorage("iconRotationEnabled") private var iconRotationEnabled: Bool = true

    // rotation degrees when selected
    private let selectedRotation: Double = 10

    private var rotationDegrees: Double {
        iconRotationEnabled ? selectedRotation : 0
    }

    var body: some View {
        ZStack {
            //Smaller Music Icon
            VStack {
                HStack {
                    ZStack {
                        Image("MusicIcon")
                            .blur(radius: 20)
                            .rotationEffect(.degrees(isMusic ? rotationDegrees : 0))
                            .animation(.easeInOut(duration: 0.35), value: isMusic)

                        Image("MusicIcon")
                            .rotationEffect(.degrees(-180))
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            .offset(y: -110 + 512)
                            .opacity(0.05)
                            .rotationEffect(.degrees(isMusic ? rotationDegrees : 0))
                            .animation(.easeInOut(duration: 0.35), value: isMusic)
                    }
                    .scaleEffect(0.30)
                    .padding(.top, 75)
                    .offset(x: -165)
                    Spacer()
                }
                Spacer()
            }
            .clipped()

            //Smaller TV Icon
            VStack {
                ZStack {
                    Image("TvIcon")
                        .blur(radius: 20)
                        .rotationEffect(.degrees(isTV ? rotationDegrees : 0))
                        .animation(.easeInOut(duration: 0.35), value: isTV)

                    Image("TvIcon")
                        .rotationEffect(.degrees(-180))
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .offset(y: -110 + 512)
                        .opacity(0.25)
                        .rotationEffect(.degrees(isTV ? rotationDegrees : 0))
                        .animation(.easeInOut(duration: 0.35), value: isTV)
                }
                .scaleEffect(0.40)
                .padding(.top, 115)
                .padding(.trailing, 280)
                Spacer()
            }

            //Larger Movie Icon
            HStack {
                Spacer()
                ZStack {
                    Image("MoviesIcon")
                        .rotationEffect(.degrees(isMovies ? rotationDegrees : 0))
                        .animation(.easeInOut(duration: 0.35), value: isMovies)

                    Image("MoviesIcon")
                        .rotationEffect(.degrees(-180))
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .offset(y: -110 + 512)
                        .opacity(0.25)
                        .rotationEffect(.degrees(isMovies ? rotationDegrees : 0))
                        .animation(.easeInOut(duration: 0.35), value: isMovies)
                }
            }
        }
    }

    private var isMovies: Bool {
        currentItem == "movies"
    }

    private var isTV: Bool {
        currentItem == "tv shows"
    }

    private var isMusic: Bool {
        currentItem == "music"
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
/// A UIViewRepresentable that captures up/down arrow key events and calls a closure
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
        view.onKey = onKey
        DispatchQueue.main.async {
            view.becomeFirstResponder()
        }
        return view
    }

    func updateUIView(_ uiView: Coordinator, context: Context) {}

    enum Key {
        case upArrow, downArrow
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
