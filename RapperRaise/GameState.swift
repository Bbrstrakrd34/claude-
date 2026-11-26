import Foundation
import Combine
import HealthKit
import WidgetKit
import AVFoundation

// MARK: - ウィジェット用の絵文字の肌色

enum SkinTone: String, CaseIterable, Identifiable, Codable {
    case light = "🏻", mediumLight = "🏼", medium = "🏽", mediumDark = "🏾", dark = "🏿"
    var id: String { rawValue }
}

// MARK: - 成長段階（年齢から決まる）

enum Stage: Int, CaseIterable, Comparable {
    case baby, kid, teen, rookie, star

    static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }

    var name: String {
        ["赤ちゃん", "キッズ", "ティーン", "新人ラッパー", "スターラッパー"][rawValue]
    }

    static func of(age: Int) -> Stage {
        switch age {
        case ..<3: return .baby
        case 3..<13: return .kid
        case 13..<18: return .teen
        case 18..<22: return .rookie
        default: return .star
        }
    }

    func emoji(_ tone: SkinTone) -> String {
        switch self {
        case .baby: return "👶" + tone.rawValue
        case .kid:  return "🧒" + tone.rawValue
        case .teen: return "🧑" + tone.rawValue
        case .rookie, .star: return "🧑" + tone.rawValue + "\u{200D}🎤"
        }
    }
}

enum RapStyle: String {
    case hardcore = "いかつい系", lyrical = "リリシスト系", party = "パーティー系", chill = "チル系"

    var items: String {
        switch self {
        case .hardcore: return "⛓️🧢"
        case .lyrical:  return "📓✒️"
        case .party:    return "🎉🕺"
        case .chill:    return "☕️🎧"
        }
    }
}

struct Stats: Codable {
    var lyric = 0, flow = 0, guts = 0, fame = 0
    var total: Int { lyric + flow + guts + fame }
}

// MARK: - 練習メニュー

enum Training: CaseIterable, Identifiable {
    case lyric, rhythm, cypher, live
    var id: Self { self }

    var title: String {
        switch self {
        case .lyric:  return "📝 ことば練習"
        case .rhythm: return "🥁 リズム練習"
        case .cypher: return "🔥 サイファー参加"
        case .live:   return "🎤 ライブ"
        }
    }

    var cost: Int {
        switch self {
        case .lyric, .rhythm: return 1
        case .cypher: return 2
        case .live: return 5
        }
    }

    var minStage: Stage {
        switch self {
        case .lyric, .rhythm: return .baby
        case .cypher: return .kid
        case .live: return .rookie
        }
    }

    func apply(_ s: inout Stats) {
        switch self {
        case .lyric:  s.lyric += 3
        case .rhythm: s.flow += 3
        case .cypher: s.guts += 2; s.flow += 1
        case .live:   s.fame += 5; s.guts += 2
        }
    }
}

// MARK: - セーブデータ

struct SaveData: Codable {
    var created = false
    var name = ""
    var appearance = Appearance()
    var stats = Stats()
    var points = 0
    var syncedDay = Date.distantPast
    var syncedSteps = 0
    var todaySteps = 0
}

// MARK: - ゲーム全体の状態

@MainActor
final class GameState: ObservableObject {
    @Published var data: SaveData { didSet { save() } }
    @Published var message = "歩いてポイントを集めよう！"
    @Published var speech: String?
    @Published var voiceOn: Bool { didSet { UserDefaults.standard.set(voiceOn, forKey: voiceKey) } }

    private let key = "rapper-save-v2"
    private let usedRhymesKey = "used-rhymes"
    private let voiceKey = "voice-on"
    private let health = HKHealthStore()
    private let synth = AVSpeechSynthesizer()

