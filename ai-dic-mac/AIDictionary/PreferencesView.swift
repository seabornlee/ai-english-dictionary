import SwiftUI

// MARK: - Linear Style Colors
private enum LinearColors {
    static let bg = Color(hex: "#fafafa")
    static let bgSubtle = Color(hex: "#f4f4f5")
    static let surface = Color(hex: "#ffffff")
    static let surfaceHover = Color(hex: "#f9f9fb")
    static let surfaceActive = Color(hex: "#f0f0f2")

    static let border = Color(hex: "#e4e4e7")
    static let borderHover = Color(hex: "#d1d1d6")

    static let primary = Color(hex: "#8b5cf6")
    static let primaryLight = Color(hex: "#a78bfa")
    static let primaryBg = Color(hex: "#f3f0ff")

    static let text = Color(hex: "#18181b")
    static let textSecondary = Color(hex: "#71717a")
    static let textTertiary = Color(hex: "#a1a1aa")
}

// MARK: - Preferences View
struct PreferencesView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding()
        .frame(width: 480, height: 360)
        .background(LinearColors.surface)
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(LinearColors.textSecondary)

                    SecureField("", text: $apiKey)
                        .font(.system(size: 13))
                        .padding(10)
                        .background(LinearColors.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(LinearColors.border, lineWidth: 1)
                        )
                        .placeholder(when: apiKey.isEmpty) {
                            Text("Enter your DeepSeek API key")
                                .foregroundColor(LinearColors.textTertiary)
                                .font(.system(size: 13))
                        }

                    Text("Required for AI-powered definitions. Get your key from DeepSeek.")
                        .font(.system(size: 11))
                        .foregroundColor(LinearColors.textTertiary)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab
    private var aboutTab: some View {
        AboutView()
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearColors.primaryBg)
                    .frame(width: 80, height: 80)

                Image(systemName: "book.closed")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(LinearColors.primary)
            }

            Text(LocalizationManager.shared.appName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(LinearColors.text)

            Text("Version 1.0")
                .font(.system(size: 13))
                .foregroundColor(LinearColors.textSecondary)

            Text("AI-powered dictionary for macOS. Get instant definitions powered by DeepSeek LLM.")
                .font(.system(size: 12))
                .foregroundColor(LinearColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)

            Spacer()

            Text("© 2024 LexisDic. All rights reserved.")
                .font(.system(size: 10))
                .foregroundColor(LinearColors.textTertiary)
        }
        .padding()
    }
}

// MARK: - Preview
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(LocalizationManager.shared)
    }
}
