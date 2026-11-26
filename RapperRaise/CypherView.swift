import SwiftUI
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
        if rhymes(diss, clean) { score += 2 }
        score += Double.random(in: 0...1.5)
        let votes = min(5, max(0, Int(score.rounded())))
        let good = ["切り返しキマった！", "会場わいてる！", "うまい返し！"]
        let bad = ["もう一押し！", "押されてるぞ…", "ちょっと弱いか"]
        return (votes, (votes >= 3 ? good : bad).randomElement()!)
    }

    /// 最後の2音の母音が同じなら韻を踏んでいるとみなす
    private static func rhymes(_ a: String, _ b: String) -> Bool {
        func tail(_ s: String) -> [Character]? {
            let kana = s.filter { !$0.isPunctuation && !$0.isWhitespace && !"「」！？!?、。".contains($0) }
            guard let v = Rhyme.vowels(of: String(kana.suffix(3))) else { return nil }
            return Array(v.suffix(2))
        }
        guard let x = tail(a), let y = tail(b) else { return false }
        return x == y
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
        .onChange(of: battle.introDone) { _, done in
            if done && phase == .intro { Task { await rivalTurn() } }
        }
    }

    // MARK: 下の操作パネル

    @ViewBuilder private var panel: some View {
        switch phase {
        case .ready:
            VStack(spacing: 12) {
                Text("街でライバルと肩がぶつかる…！\n言い返して観客の旗を取れ。先にHPが2つなくなったほうの負け。")
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
                TextField("言い返せ！", text: $reply, axis: .vertical)
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
        battle.say(["\(game.data.name)は どう いいかえす？"])
        phase = .playerTurn
        focused = true
    }

    private func submit() {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        focused = false
        let diss = disses.isEmpty ? "" : disses[round % disses.count]
        Task {
            phase = .judging
            battle.say(["\(game.data.name)の いいかえし！", "「\(text)」"])
            let (v, comment) = await BattleJudge.judge(diss: diss, reply: text, age: game.age)
            try? await Task.sleep(for: .seconds(max(1.2, Double(text.count) / 32)))
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
        myHP = 0
        battle.run("battle.setHP(0, \(foeHP))")
        finish()
    }

    private func finish() {
        won = foeHP <= 0 && myHP > 0
        game.rewardCypher(win: won)
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
        opponentName = Disses.names.randomElement()!
        disses = Disses.pick(age: game.age)
        phase = .ready
    }
}
