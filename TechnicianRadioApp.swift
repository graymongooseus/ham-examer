import SwiftUI
import UIKit

@main
struct TechnicianRadioApp: App {
    @StateObject private var model = AppModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(RadioTheme.ink2)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(RadioTheme.ink2)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(RadioTheme.text)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if model.language == nil { OnboardingView() } else { MainView() }
            }
            .environmentObject(model)
            .preferredColorScheme(model.state.theme == .light ? .light : .dark)
        }
    }
}
