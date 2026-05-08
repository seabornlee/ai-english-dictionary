import SwiftUI

// MARK: - Linear Style Colors (Shared)
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

    static let online = Color(hex: "#22c55e")
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject private var wordStore: WordStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection

            if wordStore.searchHistory.isEmpty {
                emptyState(
                    title: "No history yet",
                    systemImage: "clock",
                    description: "Your searched words will appear here"
                )
            } else {
                historyList
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(LinearColors.bg)
    }

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("History")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(LinearColors.text)

                Text("Recent lookups")
                    .font(.system(size: 13))
                    .foregroundColor(LinearColors.textSecondary)
            }

            Spacer()

            Button(action: { wordStore.clearHistory() }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                    Text("Clear")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(LinearColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(LinearColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(LinearColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var historyList: some View {
        VStack(spacing: 0) {
            tableHeader

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(wordStore.searchHistory) { word in
                        HistoryWordRow(word: word)

                        if word.id != wordStore.searchHistory.last?.id {
                            Divider()
                                .background(LinearColors.border)
                        }
                    }
                }
            }
        }
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var tableHeader: some View {
        HStack(spacing: 16) {
            Text("Word")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(LinearColors.textTertiary)
                .frame(width: 180, alignment: .leading)

            Text("Definition")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(LinearColors.textTertiary)

            Spacer()

            Text("Date")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(LinearColors.textTertiary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(LinearColors.bgSubtle)
    }

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundColor(LinearColors.textTertiary.opacity(0.5))

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(LinearColors.text)

            Text(description)
                .font(.system(size: 13))
                .foregroundColor(LinearColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - History Word Row
private struct HistoryWordRow: View {
    let word: Word

    var body: some View {
        HStack(spacing: 16) {
            Button {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenWordInDictionary"),
                    object: nil,
                    userInfo: ["word": word]
                )
            } label: {
                Text(word.term)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LinearColors.primary)
                    .frame(width: 180, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(word.definition.prefix(80) + (word.definition.count > 80 ? "..." : ""))
                .font(.system(size: 13))
                .foregroundColor(LinearColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatDate(word.timestamp))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(LinearColors.textTertiary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
