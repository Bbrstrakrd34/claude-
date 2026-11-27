import SwiftUI
import Foundation
import Combine
import UIKit
import WebKit
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - 相手のディス（年齢ごと）
// キツめに煽るけど、差別用語や、人種・性別・障害・容姿など本人が変えられないことは攻撃しない

enum Disses {
    static let kid = [
        "おまえのラップ、給食のおかわりより遅いぞ！",
        "ランドセルにマイクしまって帰りな！",
        "声ちっちゃすぎて聞こえませーん！",
        "その韻、昨日のテストより点数低いじゃん！",
        "おまえのリズム、運動会のダンスでもズレてたよな！",
        "宿題も韻もやってこないタイプだろ！",
    ]

    static let teen = [
        "親に送り迎えされてサイファー来たのか？",
        "その韻、教科書のコピペだろ",
        "イキってるけどリリック赤点、追試決定",
        "フロウが既読スルーされてんぞ",
        "ビートに置いてかれて迷子のアナウンス流しとくわ",
        "マイク握る手が震えてる、緊張しすぎだろ",
    ]

    static let adult = [
        "お前のリリック中身ゼロ、まるで空き缶",
        "そのフロウ三周遅れ、化石の展示かよ",
        "地元の名前出すなよ、誰も知らねえ",
        "ビートに置いてかれてんの気づいてる？",
        "寒いのは今夜の気温じゃなくてお前のライン",
        "マイク泣いてるぜ、持ち主選べなかったってな",
        "口だけ達者で中身はスカスカ、まるで安いポップコーン",
    ]

    static let names = [
        "MCカゲロウ", "リル・ノイズ", "ヤング・スモッグ", "DJモグラ",
        "キッド・ボルト", "MCサビ", "ビッグ・ドーナツ", "リル・ハリケーン",
    ]

    static func pick(age: Int) -> [String] {
        let pool = age < 13 ? kid : (age < 18 ? teen : adult)
        return Array(pool.shuffled().prefix(3))
    }
}

// MARK: - 判定（AI、使えなければ簡易判定）

enum BattleJudge {
    /// 青コーナー（自分）に旗を上げた人数(0〜5)とコメントを返す
    static func judge(diss: String, reply: String, age: Int) async -> (Int, String) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let r = await AIBattleJudge.judge(diss: diss, reply: reply, age: age) {
                return r
            }
        }
        #endif
        return fallback(diss: diss, reply: reply)
    }

    static func fallback(diss: String, reply: String) -> (Int, String) {
        let clean = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return (0, "何も言えてない…") }
        var score = min(Double(clean.count) / 12.0, 2.0)
        score += Double.random(in: 0...1.5)
        let votes = min(5, max(0, Int(score.rounded())))
        let good = ["切り返しキマった！", "会場わいてる！", "うまい返し！"]
        let bad = ["もう一押し！", "押されてるぞ…", "ちょっと弱いか"]
        return (votes, (votes >= 3 ? good : bad).randomElement()!)
    }

}

// MARK: - 韻の数をかぞえる（漢字まじりの文も読みに変換して比べる）

enum RhymeCounter {
    struct Word {
        let text: String
        let vowels: [Character]
    }

    /// 文を単語に分けて、それぞれの母音の並びを出す
    static func words(_ text: String) -> [Word] {
        let cf = text as CFString
        let range = CFRangeMake(0, CFStringGetLength(cf))
        guard let tk = CFStringTokenizerCreate(kCFAllocatorDefault, cf, range,
                                               CFOptionFlags(kCFStringTokenizerUnitWordBoundary),
                                               Locale(identifier: "ja_JP") as CFLocale) else { return [] }
        let ns = text as NSString
        var out: [Word] = []
        var type = CFStringTokenizerAdvanceToNextToken(tk)
        while !type.isEmpty {
            let r = CFStringTokenizerGetCurrentTokenRange(tk)
            let word = ns.substring(with: NSRange(location: r.location, length: r.length))
            var v = Rhyme.vowels(of: word)
            if v == nil,
               let latin = CFStringTokenizerCopyCurrentTokenAttribute(tk, kCFStringTokenizerAttributeLatinTranscription) as? String {
                v = vowels(romaji: latin)
            }
            if let v, !v.isEmpty { out.append(Word(text: word, vowels: v)) }
            type = CFStringTokenizerAdvanceToNextToken(tk)
        }
        return out
    }

