import SwiftUI
import Combine
import UIKit
import WebKit

// MARK: - 街（city.html を表示する）

struct CityView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = CityController()
    @State private var showFood = false
    @State private var showCloset = false
    @State private var showRhyme = false
    @State private var showRhythm = false
    @State private var showCypher = false

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
            controller.onSpot = { id in openSpot(id) }
            controller.onTalk = { game.rewardTalk() }
            sendLook()
            sendProfile()
        }
        // 「成長+2」などのお知らせを街の画面に出す
        .onChange(of: game.message) { _, new in
            controller.run("city.toast(\(CityController.json(new)))")
        }
        // 人気や年齢が変わったら、ビルボードやゲートに反映する
        .onChange(of: game.data.stats.fame) { _, _ in sendProfile() }
        .onChange(of: game.age) { _, _ in sendProfile() }
        .sheet(isPresented: $showFood) { FoodView().environmentObject(game) }
        .sheet(isPresented: $showCloset, onDismiss: sendLook) { ClosetView().environmentObject(game) }
        .sheet(isPresented: $showRhyme) { RhymeGameView().environmentObject(game) }
        .fullScreenCover(isPresented: $showRhythm) { RhythmGameView().environmentObject(game) }
        .fullScreenCover(isPresented: $showCypher) { CypherView().environmentObject(game) }
    }

    private func sendLook() {
        controller.run("city.setLook(\(Room3DView.lookJSON(game.data.appearance, stage: game.stage)))")
    }

    private struct Profile: Encodable {
        let name: String
        let age: Int
        let fame: Int
        let hour: Int
    }

    private func sendProfile() {
        let p = Profile(name: game.data.name, age: game.age, fame: game.data.stats.fame,
                        hour: Calendar.current.component(.hour, from: .now))
        controller.run("city.setProfile(\(CityController.json(p)))")
    }

    /// 街のアイコンのところでボタンが押された
    private func openSpot(_ id: String) {
        switch id {
        case "food": showFood = true
        case "closet": showCloset = true
        case "rhyme": showRhyme = true
        case "rhythm": showRhythm = true
        case "cypher":
            if game.stage < .kid {
                controller.run("city.toast(\(CityController.json("サイファーは3歳になってから！")))")
            } else {
                showCypher = true
            }
        case "live":
            if game.performLive() {
                controller.run("city.live()")
            }
        case "workout", "dance":
            let before = game.data.growth
            game.exercise(id == "workout" ? .workout : .dance)
            if game.data.growth > before {
                controller.run("city.doAction('\(id)', 4)")
            }
        default: break
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
    var onSpot: ((String) -> Void)?
    var onTalk: (() -> Void)?

    private struct Message: Decodable {
        let type: String
        let id: String?
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
        case "home": onHome?()
        case "spot": if let id = msg.id { onSpot?(id) }
        case "talk": onTalk?()
        default: break
        }
    }

    static func json<T: Encodable>(_ v: T) -> String {
        guard let d = try? JSONEncoder().encode(v), let s = String(data: d, encoding: .utf8) else { return "null" }
        return s
    }
}
