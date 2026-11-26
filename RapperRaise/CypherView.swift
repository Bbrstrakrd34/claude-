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

// MARK: - サイファー（レトロRPG風の2ラウンド制MCバトル）

struct CypherView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    enum Phase { case ready, intro, talking, command, input, judging, flags, result }

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
    @State private var foeHype: Double = 1      // 相手の「会場の支持」ゲージ（0〜1）
    @State private var myHype: Double = 1       // 自分のゲージ
    @State private var spritesIn = false        // 登場アニメーション
    @State private var foeHit = false           // ダメージで点滅
    @State private var myHit = false
    @State private var flash = false
    @FocusState private var focused: Bool

    private var blueTotal: Int { votes.reduce(0, +) }
    private var redTotal: Int { votes.count * 5 - blueTotal }

    // レトロゲーム風の色
    private let ink = Color(hex: 0x202028)
    private let paper = Color(hex: 0xF8F8F0)
    private let frame = Color(hex: 0x3A4A6B)

    var body: some View {
        ZStack {
            Color(hex: 0x101018).ignoresSafeArea()
            VStack(spacing: 0) {
                field
                bottomPanel
            }
            if flash {
                Color.white.ignoresSafeArea().transition(.opacity)
            }
        }
        .font(.system(.body, design: .monospaced).bold())
        .onAppear(perform: prepare)
    }

    // MARK: バトルフィールド

    private var field: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // 背景（上が明るい空、下が草地）
                LinearGradient(colors: [Color(hex: 0xF0F4E8), Color(hex: 0xD8E8C0), Color(hex: 0xB8D898)],
                               startPoint: .top, endPoint: .bottom)
                // 横のスジ（レトロな雰囲気）
                VStack(spacing: 6) {
                    ForEach(0..<40, id: \.self) { _ in
                        Rectangle().fill(Color.white.opacity(0.18)).frame(height: 2)
                    }
                }

                // 相手の足場とキャラ（右上）
                Ellipse().fill(Color(hex: 0x98C070))
                    .overlay(Ellipse().stroke(Color(hex: 0x6E9850), lineWidth: 3))
                    .frame(width: w * 0.46, height: h * 0.1)
                    .position(x: w * 0.72, y: h * 0.42)
                sprite(foeSprite)
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: w * 0.34, height: h * 0.36)
                    .opacity(foeHit ? 0.15 : 1)
                    .position(x: spritesIn ? w * 0.72 : w * 1.4, y: h * 0.27)

                // 自分の足場とキャラ（左下）
                Ellipse().fill(Color(hex: 0x98C070))
                    .overlay(Ellipse().stroke(Color(hex: 0x6E9850), lineWidth: 3))
                    .frame(width: w * 0.56, height: h * 0.12)
                    .position(x: w * 0.28, y: h * 0.92)
                sprite(mySprite)
                    .frame(width: w * 0.42, height: h * 0.44)
                    .opacity(myHit ? 0.15 : 1)
                    .position(x: spritesIn ? w * 0.28 : w * -0.4, y: h * 0.74)

                // 相手のステータス枠（左上）
                statusBox(name: opponentName, hype: foeHype, showNumbers: false)
                    .frame(width: w * 0.52)
                    .position(x: w * 0.3, y: h * 0.11)

                // 自分のステータス枠（右下）
                statusBox(name: game.data.name, hype: myHype, showNumbers: true)
                    .frame(width: w * 0.54)
                    .position(x: w * 0.71, y: h * 0.62)

                // 観客の旗
                if phase == .flags {
                    flagsRow
                        .padding(10)
                        .background(paper.opacity(0.92), in: RoundedRectangle(cornerRadius: 10))
                        .position(x: w * 0.5, y: h * 0.45)
                }

                // ラウンド表示と閉じるボタン
                HStack {
                    Text("ROUND \(min(round + 1, 2))/2")
                        .font(.system(.caption, design: .monospaced).bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(ink, in: Capsule())
                        .foregroundStyle(paper)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(paper)
                            .frame(width: 34, height: 34)
                            .background(ink, in: Circle())
                    }
                }
                .padding(.horizontal, 12)
                .position(x: w / 2, y: h * 0.025 + 14)
            }
        }
    }

    private func sprite(_ image: Image?) -> some View {
        (image ?? Image(systemName: "person.fill"))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }

    private func statusBox(name: String, hype: Double, showNumbers: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).lineLimit(1)
                Spacer()
                Text("Lv\(game.age)")
            }
            .font(.system(.subheadline, design: .monospaced).bold())
            HStack(spacing: 6) {
                Text("HYPE")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xF8C030))
                    .padding(.horizontal, 4)
                    .background(ink, in: RoundedRectangle(cornerRadius: 3))
                HypeBar(value: hype)
            }
            if showNumbers {
                Text("\(Int((hype * 50).rounded()))/ 50")
                    .font(.system(.caption, design: .monospaced).bold())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .foregroundStyle(ink)
        .padding(10)
        .background(paper, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ink, lineWidth: 3))
    }

    private var flagsRow: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { i in
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(flagColor(i))
                            .frame(width: 22, height: 15)
                            .offset(y: i < shownFlags ? 0 : 14)
                        Text("🧍").font(.system(size: 28))
                    }
                }
            }
            if shownFlags == 5 {
                Text("「\(comment)」").font(.system(.caption, design: .monospaced).bold()).foregroundStyle(ink)
            }
        }
    }

    private func flagColor(_ i: Int) -> Color {
        guard i < shownFlags, i < flagIsBlue.count else { return .clear }
        return flagIsBlue[i] ? .blue : .red
    }

    // MARK: 下のパネル（文字ボックス＋コマンド）

    private var bottomPanel: some View {
        VStack(spacing: 10) {
            switch phase {
            case .ready:
                messageBox("\(game.data.name)は サイファーに さんかする？\n（2pt つかいます）")
                HStack(spacing: 10) {
                    commandButton("🔥 たたかう") {
                        guard game.pay(2, minStage: .kid) else {
                            notice = game.message
                            return
                        }
                        Task { await startBattle() }
                    }
                    commandButton("🏃 やめる") { dismiss() }
                }
                if !notice.isEmpty {
                    Text(notice).foregroundStyle(Color(hex: 0xF8C030)).font(.caption)
                }
            case .intro, .talking, .judging, .flags:
                messageBox(typed)
                if phase == .judging {
                    ProgressView().tint(paper)
                }
            case .command:
                HStack(spacing: 10) {
                    messageBox("\(game.data.name)は\nどうする？")
                    VStack(spacing: 8) {
                        commandButton("🎤 いいかえす") {
                            phase = .input
                            focused = true
                        }
                        commandButton("🏃 にげる") { forfeit() }
                    }
                    .frame(width: 150)
                }
            case .input:
                messageBox(typed)
                TextField("言い返せ！", text: $reply, axis: .vertical)
                    .lineLimit(2...3)
                    .padding(10)
                    .background(paper, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(ink)
                    .focused($focused)
                commandButton("🎤 いいかえす！") { submit() }
                    .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            case .result:
                messageBox(won ? "\(game.data.name)の しょうり！\n会場は だいもりあがり！ +3pt"
                               : "\(game.data.name)は まけてしまった…\nつぎは かてる！")
                HStack(spacing: 10) {
                    commandButton("🔁 もう1戦") { rematch() }
                    commandButton("🚪 もどる") { dismiss() }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(frame)
    }

    private func messageBox(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .bold, design: .monospaced))
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
            .padding(12)
            .background(paper, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xC8A048), lineWidth: 4))
    }

    private func commandButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(paper, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ink, lineWidth: 3))
        }
    }

    // MARK: 進行

    private func prepare() {
        disses = Disses.pick(age: game.age)
        mySprite = pixel(game.data.appearance)
        foeSprite = pixel(opponentLook)
    }

    /// キャラを小さく描いてから拡大して、ドット絵っぽくする
    private func pixel(_ look: Appearance) -> Image? {
        let renderer = ImageRenderer(content: AvatarView(look: look, stage: game.stage, size: 40))
        renderer.scale = 1
        guard let cg = renderer.cgImage else { return nil }
        return Image(decorative: cg, scale: 1)
    }

    private func startBattle() async {
        phase = .intro
        // 画面がピカッと光ってから、両者が登場
        for _ in 0..<2 {
            withAnimation(.easeInOut(duration: 0.12)) { flash = true }
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.easeInOut(duration: 0.12)) { flash = false }
            try? await Task.sleep(for: .milliseconds(140))
        }
        withAnimation(.easeOut(duration: 0.7)) { spritesIn = true }
        await type("\(opponentName)（\(game.age)さい）が\nバトルを いどんできた！")
        try? await Task.sleep(for: .seconds(1))
        await opponentTurn()
    }

    private func opponentTurn() async {
        phase = .talking
        await type("\(opponentName)の ディス！\n「\(disses[round])」")
        try? await Task.sleep(for: .milliseconds(600))
        await blink(me: true)
        phase = .command
    }

    private func submit() {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        focused = false
        Task {
            phase = .judging
            await type("\(game.data.name)の いいかえし！\n「\(text)」")
            let (v, c) = await BattleJudge.judge(diss: disses[round], reply: text, age: game.age)
            votes.append(v)
            comment = c
            flagIsBlue = (Array(repeating: true, count: v) + Array(repeating: false, count: 5 - v)).shuffled()
            shownFlags = 0
            phase = .flags
            typed = "かんきゃくの はんてい！"
            for i in 1...5 {
                try? await Task.sleep(for: .milliseconds(420))
                withAnimation(.spring) { shownFlags = i }
            }
            try? await Task.sleep(for: .seconds(1))
            // 旗の数だけゲージが減る
            withAnimation(.easeInOut(duration: 0.8)) {
                foeHype = max(0, foeHype - Double(v) / 10)
                myHype = max(0, myHype - Double(5 - v) / 10)
            }
            if v >= 3 { await blink(me: false) } else { await blink(me: true) }
            typed = v >= 3 ? "かいしんの いっぱつ！ 会場がわいた！" : (v == 0 ? "まったく ひびかなかった…" : "あまり ひびかなかった…")
            try? await Task.sleep(for: .seconds(1.5))
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

    private func blink(me: Bool) async {
        for _ in 0..<3 {
            if me { myHit = true } else { foeHit = true }
            try? await Task.sleep(for: .milliseconds(90))
            myHit = false
            foeHit = false
            try? await Task.sleep(for: .milliseconds(90))
        }
    }

    private func forfeit() {
        won = false
        game.rewardCypher(win: false)
        phase = .result
    }

    private func type(_ s: String) async {
        typed = ""
        for ch in s {
            typed.append(ch)
            try? await Task.sleep(for: .milliseconds(35))
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
        foeHype = 1
        myHype = 1
        spritesIn = false
        opponentLook = Appearance.random()
        opponentName = Disses.names.randomElement()!
        prepare()
        phase = .ready
    }
}

// MARK: - HYPEゲージ（減ると緑→黄→赤）

struct HypeBar: View {
    let value: Double

    private var color: Color {
        value > 0.5 ? Color(hex: 0x58D068) : (value > 0.2 ? Color(hex: 0xF8C030) : Color(hex: 0xE85040))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x505860))
                Capsule().fill(color)
                    .frame(width: max(0, geo.size.width * value))
            }
        }
        .frame(height: 9)
        .overlay(Capsule().stroke(Color(hex: 0x202028), lineWidth: 2))
    }
}
