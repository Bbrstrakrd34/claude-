import SwiftUI

// MARK: - 部屋の色

enum RoomPalette {
    static let walls: [UInt32] = [0xF5EFE6, 0x2B2D42, 0xFFD6E0, 0xCDE7F0, 0x1C1C1E, 0x9BC53D, 0xE9C46A, 0x6D597A]
    static let floors: [UInt32] = [0xC69C6D, 0x8D6E63, 0x9E9E9E, 0x3E3E3E, 0xD7CCC8, 0x4E6E58]
}

// MARK: - 家具

enum FurnitureItem: String, OptionEnum {
    case none, sofa, bed, tv, speaker, mixer, record, plant, picture, mirrorBall
    case lamp, game, basketball, teddy, mic, trophy, headphones, guitar

    var emoji: String {
        switch self {
        case .none: return ""
        case .sofa: return "🛋️"
        case .bed: return "🛏️"
        case .tv: return "📺"
        case .speaker: return "🔊"
        case .mixer: return "🎛️"
        case .record: return "💿"
        case .plant: return "🪴"
        case .picture: return "🖼️"
        case .mirrorBall: return "🪩"
        case .lamp: return "💡"
        case .game: return "🎮"
        case .basketball: return "🏀"
        case .teddy: return "🧸"
        case .mic: return "🎤"
        case .trophy: return "🏆"
        case .headphones: return "🎧"
        case .guitar: return "🎸"
        }
    }

    var label: String {
        switch self {
        case .none: return "なし"
        case .sofa: return "🛋️ ソファ"
        case .bed: return "🛏️ ベッド"
        case .tv: return "📺 テレビ"
        case .speaker: return "🔊 スピーカー"
        case .mixer: return "🎛️ ミキサー"
        case .record: return "💿 レコード"
        case .plant: return "🪴 観葉植物"
        case .picture: return "🖼️ 絵"
        case .mirrorBall: return "🪩 ミラーボール"
        case .lamp: return "💡 ライト"
        case .game: return "🎮 ゲーム"
        case .basketball: return "🏀 ボール"
        case .teddy: return "🧸 ぬいぐるみ"
        case .mic: return "🎤 マイク"
        case .trophy: return "🏆 トロフィー"
        case .headphones: return "🎧 ヘッドホン"
        case .guitar: return "🎸 ギター"
        }
    }
}

/// 家具を置ける場所（x, y は部屋の幅・高さに対する割合）
struct FurnitureSlot {
    let name: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let front: Bool

    static let all: [FurnitureSlot] = [
        .init(name: "壁・左", x: 0.22, y: 0.22, size: 46, front: false),
        .init(name: "壁・右", x: 0.78, y: 0.22, size: 46, front: false),
        .init(name: "奥・左", x: 0.14, y: 0.52, size: 62, front: false),
        .init(name: "奥・右", x: 0.86, y: 0.52, size: 62, front: false),
        .init(name: "手前・左", x: 0.12, y: 0.88, size: 70, front: true),
        .init(name: "手前・右", x: 0.88, y: 0.88, size: 70, front: true),
    ]
}

struct RoomConfig: Codable, Equatable {
    var wall = 0
    var floor = 0
    var slots: [FurnitureItem] = [.picture, .mirrorBall, .speaker, .plant, .sofa, .none]
}

extension RoomConfig {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = RoomConfig()
        wall = c.value(.wall, d.wall)
        floor = c.value(.floor, d.floor)
        let s = c.value(.slots, d.slots)
        slots = s.count == FurnitureSlot.all.count ? s : d.slots
    }
}

// MARK: - 放置で部屋に落ちるアイテム

enum DropKind: String, Codable {
    case mic, disc, letter

    var emoji: String {
        switch self {
        case .mic: return "🎤"
        case .disc: return "💿"
        case .letter: return "💌"
        }
    }

    var points: Int {
        switch self {
        case .mic: return 1
        case .disc: return 2
        case .letter: return 5
        }
    }
}

struct IdleDrop: Codable, Identifiable, Equatable {
    var id = UUID()
    var x: Double
    var y: Double
    var kind: DropKind

