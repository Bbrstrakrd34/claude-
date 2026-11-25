import Foundation

/// アプリ → ウィジェットに渡すデータ
/// ⚠️ このファイルはアプリとウィジェットの「両方」のターゲットに入れる
struct WidgetSnapshot: Codable {
    var name: String
    var emoji: String
    var stageName: String
    var styleName: String?
    var points: Int
    var steps: Int          // 今日の歩数
    var syncedSteps: Int    // ポイントに変換済みの歩数
    var progress: Double    // 次の段階までの進み具合（0〜1）
    var stepsDate: Date     // 歩数がいつの日のものか

    static let sample = WidgetSnapshot(
        name: "MC ベイビー", emoji: "👶🏽", stageName: "赤ちゃん", styleName: nil,
        points: 3, steps: 4321, syncedSteps: 4000, progress: 0.4, stepsDate: .now
    )
}

enum SharedStore {
    // ⚠️ Signing & Capabilities の App Groups で登録したIDと同じにする
    static let groupID = "group.com.example.rapperraise"
    private static let key = "widget-snapshot"

    static var defaults: UserDefaults? { UserDefaults(suiteName: groupID) }

    static func save(_ snap: WidgetSnapshot) {
        guard let raw = try? JSONEncoder().encode(snap) else { return }
        defaults?.set(raw, forKey: key)
    }

    static func load() -> WidgetSnapshot? {
        guard let raw = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: raw)
    }
}
