import SwiftUI

// MARK: - キャラ作成画面

struct CreateView: View {
    @EnvironmentObject var game: GameState
    @State private var name = ""
    @State private var tone: SkinTone = .medium

    var body: some View {
        VStack(spacing: 24) {
            Text("赤ちゃんが生まれた！").font(.title.bold())
            Text("👶" + tone.rawValue).font(.system(size: 120))
            Picker("見た目", selection: $tone) {
                ForEach(SkinTone.allCases) { t in
                    Text("👶" + t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            TextField("名前をつけてね", text: $name)
                .textFieldStyle(.roundedBorder)
            Button("育てはじめる") {
                var d = game.data
                d.name = name
                d.tone = tone
                d.created = true
                game.data = d
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty)
        }
        .padding()
    }
}

// MARK: - メイン画面

struct ContentView: View {
    @EnvironmentObject var game: GameState
    @State private var showRhyme = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text((game.style?.items ?? "") + game.stage.emoji(game.data.tone))
                    .font(.system(size: 110))
                Text(game.data.name).font(.largeTitle.bold())
                Text(game.stage.name + (game.style.map { "・\($0.rawValue)" } ?? ""))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if let next = game.nextStage {
                    ProgressView(value: Double(game.data.stats.total),
                                 total: Double(next.requiredXP))
                    Text("\(next.name)まで あと \(next.requiredXP - game.data.stats.total) XP")
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

                Button("🚶 歩数を同期") { Task { await game.syncSteps() } }
                    .buttonStyle(.borderedProminent)

                #if DEBUG
                Button("（テスト用）+10pt") { game.data.points += 10 }
                    .font(.caption)
                #endif
            }
            .padding()
        }
        .task { await game.syncSteps() }
        .sheet(isPresented: $showRhyme) {
            RhymeGameView().environmentObject(game)
        }
    }
}
