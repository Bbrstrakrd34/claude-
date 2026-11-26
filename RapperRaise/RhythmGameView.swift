import SwiftUI
import Combine
import UIKit
import WebKit

// MARK: - リズム練習（rhythm.html を表示する）

struct RhythmGameView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = RhythmController()

    var body: some View {
        ZStack(alignment: .topLeading) {
            RhythmWebView(controller: controller)
                .ignoresSafeArea()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 8)
        }
        .background(Color(hex: 0x07080D).ignoresSafeArea())
        .onAppear {
            let game = self.game
            let c = controller
            let a = game.data.appearance
            let look: [String: String] = [
                "hoodie": Room3DView.hex(Palette.cloth[a.topColor]),
                "skin": Room3DView.hex(Palette.skins[a.skin]),
                "cap": a.hat == .none ? Room3DView.hex(Palette.hair[a.hairColor]) : Room3DView.hex(Palette.cloth[a.hatColor]),
            ]
            c.run("rhythm.setLook(\(RhythmController.json(look)))")

            // スタートが押されたら、ポイントを払えるか確認する
            c.onRequestStart = { [weak c] in
                guard let c else { return }
                if game.pay(1, minStage: .baby) {
                    c.run("rhythm.start()")
                } else {
                    c.run("rhythm.denied(\(RhythmController.json(game.message)))")
                }
            }
            // ゲームオーバーになったら、うまく跳べた数だけフロウが上がる
            c.onGameOver = { [weak c] perfect, good in
                let gain = game.rewardRhythm(perfect: perfect, good: good)
                c?.run("rhythm.showReward(\(RhythmController.json("🌊 フロウ +\(gain)")))")
            }
        }
    }
}

struct RhythmWebView: UIViewRepresentable {
    let controller: RhythmController

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsInlineMediaPlayback = true
        config.userContentController.add(controller, name: "rhythm")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.scrollView.isScrollEnabled = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.navigationDelegate = controller
        controller.web = web
        if let url = Bundle.main.url(forResource: "rhythm", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}
}

/// リズムゲーム(JavaScript)とのやりとり
@MainActor
final class RhythmController: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    weak var web: WKWebView?
    private var loaded = false
    private var queue: [String] = []
    var onRequestStart: (() -> Void)?
    var onGameOver: ((Int, Int) -> Void)?

    private struct Message: Decodable {
        let type: String
        let perfect: Int?
        let good: Int?
    }

    func run(_ js: String) {
        guard loaded, let web else {
            queue.append(js)
            return
        }
        web.evaluateJavaScript(js, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded = true
        let pending = queue
        queue = []
        for js in pending { webView.evaluateJavaScript(js, completionHandler: nil) }
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let text = message.body as? String,
              let data = text.data(using: .utf8),
              let msg = try? JSONDecoder().decode(Message.self, from: data) else { return }
        switch msg.type {
        case "requestStart": onRequestStart?()
        case "over": onGameOver?(msg.perfect ?? 0, msg.good ?? 0)
        default: break
        }
    }

    static func json<T: Encodable>(_ v: T) -> String {
        guard let d = try? JSONEncoder().encode(v), let s = String(data: d, encoding: .utf8) else { return "null" }
        return s
    }
}
