import Foundation
import Combine
import HealthKit
import WidgetKit
import AVFoundation
import SwiftUI

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
    var room = RoomConfig()
    var drops: [IdleDrop] = []
    var lastDropCheck = Date()
    var growth = 0               // 成長ポイント（ごはんで増える。年齢はこれで決まる）
    var hunger: Double = 80      // おなか（100で満腹、0でぺこぺこ）
    var lastHungerUpdate = Date()
    var weightOffset: Double = 0 // 食べたもので増減する体重(kg)
    var room3D = ""              // 3Dの部屋の家具の配置（JSON）
}

/// 項目が足りない古いデータでも、初期値で補って読めるようにする
extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
}

extension SaveData {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SaveData()
        created = c.value(.created, d.created)
        name = c.value(.name, d.name)
        appearance = c.value(.appearance, d.appearance)
        stats = c.value(.stats, d.stats)
        points = c.value(.points, d.points)
        syncedDay = c.value(.syncedDay, d.syncedDay)
        syncedSteps = c.value(.syncedSteps, d.syncedSteps)
        todaySteps = c.value(.todaySteps, d.todaySteps)
        room = c.value(.room, d.room)
        drops = c.value(.drops, d.drops)
        lastDropCheck = c.value(.lastDropCheck, d.lastDropCheck)
        // 前のバージョンでは能力の合計で年齢が決まっていたので、それを引き継ぐ
        growth = c.value(.growth, stats.total)
        hunger = c.value(.hunger, d.hunger)
        lastHungerUpdate = c.value(.lastHungerUpdate, d.lastHungerUpdate)
        weightOffset = c.value(.weightOffset, d.weightOffset)
        room3D = c.value(.room3D, d.room3D)
    }
}

// MARK: - ゲーム全体の状態

@MainActor
final class GameState: ObservableObject {
    @Published var data: SaveData { didSet { save() } }
    @Published var message = "歩いてポイントを集めよう！"
    @Published var speech: String?
    @Published var eating: String?
    /// 部屋のキャラが今している動き（"workout" / "dance"）
    @Published var activity: String?
    private var lastExercise = Date.distantPast
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

