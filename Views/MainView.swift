import SwiftUI

struct MainView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            LearningView()
                .tabItem { Label("Learn", systemImage: "book.pages") }
            FlashcardsView()
                .tabItem { Label("Flash Cards", systemImage: "rectangle.on.rectangle") }
                .badge(model.state.flashcardIDs.count)
            ExamView()
                .tabItem { Label("Mock Exam", systemImage: "checklist") }
            AboutView()
                .tabItem { Label("About", systemImage: "antenna.radiowaves.left.and.right") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(RadioTheme.amber)
        .overlay(alignment: .top) {
            if let error = model.loadError {
                Text(error)
                    .font(.footnote.weight(.semibold)).foregroundStyle(RadioTheme.onAccent)
                    .padding(10).background(RadioTheme.red).clipShape(Capsule()).padding(.top, 8)
                    .accessibilityLabel("Content error: \(error)")
            }
        }
    }
}
