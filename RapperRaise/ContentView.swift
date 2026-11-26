import SwiftUI

// MARK: - メイン画面

struct ContentView: View {
    @EnvironmentObject var game: GameState
    @State private var showRhythm = false
    @State private var showCypher = false
    @State private var showRhyme = false
    @State private var showCloset = false
    @State private var showRoom = false
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // 部屋（キャラがうろうろしている）
                RoomView()

                Text(game.data.name).font(.title.bold())
                Text("\(game.age)歳・\(game.stage.name)" + (game.style.map { "・\($0.rawValue)" } ?? ""))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("📏 \(game.heightCM)cm　⚖️ \(game.weightKG)kg　\(game.data.appearance.build.label)")
                    .font(.subheadline)

                if let next = game.nextAgeXP {
                    let total = game.data.stats.total
                    ProgressView(value: Double(total - game.currentAgeXP),
                                 total: Double(next - game.currentAgeXP))
                    Text("次の誕生日まで あと \(next - total) XP")
                        .font(.caption)
                }

                Grid(alignment: .leading, horizontalSpacing: 24) {
                    GridRow {
                        Text("📝 リリック \(game.data.stats.lyric)")
                        Text("🌊 フロウ \(game.data.stats.flow)")
                    }
                    GridRow {
                        Text("💪 度胸 \(game.data.stats.guts)")
                        Text("⭐️ 人気 \(game.data.stats.fame)")
                    }
                }

                Text("ポイント: \(game.data.points)").font(.title2.bold())
                Text(game.message).foregroundStyle(.orange)
                Text("部屋に落ちた🎤💿💌をタップすると拾えるよ（3分ごとに増える）")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // ミニゲーム
                Button("🥁 リズム練習（1pt）") { showRhythm = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                Button("🔥 サイファー（2pt）") { showCypher = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(game.stage < .kid)
                if game.stage < .kid {
                    Text("サイファーは3歳から").font(.caption).foregroundStyle(.secondary)
                }
                Button("🎤 韻踏みチャレンジ（無料）") { showRhyme = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                HStack {
                    Button("👕 着せ替え") { showCloset = true }
                    Button("🛋️ 模様替え") { showRoom = true }
                    Button(game.voiceOn ? "🔊" : "🔇") { game.voiceOn.toggle() }
                }
                .buttonStyle(.bordered)

                Button("🚶 歩数を同期") { Task { await game.syncSteps() } }
                    .buttonStyle(.borderedProminent)

                #if DEBUG
                Button("（テスト用）+10pt") { game.data.points += 10 }
                    .font(.caption)
                #endif

                Button("🔄 最初からやり直す", role: .destructive) { confirmReset = true }
                    .padding(.top, 24)
            }
            .padding()
        }
        // 歩数を同期したあと、10〜18秒ごとに勝手に話しかけてくる
        .task {
            await game.syncSteps()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 10...18)))
                if Task.isCancelled { break }
                game.talk()
            }
        }
        .fullScreenCover(isPresented: $showRhythm) {
            RhythmGameView().environmentObject(game)
        }
        .fullScreenCover(isPresented: $showCypher) {
            CypherView().environmentObject(game)
        }
        .sheet(isPresented: $showRhyme) {
            RhymeGameView().environmentObject(game)
        }
        .sheet(isPresented: $showCloset) {
            ClosetView().environmentObject(game)
        }
        .sheet(isPresented: $showRoom) {
            RoomEditView().environmentObject(game)
        }
        .alert("最初からやり直す？", isPresented: $confirmReset) {
            Button("やり直す", role: .destructive) { game.resetAll() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("育てたキャラ・ポイント・部屋・使った韻の記録がすべて消えます。")
        }
    }
}

// MARK: - ふきだし（作成画面などで使う）

struct SpeechBubble: View {
    let text: String?

    var body: some View {
        Text(text ?? " ")
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .opacity(text == nil ? 0 : 1)
            .animation(.easeInOut, value: text)
            .frame(minHeight: 44)
    }
}
