import SwiftUI

struct PreferencesView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true
    @AppStorage("fontSize") private var fontSize: Double = 14.0
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        TabView {
            generalTab
            aboutTab
        }
        .padding()
        .frame(width: 520, height: 420)
        .background(backgroundColor)
    }
    
    private var generalTab: some View {
        Form {
            Section(header: sectionHeader(NSLocalizedString("preferences.api_settings", comment: ""))) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("", text: $apiKey)
                        .font(.system(size: 13))
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(surfaceHigh)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(cyanAccent.opacity(0.2), lineWidth: 1)
                        )
                        .placeholder(when: apiKey.isEmpty) {
                            Text(NSLocalizedString("preferences.api_key_placeholder", comment: ""))
                                .foregroundColor(onSurfaceVariant)
                        }

                    Text(NSLocalizedString("preferences.api_key_hint", comment: ""))
                        .font(.system(size: 11))
                        .foregroundColor(onSurfaceVariant)
                }
            }

            Section(header: sectionHeader(NSLocalizedString("preferences.language", comment: ""))) {
                Picker("", selection: $localizationManager.currentLanguage) {
                    ForEach(LocalizationManager.supportedLanguages, id: \.self) { code in
                        Text(LocalizationManager.languageNames[code] ?? code)
                            .tag(code)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section(header: sectionHeader(NSLocalizedString("preferences.display", comment: ""))) {
                Toggle(NSLocalizedString("preferences.dark_mode", comment: ""), isOn: $darkModeEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: cyanAccent))
                    .foregroundColor(onSurface)

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: NSLocalizedString("preferences.font_size", comment: ""), Int(fontSize)))
                        .font(.system(size: 13))
                        .foregroundColor(onSurface)

                    Slider(value: $fontSize, in: 10 ... 24, step: 1) {
                        Text(NSLocalizedString("preferences.font_size_slider", comment: ""))
                    }
                    .tint(cyanAccent)
                }
            }
        }
        .formStyle(GroupedFormStyle())
        .tabItem {
            Label(NSLocalizedString("preferences.general", comment: ""), systemImage: "gear")
        }
    }
    
    
    private var aboutTab: some View {
        AboutView()
            .tabItem {
                Label(NSLocalizedString("preferences.about", comment: ""), systemImage: "info.circle")
            }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(cyanAccent)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

struct AboutView: View {
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cyanAccent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 40))
                    .foregroundColor(cyanAccent)
            }

            Text(LocalizationManager.shared.appName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(onSurface)

            Text(NSLocalizedString("about.version", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(onSurfaceVariant)

            Text(NSLocalizedString("about.description", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal)

            Spacer()

            Text(NSLocalizedString("about.copyright", comment: ""))
                .font(.system(size: 11))
                .foregroundColor(onSurfaceVariant.opacity(0.7))
        }
        .padding()
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
