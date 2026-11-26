import SwiftUI

// MARK: - ごはん（ポイントを使って成長させる）

enum Food: String, CaseIterable, Identifiable {
    case milk, riceBall, salad, chicken, burger, cake
    var id: Self { self }

    var emoji: String {
        switch self {
        case .milk: return "🍼"
        case .riceBall: return "🍙"
        case .salad: return "🥗"
        case .chicken: return "🍗"
        case .burger: return "🍔"
        case .cake: return "🍰"
        }
    }

    var name: String {
        switch self {
        case .milk: return "ミルク"
        case .riceBall: return "おにぎり"
        case .salad: return "サラダ"
        case .chicken: return "チキン"
        case .burger: return "バーガー"
        case .cake: return "ケーキ"
        }
    }

    var cost: Int {
        switch self {
        case .milk: return 1
        case .riceBall: return 2
        case .salad: return 3
        case .chicken: return 4
        case .burger: return 3
        case .cake: return 5
        }
    }

    /// 成長ポイント
    private var baseGrowth: Int {
        switch self {
        case .milk: return 3
        case .riceBall: return 5
        case .salad: return 6
        case .chicken: return 9
        case .burger: return 6
        case .cake: return 4
        }
    }

    /// ミルクは赤ちゃんのときだけよく育つ
    func growth(forAge age: Int) -> Int {
        self == .milk && age >= 3 ? 1 : baseGrowth
    }

    /// おなかの回復量
    var fill: Double {
        switch self {
        case .milk: return 15
        case .riceBall: return 25
        case .salad: return 20
        case .chicken: return 35
        case .burger: return 40
        case .cake: return 20
        }
    }

    /// 体重の変化(kg)
    var weight: Double {
        switch self {
        case .salad: return -0.5
        case .chicken: return 0.3
        case .burger: return 1
        case .cake: return 1
        default: return 0
        }
    }

    var reaction: String {
        switch self {
        case .milk: return "ミルクうま"
        case .riceBall: return "やっぱ米だな"
        case .salad: return "体が軽くなる感じ"
        case .chicken: return "これは力が出るぜ"
        case .burger: return "ジャンクしか勝たん"
        case .cake: return "甘いのは正義"
        }
    }

    var effectText: String {
        var t = "成長+\(baseGrowth)　おなか+\(Int(fill))"
        if weight > 0 { t += "　体重↑" }
        if weight < 0 { t += "　体重↓" }
        if self == .milk { t += "（赤ちゃん向け）" }
        return t
    }
}

// MARK: - ごはんを選ぶ画面

struct FoodView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HungerGauge(hunger: game.data.hunger)
                    Text("ポイント: \(game.data.points)").bold()
                }
                Section("メニュー") {
                    ForEach(Food.allCases) { food in
                        Button {
                            game.feed(food)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Text(food.emoji).font(.largeTitle)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name).bold()
                                    Text(food.effectText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(food.cost)pt").bold()
                            }
                        }
                        .disabled(game.data.points < food.cost)
                    }
                }
            }
            .navigationTitle("🍽 ごはん")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - おなかのゲージ

struct HungerGauge: View {
    let hunger: Double

    private var color: Color {
        hunger < 25 ? .red : (hunger < 60 ? .orange : .green)
    }

    private var label: String {
        hunger < 25 ? "ぺこぺこ" : (hunger < 60 ? "ふつう" : "まんぷく")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("🍽 おなか")
                Spacer()
                Text(label).foregroundStyle(color).bold()
            }
            .font(.subheadline)
            ProgressView(value: hunger, total: 100)
                .tint(color)
        }
    }
}
