import SwiftUI

struct PreferencesView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true
    @AppStorage("fontSize") private var fontSize: Double = 14.0
    @AppStorage("shortcutEnabled") private var shortcutEnabled: Bool = true
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        TabView {
            generalTab
            shortcutsTab
            aboutTab
        }
        .padding()
        .frame(width: 520, height: 420)
        .background(backgroundColor)
    }
    
    private var generalTab: some View {
        Form {
            Section(header: sectionHeader("API Settings")) {
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
                            Text("DeepSeek API Key")
                                .foregroundColor(onSurfaceVariant)
                        }

                    Text("You can obtain an API key from DeepSeek's website.")
                        .font(.system(size: 11))
                        .foregroundColor(onSurfaceVariant)
                }
            }

            Section(header: sectionHeader("Display")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: cyanAccent))
                    .foregroundColor(onSurface)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(fontSize))pt")
                        .font(.system(size: 13))
                        .foregroundColor(onSurface)

                    Slider(value: $fontSize, in: 10 ... 24, step: 1) {
                        Text("Font Size")
                    }
                    .tint(cyanAccent)
                }
            }
        }
        .formStyle(GroupedFormStyle())
        .tabItem {
            Label("General", systemImage: "gear")
        }
    }
    
    private var shortcutsTab: some View {
        Form {
            Section(header: sectionHeader("Keyboard Shortcuts")) {
                Toggle("Enable Global Shortcut (⌘D)", isOn: $shortcutEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: cyanAccent))
                    .foregroundColor(onSurface)

                Text("When enabled, you can use Command+D anywhere to look up a word.")
                    .font(.system(size: 11))
                    .foregroundColor(onSurfaceVariant)
            }

            Section(header: sectionHeader("Text Selection")) {
                Text("Choose how you want to select text for lookup:")
                    .font(.system(size: 13))
                    .foregroundColor(onSurface)

                Picker("Selection Mode", selection: .constant("auto")) {
                    Text("Auto (Smart Detection)").tag("auto")
                    Text("On Select").tag("select")
                    Text("On Click").tag("click")
                }
                .pickerStyle(RadioGroupPickerStyle())
                .foregroundColor(onSurface)
            }
        }
        .formStyle(GroupedFormStyle())
        .tabItem {
            Label("Shortcuts", systemImage: "keyboard")
        }
    }
    
    private var aboutTab: some View {
        AboutView()
            .tabItem {
                Label("About", systemImage: "info.circle")
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

            Text("AI Dictionary")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(onSurface)

            Text("Version 1.0.0")
                .font(.system(size: 14))
                .foregroundColor(onSurfaceVariant)

            Text("An AI-powered English-to-English dictionary that helps users learn and understand English words through pure English explanations.")
                .font(.system(size: 13))
                .foregroundColor(onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal)

            Spacer()

            Text("© 2025 AI Dictionary")
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
