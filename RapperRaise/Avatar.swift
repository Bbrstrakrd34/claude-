import SwiftUI

// MARK: - 色

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

enum Palette {
    /// 肌の色（明るい → 濃い）
    static let skins: [UInt32] = [0xFFE0C4, 0xF5C9A0, 0xE8B48A, 0xD69A6B, 0xB97A4F, 0x8D5A3B, 0x6B4129, 0x4A2C1C]
    /// 髪の色
    static let hair: [UInt32] = [0x1E1A18, 0x3B2618, 0x6B4423, 0xD9B26A, 0xA9472A, 0x9A9A9A, 0xE87BB0, 0x4A7BE0]
    /// 服・帽子の色
    static let cloth: [UInt32] = [0x1C1C1E, 0xF2F2F2, 0xD7263D, 0x1B3A6B, 0x2E8B57, 0xF4C430, 0x7B2FF7, 0x8E8E93]
}

// MARK: - パーツの種類

protocol OptionEnum: CaseIterable, Identifiable, Hashable, Codable where AllCases: RandomAccessCollection {
    var label: String { get }
}
extension OptionEnum {
    var id: Self { self }
}

enum HairStyle: String, OptionEnum {
    case bald, buzz, short, afro, long, braids, mohawk
    var label: String {
        switch self {
        case .bald: return "スキンヘッド"
        case .buzz: return "坊主"
        case .short: return "ショート"
        case .afro: return "アフロ"
        case .long: return "ロング"
        case .braids: return "ブレイズ"
        case .mohawk: return "モヒカン"
        }
    }
}

enum EyeStyle: String, OptionEnum {
    case round, sleepy, sharp
    var label: String {
        switch self {
        case .round: return "まんまる"
        case .sleepy: return "眠そう"
        case .sharp: return "キリッ"
        }
    }
}

enum BrowStyle: String, OptionEnum {
    case soft, thick, angry
    var label: String {
        switch self {
        case .soft: return "ふつう"
        case .thick: return "太まゆ"
        case .angry: return "つり上がり"
        }
    }
}

enum MouthStyle: String, OptionEnum {
    case smile, neutral, smirk, grin
    var label: String {
        switch self {
        case .smile: return "にっこり"
        case .neutral: return "真顔"
        case .smirk: return "ニヤリ"
        case .grin: return "歯を見せる"
        }
    }
}

enum BeardStyle: String, OptionEnum {
    case none, stubble, goatee, full
    var label: String {
        switch self {
        case .none: return "なし"
        case .stubble: return "無精ひげ"
        case .goatee: return "あごひげ"
        case .full: return "フルひげ"
        }
    }
}

enum HatStyle: String, OptionEnum {
    case none, cap, beanie, bucket
    var label: String {
        switch self {
        case .none: return "なし"
        case .cap: return "キャップ"
        case .beanie: return "ニット帽"
        case .bucket: return "バケハ"
        }
    }
}

enum GlassesStyle: String, OptionEnum {
    case none, round, shades
    var label: String {
        switch self {
        case .none: return "なし"
        case .round: return "丸メガネ"
        case .shades: return "サングラス"
        }
    }
}

enum TopStyle: String, OptionEnum {
    case tee, hoodie, jersey, jacket
    var label: String {
        switch self {
        case .tee: return "Tシャツ"
        case .hoodie: return "パーカー"
        case .jersey: return "ユニフォーム"
        case .jacket: return "ジャケット"
        }
    }
}

enum ChainStyle: String, OptionEnum {
    case none, gold, silver
    var label: String {
        switch self {
        case .none: return "なし"
        case .gold: return "ゴールド"
        case .silver: return "シルバー"
        }
    }
}

