import SwiftUI
import Combine
import UIKit
import WebKit

// MARK: - 街（city.html を表示する）

struct CityView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = CityController()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CityWebView(controller: controller)
                .ignoresSafeArea()
            Button {
                dismiss()
            } label: {
                Label("家に帰る", systemImage: "house.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(.black.opacity(0.55), in: Capsule())
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .background(Color(hex: 0xC3CBD2).ignoresSafeArea())
        .onAppear {
            let close = dismiss
            controller.onHome = { close() }
            controller.run("city.setLook(\(Room3DView.lookJSON(game.data.appearance, stage: game.stage)))")
        }
    }
}

struct CityWebView: UIViewRepresentable {
    let controller: CityController

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(controller, name: "city")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.navigationDelegate = controller
        controller.web = web
        if let url = Bundle.main.url(forResource: "city", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}
}

/// 街(JavaScript)とのやりとり
@MainActor
final class CityController: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    weak var web: WKWebView?
    private var loaded = false
    private var queue: [String] = []
    var onHome: (() -> Void)?

    private struct Message: Decodable {
        let type: String
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
        if msg.type == "home" { onHome?() }
    }
}
