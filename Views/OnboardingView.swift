import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    BrandHeader(title: "Radio License Study")

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.title2)
                            .foregroundStyle(RadioTheme.cyan)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("所有信息都保存在本地手机，我们不收集任何个人资料。")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RadioTheme.text)
                            Text("All information is stored locally on your phone. We do not collect any personal information.")
                                .font(.footnote)
                                .foregroundStyle(RadioTheme.muted)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .radioPanel()
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE YOUR STUDY AID")
                            .font(.caption.weight(.heavy)).tracking(1.5).foregroundStyle(RadioTheme.amber)
                        Text("English stays official and primary.")
                            .font(.largeTitle.bold()).foregroundStyle(RadioTheme.text)
                        Text("Choose the language for explanations. Non-English selections also show a study translation beneath each English question and choice. You can switch at any time without losing progress.")
                            .font(.body).foregroundStyle(RadioTheme.muted)
                    }

                    VStack(spacing: 12) {
                        ForEach(AuxiliaryLanguage.allCases) { language in
                            Button {
                                model.chooseLanguage(language)
                            } label: {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(language.nativeName).font(.title3.bold()).foregroundStyle(RadioTheme.text)
                                        Text(language.name).font(.subheadline).foregroundStyle(RadioTheme.muted)
                                    }
                                    Spacer()
                                    Text(language.welcome).font(.subheadline.weight(.semibold)).foregroundStyle(RadioTheme.cyan)
                                    Image(systemName: "chevron.right").foregroundStyle(RadioTheme.amber)
                                }
                                .padding(18)
                                .radioPanel()
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Use \(language.name) study explanations")
                        }
                    }

                    Text("Auxiliary translations are unofficial study aids. If anything differs, use the English pool and official answer key.")
                        .font(.footnote).foregroundStyle(RadioTheme.muted)
                }
                .padding(22)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
