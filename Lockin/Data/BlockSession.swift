import Foundation

enum BlockMode: String, CaseIterable, Identifiable, Hashable {
    case now, limit, schedule
    var id: String { rawValue }

    var title: String {
        switch self {
        case .now:      return "NOW"
        case .limit:    return "LIMIT"
        case .schedule: return "SCHEDULE"
        }
    }

    var subtitle: String {
        switch self {
        case .now:      return "今すぐ一定時間ロックする"
        case .limit:    return "アプリごとに1日の上限を設ける"
        case .schedule: return "曜日と時間で自動ブロック"
        }
    }

    var systemImage: String {
        switch self {
        case .now:      return "bolt.fill"
        case .limit:    return "gauge.with.needle.fill"
        case .schedule: return "calendar.badge.clock"
        }
    }

    var isPremiumOnly: Bool { self == .schedule }
}

struct BlockSession: Identifiable, Hashable {
    let id = UUID()
    var mode: BlockMode
    var durationMinutes: Int
    var appNames: [String]
    var strictMode: Bool
    var startedAt: Date = .init()

    var endsAt: Date { startedAt.addingTimeInterval(TimeInterval(durationMinutes * 60)) }
}
