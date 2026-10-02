import SwiftUI

struct LearningView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var jumpText = ""
    @State private var showInvalidID = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                if let question = model.currentQuestion, let content = model.content(for: question), let language = model.language {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 18) {
                                BrandHeader()
                                progressPanel
                                questionCard(question: question, content: content, language: language)
                                    .id(question.id)
                                navigationButtons(proxy: proxy)
                            }
                            .padding(16)
                            .frame(maxWidth: 820)
                            .frame(maxWidth: .infinity)
                        }
                    }
                } else {
                    ContentUnavailableView("Study content unavailable", systemImage: "exclamationmark.triangle", description: Text(model.loadError ?? "Choose a study language."))
                        .foregroundStyle(RadioTheme.text)
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { languageMenu }
            .alert("Question not found", isPresented: $showInvalidID) { Button("OK", role: .cancel) {} } message: { Text("Enter a number from 1–409 or an ID such as T5D03.") }
        }
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(alignment: .center, spacing: 8))) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEVICE PROGRESS").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(RadioTheme.amber)
                    Text("\(model.completedCount) practiced · \(model.correctEverCount) mastered")
                        .font(.subheadline).foregroundStyle(RadioTheme.muted)
                }
                Text("\(Int(model.completionFraction * 100))%")
                    .font(.title2.monospacedDigit().bold()).foregroundStyle(RadioTheme.text)
            }
            ProgressView(value: model.completionFraction).tint(RadioTheme.amber)

            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))) {
                Menu {
                    ForEach(Array(Dictionary(grouping: model.pool.questions, by: \.subelement).keys.sorted()), id: \.self) { subelement in
                        Button(subelement) {
                            if let index = model.pool.questions.firstIndex(where: { $0.subelement == subelement }) { model.goToQuestion(index) }
                        }
                    }
                } label: {
                    Label(model.currentQuestion?.subelement ?? "Section", systemImage: "list.bullet").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                TextField("No. or ID", text: $jumpText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { jump() }
                    .padding(.horizontal, 12).frame(minHeight: 46)
                    .background(RadioTheme.ink2).clipShape(RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(RadioTheme.line))
                Button("Go", action: jump).buttonStyle(.borderedProminent).tint(RadioTheme.amber).foregroundStyle(RadioTheme.onAccent)
            }
        }
        .padding(18)
        .radioPanel()
    }

    private func questionCard(question: Question, content: AuxiliaryContent, language: AuxiliaryLanguage) -> some View {
        let record = model.state.records[question.id]
        let optionOrder = model.learningOptionOrder(for: question)
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LEARNING MODE").font(.caption.weight(.heavy)).tracking(1.3).foregroundStyle(RadioTheme.amber)
                    Text("\(model.state.currentQuestionIndex + 1) / \(model.pool.questions.count) · \(question.group)")
                        .font(.subheadline).foregroundStyle(RadioTheme.muted)
                }
                Spacer()
            }
            Button {
                model.toggleFlashcard(for: question)
            } label: {
                Label(model.state.flashcardIDs.contains(question.id) ? "Added to Flash Cards" : "Add to Flash Cards",
                      systemImage: model.state.flashcardIDs.contains(question.id) ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityHint(model.state.flashcardIDs.contains(question.id) ? "Remove this question from Flash Cards" : "Save this question for flash card review")
            QuestionHeading(question: question, content: content, language: language)
            if let diagram = question.diagramName { DiagramView(name: diagram) }
            VStack(spacing: 11) {
                ForEach(optionOrder, id: \.self) { originalIndex in
                    let letter = question.displayLetter(for: originalIndex, in: optionOrder) ?? "—"
                    let selected = record?.selectedIndex == originalIndex
                    let revealed = record?.selectedIndex != nil
                    Button {
                        model.selectLearningAnswer(originalIndex, for: question)
                    } label: {
                        AnswerRow(
                            displayLetter: letter,
                            english: question.answers[originalIndex],
                            auxiliary: language == .english ? "" : content.answers[originalIndex],
                            isSelected: selected,
                            result: revealed ? (originalIndex == question.correct ? .correct : selected ? .wrong : nil) : nil
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(revealed)
                    .accessibilityLabel(answerAccessibilityLabel(letter: letter, english: question.answers[originalIndex], auxiliary: content.answers[originalIndex], language: language))
                }
            }
            if let selectedIndex = record?.selectedIndex {
                FeedbackPanel(question: question, content: content, language: language, selectedIndex: selectedIndex, optionOrder: optionOrder)
                Button("Answer again") { model.repeatLearningQuestion(question) }.buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(20)
        .radioPanel()
    }

    private func answerAccessibilityLabel(letter: String, english: String, auxiliary: String, language: AuxiliaryLanguage) -> String {
        language == .english ? "Option \(letter): \(english)" : "Option \(letter): \(english). \(auxiliary)"
    }

    private func navigationButtons(proxy: ScrollViewProxy) -> some View {
        (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))) {
            Button("Previous") {
                model.goToQuestion(model.state.currentQuestionIndex - 1)
                scrollToCurrent(proxy)
            }
            .buttonStyle(SecondaryButtonStyle()).disabled(model.state.currentQuestionIndex == 0)
            Button(model.state.currentQuestionIndex == model.pool.questions.count - 1 ? "Back to first" : "Next") {
                model.goToQuestion(model.state.currentQuestionIndex == model.pool.questions.count - 1 ? 0 : model.state.currentQuestionIndex + 1)
                scrollToCurrent(proxy)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.bottom, 20)
    }

    private func scrollToCurrent(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async { if let id = model.currentQuestion?.id { withAnimation { proxy.scrollTo(id, anchor: .top) } } }
    }

    private func jump() {
        let raw = jumpText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = Int(raw), (1...model.pool.questions.count).contains(number) {
            model.goToQuestion(number - 1); jumpText = ""
        } else if model.goToQuestion(id: raw) {
            jumpText = ""
        } else {
            showInvalidID = true
        }
    }

    @ToolbarContentBuilder private var languageMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(AuxiliaryLanguage.allCases) { language in
                    Button { model.chooseLanguage(language) } label: {
                        if language == model.language { Label(language.nativeName, systemImage: "checkmark") } else { Text(language.nativeName) }
                    }
                }
            } label: { Image(systemName: "globe") }
            .accessibilityLabel("Change auxiliary language")
        }
    }
}
