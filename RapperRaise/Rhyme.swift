import Foundation

struct RhymeWord {
    let display: String   // 画面に出す表記
    let reading: String   // ひらがなの読み
}

enum Rhyme {
    // MARK: お題（6音以上のものだけ使う）

    static let words: [RhymeWord] = [
        .init(display: "東京タワー", reading: "とうきょうたわー"),
        .init(display: "ハンバーガー", reading: "はんばーがー"),
        .init(display: "携帯電話", reading: "けいたいでんわ"),
        .init(display: "自動販売機", reading: "じどうはんばいき"),
        .init(display: "宇宙飛行士", reading: "うちゅうひこうし"),
        .init(display: "花火大会", reading: "はなびたいかい"),
        .init(display: "運動会", reading: "うんどうかい"),
        .init(display: "新幹線", reading: "しんかんせん"),
        .init(display: "卒業式", reading: "そつぎょうしき"),
        .init(display: "修学旅行", reading: "しゅうがくりょこう"),
        .init(display: "天気予報", reading: "てんきよほう"),
        .init(display: "目覚まし時計", reading: "めざましどけい"),
        .init(display: "焼肉定食", reading: "やきにくていしょく"),
        .init(display: "遠距離恋愛", reading: "えんきょりれんあい"),
        .init(display: "一生懸命", reading: "いっしょうけんめい"),
        .init(display: "満員電車", reading: "まんいんでんしゃ"),
        .init(display: "大統領", reading: "だいとうりょう"),
        .init(display: "超能力", reading: "ちょうのうりょく"),
        .init(display: "世界一周", reading: "せかいいっしゅう"),
        .init(display: "三日坊主", reading: "みっかぼうず"),
        .init(display: "期間限定", reading: "きかんげんてい"),
        .init(display: "自由研究", reading: "じゆうけんきゅう"),
        .init(display: "給食当番", reading: "きゅうしょくとうばん"),
        .init(display: "お好み焼き", reading: "おこのみやき"),
        .init(display: "回転寿司", reading: "かいてんずし"),
        .init(display: "筋肉痛", reading: "きんにくつう"),
    ].filter { (vowels(of: $0.reading)?.count ?? 0) >= 6 }

    // MARK: 母音への変換

    private static let table: [Character: Character] = {
        let rows: [Character: String] = [
            "a": "あかさたなはまやらわがざだばぱ",
            "i": "いきしちにひみりぎじぢびぴ",
            "u": "うくすつぬふむゆるぐずづぶぷゔ",
            "e": "えけせてねへめれげぜでべぺ",
            "o": "おこそとのほもよろをごぞどぼぽ",
        ]
        var t: [Character: Character] = [:]
        for (v, chars) in rows {
            for c in chars { t[c] = v }
        }
        return t
    }()

    private static let small: [Character: Character] = [
        "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
        "ゃ": "a", "ゅ": "u", "ょ": "o", "ゎ": "a",
    ]

    /// カタカナ→ひらがなにして、空白を取り除く
    static func toHiragana(_ s: String) -> String {
        (s.applyingTransform(.hiraganaToKatakana, reverse: true) ?? s)
            .filter { $0 != " " && $0 != "　" }
    }

    /// 母音の配列にする（a i u e o / N=ん / Q=っ）。かな以外が入っていたら nil
    static func vowels(of text: String) -> [Character]? {
        var result: [Character] = []
        for ch in toHiragana(text) {
            if let v = table[ch] {
                result.append(v)
            } else if let v = small[ch] {
                // 「きゃ」の「ゃ」は直前の母音を置き換える
                if result.isEmpty { result.append(v) } else { result[result.count - 1] = v }
            } else if ch == "ん" {
                result.append("N")
            } else if ch == "っ" {
                result.append("Q")
            } else if ch == "ー" {
                guard let last = result.last, "aiueo".contains(last) else { return nil }
                result.append(last)
            } else {
                return nil   // 漢字・英字など
            }
        }
        // 長音のゆれをそろえる: おう→おお、えい→ええ
        for i in result.indices.dropFirst() {
            if result[i] == "u" && result[i - 1] == "o" { result[i] = "o" }
            if result[i] == "i" && result[i - 1] == "e" { result[i] = "e" }
        }
        return result.isEmpty ? nil : result
    }

    /// 表示用: a→あ, N→ん, Q→っ
    static func kana(_ v: Character) -> String {
        let map: [Character: String] = [
            "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お", "N": "ん", "Q": "っ",
        ]
        return map[v] ?? "?"
    }

    // MARK: 判定

    enum Judge {
        case ok(hiragana: String)
        case ng(message: String, vowels: [Character]?)
    }

    static func judge(_ input: String, prompt: RhymeWord) -> Judge {
        let hira = toHiragana(input)
        guard !hira.isEmpty else {
            return .ng(message: "言葉を入れてね", vowels: nil)
        }
        guard let answer = vowels(of: hira) else {
            return .ng(message: "ひらがな・カタカナで入力してね", vowels: nil)
        }
        guard hira != prompt.reading else {
            return .ng(message: "お題と同じ言葉はナシ！", vowels: nil)
        }
        guard !hira.allSatisfy({ "あいうえおんっー".contains($0) }) else {
            return .ng(message: "母音だけの言葉はナシ！", vowels: nil)
        }
        guard answer == vowels(of: prompt.reading) else {
            return .ng(message: "韻がズレてる！", vowels: answer)
        }
        return .ok(hiragana: hira)
    }
}
