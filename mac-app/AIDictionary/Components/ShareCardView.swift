import SwiftUI
import AppKit

enum ShareCardTheme: String, CaseIterable, Identifiable {
    case blue
    case purple
    case dark
    case gradient

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blue: return NSLocalizedString("share.theme.blue", comment: "")
        case .purple: return NSLocalizedString("share.theme.purple", comment: "")
        case .dark: return NSLocalizedString("share.theme.dark", comment: "")
        case .gradient: return NSLocalizedString("share.theme.gradient", comment: "")
        }
    }

    var backgroundGradient: LinearGradient {
        switch self {
        case .blue:
            return LinearGradient(
                colors: [Color(hex: "#1a2980"), Color(hex: "#26d0ce")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purple:
            return LinearGradient(
                colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                colors: [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gradient:
            return LinearGradient(
                colors: [Color(hex: "#11998e"), Color(hex: "#38ef7d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var cardBackground: Color {
        switch self {
        case .blue, .purple, .gradient:
            return Color.white.opacity(0.15)
        case .dark:
            return Color.white.opacity(0.1)
        }
    }

    var textColor: Color {
        .white
    }

    var secondaryTextColor: Color {
        Color.white.opacity(0.8)
    }

    var accentColor: Color {
        switch self {
        case .blue: return Color(hex: "#26d0ce")
        case .purple: return Color(hex: "#f093fb")
        case .dark: return Color(hex: "#00d4ff")
        case .gradient: return Color(hex: "#c3ff00")
        }
    }
}

struct ShareCardView: View {
    let word: Word
    var theme: ShareCardTheme = .blue
    var cardSize: CGSize = CGSize(width: 1080, height: 1080)

    @State private var renderedImage: NSImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                theme.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    cardContent
                        .frame(maxWidth: cardSize.width * 0.85)

                    Spacer()

                    appBranding
                        .padding(.bottom, 40)
                }
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

    private var cardContent: some View {
        VStack(spacing: 24) {
            wordHeader

            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.horizontal, 20)

            definitionSection

            if !word.exampleSentences.isEmpty {
                exampleSection
            }
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 40, x: 0, y: 20)
    }

    private var wordHeader: some View {
        VStack(spacing: 12) {
            Text(word.term)
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundColor(theme.textColor)
                .tracking(-1)

            HStack(spacing: 16) {
                Text(pronunciationText)
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(theme.accentColor)

                Text(word.partOfSpeech ?? NSLocalizedString("word.entry", comment: ""))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor)
                    .textCase(.uppercase)
            }
        }
    }

    private var definitionSection: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("share.definition", comment: ""))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.accentColor)
                .textCase(.uppercase)
                .tracking(2)

            Text(truncatedDefinition)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }

    private var exampleSection: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("share.example", comment: ""))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.accentColor)
                .textCase(.uppercase)
                .tracking(2)

            Text(exampleSentence)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }

    private var appBranding: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 24))
                .foregroundColor(theme.accentColor)

            Text(LocalizationManager.shared.appName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.textColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }

    private var pronunciationText: String {
        if let pronunciation = word.pronunciation?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pronunciation.isEmpty {
            return "/\(pronunciation)/"
        }
        return ""
    }

    private var truncatedDefinition: String {
        let limit = 200
        if word.definition.count > limit {
            let index = word.definition.index(word.definition.startIndex, offsetBy: limit)
            return String(word.definition[..<index]) + "..."
        }
        return word.definition
    }

    private var exampleSentence: String {
        let sentences = word.exampleSentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let firstSentence = sentences.first else {
            return ""
        }

        let limit = 150
        if firstSentence.count > limit {
            let index = firstSentence.index(firstSentence.startIndex, offsetBy: limit)
            return String(firstSentence[..<index]) + "..."
        }
        return firstSentence
    }
}

// MARK: - Image Generation Extension

extension ShareCardView {
    func generateImage() -> NSImage? {
        let hostingView = NSHostingView(rootView: self)
        hostingView.frame = CGRect(origin: .zero, size: cardSize)

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }

        bitmapRep.size = cardSize
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

        let image = NSImage(size: cardSize)
        image.addRepresentation(bitmapRep)

        return image
    }

    func generatePNGData() -> Data? {
        guard let image = generateImage(),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = cardSize
        return bitmapRep.representation(using: .png, properties: [:])
    }
}

// MARK: - Share Card Preview

struct ShareCardPreviewView: View {
    let word: Word
    @Binding var selectedTheme: ShareCardTheme
    @State private var showingShareSheet = false
    @State private var generatedImage: NSImage?

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("share.preview_title", comment: ""))
                .font(.system(size: 18, weight: .semibold))

            // Theme selector
            HStack(spacing: 12) {
                ForEach(ShareCardTheme.allCases) { theme in
                    themePreviewButton(theme)
                }
            }

            // Card preview
            ShareCardView(word: word, theme: selectedTheme, cardSize: CGSize(width: 540, height: 540))
                .frame(width: 540, height: 540)
                .cornerRadius(12)
                .shadow(radius: 10)

            // Share buttons
            HStack(spacing: 16) {
                Button(action: copyImage) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                        Text(NSLocalizedString("share.copy_image", comment: ""))
                    }
                }
                .buttonStyle(ShareButtonStyle())

                Button(action: saveImage) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                        Text(NSLocalizedString("share.save_image", comment: ""))
                    }
                }
                .buttonStyle(ShareButtonStyle())

                Button(action: showShareSheet) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(NSLocalizedString("share.share", comment: ""))
                    }
                }
                .buttonStyle(ShareButtonStyle(isPrimary: true))
            }
        }
        .padding(24)
        .background(Color(hex: "#1a1a2e"))
        .sheet(isPresented: $showingShareSheet) {
            if let image = generatedImage {
                ShareSheet(items: [image])
            }
        }
    }

    private func themePreviewButton(_ theme: ShareCardTheme) -> some View {
        Button(action: { selectedTheme = theme }) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedTheme == theme ? Color.white : Color.clear, lineWidth: 3)
                    )

                Text(theme.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private func generateImage() {
        let cardView = ShareCardView(word: word, theme: selectedTheme)
        generatedImage = cardView.generateImage()
    }

    private func copyImage() {
        generateImage()
        if let image = generatedImage {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }
    }

    private func saveImage() {
        generateImage()
        guard let image = generatedImage else { return }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "\(word.term)_card.png"
        savePanel.allowedContentTypes = [.png]

        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else { return }

            if let pngData = image.pngData {
                try? pngData.write(to: url)
            }
        }
    }

    private func showShareSheet() {
        generateImage()
        showingShareSheet = true
    }
}

// MARK: - Share Button Style

struct ShareButtonStyle: ButtonStyle {
    var isPrimary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isPrimary ? Color(hex: "#003642") : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPrimary ? Color(hex: "#00d4ff") : Color.white.opacity(0.1))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Share Sheet

struct ShareSheet: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            let sharingServicePicker = NSSharingServicePicker(items: self.items)
            sharingServicePicker.delegate = context.coordinator
            sharingServicePicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        let parent: ShareSheet

        init(_ parent: ShareSheet) {
            self.parent = parent
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
            return proposedServices
        }
    }
}

// MARK: - NSImage Extension

extension NSImage {
    var pngData: Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = self.size
        return bitmapRep.representation(using: .png, properties: [:])
    }
}