    var age: Int { Self.ageXP.lastIndex(where: { data.growth >= $0 }) ?? 0 }
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
        let line = text ?? (data.hunger < 25 && Bool.random() ? hungryLine : TalkLines.line(age: age))
        speech = line
        guard voiceOn else { return }
        let u = AVSpeechUtterance(string: line)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        u.pitchMultiplier = TalkLines.pitch(age: age)
        u.rate = AVSpeechUtteranceDefaultSpeechRate
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        synth.speak(u)
    }

    private var hungryLine: String {
        switch age {
        case ..<3: return ["おぎゃー！おぎゃー！", "んまんま…", "ふぇぇ…"].randomElement()!
        case 3..<13: return ["おなかすいたー！", "ごはんまだー？"].randomElement()!
        default: return ["腹減った…", "なんか食わせてくれ", "ハラが減ってはバトルできねえ"].randomElement()!
        }
    }

    // MARK: ごはん

    func feed(_ food: Food) {
        guard data.hunger < 95 else {
            message = "もうおなかいっぱい！"
            talk(age < 3 ? "ぷいっ" : "もう食べられない…")
            return
        }
        guard pay(food.cost, minStage: .baby) else { return }
        let beforeAge = age, beforeStage = stage
        var d = data
        d.growth += food.growth(forAge: age)
        d.hunger = min(100, d.hunger + food.fill)
        d.weightOffset = min(15, max(-8, d.weightOffset + food.weight))
        data = d
        withAnimation { eating = food.emoji }
        talk(age < 3 ? "あむあむ…" : "もぐもぐ… \(food.reaction)")
        celebrate(beforeAge: beforeAge, beforeStage: beforeStage,
                  otherwise: "\(food.emoji) \(food.name)を食べた！ 成長+\(food.growth(forAge: beforeAge))")
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { eating = nil }
        }
    }

    // MARK: 筋トレ・ダンス（いつでもできる。おなかが減る）

    enum Exercise {
        case workout, dance
    }

    func exercise(_ kind: Exercise) {
        guard Date().timeIntervalSince(lastExercise) > 6 else {
            message = "ちょっと休憩中…"
            return
        }
        guard data.hunger >= 10 else {
            message = "おなかがすいて動けない…ごはんをあげよう"
            talk(hungryLine)
            return
        }
        lastExercise = Date()
        let beforeAge = age, beforeStage = stage
        var d = data
        d.growth += 2
        switch kind {
        case .workout:
            d.hunger = max(0, d.hunger - 6)
            d.stats.guts += 1
            d.weightOffset = max(-8, d.weightOffset - 0.2)
        case .dance:
            d.hunger = max(0, d.hunger - 5)
            d.stats.flow += 1
        }
        data = d
        activity = kind == .workout ? "workout" : "dance"
        let line: String
        if age < 3 {
            line = kind == .workout ? "んしょ、んしょ！" : "きゃっきゃっ♪"
        } else {
            line = kind == .workout ? ["ふんっ！ふんっ！", "筋肉は裏切らねえ", "あと10回！"].randomElement()!
                                    : ["ノッてきた！", "このビート最高", "ステップ決まった！"].randomElement()!
        }
        talk(line)
        celebrate(beforeAge: beforeAge, beforeStage: beforeStage,
                  otherwise: kind == .workout ? "💪 筋トレ！ 成長+2・度胸+1" : "🕺 ダンス！ 成長+2・フロウ+1")
        Task {
            try? await Task.sleep(for: .seconds(4.5))
            activity = nil
        }
    }

    /// 時間がたつとおなかが減る（6分で1、約10時間でぺこぺこ）
    func refreshHunger() {
        let elapsed = Date().timeIntervalSince(data.lastHungerUpdate)
        guard elapsed > 60 else { return }
        var d = data
        d.hunger = max(0, d.hunger - elapsed / 360)
        d.lastHungerUpdate = Date()
        data = d
    }

    // MARK: 体

    /// 身長(cm)。年齢と「身長」の設定から決まる
    var heightCM: Int {
        let table: [Double] = [50, 75, 86, 95, 102, 108, 115, 121, 127, 133,
                               138, 144, 150, 156, 161, 165, 168, 170, 171]
        let base = table[min(age, table.count - 1)]
        let f = age < 3 ? 1 : data.appearance.height.cmFactor
        return Int((base * f).rounded())
    }

    /// 体重(kg)。身長と「体格」から決まる
    var weightKG: Int {
        let h = Double(heightCM) / 100
        let bmi: Double = age < 3 ? 16 : (age < 12 ? 16.5 : 21)
        let w = bmi * data.appearance.build.weightFactor * h * h + data.weightOffset * min(1, Double(age) / 15)
        return max(3, Int(w.rounded()))
    }

    // MARK: ミニゲーム

    /// ポイントを払う。足りない・年齢が足りないときは false
    func pay(_ cost: Int, minStage: Stage) -> Bool {
        guard stage >= minStage else {
            message = "\(minStage.name)になったらできるよ"
            return false
        }
        guard data.points >= cost else {
            message = "ポイントが足りない…歩くか、部屋のアイテムを拾おう！"
            return false
        }
        data.points -= cost
        return true
    }

    /// リズム練習の結果。上がったフロウを返す
    func rewardRhythm(perfect: Int, good: Int) -> Int {
        let beforeAge = age, beforeStage = stage
        let gain = max(1, (perfect * 2 + good) / 3)
        data.stats.flow += gain
        celebrate(beforeAge: beforeAge, beforeStage: beforeStage, otherwise: "🥁 リズム練習 フロウ+\(gain)")
        return gain
    }

    /// サイファーの結果
    /// rhymes: バトル中に踏んだ韻の数。その数だけボーナスポイント
    func rewardCypher(win: Bool, rhymes: Int = 0) {
        let beforeAge = age, beforeStage = stage
        var d = data
        if win {
            d.stats.guts += 3
            d.stats.lyric += 3
            d.stats.fame += 4
            d.points += 3
        } else {
            d.stats.guts += 2
            d.stats.lyric += 1
        }
        d.points += rhymes
        d.stats.lyric += rhymes / 2
        data = d
        celebrate(beforeAge: beforeAge, beforeStage: beforeStage,
                  otherwise: win ? "🏆 サイファーで勝った！" : "😤 サイファーで負けた…次は勝つ")
    }

    // MARK: 放置

    /// 3分ごとに部屋にアイテムが1つ落ちる（最大12個）
    func refreshIdle() {
        guard data.created else { return }
        refreshHunger()
    }

    func collect(_ drop: IdleDrop) {
        var d = data
        d.drops.removeAll { $0.id == drop.id }
        d.points += drop.kind.points
        if drop.kind == .letter { d.stats.fame += 1 }
        data = d
        message = "\(drop.kind.emoji) +\(drop.kind.points)pt"
    }

    // MARK: リセット

    /// キャラ作成画面に戻る。今日の歩数の同期記録だけは残す（もう一度ポイントをもらえないように）
    func resetAll() {
        synth.stopSpeaking(at: .immediate)
        UserDefaults.standard.removeObject(forKey: usedRhymesKey)
        var fresh = SaveData()
        fresh.lastDropCheck = Date()
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

    // MARK: 韻踏練習

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
        celebrate(beforeAge: beforeAge, beforeStage: beforeStage, otherwise: "🎤 韻踏練習 成功！ +\(gained)pt")
        return gained
    }

    // MARK: ウィジェット

    /// ウィジェット用のデータを書き出して、再描画を依頼する
    func publishWidget() {
        guard data.created else { return }
        let total = data.growth
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
