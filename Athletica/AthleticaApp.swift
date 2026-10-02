import SwiftUI

@main struct AthleticaApp: App {
    @StateObject private var store=AppStore()
    @StateObject private var health=HealthKitManager()
    @StateObject private var subscriptions=SubscriptionManager()
    var body: some Scene { WindowGroup { ContentView().environmentObject(store).environmentObject(health).environmentObject(subscriptions) } }
}
