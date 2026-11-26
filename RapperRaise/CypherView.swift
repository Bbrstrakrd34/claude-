import SwiftUI
import CoreGraphics
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
        return Array(pool.shuffled().prefix(2))
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

// MARK: - サイファー（2ラウンド制のMCバトル）

struct CypherView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    enum Phase { case ready, talking, playerTurn, judging, flags, result }

    @State private var phase: Phase = .ready
    @State private var round = 0
    @State private var opponentLook = Appearance.random()
    @State private var opponentName = Disses.names.randomElement()!
    @State private var disses: [String] = []
    @State private var typed = ""
    @State private var reply = ""
    @State private var votes: [Int] = []
    @State private var comment = ""
    @State private var flagIsBlue: [Bool] = []
    @State private var shownFlags = 0
    @State private var mySprite: Image?
    @State private var foeSprite: Image?
    @State private var won = false
    @State private var notice = ""
    @FocusState private var focused: Bool

    private var blueTotal: Int { votes.reduce(0, +) }
    private var redTotal: Int { votes.count * 5 - blueTotal }
    private let field = Color(hex: 0xC8D8A8)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                header
                arena
                switch phase {
                case .ready: readyPanel
                case .talking: textBox
                case .playerTurn: playerPanel
                case .judging:
                    textBox
                    ProgressView("観客が審査中…").tint(.white).foregroundStyle(.white)
                case .flags: flagsPanel
                case .result: resultPanel
                }
                Spacer()
            }
            .padding()
        }
        .onAppear(perform: prepare)
    }

    // MARK: 画面のパーツ

    private var header: some View {
        HStack {
            Text("ROUND \(min(round + 1, 2))/2")
            Spacer()
            Text("🟥 \(redTotal)  🟦 \(blueTotal)")
            Spacer()
            Button("✕") { dismiss() }
        }
        .font(.system(.headline, design: .monospaced))
        .foregroundStyle(.white)
    }

    private var arena: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                nameplate(opponentName, age: game.age, corner: .red)
                Spacer()
                sprite(foeSprite).scaleEffect(x: -1, y: 1)
            }
            HStack(alignment: .bottom) {
                sprite(mySprite)
                Spacer()
                nameplate(game.data.name, age: game.age, corner: .blue)
            }
        }
        .padding(12)
        .background(field, in: RoundedRectangle(cornerRadius: 12))
    }

    private func sprite(_ image: Image?) -> some View {
        (image ?? Image(systemName: "person.fill"))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 110, height: 130)
    }

    private func nameplate(_ name: String, age: Int, corner: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).bold()
            Text("Lv.\(age)")
        }
        .font(.system(.subheadline, design: .monospaced))
        .foregroundStyle(.black)
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(corner, lineWidth: 3))
    }

    private var textBox: some View {
        Text(typed)
            .font(.system(size: 17, design: .monospaced))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 3))
    }

    private var readyPanel: some View {
        VStack(spacing: 12) {
            Text("相手のディスに言い返して、観客5人の旗を取れ！\n2ラウンドで旗が多いほうの勝ち。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Button("🔥 バトル開始（2pt）") {
                guard game.pay(2, minStage: .kid) else {
                    notice = game.message
                    return
                }
                Task { await startBattle() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            if !notice.isEmpty {
                Text(notice).foregroundStyle(.yellow)
            }
        }
    }

    private var playerPanel: some View {
        VStack(spacing: 10) {
            textBox
            TextField("言い返せ！", text: $reply, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
            Button("🎤 言い返す！") { submit() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var flagsPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ForEach(0..<5, id: \.self) { i in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(flagColor(i))
                            .frame(width: 26, height: 18)
                            .offset(y: i < shownFlags ? 0 : 18)
                        Text("🧍").font(.system(size: 34))
                    }
                }
            }
            if shownFlags == 5 {
                Text("「\(comment)」")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    private var resultPanel: some View {
        VStack(spacing: 12) {
            Text(won ? "🏆 勝利！" : "😤 敗北…")
                .font(.largeTitle.bold())
                .foregroundStyle(won ? .yellow : .white)
            Text("🟦 \(blueTotal) 対 🟥 \(redTotal)")
                .font(.title2.monospaced())
                .foregroundStyle(.white)
            Text(won ? "度胸・リリック・人気が大きく上がった！ +3pt" : "度胸とリリックが少し上がった")
                .foregroundStyle(.white.opacity(0.85))
            HStack {
                Button("もう1戦") { rematch() }.buttonStyle(.borderedProminent)
                Button("閉じる") { dismiss() }.buttonStyle(.bordered).tint(.white)
            }
        }
    }

    private func flagColor(_ i: Int) -> Color {
        guard i < shownFlags, i < flagIsBlue.count else { return .clear }
        return flagIsBlue[i] ? .blue : .red
    }

    // MARK: 進行

    private func prepare() {
        disses = Disses.pick(age: game.age)
        mySprite = pixel(game.data.appearance)
        foeSprite = pixel(opponentLook)
    }

    /// キャラを小さく描いてから拡大して、ドット絵っぽくする
    private func pixel(_ look: Appearance) -> Image? {
        let renderer = ImageRenderer(content: AvatarView(look: look, stage: game.stage, size: 36))
        renderer.scale = 1
        guard let cg = renderer.cgImage else { return nil }
        return Image(decorative: cg, scale: 1)
    }

    private func startBattle() async {
        phase = .talking
        await type("\(opponentName)（\(game.age)歳）が\nバトルを しかけてきた！")
        try? await Task.sleep(for: .seconds(1))
        await opponentTurn()
    }

    private func opponentTurn() async {
        phase = .talking
        await type("\(opponentName)：\n「\(disses[round])」")
        phase = .playerTurn
        focused = true
    }

    private func submit() {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        focused = false
        Task {
            phase = .judging
            await type("\(game.data.name)：\n「\(text)」")
            let (v, c) = await BattleJudge.judge(diss: disses[round], reply: text, age: game.age)
            votes.append(v)
            comment = c
            flagIsBlue = (Array(repeating: true, count: v) + Array(repeating: false, count: 5 - v)).shuffled()
            shownFlags = 0
            phase = .flags
            for i in 1...5 {
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.spring) { shownFlags = i }
            }
            try? await Task.sleep(for: .seconds(2))
            reply = ""
            if round == 0 {
                round = 1
                await opponentTurn()
            } else {
                won = blueTotal >= 6
                game.rewardCypher(win: won)
                phase = .result
            }
        }
    }

    private func type(_ s: String) async {
        typed = ""
        for ch in s {
            typed.append(ch)
            try? await Task.sleep(for: .milliseconds(40))
        }
    }

    private func rematch() {
        round = 0
        votes = []
        comment = ""
        typed = ""
        reply = ""
        notice = ""
        shownFlags = 0
        flagIsBlue = []
        opponentLook = Appearance.random()
        opponentName = Disses.names.randomElement()!
        prepare()
        phase = .ready
    }
}