    static func random() -> IdleDrop {
        let r = Double.random(in: 0..<1)
        let kind: DropKind = r < 0.7 ? .mic : (r < 0.95 ? .disc : .letter)
        return IdleDrop(x: Double.random(in: 0.2...0.8), y: Double.random(in: 0.64...0.94), kind: kind)
    }
}

// MARK: - 部屋の画面（キャラがうろうろする）

struct RoomView: View {
    @EnvironmentObject var game: GameState
    var height: CGFloat = 330

    @State private var pos = CGPoint(x: 0.5, y: 0.75)
    @State private var facingLeft = false
    @State private var bob = false

    private var stageScale: CGFloat {
        switch game.stage {
        case .baby: return 0.6
        case .kid: return 0.8
        case .teen: return 0.95
        case .rookie, .star: return 1
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let room = game.data.room
            let avatarSize = 92 * stageScale * game.data.appearance.height.scale

            ZStack {
                // 壁
                Rectangle()
                    .fill(Color(hex: RoomPalette.walls[room.wall]))
                    .frame(width: w, height: h * 0.55)
                    .position(x: w / 2, y: h * 0.275)
                // 床
                Rectangle()
                    .fill(Color(hex: RoomPalette.floors[room.floor]))
                    .frame(width: w, height: h * 0.45)
                    .position(x: w / 2, y: h * 0.775)
                // 床の線（奥行き）
                ForEach(1..<6, id: \.self) { i in
                    Rectangle().fill(.black.opacity(0.06))
                        .frame(width: w, height: 2)
                        .position(x: w / 2, y: h * 0.55 + h * 0.45 * CGFloat(i) / 6)
                }
                Rectangle().fill(.black.opacity(0.12))
                    .frame(width: w, height: 4)
                    .position(x: w / 2, y: h * 0.55)

                // 奥の家具
                furniture(front: false, w: w, h: h, room: room)

                // 落ちているアイテム
                ForEach(game.data.drops) { drop in
                    Text(drop.kind.emoji)
                        .font(.system(size: 28))
                        .shadow(radius: 2)
                        .position(x: drop.x * w, y: drop.y * h)
                        .onTapGesture { game.collect(drop) }
                }

                // キャラとふきだし
                VStack(spacing: 2) {
                    if let speech = game.speech {
                        Text(speech)
                            .font(.caption.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.black)
                            .frame(maxWidth: 200)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    AvatarView(look: game.data.appearance, stage: game.stage, size: avatarSize)
                        .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
                        .offset(y: bob ? -3 : 0)
                        .onTapGesture { game.talk() }
                }
                .position(x: pos.x * w, y: pos.y * h - avatarSize * 0.55)

                // 手前の家具
                furniture(front: true, w: w, h: h, room: room)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35).repeatForever()) { bob = true }
        }
        // うろうろ歩く
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 2.5...5)))
                let nx = Double.random(in: 0.22...0.78)
                let ny = Double.random(in: 0.68...0.86)
                facingLeft = nx < pos.x
                withAnimation(.easeInOut(duration: 2.2)) { pos = CGPoint(x: nx, y: ny) }
            }
        }
        // 放置アイテムを増やす
        .task {
            while !Task.isCancelled {
                game.refreshIdle()
                try? await Task.sleep(for: .seconds(20))
            }
        }
    }

    private func furniture(front: Bool, w: CGFloat, h: CGFloat, room: RoomConfig) -> some View {
        ForEach(FurnitureSlot.all.indices.filter { FurnitureSlot.all[$0].front == front }, id: \.self) { i in
            let slot = FurnitureSlot.all[i]
            let item = room.slots[i]
            if item != .none {
                Text(item.emoji)
                    .font(.system(size: slot.size))
                    .position(x: slot.x * w, y: slot.y * h - slot.size * 0.4)
            }
        }
    }
}

// MARK: - 模様替え画面

struct RoomEditView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    RoomView(height: 260)
                    ColorRow(title: "壁の色", colors: RoomPalette.walls, selection: $game.data.room.wall)
                    ColorRow(title: "床の色", colors: RoomPalette.floors, selection: $game.data.room.floor)
                    Divider()
                    ForEach(FurnitureSlot.all.indices, id: \.self) { i in
                        ChipRow(title: FurnitureSlot.all[i].name, selection: $game.data.room.slots[i])
                    }
                }
                .padding()
            }
            .navigationTitle("模様替え")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}
