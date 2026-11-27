import Foundation

struct RhymeWord {
    let display: String   // 画面に出す表記
    let reading: String   // ひらがなの読み
}

enum Rhyme {
    // MARK: お題（母音が5つ以上のものだけ使う）

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
        .init(display: "夏休み", reading: "なつやすみ"),
        .init(display: "冷蔵庫", reading: "れいぞうこ"),
        .init(display: "扇風機", reading: "せんぷうき"),
        .init(display: "掃除機", reading: "そうじき"),
        .init(display: "洗濯機", reading: "せんたくき"),
        .init(display: "電子レンジ", reading: "でんしれんじ"),
        .init(display: "ドライヤー", reading: "どらいやー"),
        .init(display: "エレベーター", reading: "えれべーたー"),
        .init(display: "エスカレーター", reading: "えすかれーたー"),
        .init(display: "ジェットコースター", reading: "じぇっとこーすたー"),
        .init(display: "観覧車", reading: "かんらんしゃ"),
        .init(display: "遊園地", reading: "ゆうえんち"),
        .init(display: "動物園", reading: "どうぶつえん"),
        .init(display: "水族館", reading: "すいぞくかん"),
        .init(display: "図書館", reading: "としょかん"),
        .init(display: "映画館", reading: "えいがかん"),
        .init(display: "美術館", reading: "びじゅつかん"),
        .init(display: "体育館", reading: "たいいくかん"),
        .init(display: "商店街", reading: "しょうてんがい"),
        .init(display: "交差点", reading: "こうさてん"),
        .init(display: "横断歩道", reading: "おうだんほどう"),
        .init(display: "信号機", reading: "しんごうき"),
        .init(display: "高速道路", reading: "こうそくどうろ"),
        .init(display: "駐車場", reading: "ちゅうしゃじょう"),
        .init(display: "コンビニ弁当", reading: "こんびにべんとう"),
        .init(display: "カップラーメン", reading: "かっぷらーめん"),
        .init(display: "チョコレート", reading: "ちょこれーと"),
        .init(display: "アイスクリーム", reading: "あいすくりーむ"),
        .init(display: "ショートケーキ", reading: "しょーとけーき"),
        .init(display: "ポテトチップス", reading: "ぽてとちっぷす"),
        .init(display: "フライドポテト", reading: "ふらいどぽてと"),
        .init(display: "オムライス", reading: "おむらいす"),
        .init(display: "カレーライス", reading: "かれーらいす"),
        .init(display: "チャーハン定食", reading: "ちゃーはんていしょく"),
        .init(display: "味噌ラーメン", reading: "みそらーめん"),
        .init(display: "たこ焼き屋さん", reading: "たこやきやさん"),
        .init(display: "唐揚げ弁当", reading: "からあげべんとう"),
        .init(display: "目玉焼き", reading: "めだまやき"),
        .init(display: "卵かけご飯", reading: "たまごかけごはん"),
        .init(display: "誕生日会", reading: "たんじょうびかい"),
        .init(display: "クリスマスツリー", reading: "くりすますつりー"),
        .init(display: "お正月", reading: "おしょうがつ"),
        .init(display: "年賀状", reading: "ねんがじょう"),
        .init(display: "バレンタイン", reading: "ばれんたいん"),
        .init(display: "入学式", reading: "にゅうがくしき"),
        .init(display: "文化祭", reading: "ぶんかさい"),
        .init(display: "夏祭り", reading: "なつまつり"),
        .init(display: "盆踊り", reading: "ぼんおどり"),
        .init(display: "初日の出", reading: "はつひので"),
        .init(display: "天の川", reading: "あまのがわ"),
        .init(display: "流れ星", reading: "ながれぼし"),
        .init(display: "満月の夜", reading: "まんげつのよる"),
        .init(display: "真夏の太陽", reading: "まなつのたいよう"),
        .init(display: "雪だるま", reading: "ゆきだるま"),
        .init(display: "春一番", reading: "はるいちばん"),
        .init(display: "台風一過", reading: "たいふういっか"),
        .init(display: "にわか雨", reading: "にわかあめ"),
        .init(display: "虹の架け橋", reading: "にじのかけはし"),
        .init(display: "富士山頂", reading: "ふじさんちょう"),
        .init(display: "太平洋", reading: "たいへいよう"),
        .init(display: "北極星", reading: "ほっきょくせい"),
        .init(display: "地球温暖化", reading: "ちきゅうおんだんか"),
        .init(display: "恐竜時代", reading: "きょうりゅうじだい"),
        .init(display: "宇宙人", reading: "うちゅうじん"),
        .init(display: "ロボット工場", reading: "ろぼっとこうじょう"),
        .init(display: "人工知能", reading: "じんこうちのう"),
        .init(display: "スマートフォン", reading: "すまーとふぉん"),
        .init(display: "ゲームセンター", reading: "げーむせんたー"),
        .init(display: "カラオケボックス", reading: "からおけぼっくす"),
        .init(display: "ヘッドフォン", reading: "へっどふぉん"),
        .init(display: "ターンテーブル", reading: "たーんてーぶる"),
        .init(display: "マイクロフォン", reading: "まいくろふぉん"),
        .init(display: "スニーカー", reading: "すにーかー"),
        .init(display: "キャップ帽子", reading: "きゃっぷぼうし"),
        .init(display: "金のネックレス", reading: "きんのねっくれす"),
        .init(display: "サングラス", reading: "さんぐらす"),
        .init(display: "スケートボード", reading: "すけーとぼーど"),
        .init(display: "バスケットボール", reading: "ばすけっとぼーる"),
        .init(display: "サッカー選手", reading: "さっかーせんしゅ"),
        .init(display: "野球部員", reading: "やきゅうぶいん"),
        .init(display: "陸上競技", reading: "りくじょうきょうぎ"),
        .init(display: "水泳大会", reading: "すいえいたいかい"),
        .init(display: "ボクシングジム", reading: "ぼくしんぐじむ"),
        .init(display: "腕立て伏せ", reading: "うでたてふせ"),
        .init(display: "朝ごはん", reading: "あさごはん"),
        .init(display: "晩ごはん", reading: "ばんごはん"),
        .init(display: "寝不足", reading: "ねぶそく"),
        .init(display: "二度寝", reading: "にどね"),
        .init(display: "早起き", reading: "はやおき"),
        .init(display: "深夜番組", reading: "しんやばんぐみ"),
        .init(display: "生放送", reading: "なまほうそう"),
        .init(display: "大成功", reading: "だいせいこう"),
        .init(display: "大失敗", reading: "だいしっぱい"),
        .init(display: "一発逆転", reading: "いっぱつぎゃくてん"),
        .init(display: "絶体絶命", reading: "ぜったいぜつめい"),
        .init(display: "前代未聞", reading: "ぜんだいみもん"),
        .init(display: "有言実行", reading: "ゆうげんじっこう"),
        .init(display: "自画自賛", reading: "じがじさん"),
        .init(display: "十人十色", reading: "じゅうにんといろ"),
        .init(display: "一石二鳥", reading: "いっせきにちょう"),
        .init(display: "七転び八起き", reading: "ななころびやおき"),
        .init(display: "石の上にも三年", reading: "いしのうえにもさんねん"),
        .init(display: "棚からぼたもち", reading: "たなからぼたもち"),
        .init(display: "猫に小判", reading: "ねこにこばん"),
        .init(display: "急がば回れ", reading: "いそがばまわれ"),
        .init(display: "親友", reading: "しんゆう"),
        .init(display: "幼なじみ", reading: "おさななじみ"),
        .init(display: "同級生", reading: "どうきゅうせい"),
        .init(display: "先生", reading: "せんせい"),
        .init(display: "校長先生", reading: "こうちょうせんせい"),
        .init(display: "お母さん", reading: "おかあさん"),
        .init(display: "おばあちゃん", reading: "おばあちゃん"),
        .init(display: "おじいちゃん", reading: "おじいちゃん"),
        .init(display: "赤ちゃん", reading: "あかちゃん"),
        .init(display: "お兄ちゃん", reading: "おにいちゃん"),
        .init(display: "社長室", reading: "しゃちょうしつ"),
        .init(display: "会社員", reading: "かいしゃいん"),
        .init(display: "お医者さん", reading: "おいしゃさん"),
        .init(display: "消防車", reading: "しょうぼうしゃ"),
        .init(display: "救急車", reading: "きゅうきゅうしゃ"),
        .init(display: "パトカー", reading: "ぱとかー"),
        .init(display: "飛行機雲", reading: "ひこうきぐも"),
        .init(display: "自転車", reading: "じてんしゃ"),
        .init(display: "三輪車", reading: "さんりんしゃ"),
        .init(display: "地下鉄", reading: "ちかてつ"),
        .init(display: "終電", reading: "しゅうでん"),
        .init(display: "始発電車", reading: "しはつでんしゃ"),
        .init(display: "ライブハウス", reading: "らいぶはうす"),
        .init(display: "ステージ衣装", reading: "すてーじいしょう"),
        .init(display: "スポットライト", reading: "すぽっとらいと"),
        .init(display: "アンコール", reading: "あんこーる"),
        .init(display: "フリースタイル", reading: "ふりーすたいる"),
        .init(display: "レコード屋さん", reading: "れこーどやさん"),
        .init(display: "路上ライブ", reading: "ろじょうらいぶ"),
        .init(display: "夢の続き", reading: "ゆめのつづき"),
        .init(display: "ありがとう", reading: "ありがとう"),
        .init(display: "こんにちは", reading: "こんにちは"),
        .init(display: "おやすみなさい", reading: "おやすみなさい"),
        .init(display: "いただきます", reading: "いただきます"),
        .init(display: "ごちそうさま", reading: "ごちそうさま"),
    ].filter { (vowels(of: $0.reading)?.count ?? 0) >= 5 }

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
