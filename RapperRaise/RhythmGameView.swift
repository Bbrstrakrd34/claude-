import SwiftUI
import AVFoundation

// MARK: - ビートを作って鳴らす（ドラムの音をその場で合成する）

final class BeatEngine {
    let sampleRate = 44100.0
    let bpm = 92.0
    let lead = 0.5          // 再生開始から最初の音までの間
    let countIn = 4         // カウント（3,2,1…）の拍数
    let beats = 16          // 本番の拍数
    var spb: Double { 60 / bpm }  // 1拍の秒数
    var totalDuration: Double { lead + Double(countIn + beats + 2) * spb }

    /// タップすべきタイミング（再生開始からの秒数）
    let noteTimes: [Double]

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    enum BeatError: Error { case format }

    init() {
        let spb = 60 / 92.0
        var notes: [Double] = []
        for b in 0..<16 {
            // 小節の頭は必ず、それ以外は75%で表拍に音符
            if b % 4 == 0 || Double.random(in: 0..<1) < 0.75 {
                notes.append(0.5 + Double(4 + b) * spb)
            }
            // 後半は裏拍も混ぜる
            if b >= 8 && b % 2 == 1 && Double.random(in: 0..<1) < 0.4 {
                notes.append(0.5 + (Double(4 + b) + 0.5) * spb)
            }
        }
        noteTimes = notes.sorted()
    }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback)
        try session.setActive(true)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw BeatError.format
        }
        let frames = AVAudioFrameCount(totalDuration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData?[0] else {
            throw BeatError.format
        }
        buffer.frameLength = frames
        let count = Int(frames)
        for i in 0..<count { data[i] = 0 }

        let sr = sampleRate
        func add(at time: Double, length: Double, _ sound: (Double) -> Double) {
            let start = Int(time * sr)
            let n = Int(length * sr)
            for i in 0..<n where start + i < count {
                data[start + i] += Float(sound(Double(i) / sr))
            }
        }

        // キック: 周波数が下がっていくサイン波
        let kick: (Double) -> Double = { t in
            sin(2 * .pi * (50 * t + 100 * (1 - exp(-t * 30)) / 30)) * exp(-t * 9) * 0.9
        }
        // スネア: ノイズ + 少し音程
        let snare: (Double) -> Double = { t in
            (Double.random(in: -1...1) * 0.5 + sin(2 * .pi * 190 * t) * 0.3) * exp(-t * 18)
        }
        // ハイハット: 短いノイズ
        let hat: (Double) -> Double = { t in
            Double.random(in: -1...1) * exp(-t * 70) * 0.22
        }
        // カウントの音
        let click: (Double) -> Double = { t in
            sin(2 * .pi * 1500 * t) * exp(-t * 40) * 0.5
        }

        for c in 0..<countIn {
            add(at: lead + Double(c) * spb, length: 0.1, click)
        }
        for b in 0..<beats {
            let t = lead + Double(countIn + b) * spb
            add(at: t, length: 0.4, kick)
            if b % 2 == 1 { add(at: t, length: 0.25, snare) }
            add(at: t, length: 0.06, hat)
            add(at: t + spb / 2, length: 0.06, hat)
        }
        for i in 0..<count { data[i] = max(-1, min(1, data[i])) }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try engine.start()
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }

    func stop() {
        player.stop()
        engine.stop()
    }
}

// MARK: - リズム練習の画面