    /// ローマ字 → 母音の並び（a i u e o / N=ん）
    static func vowels(romaji: String) -> [Character]? {
        let folded = romaji.lowercased()
            .replacingOccurrences(of: "ā", with: "aa").replacingOccurrences(of: "ī", with: "ii")
            .replacingOccurrences(of: "ū", with: "uu").replacingOccurrences(of: "ē", with: "ee")
            .replacingOccurrences(of: "ō", with: "oo").replacingOccurrences(of: "â", with: "aa")
            .replacingOccurrences(of: "î", with: "ii").replacingOccurrences(of: "û", with: "uu")
            .replacingOccurrences(of: "ê", with: "ee").replacingOccurrences(of: "ô", with: "oo")
        let chars = Array(folded)
        var result: [Character] = []
        for (i, c) in chars.enumerated() {
            if "aiueo".contains(c) {
                result.append(c)
            } else if c == "n" {
                let next: Character? = i + 1 < chars.count ? chars[i + 1] : nil
                if next == nil || !"aiueoy".contains(next!) { result.append("N") }
            } else if c == "-", let last = result.last {
                result.append(last)
            }
        }
        for i in result.indices.dropFirst() {
            if result[i] == "u" && result[i - 1] == "o" { result[i] = "o" }
            if result[i] == "i" && result[i - 1] == "e" { result[i] = "e" }
        }
        return result.isEmpty ? nil : result
    }

    /// 後ろから何音、母音がそろっているか
    private static func commonTail(_ a: [Character], _ b: [Character]) -> Int {
        var n = 0
        while n < a.count, n < b.count, a[a.count - 1 - n] == b[b.count - 1 - n] { n += 1 }
        return n
    }

