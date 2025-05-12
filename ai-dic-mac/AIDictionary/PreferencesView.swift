import SwiftUI

struct PreferencesView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @AppStorage("fontSize") private var fontSize: Double = 14.0
    @AppStorage("shortcutEnabled") private var shortcutEnabled: Bool = true

    var body: some View {
        TabView {
            Form {
                Section(header: Text("API Settings")) {
                    TextField("DeepSeek API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("You can obtain an API key from DeepSeek's website.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Display")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)

                    VStack(alignment: .leading) {
                        Text("Font Size: \(Int(fontSize))pt")

                        Slider(value: $fontSize, in: 10 ... 24, step: 1) {
                            Text("Font Size")
                        }
                    }
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }

            Form {
                Section(header: Text("Keyboard Shortcuts")) {
                    Toggle("Enable Global Shortcut (Command+D)", isOn: $shortcutEnabled)

                    Text("When enabled, you can use Command+D anywhere to look up a word.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Text Selection")) {
                    Text("Choose how you want to select text for lookup:")

                    Picker("Selection Mode", selection: .constant("auto")) {
                        Text("Auto (Smart Detection)").tag("auto")
                        Text("On Select").tag("select")
                        Text("On Click").tag("click")
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }
            }
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("AI English Dictionary")
                .font(.largeTitle)
                .bold()

            Text("Version 1.0.0")
                .font(.title3)

            Text("An AI-powered English-to-English dictionary that helps users learn and understand English words through pure English explanations.")
                .multilineTextAlignment(.center)
                .padding()

            Spacer()

            Text("© 2023 AI Dictionary Team")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
