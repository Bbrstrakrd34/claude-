import Foundation

/// 年齢ごとのセリフ。大きくなるほどストリートな言葉が混ざり、22歳以上はそれだけになる
enum TalkLines {
    static let babble = ["あー", "うー", "ばぶー", "だぁ！", "きゃっきゃっ", "んまんま", "あぶぅ"]

    static let firstWords = ["まんま！", "ねんね…", "あっち！", "やだ！", "ブーブー", "もっと！", "だっこ！"]

    static let small = [
        "ねえねえ、あそぼ！", "これなあに？", "おなかすいたー", "なんで？なんで？",
        "リズムあそびたのしい！", "きょうなにするの？", "ジュースのみたい！",
    ]

    static let kid = [
        "学校でラップ流行ってる！", "宿題めんどくさいなー", "今日いっぱい歩いた？",
        "将来ラッパーになる！", "韻ふむの得意になってきた", "放課後サイファーしよ！",
    ]

    static let teen = [
        "…別に。", "マジだるい", "サイファー行ってくるわ", "このビートやばくない？",
        "リリック書いてんだから話しかけんな", "いつかデカいステージ立つから",
    ]

    static let young = [
        "ヨー、調子どう？", "今日もリリック書いてるぜ", "地元のために歌う",
        "フロウ磨いてる最中", "まだまだこんなもんじゃねえ", "ライブ決まったぜ",
    ]

    static let gang = [
        "ヨー、俺らのシマに何の用だ？", "リアルしか勝たん", "フェイクな奴は消えな",
        "クルーが全てだ", "ナメた口きくなよ", "ストリートが俺を育てた",
        "金の匂いがするぜ", "俺の名前、街中に響かせてやる", "背中は預けたぜ、ブロ",
        "ビビってんのか？", "この街の頂点は俺だ", "言葉が俺の武器だ",
    ]

    static func line(age: Int) -> String {
        if age >= 22 { return gang.randomElement()! }
        // 14歳から少しずつストリートな言葉が混ざる
        let gangChance = age >= 14 ? Double(age - 13) / 9.0 : 0
        if Double.random(in: 0..<1) < gangChance { return gang.randomElement()! }
        switch age {
        case 0: return babble.randomElement()!
        case 1...2: return firstWords.randomElement()!
        case 3...5: return small.randomElement()!
        case 6...12: return kid.randomElement()!
        case 13...17: return teen.randomElement()!
        default: return young.randomElement()!
        }
    }

    /// 読み上げの声の高さ（赤ちゃんは高く、大人は低く）
    static func pitch(age: Int) -> Float {
        switch age {
        case ..<3: return 1.9
        case 3..<7: return 1.6
        case 7..<13: return 1.4
        case 13..<18: return 1.1
        default: return 0.8
        }
    }
}
