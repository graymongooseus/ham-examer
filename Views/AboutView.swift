import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        BrandHeader(eyebrow: "SOURCE & BLUEPRINT", title: "Complete official pool")
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Not a reduced question set").font(.largeTitle.bold()).foregroundStyle(RadioTheme.text)
                            Text("All 409 English questions, official answer mappings, 35 groups, and three diagrams from the current 2026–2030 Technician pool are included offline.")
                                .foregroundStyle(RadioTheme.muted)
                        }
                        .padding(22).radioPanel()

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
                            factCard("VERSION", "Feb 19, 2026", "Effective Jul 1, 2026 through Jun 30, 2030")
                            factCard("POOL", "409 · 35", "Four choices each; one exam question per official group")
                            factCard("DIAGRAMS", "3 official", "Figures T-1, T-2, and T-3 are bundled for offline use")
                            factCard("PASS", "26 / 35", "Mock exams use the official passing threshold")
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Study language").font(.title3.bold()).foregroundStyle(RadioTheme.text)
                            Picker("Explanation language", selection: Binding(get: { model.language ?? .english }, set: model.chooseLanguage)) {
                                ForEach(AuxiliaryLanguage.allCases) { Text("\($0.nativeName) · \($0.name)").tag($0) }
                            }
                            .pickerStyle(.menu).tint(RadioTheme.amber)
                            Text("Official questions and choices always remain in English. Translations and all explanations are unofficial study aids.").font(.footnote).foregroundStyle(RadioTheme.muted)
                        }
                        .padding(20).radioPanel()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sources").font(.title3.bold()).foregroundStyle(RadioTheme.text)
                            Link("NCVEC official 2026–2030 Technician pool", destination: URL(string: "https://ncvec.org/index.php/2026-2030-technician-question-pool")!)
                            Link("ARRL question pool announcement", destination: URL(string: "https://www.arrl.org/news/new-technician-question-pool-takes-effect-july-1")!)
                            Link("ARRL withdrawn questions", destination: URL(string: "https://www.arrl.org/withdrawn-questions")!)
                        }
                        .tint(RadioTheme.cyan).padding(20).radioPanel()

                        Text("Independent, unofficial study software. Not affiliated with or endorsed by the FCC, NCVEC, or ARRL. Account sync is intentionally not enabled until the companion website supplies its documented backend contract; local study works fully offline.")
                            .font(.footnote).foregroundStyle(RadioTheme.muted).padding(.vertical, 10)
                    }
                    .padding(16).padding(.bottom, 20).frame(maxWidth: 820).frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func factCard(_ kicker: String, _ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kicker).font(.caption2.weight(.heavy)).tracking(1.2).foregroundStyle(RadioTheme.amber)
            Text(title).font(.title3.bold()).foregroundStyle(RadioTheme.text)
            Text(detail).font(.caption).foregroundStyle(RadioTheme.muted)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading).padding(16).radioPanel()
    }
}
