import SwiftUI

@main
struct RapperRaiseApp: App {
    @StateObject private var game = GameState()

    var body: some Scene {
        WindowGroup {
            Group {
                if game.data.created { ContentView() } else { CreateView() }
            }
            .environmentObject(game)
        }
    }
}
