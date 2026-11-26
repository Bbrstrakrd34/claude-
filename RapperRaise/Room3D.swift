import SwiftUI
import UIKit
import WebKit

/// 3Dの部屋（room3d.html を WebView で表示する）
struct Room3DView: UIViewRepresentable {
    @EnvironmentObject var game: GameState
    /// true: メイン画面用（ボタン類を隠す） / false: 全画面の模様替え用
    var compact = true

    /// room3d.html がアプリに入っているか
    static var isAvailable: Bool {
        Bundle.main.url(forResource: "room3d", withExtension: "html") != nil
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let c = context.coordinator
        let config = WKWebViewConfiguration()
        config.userContentController.add(c, name: "layout")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.navigationDelegate = c
        c.web = web

        // 家具の配置が変わったら保存する
        let game = self.game
        c.onLayout = { [weak c] json in
            c?.lastLayout = json
            if game.data.room3D != json { game.data.room3D = json }
        }

        c.run("app.setCompact(\(compact))")
        c.run("app.setLight('\(Self.lightForNow())')")
        if !game.data.room3D.isEmpty {
            c.lastLayout = game.data.room3D
            c.run("app.setLayout(\(game.data.room3D))")
        }

        if let url = Bundle.main.url(forResource: "room3d", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        let c = context.coordinator

        // 見た目（肌・髪・服・大きさ）
        let look = lookJSON()
        if look != c.lastLook {
            c.lastLook = look
            c.run("app.setLook(\(look))")
        }

        // セリフ
        if game.speech != c.lastSpeech {
            c.lastSpeech = game.speech
            if let s = game.speech { c.run("app.say(\(Self.js(s)))") }
        }

        // 食べている物
        if game.eating != c.lastEating {
            c.lastEating = game.eating
            if let e = game.eating { c.run("app.emote(\(Self.js(e)))") }
        }

        // 別の画面で模様替えされたら反映する
        if game.data.room3D != c.lastLayout {
            c.lastLayout = game.data.room3D
            if game.data.room3D.isEmpty {
                c.run("app.resetLayout()")
            } else {
                c.run("app.setLayout(\(game.data.room3D))")
            }
        }
    }

    // MARK: - 補助

    /// 時間帯で部屋の明るさを変える
    static func lightForNow() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 6..<16: return "morning"
        case 16..<19: return "sunset"
        default: return "rain"
        }
    }

    private struct JSLook: Encodable {
        let skin: String
        let hair: String
        let top: String
        let scale: Double
        let bald: Bool
    }

    private func lookJSON() -> String {
        let a = game.data.appearance
        let stageScale: Double
        switch game.stage {
        case .baby: stageScale = 0.55
        case .kid: stageScale = 0.75
        case .teen: stageScale = 0.92
        case .rookie, .star: stageScale = 1
        }
        let look = JSLook(
            skin: Self.hex(Palette.skins[a.skin]),
            hair: Self.hex(Palette.hair[a.hairColor]),
            top: Self.hex(Palette.cloth[a.topColor]),
            scale: stageScale * Double(a.height.scale),
            bald: a.hair == .bald
        )
        guard let data = try? JSONEncoder().encode(look) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func hex(_ v: UInt32) -> String {
        String(format: "#%06X", v)
    }

    /// Swift の文字列を JavaScript の文字列として安全に埋め込む
    static func js(_ s: String) -> String {
        guard let data = try? JSONEncoder().encode(s) else { return "\"\"" }
        return String(data: data, encoding: .utf8) ?? "\"\""
    }

    // MARK: - WebView とのやりとり

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var web: WKWebView?
        var loaded = false
        var queue: [String] = []
        var lastLook = ""
        var lastSpeech: String?
        var lastEating: String?
        var lastLayout = ""
        var onLayout: ((String) -> Void)?

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
            for js in pending {
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "layout", let json = message.body as? String else { return }
            onLayout?(json)
        }
    }
}

// MARK: - 全画面の部屋（模様替え・カメラ・明るさを変えられる）

struct Room3DFullView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Room3DView(compact: false)
                .ignoresSafeArea()
            Button {
                dismiss()
            } label: {
                Label("閉じる", systemImage: "xmark")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.trailing, 16)
            .padding(.bottom, 90)
        }
        .background(Color.black)
    }
}

// MARK: - 部屋に落ちたアイテム（3Dの部屋の上に重ねる）

struct DropsOverlay: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        GeometryReader { geo in
            ForEach(game.data.drops) { drop in
                Text(drop.kind.emoji)
                    .font(.system(size: 28))
                    .shadow(radius: 3)
                    .position(x: drop.x * geo.size.width, y: drop.y * geo.size.height)
                    .onTapGesture { game.collect(drop) }
            }
        }
        .task {
            while !Task.isCancelled {
                game.refreshIdle()
                try? await Task.sleep(for: .seconds(20))
            }
        }
    }
}
