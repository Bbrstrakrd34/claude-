import SwiftUI

// MARK: - メニューの項目

enum MenuAction: Identifiable {
    case food, workout, dance, rhythm, cypher, rhyme, closet, room, status, steps, voice, reset
    var id: Self { self }
}

// MARK: - メイン画面（部屋が全画面）

struct ContentView: View {
    @EnvironmentObject var game: GameState
    @State private var showMenu = false
    @State private var pending: MenuAction?
    @State private var showFood = false
    @State private var showRhythm = false
    @State private var showCypher = false
    @State private var showRhyme = false
    @State private var showCloset = false
    @State private var showStatus = false
    @State private var editing = false
    @State private var selectedFurniture: String? = "sofa_ivory"
    @State private var deleteMode = false
    @State private var rotateCount = 0
    @State private var resetCount = 0
    @State private var confirmReset = false
    @State private var toast: String?

    var body: some View {
        ZStack {
            // 部屋
            if Room3DView.isAvailable {
                Room3DView(editing: editing,
                           selectedFurniture: selectedFurniture,
                           deleteMode: deleteMode,
                           rotateCount: rotateCount,
                           resetCount: resetCount)
                    .ignoresSafeArea()
            } else {
                Color.white.ignoresSafeArea()
                RoomView(height: 420).padding(.top, 120)
            }

            // 上の情報とメニューボタン
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    statusCard
                    Spacer()
                    if editing {
                        Button("完了") {
                            editing = false
                            deleteMode = false
                        }
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    Button {
                        showMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .frame(width: 48, height: 48)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                if let toast {
                    Text(toast)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                if editing { editPanel }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .onChange(of: game.message) { _, new in
            withAnimation { toast = new }
            Task {
                try? await Task.sleep(for: .seconds(3))
                if toast == new { withAnimation { toast = nil } }
            }
        }
        // 歩数を同期したあと、10〜18秒ごとに勝手に話しかけてくる
        .task {
            await game.syncSteps()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 10...18)))
                if Task.isCancelled { break }
                game.refreshIdle()
                if !editing { game.talk() }
            }
        }
        .sheet(isPresented: $showMenu, onDismiss: runPending) {
            MenuView(pending: $pending).environmentObject(game)
        }
        .sheet(isPresented: $showFood) { FoodView().environmentObject(game) }
        .sheet(isPresented: $showRhyme) { RhymeGameView().environmentObject(game) }
        .sheet(isPresented: $showCloset) { ClosetView().environmentObject(game) }
        .sheet(isPresented: $showStatus) { StatusView().environmentObject(game) }
        .fullScreenCover(isPresented: $showRhythm) { RhythmGameView().environmentObject(game) }
        .fullScreenCover(isPresented: $showCypher) { CypherView().environmentObject(game) }
        .alert("最初からやり直す？", isPresented: $confirmReset) {
            Button("やり直す", role: .destructive) { game.resetAll() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("育てたキャラ・ポイント・部屋・使った韻の記録がすべて消えます。")
        }
    }

    /// 模様替え中に下に出す操作パネル
    private var editPanel: some View {
        VStack(spacing: 10) {
            Text(deleteMode ? "撤去したい家具をタップ"
                            : "家具を指でつかんで動かす／何もない床をタップで選んだ家具を置く")
                .font(.caption.bold())
                .multilineTextAlignment(.center)
            Text("2本指でつまむと拡大・ずらすと移動").font(.caption2).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FurnitureChoice.all) { item in
                        let active = !deleteMode && selectedFurniture == item.id
                        Button {
                            deleteMode = false
                            selectedFurniture = item.id
                        } label: {
                            VStack(spacing: 2) {
                                Text(item.emoji).font(.title2)
                                Text(item.name).font(.caption2.bold())
                                Text(item.size).font(.system(size: 9)).foregroundStyle(.secondary)
                            }
                            .frame(width: 74, height: 70)
                            .background(active ? Color.orange.opacity(0.3) : Color.white.opacity(0.5),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(active ? Color.orange : Color.clear, lineWidth: 2))
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            HStack(spacing: 10) {
                Button("↻ 向きを変える") { rotateCount += 1 }
                    .buttonStyle(.bordered)
                Button(deleteMode ? "🗑 撤去中" : "🗑 撤去") { deleteMode.toggle() }
                    .buttonStyle(.borderedProminent)
                    .tint(deleteMode ? .red : .gray)
                Button("初期配置") { resetCount += 1 }
                    .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.bottom, 8)
    }

    /// 左上の小さなステータス
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(game.data.name).font(.headline)
            Text("\(game.age)歳・\(game.stage.name)").font(.caption)
            HStack(spacing: 6) {
                Text("🍽").font(.caption)
                ProgressView(value: game.data.hunger, total: 100)
                    .tint(game.data.hunger < 25 ? .red : (game.data.hunger < 60 ? .orange : .green))
                    .frame(width: 70)
            }
            Text("ポイント \(game.data.points)").font(.caption.bold())
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    /// メニューで選ばれたものを、メニューが閉じてから実行する
    private func runPending() {
        guard let action = pending else { return }
        pending = nil
        switch action {
        case .food: showFood = true
        case .workout: game.exercise(.workout)
        case .dance: game.exercise(.dance)
        case .rhythm: showRhythm = true
        case .cypher: showCypher = true
        case .rhyme: showRhyme = true
        case .closet: showCloset = true
        case .room: editing = true
        case .status: showStatus = true
        case .steps: Task { await game.syncSteps() }
        case .voice: game.voiceOn.toggle()
        case .reset: confirmReset = true
        }
    }
}

// MARK: - ハンバーガーメニュー

struct MenuView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    @Binding var pending: MenuAction?

    var body: some View {
        NavigationStack {
            List {
                Section("育てる（成長ポイントが増える）") {
                    row(.food, "🍽", "ごはんをあげる", "ポイントを使う")
                    row(.workout, "💪", "筋トレ", "いつでも・成長+2・度胸+1")
                    row(.dance, "🕺", "ダンス", "いつでも・成長+2・フロウ+1")
                }
                Section("ミニゲーム（能力が上がる）") {
                    row(.rhythm, "🥁", "リズム練習", "1pt")
                    row(.cypher, "🔥", "サイファー", game.stage < .kid ? "3歳から" : "2pt")
                        .disabled(game.stage < .kid)
                    row(.rhyme, "🎤", "韻踏みチャレンジ", "無料")
                }
                Section("見た目") {
                    row(.closet, "👕", "着せ替え", nil)
                    row(.room, "🛋️", "模様替え", "家具を置く・動かす")
                }
                Section("その他") {
                    row(.status, "📊", "ステータス", nil)
                    row(.steps, "🚶", "歩数を同期", "100歩 = 1pt")
                    row(.voice, game.voiceOn ? "🔊" : "🔇", game.voiceOn ? "声をオフにする" : "声をオンにする", nil)
                    #if DEBUG
                    Button("（テスト用）+10pt") { game.data.points += 10 }
                    #endif
                    Button(role: .destructive) {
                        choose(.reset)
                    } label: {
                        Label("最初からやり直す", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("メニュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func row(_ action: MenuAction, _ icon: String, _ title: String, _ detail: String?) -> some View {
        Button {
            choose(action)
        } label: {
            HStack(spacing: 14) {
                Text(icon).font(.title2)
                Text(title).foregroundStyle(.primary)
                Spacer()
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func choose(_ action: MenuAction) {
        pending = action
        dismiss()
    }
}

// MARK: - ステータス画面

struct StatusView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("名前", value: game.data.name)
                    LabeledContent("年齢", value: "\(game.age)歳・\(game.stage.name)")
                    if let style = game.style {
                        LabeledContent("スタイル", value: style.rawValue)
                    }
                    LabeledContent("身長・体重", value: "\(game.heightCM)cm・\(game.weightKG)kg")
                    LabeledContent("体格", value: game.data.appearance.build.label)
                }
                Section("成長") {
                    if let next = game.nextAgeXP {
                        let total = game.data.growth
                        ProgressView(value: Double(total - game.currentAgeXP),
                                     total: Double(next - game.currentAgeXP))
                        Text("次の誕生日まで あと \(next - total)").font(.caption)
                    } else {
                        Text("最大まで成長した！")
                    }
                    HungerGauge(hunger: game.data.hunger)
                }
                Section("能力") {
                    LabeledContent("📝 リリック", value: "\(game.data.stats.lyric)")
                    LabeledContent("🌊 フロウ", value: "\(game.data.stats.flow)")
                    LabeledContent("💪 度胸", value: "\(game.data.stats.guts)")
                    LabeledContent("⭐️ 人気", value: "\(game.data.stats.fame)")
                }
                Section {
                    LabeledContent("ポイント", value: "\(game.data.points)")
                    LabeledContent("今日の歩数", value: "\(game.data.todaySteps)歩")
                }
            }
            .navigationTitle("📊 ステータス")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
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
