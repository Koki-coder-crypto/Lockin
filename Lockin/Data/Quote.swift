import Foundation

struct Quote: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let author: String
    let category: String

    enum CodingKeys: String, CodingKey { case text, author, category }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.text = try c.decode(String.self, forKey: .text)
        self.author = try c.decode(String.self, forKey: .author)
        self.category = (try? c.decode(String.self, forKey: .category)) ?? "focus"
    }
}

private struct QuoteBundle: Decodable { let quotes: [Quote] }

enum QuoteRepository {
    static let all: [Quote] = {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return fallback }
        if let bundle = try? JSONDecoder().decode(QuoteBundle.self, from: data) {
            return bundle.quotes
        }
        if let flat = try? JSONDecoder().decode([Quote].self, from: data) {
            return flat
        }
        return fallback
    }()

    static func daily(for date: Date = .init()) -> Quote {
        let index = Calendar.current.component(.dayOfYear, from: date) % max(all.count, 1)
        return all.indices.contains(index) ? all[index] : fallback[0]
    }

    static func random() -> Quote {
        all.randomElement() ?? fallback[0]
    }

    private static let fallback: [Quote] = [
        Quote(text: "今、集中することが、未来の自分への最大の贈り物である。", author: "Lockin", category: "focus"),
        Quote(text: "時間は戻らない。だから、奪わせない。", author: "Lockin", category: "time")
    ]
}

extension Quote {
    init(text: String, author: String, category: String) {
        self.id = UUID()
        self.text = text
        self.author = author
        self.category = category
    }
}