    init() {
        if let raw = UserDefaults.standard.data(forKey: "rapper-save-v2"),
           let saved = try? JSONDecoder().decode(SaveData.self, from: raw) {
            data = saved
        } else {
            data = SaveData()
        }
        voiceOn = UserDefaults.standard.object(forKey: "voice-on") as? Bool ?? true
        publishWidget()
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: key)
        }
        publishWidget()
    }

    // MARK: 年齢と成長

    /// 各年齢になるのに必要な経験値（ステータス合計）。0歳〜30歳
    static let ageXP: [Int] = (0...30).map { a in Int(0.4 * Double(a * a)) + 2 * a }

    var age: Int { Self.ageXP.lastIndex(where: { data.stats.total >= $0 }) ?? 0 }
    var currentAgeXP: Int { Self.ageXP[age] }
    var nextAgeXP: Int? { age + 1 < Self.ageXP.count ? Self.ageXP[age + 1] : nil }
    var stage: Stage { Stage.of(age: age) }

    /// 新人ラッパー以上になると、一番高い能力でスタイルが決まる
    var style: RapStyle? {
        guard stage >= .rookie else { return nil }
        let s = data.stats
        let ranking: [(Int, RapStyle)] = [
            (s.guts, .hardcore), (s.lyric, .lyrical), (s.fame, .party), (s.flow, .chill),
        ]
        return ranking.max { $0.0 < $1.0 }?.1
    }

    private func celebrate(beforeAge: Int, beforeStage: Stage, otherwise: String) {
        guard age > beforeAge else { message = otherwise; return }
        message = stage != beforeStage
            ? "🎉 \(stage.name)に成長した！（\(age)歳）"
            : "🎂 \(age)歳になった！"
        talk()
    }

    // MARK: 話しかける

    func talk(_ text: String? = nil) {
        let line = text ?? TalkLines.line(age: age)
        speech = line
        guard voiceOn else { return }
        let u = AVSpeechUtterance(string: line)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        u.pitchMultiplier = TalkLines.pitch(age: age)
        u.rate = AVSpeechUtteranceDefaultSpeechRate
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        synth.speak(u)
    }

    // MARK: 練習

    func train(_ t: Training) {
        guard stage >= t.minStage else {
            message = "\(t.minStage.name)になったらできるよ"; return
        }
        guard data.points >= t.cost else {
            message = "ポイントが足りない…歩こう！🚶"; return
        }
        let beforeAge = age, beforeStage = stage
        var d = data
        d.points -= t.cost
        t.apply(&d.stats)
        data = d
        celebrate(beforeAge: beforeAge, beforeStage: beforeStage, otherwise: "\(t.title) 完了！")
    }

    // MARK: リセット

    /// キャラ作成画面に戻る。今日の歩数の同期記録だけは残す（もう一度ポイントをもらえないように）
    func resetAll() {
        synth.stopSpeaking(at: .immediate)
        UserDefaults.standard.removeObject(forKey: usedRhymesKey)
        var fresh = SaveData()
        fresh.syncedDay = data.syncedDay
        fresh.syncedSteps = data.syncedSteps
        fresh.todaySteps = data.todaySteps
        speech = nil
        message = "歩いてポイントを集めよう！"
        data = fresh
    }

    // MARK: 歩数

    /// 今日の歩数を取得し、前回から増えた分をポイントに変換する（100歩 = 1pt）
    func syncSteps() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            message = "この端末ではヘルスケアが使えません"; return
        }
        let type = HKQuantityType(.stepCount)
        do {
            try await health.requestAuthorization(toShare: [], read: [type])
            let start = Calendar.current.startOfDay(for: .now)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
            let query = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: type, predicate: predicate),
                options: .cumulativeSum
            )
            let today = Int(try await query.result(for: health)?
                .sumQuantity()?.doubleValue(for: .count()) ?? 0)

            var d = data
            if !Calendar.current.isDateInToday(d.syncedDay) {
                d.syncedDay = .now
                d.syncedSteps = 0
            }
            d.todaySteps = today
            let gained = max(0, (today - d.syncedSteps) / 100)
            d.points += gained
            d.syncedSteps += gained * 100
            data = d
            message = "今日 \(today) 歩 → +\(gained) ポイント"
        } catch {
            message = "歩数を取得できませんでした"
        }
    }

    // MARK: 韻踏みチャレンジ

    func isUsedRhyme(prompt: String, answer: String) -> Bool {
        let used = UserDefaults.standard.stringArray(forKey: usedRhymesKey) ?? []
        return used.contains("\(prompt):\(answer)")
    }

    /// 成功報酬: 3pt + 残り10秒ごとに1pt、リリック+2
    func rhymeReward(prompt: String, answer: String, secondsLeft: Int) -> Int {
        var used = UserDefaults.standard.stringArray(forKey: usedRhymesKey) ?? []
        used.append("\(prompt):\(answer)")
        UserDefaults.standard.set(used, forKey: usedRhymesKey)

        let beforeAge = age, beforeStage = stage
        let gained = 3 + secondsLeft / 10
        var d = data
        d.points += gained
        d.stats.lyric += 2
        data = d
        celebrate(beforeAge: beforeAge, beforeStage: beforeStage, otherwise: "🎤 韻踏み成功！ +\(gained)pt")
        return gained
    }

    // MARK: ウィジェット

    /// ウィジェット用のデータを書き出して、再描画を依頼する
    func publishWidget() {
        guard data.created else { return }
        let total = data.stats.total
        let progress: Double
        if let next = nextAgeXP {
            progress = Double(total - currentAgeXP) / Double(max(next - currentAgeXP, 1))
        } else {
            progress = 1
        }
        let toneIndex = min(SkinTone.allCases.count - 1,
                            data.appearance.skin * SkinTone.allCases.count / Palette.skins.count)
        SharedStore.save(WidgetSnapshot(
            name: data.name,
            emoji: (style?.items ?? "") + stage.emoji(SkinTone.allCases[toneIndex]),
            stageName: "\(age)歳・\(stage.name)",
            styleName: style?.rawValue,
            points: data.points,
            steps: data.todaySteps,
            syncedSteps: data.syncedSteps,
            progress: progress,
            stepsDate: data.syncedDay
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