struct RhythmGameView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    @State private var beat = BeatEngine()
    @State private var startDate: Date?
    @State private var results: [Int: Bool] = [:]   // 音符の番号 → PERFECT なら true
    @State private var flash = ""
    @State private var finished = false
    @State private var gain = 0
    @State private var notice = ""
    @State private var runID = UUID()

    private var perfect: Int { results.values.filter { $0 }.count }
    private var good: Int { results.values.filter { !$0 }.count }
    private var miss: Int { beat.noteTimes.count - results.count }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B1035), Color(hex: 0x3A0CA3)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Text("🥁 リズム練習").font(.title2.bold())
                    Spacer()
                    Button("閉じる") {
                        beat.stop()
                        dismiss()
                    }
                }
                .foregroundStyle(.white)

                if finished {
                    resultView
                } else if startDate == nil {
                    readyView
                } else {
                    playView
                }
                Spacer()
            }
            .padding()
        }
        .onDisappear { beat.stop() }
    }

    private var readyView: some View {
        VStack(spacing: 16) {
            Text("🎧").font(.system(size: 80))
            Text("ビートに合わせて、\nオレンジの輪っかが白い円に重なった瞬間にタップ！")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Button("スタート（1pt）") { startGame() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            if !notice.isEmpty {
                Text(notice).foregroundStyle(.yellow)
            }
        }
    }

    private var playView: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(startDate ?? ctx.date)
            let beatPos = (t - beat.lead) / beat.spb
            let pulse: Double = beatPos >= 0 ? 1 - (beatPos - beatPos.rounded(.down)) : 0

            VStack(spacing: 24) {
                Text(countText(beatPos))
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.yellow)
                    .frame(height: 54)
                ZStack {
                    ForEach(Array(beat.noteTimes.enumerated()), id: \.offset) { item in
                        let dt = item.element - t
                        if results[item.offset] == nil && dt > -0.15 && dt < 1.3 {
                            Circle()
                                .stroke(Color.orange, lineWidth: 5)
                                .frame(width: 130 + dt * 260, height: 130 + dt * 260)
                                .opacity(dt < 0 ? 0.4 : 1)
                        }
                    }
                    Circle().fill(Color.white.opacity(0.15))
                        .frame(width: 130, height: 130)
                        .scaleEffect(1 + 0.08 * pulse)
                    Circle().stroke(Color.white, lineWidth: 6)
                        .frame(width: 130, height: 130)
                    Text(flash)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                .frame(width: 340, height: 420)
                .contentShape(Rectangle())
                .onTapGesture { tap() }

                Text("PERFECT \(perfect)　GOOD \(good)")
                    .font(.headline.monospaced())
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 14) {
            Text(miss == 0 ? "🔥" : "🎵").font(.system(size: 80))
            Text("PERFECT \(perfect)\nGOOD \(good)\nMISS \(miss)")
                .font(.title2.monospaced().bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text("🌊 フロウ +\(gain)")
                .font(.title3.bold())
                .foregroundStyle(.yellow)
            HStack {
                Button("もう1回") { reset() }.buttonStyle(.borderedProminent)
                Button("閉じる") { dismiss() }.buttonStyle(.bordered).tint(.white)
            }
        }
    }

    private func countText(_ pos: Double) -> String {
        guard pos >= 0 else { return "" }
        let n = Int(pos)
        return n < beat.countIn ? "\(beat.countIn - n)" : ""
    }

    private func startGame() {
        guard game.pay(1, minStage: .baby) else {
            notice = game.message
            return
        }
        do {
            try beat.start()
        } catch {
            notice = "音を鳴らせませんでした"
        }
        startDate = Date()
        let id = UUID()
        runID = id
        let duration = beat.totalDuration
        Task {
            try? await Task.sleep(for: .seconds(duration))
            finish(id)
        }
    }

    private func tap() {
        guard let start = startDate else { return }
        let t = Date().timeIntervalSince(start)
        var best: (index: Int, diff: Double)?
        for (i, nt) in beat.noteTimes.enumerated() where results[i] == nil {
            let d = abs(nt - t)
            if d < 0.2 && (best == nil || d < best!.diff) {
                best = (i, d)
            }
        }
        guard let hit = best else {
            flash = "…"
            return
        }
        results[hit.index] = hit.diff < 0.08
        flash = hit.diff < 0.08 ? "PERFECT!" : "GOOD"
    }

    private func finish(_ id: UUID) {
        guard id == runID, !finished, startDate != nil else { return }
        beat.stop()
        gain = game.rewardRhythm(perfect: perfect, good: good)
        finished = true
    }

    private func reset() {
        runID = UUID()
        beat = BeatEngine()
        results = [:]
        flash = ""
        notice = ""
        startDate = nil
        finished = false
    }
}
