import SwiftUI

// MARK: - メイン画面

struct ContentView: View {
    @EnvironmentObject var game: GameState
    @State private var showRhyme = false
    @State private var showCloset = false
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SpeechBubble(text: game.speech)

                AvatarView(look: game.data.appearance, stage: game.stage)
                    .onTapGesture { game.talk() }

                Text(game.data.name).font(.largeTitle.bold())
                Text("\(game.age)歳・\(game.stage.name)" + (game.style.map { "・\($0.rawValue)" } ?? ""))
                    .font(.headline)
                    .foregroundStyle(.secondary)

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

                ForEach(Training.allCases) { t in
                    Button("\(t.title)（\(t.cost)pt）") { game.train(t) }
                        .buttonStyle(.bordered)
                        .disabled(game.stage < t.minStage)
                }

                Button("🎤 韻踏みチャレンジ（無料）") { showRhyme = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                HStack {
                    Button("👕 着せ替え") { showCloset = true }
                        .buttonStyle(.bordered)
                    Button(game.voiceOn ? "🔊 声オン" : "🔇 声オフ") { game.voiceOn.toggle() }
                        .buttonStyle(.bordered)
                }

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
        .sheet(isPresented: $showRhyme) {
            RhymeGameView().environmentObject(game)
        }
        .sheet(isPresented: $showCloset) {
            ClosetView().environmentObject(game)
        }
        .alert("最初からやり直す？", isPresented: $confirmReset) {
            Button("やり直す", role: .destructive) { game.resetAll() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("育てたキャラ・ポイント・使った韻の記録がすべて消えます。")
        }
    }
}

// MARK: - ふきだし

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
