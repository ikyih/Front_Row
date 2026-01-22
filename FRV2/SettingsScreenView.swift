import SwiftUI

struct SettingsScreenView: View {
    @AppStorage("showHomeOnMacCatalyst") private var showHomeOnMacCatalyst: Bool = false
    @AppStorage("showCurrentSongInMusic") private var showCurrentSongInMusic: Bool = false
    @AppStorage("iconRotationEnabled") private var iconRotationEnabled: Bool = true
    @AppStorage("modernStyleEnabled") private var modernStyleEnabled: Bool = false
    @AppStorage("colorInvertEnabled") private var colorInvertEnabled: Bool = false
    @AppStorage("appBackgroundHex") private var appBackgroundHex: String = "#000000FF"
    @State private var backgroundColorSelection: Color = .black

    @State private var showingUpdateAlert = false
    @State private var updateResult: UpdateResult?

    struct UpdateResult {
        let message: String
        let changelog: String?
        let localVersion: String
        let remoteVersion: String?
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .onAppear {
            if let c = Color(hexRGBA: appBackgroundHex) {
                backgroundColorSelection = c
            } else {
                backgroundColorSelection = .black
                appBackgroundHex = "#000000FF"
            }
        }
        .onChange(of: backgroundColorSelection) { newValue in
            appBackgroundHex = newValue.hexRGBAString
        }
        .alert("Update Check", isPresented: $showingUpdateAlert) {
            Button("OK", role: .cancel) {}
            if let result = updateResult,
               result.message.contains("update"),
               result.message.contains("frontrow-app.vercel.app") 
            {
                Button("Go to Download Page") {
                    if let url = URL(string: "https://frontrow-app.vercel.app/") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            if let result = updateResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.message)
                    if let changelog = result.changelog, !changelog.isEmpty {
                        Divider()
                        Text("Changelog:")
                            .font(.headline)
                        Text(changelog)
                            .font(.body)
                    }
                    Divider()
                    Text("Installed Version: \(result.localVersion)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("Latest Version: \(result.remoteVersion ?? "Unknown")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var header: some View {
        HStack { Spacer() }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Debug")
                #if targetEnvironment(macCatalyst)
                settingToggle(
                    title: "Show Home on Mac Catalyst",
                    isOn: $showHomeOnMacCatalyst
                )
                Divider().background(Color.white.opacity(0.1))
                #endif

                sectionHeader("Music")
                settingToggle(
                    title: "Show Current Song Playing in Music",
                    isOn: $showCurrentSongInMusic
                )
                Divider().background(Color.white.opacity(0.1))

                sectionHeader("Appearance")
                settingToggle(
                    title: "Enable Icon Rotation",
                    isOn: $iconRotationEnabled
                )
                Divider().background(Color.white.opacity(0.1))

                settingToggle(
                    title: "Modern Style",
                    isOn: $modernStyleEnabled
                )
                Divider().background(Color.white.opacity(0.1))
                
                backgroundColorRow
                Divider().background(Color.white.opacity(0.1))

                // --- Update Check Button ---
                Button {
                    Task { await checkForUpdate() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Check for Update")
                            .font(modernStyleEnabled ? .system(size: 18, weight: .semibold)
                                  : Font.custom("Lucida Grande Bold", size: 18))
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                Divider().background(Color.white.opacity(0.1))
                // --- End Update Check Button ---

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(modernStyleEnabled ? .system(size: 18, weight: .semibold)
                  : Font.custom("Lucida Grande Bold", size: 18))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    private func settingToggle(title: String, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            HStack {
                Text(title)
                    .font(modernStyleEnabled ? .system(size: 18, weight: .semibold)
                          : Font.custom("Lucida Grande Bold", size: 18))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color(red: 43/255, green: 75/255, blue: 121/255))
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Update Check Logic
    private func checkForUpdate() async {
        let localVersion = await loadLocalVersion() ?? "Unknown"
        do {
            guard let updateURL = URL(string: "https://frontrow-app.vercel.app/update.json") else {
                updateResult = UpdateResult(
                    message: "Invalid update URL.",
                    changelog: nil,
                    localVersion: localVersion,
                    remoteVersion: nil
                )
                showingUpdateAlert = true
                return
            }
            let (data, _) = try await URLSession.shared.data(from: updateURL)
            guard let text = String(data: data, encoding: .utf8) else {
                updateResult = UpdateResult(
                    message: "Could not decode update info.",
                    changelog: nil,
                    localVersion: localVersion,
                    remoteVersion: nil
                )
                showingUpdateAlert = true
                return
            }
            guard let remoteVersion = text.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !remoteVersion.isEmpty else {
                updateResult = UpdateResult(
                    message: "Update info not found.",
                    changelog: nil,
                    localVersion: localVersion,
                    remoteVersion: nil
                )
                showingUpdateAlert = true
                return
            }

            let comparison = localVersion.compare(remoteVersion, options: .numeric)
            switch comparison {
            case .orderedAscending:
                let changelog = await loadChangelog()
                updateResult = UpdateResult(
                    message: "Version \(remoteVersion) is available! Please visit frontrow-app.vercel.app to update.",
                    changelog: changelog,
                    localVersion: localVersion,
                    remoteVersion: remoteVersion
                )
            case .orderedSame:
                updateResult = UpdateResult(
                    message: "You're all up-to-date.",
                    changelog: nil,
                    localVersion: localVersion,
                    remoteVersion: remoteVersion
                )
            case .orderedDescending:
                let changelog = await loadChangelog()
                updateResult = UpdateResult(
                    message: "Thank You for Beta Testing Front Row! You are on an Unreleased version.",
                    changelog: changelog,
                    localVersion: localVersion,
                    remoteVersion: remoteVersion
                )
            }
        } catch {
            updateResult = UpdateResult(
                message: "Failed to check for updates: \(error.localizedDescription)",
                changelog: nil,
                localVersion: localVersion,
                remoteVersion: nil
            )
        }
        showingUpdateAlert = true
    }

    private func loadLocalVersion() async -> String? {
        guard let url = Bundle.main.url(forResource: "version", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let string = String(data: data, encoding: .utf8)?
                .components(separatedBy: .newlines).first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return string?.isEmpty == false ? string : nil
        } catch {
            return nil
        }
    }

    private func loadChangelog() async -> String? {
        guard let url = Bundle.main.url(forResource: "change", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let string = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return string?.isEmpty == false ? string : nil
        } catch {
            return nil
        }
    }

    // MARK: - Background Color Row (unchanged)
    private var backgroundColorRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background Color")
                .font(modernStyleEnabled ? .system(size: 18, weight: .semibold)
                      : Font.custom("Lucida Grande Bold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            #if os(tvOS)
            HStack(spacing: 12) {
                ForEach(presetColors, id: \.self) { color in
                    Button {
                        backgroundColorSelection = color
                    } label: {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(color)
                            .frame(width: 48, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(color == backgroundColorSelection ? 1.0 : 0.3),
                                            lineWidth: color == backgroundColorSelection ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .focusable(true)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColorSelection)
                    .frame(width: 80, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            #else
            HStack {
                ColorPicker("",
                            selection: $backgroundColorSelection,
                            supportsOpacity: true)
                    .labelsHidden()
                Spacer()
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColorSelection)
                    .frame(width: 80, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            #endif
        }
    }

    private var presetColors: [Color] {
        [
            Color.black,
            Color(.sRGB, red: 0.1, green: 0.1, blue: 0.12, opacity: 1),
            Color(.sRGB, red: 0.1, green: 0.15, blue: 0.22, opacity: 1),
            Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2, opacity: 1),
            Color(.sRGB, red: 0.05, green: 0.05, blue: 0.05, opacity: 1)
        ]
    }
}

// MARK: - Color <-> Hex helpers
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

    var hexRGBAString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let R = UInt8(max(0, min(255, Int(round(r * 255)))))
        let G = UInt8(max(0, min(255, Int(round(g * 255)))))
        let B = UInt8(max(0, min(255, Int(round(b * 255)))))
        let A = UInt8(max(0, min(255, Int(round(a * 255)))))
        return String(format: "#%02X%02X%02%02X", R, G, B, A)
    }
}
