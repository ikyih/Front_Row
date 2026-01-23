// Mesage to Modders, Settings must be added to both SettingsView.swift and SettingsScreenView.swift.
import SwiftUI
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

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("showHomeOnMacCatalyst") private var showHomeOnMacCatalyst: Bool = false
    @AppStorage("showCurrentSongInMusic") private var showCurrentSongInMusic: Bool = false
    @AppStorage("showPhotos") private var showPhotos: Bool = true

    // New: background color
    @AppStorage("appBackgroundHex") private var appBackgroundHex: String = "#000000FF"
    @State private var backgroundColorSelection: Color = .black

    // For update check
    @State private var showingUpdateAlert = false
    @State private var updateAlertMessage = ""
    @State private var updateChangelog: String? = nil

    var body: some View {
        NavigationView {
            Form {
                #if targetEnvironment(macCatalyst)
                Toggle("Show Home on Mac Catalyst", isOn: $showHomeOnMacCatalyst)
                #endif
                Toggle("Show Current Song Playing in Music", isOn: $showCurrentSongInMusic)
                Toggle("Show Photos", isOn: $showPhotos)

                Section(header: Text("Appearance")) {
                    ColorPicker("Background Color", selection: $backgroundColorSelection, supportsOpacity: true)
                }

                // --- Update Check Button ---
                Button {
                    Task { await checkForUpdate() }
                } label: {
                    Label("Check for Update", systemImage: "arrow.triangle.2.circlepath")
                }
                .foregroundColor(.accentColor)
                // --- End Update Check Button ---
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Update Check", isPresented: $showingUpdateAlert) {
                Button("OK", role: .cancel) {}
                if updateAlertMessage.contains("update") && updateAlertMessage.contains("frontrow-app.vercel.app") {
                    Button("Go to Download Page") {
                        if let url = URL(string: "https://frontrow-app.vercel.app/Leopard.html") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(updateAlertMessage)
                    if let changelog = updateChangelog, !changelog.isEmpty {
                        Divider()
                        Text("Changelog:")
                            .font(.headline)
                        Text(changelog)
                            .font(.body)
                    }
                }
            }
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
    }

    // MARK: - Update Check Logic
    private func checkForUpdate() async {
        let currentVersion = await loadLocalVersion()
        guard let currentVersion = currentVersion else {
            updateAlertMessage = "Could not determine current version from version.json."
            updateChangelog = nil
            showingUpdateAlert = true
            return
        }
        guard let url = URL(string: "https://frontrow-app.vercel.app/update.json") else {
            updateAlertMessage = "Invalid update URL."
            updateChangelog = nil
            showingUpdateAlert = true
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let text = String(data: data, encoding: .utf8) else {
                updateAlertMessage = "Could not decode update info."
                updateChangelog = nil
                showingUpdateAlert = true
                return
            }
            if let firstLine = text.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines), !firstLine.isEmpty {
                let result = compareVersion(current: currentVersion, latest: firstLine)
                switch result {
                case .orderedAscending:
                    // Show changelog (plain string) for this version
                    let changelog = await loadChangelog()
                    updateAlertMessage = "A new version (\(firstLine)) is available! Please visit frontrow-app.vercel.app to update."
                    updateChangelog = changelog
                case .orderedSame:
                    updateAlertMessage = "You're all up-to-date."
                    updateChangelog = nil
                case .orderedDescending:
                    updateAlertMessage = "Hi beta Tester!"
                    updateChangelog = nil
                }
            } else {
                updateAlertMessage = "Update info not found."
                updateChangelog = nil
            }
        } catch {
            updateAlertMessage = "Failed to check for updates: \(error.localizedDescription)"
            updateChangelog = nil
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

    private func compareVersion(current: String, latest: String) -> ComparisonResult {
        current.compare(latest, options: .numeric)
    }

    private func loadChangelog() async -> String? {
        // Load change.json as a plain string
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
}