enum BuildStyle: String, OptionEnum {
    case slim, normal, muscle, chubby
    var label: String {
        switch self {
        case .slim: return "細身"
        case .normal: return "ふつう"
        case .muscle: return "マッチョ"
        case .chubby: return "ぽっちゃり"
        }
    }
    var widthFactor: CGFloat {
        switch self {
        case .slim: return 0.85
        case .normal: return 1
        case .muscle: return 1.12
        case .chubby: return 1.18
        }
    }
    var armWidth: CGFloat {
        switch self {
        case .slim: return 16
        case .normal: return 20
        case .muscle: return 30
        case .chubby: return 26
        }
    }
    var weightFactor: Double {
        switch self {
        case .slim: return 0.85
        case .normal: return 1
        case .muscle: return 1.15
        case .chubby: return 1.35
        }
    }
}

enum HeightStyle: String, OptionEnum {
    case short, average, tall
    var label: String {
        switch self {
        case .short: return "小柄"
        case .average: return "ふつう"
        case .tall: return "高身長"
        }
    }
    /// 胴体の長さの倍率
    var bodyFactor: CGFloat {
        switch self {
        case .short: return 0.88
        case .average: return 1
        case .tall: return 1.12
        }
    }
    /// 部屋の中での大きさの倍率
    var scale: CGFloat {
        switch self {
        case .short: return 0.92
        case .average: return 1
        case .tall: return 1.08
        }
    }
    /// 身長(cm)の倍率
    var cmFactor: Double {
        switch self {
        case .short: return 0.94
        case .average: return 1
        case .tall: return 1.07
        }
    }
}

// MARK: - 見た目の設定

struct Appearance: Codable, Equatable {
    var skin = 3
    var hair: HairStyle = .short
    var hairColor = 0
    var eyes: EyeStyle = .round
    var brows: BrowStyle = .soft
    var mouth: MouthStyle = .smile
    var beard: BeardStyle = .none
    var hat: HatStyle = .none
    var hatColor = 0
    var glasses: GlassesStyle = .none
    var top: TopStyle = .tee
    var topColor = 2
    var chain: ChainStyle = .none
    var earring = false
    var build: BuildStyle = .normal
    var height: HeightStyle = .average

    static func random() -> Appearance {
        var a = Appearance()
        a.skin = Int.random(in: 0..<Palette.skins.count)
        a.hair = HairStyle.allCases.randomElement()!
        a.hairColor = Int.random(in: 0..<Palette.hair.count)
        a.eyes = EyeStyle.allCases.randomElement()!
        a.brows = BrowStyle.allCases.randomElement()!
        a.mouth = MouthStyle.allCases.randomElement()!
        a.beard = BeardStyle.allCases.randomElement()!
        a.hat = HatStyle.allCases.randomElement()!
        a.hatColor = Int.random(in: 0..<Palette.cloth.count)
        a.glasses = GlassesStyle.allCases.randomElement()!
        a.top = TopStyle.allCases.randomElement()!
        a.topColor = Int.random(in: 0..<Palette.cloth.count)
        a.chain = ChainStyle.allCases.randomElement()!
        a.earring = Bool.random()
        a.build = BuildStyle.allCases.randomElement()!
        a.height = HeightStyle.allCases.randomElement()!
        return a
    }
}

// 項目が増えても、前のセーブデータを読めるようにする（足りない項目は初期値）
extension Appearance {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Appearance()
        skin = c.value(.skin, d.skin)
        hair = c.value(.hair, d.hair)
        hairColor = c.value(.hairColor, d.hairColor)
        eyes = c.value(.eyes, d.eyes)
        brows = c.value(.brows, d.brows)
        mouth = c.value(.mouth, d.mouth)
        beard = c.value(.beard, d.beard)
        hat = c.value(.hat, d.hat)
        hatColor = c.value(.hatColor, d.hatColor)
        glasses = c.value(.glasses, d.glasses)
        top = c.value(.top, d.top)
        topColor = c.value(.topColor, d.topColor)
        chain = c.value(.chain, d.chain)
        earring = c.value(.earring, d.earring)
        build = c.value(.build, d.build)
        height = c.value(.height, d.height)
    }
}

// MARK: - 成長段階・体格ごとの体の比率

