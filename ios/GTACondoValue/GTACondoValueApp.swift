import SwiftUI

@main
struct GTACondoValueApp: App {
    @StateObject private var store = ValuationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
