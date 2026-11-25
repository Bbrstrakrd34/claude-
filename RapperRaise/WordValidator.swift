import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// 入力された言葉が実在するかを、端末内のAI（Apple Intelligence）でチェックする
enum WordValidator {
    /// 実在する言葉なら true。AIが使えない端末では常に true
    static func isRealWord(_ reading: String) async -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await AIWordCheck.check(reading)
        }
        #endif
        return true
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct WordCheck {
    @Guide(description: "日本語として実在する単語・固有名詞・よく使う言い回しなら true")
    var isReal: Bool
}

@available(iOS 26.0, *)
enum AIWordCheck {
    static func check(_ reading: String) async -> Bool {
        guard SystemLanguageModel.default.isAvailable else { return true }
        let session = LanguageModelSession(instructions: """
            あなたは日本語の辞書です。ひらがなで与えられた言葉が、
            実在する単語・固有名詞・よく使う言い回しかどうかだけを判定します。
            """)
        do {
            let res = try await session.respond(to: "「\(reading)」", generating: WordCheck.self)
            return res.content.isReal
        } catch {
            return true   // AIがエラーのときはプレイヤーに有利に
        }
    }
}
#endif