struct AvatarMetrics {
    let headW: CGFloat, headH: CGFloat, headY: CGFloat
    let bodyW: CGFloat, bodyH: CGFloat, bodyY: CGFloat
    let eyeScale: CGFloat, armW: CGFloat

    init(stage: Stage, look: Appearance) {
        var hw: CGFloat, hh: CGFloat, hy: CGFloat
        var bw: CGFloat, bh: CGFloat, by: CGFloat, es: CGFloat
        switch stage {
        case .baby:
            hw = 128; hh = 122; hy = 125; bw = 96; bh = 70; by = 230; es = 1.35
        case .kid:
            hw = 118; hh = 122; hy = 112; bw = 120; bh = 95; by = 232; es = 1.2
        case .teen:
            hw = 110; hh = 128; hy = 102; bw = 140; bh = 115; by = 236; es = 1.05
        case .rookie, .star:
            hw = 106; hh = 132; hy = 96; bw = 162; bh = 128; by = 240; es = 1
        }
        bw *= look.build.widthFactor
        if look.build == .chubby { hw *= 1.05 }
        let top = by - bh / 2
        bh *= look.height.bodyFactor
        by = top + bh / 2
        headW = hw; headH = hh; headY = hy
        bodyW = bw; bodyH = bh; bodyY = by
        eyeScale = es
        armW = look.build.armWidth * (stage == .baby ? 0.7 : 1)
    }
}

// MARK: - キャラの絵（240×300 の中に描いて、size に合わせて拡大縮小）

struct AvatarView: View {
    let look: Appearance
    let stage: Stage
    var size: CGFloat = 220

    private var m: AvatarMetrics { AvatarMetrics(stage: stage, look: look) }
    private var skin: Color { Color(hex: Palette.skins[look.skin]) }
    private var hairC: Color { Color(hex: Palette.hair[look.hairColor]) }
    private var topC: Color { Color(hex: Palette.cloth[look.topColor]) }
    private var hatC: Color { Color(hex: Palette.cloth[look.hatColor]) }
    private let ink = Color(hex: 0x2B1D14)
    private var s: CGFloat { m.eyeScale }
    private var eyeY: CGFloat { m.headY + m.headH * 0.04 }
    private var mouthY: CGFloat { m.headY + m.headH * 0.30 }
    private var bodyTop: CGFloat { m.bodyY - m.bodyH / 2 }

    var body: some View {
        ZStack {
            hairBack
            // 首
            Rectangle().fill(skin).brightness(-0.05)
                .frame(width: m.headW * 0.36, height: 46)
                .position(x: 120, y: bodyTop - 14)
            arms
            torso
            chain
            // 耳
            ForEach([-1.0, 1.0], id: \.self) { side in
                Ellipse().fill(skin).brightness(-0.04)
                    .frame(width: 22, height: 30)
                    .position(x: 120 + side * m.headW / 2, y: m.headY + 6)
            }
            // 顔
            Ellipse().fill(skin)
                .frame(width: m.headW, height: m.headH)
                .position(x: 120, y: m.headY)
            if stage <= .kid { cheeks }
            if stage >= .teen { beard }
            face
            hairFront
            hat
            glasses
            if look.earring {
                Circle().fill(Color(hex: 0xF4C430))
                    .frame(width: 9, height: 9)
                    .position(x: 120 - m.headW / 2 - 1, y: m.headY + 22)
            }
        }
        .frame(width: 240, height: 300)
        .scaleEffect(size / 240)
        .frame(width: size, height: size * 1.25)
    }

    // 頭の上半分だけの楕円（髪・帽子に使う）
    private func capShape(_ color: Color, fraction: CGFloat, extra: CGFloat = 8) -> some View {
        let h = m.headH + extra
        return Ellipse().fill(color)
            .frame(width: m.headW + extra, height: h)
            .mask(alignment: .top) { Rectangle().frame(height: h * fraction) }
            .position(x: 120, y: m.headY)
    }

