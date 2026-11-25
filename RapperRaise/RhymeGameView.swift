import SwiftUI
import Combine

struct RhymeGameView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    enum Phase { case ready, playing, success(Int), timeUp }

    @State private var phase: Phase = .ready
    @State private var word = Rhyme.words.randomElement()!
    @State private var answer = ""
    @State private var remaining = 30
    @State private var feedback: String?
    @State private var wrongVowels: [Character]?
    @State private var isChecking = false
    @FocusState private var focused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var target: [Character] { Rhyme.vowels(of: word.reading) ?? [] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                switch phase {
                case .ready:           readyView
                case .playing:         playingView
                case .success(let pt): resultView(success: true, gained: pt)
                case .timeUp:          resultView(success: false, gained: 0)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("韻踏みチャレンジ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .onReceive(timer) { _ in tick() }
    }

    // MARK: 画面

    private var readyView: some View {
        VStack(spacing: 16) {
            Text("🎤").font(.system(size: 80))
            Text("お題と**母音が完全に一致する言葉**を\n30秒以内に入力しよう！")
                .multilineTextAlignment(.center)
            Text("例）とうきょうたわー → おおおおあああ")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("スタート") { start() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private var playingView: some View {
        VStack(spacing: 16) {
            Text("\(remaining)")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(remaining <= 10 ? .red : .primary)
                .contentTransition(.numericText())

            VStack(spacing: 4) {
                Text(word.display).font(.largeTitle.bold())
                Text(word.reading).foregroundStyle(.secondary)
            }

            TextField("韻を踏む言葉（ひらがな）", text: $answer)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .autocorrectionDisabled()
                .focused($focused)
                .onSubmit { submit() }

            Button(isChecking ? "判定中…" : "これで勝負！") { submit() }
                .buttonStyle(.borderedProminent)
                .disabled(isChecking)

            if let feedback {
                Text(feedback).foregroundStyle(.red).bold()
            }
            if let wrongVowels {
                VStack(alignment: .leading, spacing: 6) {
                    VowelRow(label: "お題", vowels: target, compare: nil)
                    VowelRow(label: "あなた", vowels: wrongVowels, compare: target)
                }
            }
        }
    }

    private func resultView(success: Bool, gained: Int) -> some View {
        VStack(spacing: 16) {
            Text(success ? "🔥" : "⏰").font(.system(size: 80))
            Text(success ? "完璧な韻！ +\(gained)pt" : "時間切れ…")
                .font(.title.bold())
            Text(success ? "「\(word.display)」×「\(answer)」" : "「\(word.display)」の母音はこれ")
            VowelRow(label: "母音", vowels: target, compare: nil)
            HStack {
                Button("もう1回") { start() }.buttonStyle(.borderedProminent)
                Button("閉じる") { dismiss() }.buttonStyle(.bordered)
            }
        }
    }

    // MARK: 処理

    private func start() {
        var next = Rhyme.words.randomElement()!
        while next.reading == word.reading && Rhyme.words.count > 1 {
            next = Rhyme.words.randomElement()!
        }
        word = next
        answer = ""
        remaining = 30
        feedback = nil
        wrongVowels = nil
        phase = .playing
        focused = true
    }

    private func tick() {
        guard case .playing = phase, !isChecking else { return }
        withAnimation { remaining -= 1 }
        if remaining <= 0 {
            phase = .timeUp
            focused = false
        }
    }

    private func submit() {
        guard case .playing = phase, !isChecking else { return }
        switch Rhyme.judge(answer, prompt: word) {
        case .ng(let message, let vowels):
            feedback = message
            wrongVowels = vowels
        case .ok(let hira):
            guard !game.isUsedRhyme(prompt: word.reading, answer: hira) else {
                feedback = "その韻は前に使ったよ！別の言葉で"
                wrongVowels = nil
                return
            }
            isChecking = true   // AI判定中はタイマーを止める
            Task {
                let real = await WordValidator.isRealWord(hira)
                isChecking = false
                guard case .playing = phase else { return }
                if real {
                    let pt = game.rhymeReward(prompt: word.reading, answer: hira,
                                              secondsLeft: remaining)
                    focused = false
                    phase = .success(pt)
                } else {
                    feedback = "「\(answer)」は実在する言葉じゃないかも…"
                    wrongVowels = nil
                }
            }
        }
    }
}

/// 母音を1マスずつ表示。compare と違う位置は赤くする
struct VowelRow: View {
    let label: String
    let vowels: [Character]
    let compare: [Character]?

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .frame(width: 44, alignment: .leading)
            ForEach(Array(vowels.enumerated()), id: \.offset) { item in
                Text(Rhyme.kana(item.element))
                    .font(.body.monospaced().bold())
                    .frame(width: 26, height: 26)
                    .background(isMatch(item.offset, item.element)
                                ? Color.green.opacity(0.25)
                                : Color.red.opacity(0.35),
                                in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func isMatch(_ i: Int, _ v: Character) -> Bool {
        guard let compare else { return true }
        return i < compare.count && compare[i] == v
    }
}