    /// 言い返しの中で韻を踏んでいる数（相手のディスの言葉、または自分の別の言葉と、
    /// 後ろ3音がそろえば1つ、4音以上そろえば2つ）
    static func count(reply: String, diss: String) -> Int {
        let mine = words(reply).filter { $0.vowels.count >= 3 }
        let theirs = words(diss).filter { $0.vowels.count >= 3 }
        var total = 0
        for (i, w) in mine.enumerated() {
            var best = 0
            for (j, o) in mine.enumerated() where j != i && o.text != w.text {
                best = max(best, commonTail(w.vowels, o.vowels))
            }
            for o in theirs where o.text != w.text {
                best = max(best, commonTail(w.vowels, o.vowels))
            }
            if best >= 4 { total += 2 } else if best >= 3 { total += 1 }
        }
        return min(total, 10)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct BattleVerdict {
    @Guide(description: "青コーナー（言い返した側）に旗を上げた観客の人数", .range(0...5))
    var blueVotes: Int
    @Guide(description: "観客のひとことコメント。20文字以内の日本語")
    var comment: String
}

@available(iOS 26.0, *)
enum AIBattleJudge {
    static func judge(diss: String, reply: String, age: Int) async -> (Int, String)? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
            あなたはMCバトル会場の観客5人です。赤コーナーのディスに対する、青コーナーの切り返しを審査します。
            韻を踏んでいるか、相手の言葉をうまく拾って返しているか、ユーモアと勢いがあるかで評価してください。
            差別的な言葉や、人種・性別・障害・容姿など本人が変えられないことへの攻撃は大きく減点してください。
            """)
        let prompt = "選手の年齢: \(age)歳\n赤コーナー:「\(diss)」\n青コーナー:「\(reply)」"
        do {
            let r = try await session.respond(to: prompt, generating: BattleVerdict.self)
            return (min(max(r.content.blueVotes, 0), 5), r.content.comment)
        } catch {
            return nil
        }
    }
}
#endif

// MARK: - バトル画面（cypher.html を表示する）

struct BattleWebView: UIViewRepresentable {
    let controller: BattleController

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(controller, name: "battle")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.scrollView.isScrollEnabled = false
        web.navigationDelegate = controller
        controller.web = web
        if let url = Bundle.main.url(forResource: "cypher", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}
}

/// バトル画面(JavaScript)とのやりとり
@MainActor
final class BattleController: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    weak var web: WKWebView?
    private var loaded = false
    private var queue: [String] = []
    @Published var introDone = false

    func run(_ js: String) {
        guard loaded, let web else {
            queue.append(js)
            return
        }
        web.evaluateJavaScript(js, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded = true
        let pending = queue
        queue = []
        for js in pending { webView.evaluateJavaScript(js, completionHandler: nil) }
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if let s = message.body as? String, s == "introDone" { introDone = true }
    }

    func say(_ lines: [String]) {
        run("battle.say(\(Self.json(lines)))")
    }

    static func json<T: Encodable>(_ v: T) -> String {
        guard let d = try? JSONEncoder().encode(v), let s = String(data: d, encoding: .utf8) else { return "null" }
        return s
    }
}

// MARK: - サイファー（GBA風・HP2つの言い合いバトル）

struct CypherView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var battle = BattleController()

    enum Phase { case ready, intro, rivalTurn, playerTurn, judging, result }

    @State private var phase: Phase = .ready
    @State private var round = 0
    @State private var opponentName = Disses.names.randomElement()!
    @State private var disses: [String] = []
    @State private var reply = ""
    @State private var myHP = 2
    @State private var foeHP = 2
    @State private var won = false
    @State private var notice = ""
    @State private var timeLeft = 30
    @State private var timerTask: Task<Void, Never>?
    @State private var totalRhymes = 0
    @FocusState private var focused: Bool

    private struct Fighter: Encodable {
        let name: String
        let lv: Int
        let hoodie: String
        let skin: String
        let pants: String
        var cap: String? = nil
        var hasCap: Bool? = nil
        var hair: String? = nil
        var accent: String? = nil
        var inner: String? = nil
    }
    private struct Config: Encodable {
        let player: Fighter
        let rival: Fighter
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("🔥 サイファー").font(.headline)
                Spacer()
                Button("閉じる") { dismiss() }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            BattleWebView(controller: battle)
                .aspectRatio(3 / 2, contentMode: .fit)

            panel
                .padding(16)
            Spacer(minLength: 0)
        }
        .background(Color(hex: 0x11131A).ignoresSafeArea())
        .onAppear { disses = Disses.pick(age: game.age) }
        .onDisappear { timerTask?.cancel() }
        .onChange(of: battle.introDone) { _, done in
            if done && phase == .intro { Task { await rivalTurn() } }
        }
    }

    // MARK: 下の操作パネル

    @ViewBuilder private var panel: some View {
        switch phase {
        case .ready:
            VStack(spacing: 12) {
                Text("街でライバルと肩がぶつかる…！\n30秒以内に言い返して観客の旗を取れ。\n韻を踏めば踏むほど旗とポイントが増える！")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                pixelButton("▶ バトル開始（2pt）", color: Color(hex: 0xDC2626)) { start() }
                if !notice.isEmpty {
                    Text(notice).foregroundStyle(.yellow).font(.caption)
                }
            }
        case .intro, .rivalTurn:
            Text("…").foregroundStyle(.white.opacity(0.6))
        case .playerTurn:
            VStack(spacing: 10) {
                HStack {
                    Text("⏱ \(timeLeft)秒")
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .foregroundStyle(timeLeft <= 10 ? .red : .white)
                        .contentTransition(.numericText())
                    Spacer()
                    let live = RhymeCounter.count(reply: reply, diss: currentDiss)
                    Text("🎤 韻 ×\(live)")
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundStyle(live > 0 ? .yellow : .white.opacity(0.5))
                }
                TextField("言い返せ！（韻を踏むほど強い）", text: $reply, axis: .vertical)
                    .lineLimit(2...3)
                    .padding(12)
                    .background(Color(hex: 0xF8F6E8), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color(hex: 0x0F172A))
                    .focused($focused)
                HStack(spacing: 10) {
                    pixelButton("▶ いいかえす", color: Color(hex: 0x2563EB)) { submit() }
                        .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    pixelButton("にげる", color: Color(hex: 0x475569)) { forfeit() }
                }
            }
        case .judging:
            HStack(spacing: 10) {
                ProgressView().tint(.white)
                Text("観客が判定中…").foregroundStyle(.white)
            }
        case .result:
            VStack(spacing: 12) {
                Text(won ? "🏆 勝利！ 度胸・リリック・人気アップ ＋3pt" : "😤 負けた… 度胸とリリックが少し上がった")
                    .foregroundStyle(.white)
                if totalRhymes > 0 {
                    Text("🎤 踏んだ韻 ×\(totalRhymes) → ボーナス ＋\(totalRhymes)pt")
                        .foregroundStyle(.yellow)
                        .font(.callout.bold())
                }
                HStack(spacing: 10) {
                    pixelButton("もう1戦", color: Color(hex: 0xDC2626)) { rematch() }
                    pixelButton("もどる", color: Color(hex: 0x475569)) { dismiss() }
                }
            }
        }
    }

    private func pixelButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(color, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0x64748B), lineWidth: 2))
                .shadow(color: Color(hex: 0x0F172A), radius: 0, x: 0, y: 3)
        }
    }

    // MARK: 進行

    private func start() {
        guard game.pay(2, minStage: .kid) else {
            notice = game.message
            return
        }
        let a = game.data.appearance
        let hex = Room3DView.hex
        let player = Fighter(
            name: game.data.name, lv: game.age,
            hoodie: hex(Palette.cloth[a.topColor]),
            skin: hex(Palette.skins[a.skin]),
            pants: "#1d4ed8",
            cap: hex(Palette.cloth[a.hatColor]),
            hasCap: a.hat != .none,
            hair: hex(Palette.hair[a.hairColor])
        )
        let r = Appearance.random()
        let rival = Fighter(
            name: opponentName, lv: game.age,
            hoodie: hex(Palette.cloth[r.topColor]),
            skin: hex(Palette.skins[r.skin]),
            pants: "#1e293b",
            accent: ["#ec4899", "#22d3ee", "#facc15", "#a3e635"].randomElement()!,
            inner: hex(Palette.cloth[r.hatColor])
        )
        battle.introDone = false
        phase = .intro
        battle.run("battle.start(\(BattleController.json(Config(player: player, rival: rival))))")
    }

    private func rivalTurn() async {
        phase = .rivalTurn
        let diss = disses.isEmpty ? "お前のラップ、聞こえねえな" : disses[round % disses.count]
        battle.say(["\(opponentName)の ディス！", "「\(diss)」"])
        try? await Task.sleep(for: .seconds(Double(diss.count) / 32 + 1.4))
        battle.run("battle.hit('player')")
        try? await Task.sleep(for: .seconds(0.6))
        battle.say(["\(game.data.name)は どう いいかえす？", "のこり 30びょう！"])
        phase = .playerTurn
        focused = true
        startTimer()
    }

    private var currentDiss: String {
        disses.isEmpty ? "" : disses[round % disses.count]
    }

    /// 30秒のカウントダウン。0になったら今書いてある言葉で勝負する
    private func startTimer() {
        timerTask?.cancel()
        timeLeft = 30
        timerTask = Task {
            while timeLeft > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                withAnimation { timeLeft -= 1 }
            }
            if phase == .playerTurn { submit(timeUp: true) }
        }
    }

    private func submit(timeUp: Bool = false) {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || timeUp else { return }
        timerTask?.cancel()
        focused = false
        let diss = currentDiss
        Task {
            phase = .judging
            let v: Int
            let comment: String
            if text.isEmpty {
                battle.say(["じかんぎれ！", "\(game.data.name)は なにも いえなかった…"])
                v = 0
                comment = "時間切れ…"
                try? await Task.sleep(for: .seconds(1.6))
            } else {
                battle.say(["\(game.data.name)の いいかえし！", "「\(text)」"])
                // 韻を踏んだ数だけ、観客の旗が増える
                let rhymes = RhymeCounter.count(reply: text, diss: diss)
                totalRhymes += rhymes
                let (base, c) = await BattleJudge.judge(diss: diss, reply: text, age: game.age)
                v = min(5, base + rhymes)
                comment = rhymes > 0 ? "韻×\(rhymes)！ \(c)" : c
                try? await Task.sleep(for: .seconds(max(1.2, Double(text.count) / 32)))
            }
            let flags = (Array(repeating: true, count: v) + Array(repeating: false, count: 5 - v)).shuffled()
            battle.run("battle.flags(\(BattleController.json(flags)))")
            try? await Task.sleep(for: .seconds(2.4))
            if v >= 3 {
                foeHP -= 1
                battle.run("battle.hit('rival')")
                battle.say(["観客 あお\(v) － あか\(5 - v)", "「\(comment)」 \(opponentName)に きいた！"])
            } else {
                myHP -= 1
                battle.run("battle.hit('player')")
                battle.say(["観客 あお\(v) － あか\(5 - v)", "「\(comment)」 \(opponentName)の ペースだ…"])
            }
            battle.run("battle.setHP(\(myHP), \(foeHP))")
            try? await Task.sleep(for: .seconds(2.4))
            battle.run("battle.clearFlags()")
            reply = ""
            if myHP <= 0 || foeHP <= 0 {
                finish()
            } else {
                round += 1
                await rivalTurn()
            }
        }
    }

    private func forfeit() {
        timerTask?.cancel()
        myHP = 0
        battle.run("battle.setHP(0, \(foeHP))")
        finish()
    }

    private func finish() {
        won = foeHP <= 0 && myHP > 0
        game.rewardCypher(win: won, rhymes: totalRhymes)
        battle.run("battle.end(\(won))")
        battle.say(won ? ["\(opponentName)は マイクを おとした！", "\(game.data.name)の しょうり！"]
                       : ["\(game.data.name)は いいかえせなかった…", "つぎは ぜったい かつ！"])
        phase = .result
    }

    private func rematch() {
        round = 0
        myHP = 2
        foeHP = 2
        reply = ""
        notice = ""
        totalRhymes = 0
        opponentName = Disses.names.randomElement()!
        disses = Disses.pick(age: game.age)
        phase = .ready
    }
}
