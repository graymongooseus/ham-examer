import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    private var version: String {
        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(release) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        BrandHeader(eyebrow: "PREFERENCES", title: "System Settings")

                        VStack(alignment: .leading, spacing: 14) {
                            Label("Theme · 主题", systemImage: "circle.lefthalf.filled")
                                .font(.title3.bold()).foregroundStyle(RadioTheme.text)
                            ForEach(AppTheme.allCases) { theme in
                                Button {
                                    model.chooseTheme(theme)
                                } label: {
                                    HStack(spacing: 12) {
                                        Label(theme.name, systemImage: theme.symbol)
                                        Spacer(minLength: 8)
                                        if model.state.theme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(RadioTheme.cyan)
                                        }
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .accessibilityAddTraits(model.state.theme == theme ? .isSelected : [])
                            }
                            Text("Your theme is saved on this phone.")
                                .font(.footnote).foregroundStyle(RadioTheme.muted)
                        }
                        .padding(20).radioPanel()

                        VStack(alignment: .leading, spacing: 14) {
                            Label("App & Developer", systemImage: "info.circle")
                                .font(.title3.bold()).foregroundStyle(RadioTheme.text)
                            detail("Version · 版本", value: version)
                            detail("Developer · 开发者", value: "Gray Mongoose")
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Contact · 联系邮箱")
                                    .font(.subheadline).foregroundStyle(RadioTheme.muted)
                                Link("ham@graymongoose.us", destination: URL(string: "mailto:ham@graymongoose.us")!)
                                    .font(.headline).tint(RadioTheme.cyan)
                                    .textSelection(.enabled)
                                    .accessibilityLabel("Email developer: ham@graymongoose.us")
                            }
                        }
                        .padding(20).radioPanel()

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Privacy · 隐私", systemImage: "lock.shield")
                                .font(.title3.bold()).foregroundStyle(RadioTheme.text)
                            Text("所有信息都保存在本地手机，我们不收集任何个人资料。")
                                .foregroundStyle(RadioTheme.text)
                            Text("All information is stored locally on your phone. We do not collect any personal information.")
                                .font(.footnote).foregroundStyle(RadioTheme.muted)
                        }
                        .padding(20).radioPanel()
                    }
                    .padding(16).padding(.bottom, 20)
                    .frame(maxWidth: 820).frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func detail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(RadioTheme.muted)
            Text(value).font(.headline).foregroundStyle(RadioTheme.text).textSelection(.enabled)
        }
    }
}