    @ViewBuilder private var hairBack: some View {
        switch look.hair {
        case .afro:
            Circle().fill(hairC)
                .frame(width: m.headW * 1.6, height: m.headW * 1.6)
                .position(x: 120, y: m.headY - m.headH * 0.12)
        case .long:
            RoundedRectangle(cornerRadius: m.headW * 0.4).fill(hairC)
                .frame(width: m.headW * 1.2, height: m.headH * 1.3)
                .position(x: 120, y: m.headY + m.headH * 0.2)
        case .braids:
            ForEach(0..<8, id: \.self) { i in
                Capsule().fill(hairC)
                    .frame(width: 11, height: m.headH)
                    .position(x: 120 - m.headW * 0.62 + CGFloat(i) * m.headW * 0.177,
                              y: m.headY + m.headH * 0.32)
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder private var hairFront: some View {
        switch look.hair {
        case .bald:
            Ellipse().fill(.white.opacity(0.25))
                .frame(width: 30, height: 12)
                .position(x: 100, y: m.headY - m.headH * 0.36)
        case .buzz:
            capShape(hairC.opacity(0.7), fraction: 0.30, extra: 4)
        case .short:
            capShape(hairC, fraction: 0.36)
            Capsule().fill(hairC)
                .frame(width: m.headW * 0.5, height: 20)
                .rotationEffect(.degrees(-12))
                .position(x: 105, y: m.headY - m.headH * 0.28)
        case .afro:
            capShape(hairC, fraction: 0.30, extra: 16)
        case .long:
            capShape(hairC, fraction: 0.36, extra: 10)
        case .braids:
            capShape(hairC, fraction: 0.34)
            ForEach(-2...2, id: \.self) { i in
                Capsule().fill(.black.opacity(0.25))
                    .frame(width: 3, height: m.headH * 0.28)
                    .position(x: 120 + CGFloat(i) * m.headW * 0.14, y: m.headY - m.headH * 0.38)
            }
        case .mohawk:
            capShape(hairC.opacity(0.45), fraction: 0.26, extra: 2)
            Capsule().fill(hairC)
                .frame(width: 24, height: m.headH * 0.6)
                .position(x: 120, y: m.headY - m.headH * 0.52)
        }
    }

    private var cheeks: some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            Circle().fill(Color.pink.opacity(0.25))
                .frame(width: 20, height: 20)
                .position(x: 120 + side * m.headW * 0.3, y: m.headY + m.headH * 0.18)
        }
    }

    private var browHeight: CGFloat {
        switch look.brows {
        case .soft: return 4
        case .thick: return 8
        case .angry: return 6
        }
    }

    private var browAngle: Double {
        switch look.brows {
        case .soft: return 3
        case .thick: return 0
        case .angry: return -15
        }
    }

    @ViewBuilder private var face: some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            Capsule().fill(look.hair == .bald ? ink : hairC).brightness(-0.1)
                .frame(width: 22 * s, height: browHeight * s)
                .rotationEffect(.degrees(browAngle * side))
                .position(x: 120 + side * m.headW * 0.2, y: eyeY - 17 * s)
            eye(side: side)
                .position(x: 120 + side * m.headW * 0.2, y: eyeY)
        }
        // 鼻
        Capsule().fill(.black.opacity(0.14))
            .frame(width: 7, height: 16 * min(s, 1.1))
            .position(x: 120, y: m.headY + m.headH * 0.16)
        mouth
            .position(x: 120, y: mouthY)
    }

    @ViewBuilder private func eye(side: Double) -> some View {
        switch look.eyes {
        case .round:
            ZStack {
                Ellipse().fill(.white).frame(width: 17 * s, height: 19 * s)
                Circle().fill(ink).frame(width: 11 * s, height: 11 * s)
                Circle().fill(.white).frame(width: 3.5 * s, height: 3.5 * s).offset(x: 2 * s, y: -2 * s)
            }
        case .sleepy:
            ZStack {
                Ellipse().fill(.white).frame(width: 17 * s, height: 12 * s)
                Circle().fill(ink).frame(width: 9 * s, height: 9 * s).offset(y: 1.5 * s)
                Capsule().fill(skin).brightness(-0.12)
                    .frame(width: 19 * s, height: 6 * s).offset(y: -4 * s)
            }
        case .sharp:
            ZStack {
                Ellipse().fill(.white).frame(width: 19 * s, height: 10 * s)
                Circle().fill(ink).frame(width: 8 * s, height: 8 * s)
            }
            .rotationEffect(.degrees(-8 * side))
        }
    }

    @ViewBuilder private var mouth: some View {
        let w = 28 * min(s, 1.1)
        switch look.mouth {
        case .smile:
            Circle().trim(from: 0.08, to: 0.42)
                .stroke(ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: w, height: w)
                .offset(y: -w * 0.35)
        case .neutral:
            Capsule().fill(ink).frame(width: w * 0.8, height: 4)
        case .smirk:
            Capsule().fill(ink).frame(width: w * 0.8, height: 4)
                .rotationEffect(.degrees(-12)).offset(x: 4)
        case .grin:
            ZStack {
                Circle().trim(from: 0, to: 0.5).fill(.white)
                Circle().trim(from: 0, to: 0.5).stroke(ink, lineWidth: 3)
            }
            .frame(width: w * 1.1, height: w * 1.1)
            .offset(y: -w * 0.4)
        }
    }

    @ViewBuilder private var beard: some View {
        switch look.beard {
        case .none:
            EmptyView()
        case .stubble:
            Ellipse().fill(hairC.opacity(0.3))
                .frame(width: m.headW * 0.86, height: m.headH * 0.5)
                .mask(alignment: .bottom) { Rectangle().frame(height: m.headH * 0.32) }
                .position(x: 120, y: m.headY + m.headH * 0.24)
        case .goatee:
            Capsule().fill(hairC)
                .frame(width: 34, height: 7)
                .position(x: 120, y: mouthY - 9)
            RoundedRectangle(cornerRadius: 9).fill(hairC)
                .frame(width: 22, height: 20)
                .position(x: 120, y: mouthY + 16)
        case .full:
            Ellipse().fill(hairC)
                .frame(width: m.headW, height: m.headH * 0.66)
                .mask(alignment: .bottom) { Rectangle().frame(height: m.headH * 0.42) }
                .position(x: 120, y: m.headY + m.headH * 0.2)
        }
    }

    private var arms: some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            let x = 120 + side * (m.bodyW / 2 + m.armW / 2 - 8)
            Capsule().fill(topC).brightness(-0.06)
                .frame(width: m.armW, height: m.bodyH * 0.9)
                .position(x: x, y: m.bodyY + 2)
            Circle().fill(skin)
                .frame(width: m.armW * 0.95, height: m.armW * 0.95)
                .position(x: x, y: m.bodyY + m.bodyH * 0.45)
        }
    }

    @ViewBuilder private var torso: some View {
        let bottomR: CGFloat = look.build == .chubby ? m.bodyW * 0.28 : 6
        UnevenRoundedRectangle(topLeadingRadius: m.bodyW * 0.3, bottomLeadingRadius: bottomR,
                               bottomTrailingRadius: bottomR, topTrailingRadius: m.bodyW * 0.3)
            .fill(topC)
            .frame(width: m.bodyW, height: m.bodyH)
            .position(x: 120, y: m.bodyY)
        switch look.top {
        case .tee:
            Ellipse().fill(skin).brightness(-0.05)
                .frame(width: m.headW * 0.42, height: 18)
                .position(x: 120, y: bodyTop + 2)
        case .hoodie:
            Capsule().fill(topC).brightness(-0.12)
                .frame(width: m.bodyW * 0.62, height: 28)
                .position(x: 120, y: bodyTop + 6)
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(.white.opacity(0.85))
                    .frame(width: 4, height: 30)
                    .position(x: 120 + side * 12, y: bodyTop + 34)
            }
            RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.18), lineWidth: 3)
                .frame(width: m.bodyW * 0.55, height: m.bodyH * 0.28)
                .position(x: 120, y: m.bodyY + m.bodyH * 0.26)
        case .jersey:
            Ellipse().fill(skin).brightness(-0.05)
                .frame(width: m.headW * 0.42, height: 18)
                .position(x: 120, y: bodyTop + 2)
            Text("23")
                .font(.system(size: m.bodyH * 0.38, weight: .black, design: .rounded))
                .foregroundStyle((look.topColor == 1 ? Color.black : Color.white).opacity(0.85))
                .position(x: 120, y: m.bodyY + 6)
        case .jacket:
            Rectangle().fill(.black.opacity(0.3))
                .frame(width: 3, height: m.bodyH)
                .position(x: 120, y: m.bodyY)
            ForEach([-1.0, 1.0], id: \.self) { side in
                RoundedRectangle(cornerRadius: 4).fill(topC).brightness(-0.15)
                    .frame(width: 18, height: 46)
                    .rotationEffect(.degrees(side * -22))
                    .position(x: 120 + side * 18, y: bodyTop + 18)
            }
        }
    }

    @ViewBuilder private var chain: some View {
        if look.chain != .none {
            let c = look.chain == .gold ? Color(hex: 0xF4C430) : Color(hex: 0xC8CCD2)
            let r = m.headW * 0.34
            Path { p in
                p.move(to: CGPoint(x: 120 - r, y: bodyTop))
                p.addQuadCurve(to: CGPoint(x: 120 + r, y: bodyTop),
                               control: CGPoint(x: 120, y: bodyTop + r * 1.7))
            }
            .stroke(c, style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [7, 3]))
            Circle().fill(c)
                .frame(width: 20, height: 20)
                .position(x: 120, y: bodyTop + r * 0.85 + 8)
        }
    }

    @ViewBuilder private var hat: some View {
        switch look.hat {
        case .none:
            EmptyView()
        case .cap:
            capShape(hatC, fraction: 0.36, extra: 12)
            Ellipse().fill(hatC).brightness(-0.12)
                .frame(width: m.headW * 0.95, height: 18)
                .position(x: 120, y: m.headY - m.headH * 0.15)
        case .beanie:
            capShape(hatC, fraction: 0.44, extra: 14)
            RoundedRectangle(cornerRadius: 7).fill(hatC).brightness(-0.15)
                .frame(width: m.headW + 16, height: 22)
                .position(x: 120, y: m.headY - (m.headH + 14) / 2 + (m.headH + 14) * 0.44 - 6)
        case .bucket:
            RoundedRectangle(cornerRadius: 22).fill(hatC)
                .frame(width: m.headW * 0.92, height: m.headH * 0.36)
                .position(x: 120, y: m.headY - m.headH * 0.42)
            Ellipse().fill(hatC).brightness(-0.1)
                .frame(width: m.headW * 1.4, height: 26)
                .position(x: 120, y: m.headY - m.headH * 0.25)
        }
    }

    @ViewBuilder private var glasses: some View {
        let lens = 28 * min(s, 1.15)
        switch look.glasses {
        case .none:
            EmptyView()
        case .round:
            ForEach([-1.0, 1.0], id: \.self) { side in
                Circle().stroke(.black, lineWidth: 3)
                    .frame(width: lens, height: lens)
                    .position(x: 120 + side * m.headW * 0.2, y: eyeY)
            }
            Capsule().fill(.black)
                .frame(width: max(m.headW * 0.4 - lens, 4), height: 3)
                .position(x: 120, y: eyeY)
        case .shades:
            ForEach([-1.0, 1.0], id: \.self) { side in
                RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.88))
                    .frame(width: lens + 6, height: lens * 0.7)
                    .position(x: 120 + side * m.headW * 0.2, y: eyeY)
            }
            Capsule().fill(.black)
                .frame(width: max(m.headW * 0.4 - lens - 6, 4), height: 4)
                .position(x: 120, y: eyeY - 3)
        }
    }
}
