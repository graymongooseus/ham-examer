import SwiftUI

struct FlashcardsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var currentIndex = 0
    @State private var showingAnswer = false

    private var questions: [Question] { model.flashcardQuestions }
    private var safeIndex: Int { min(max(0, currentIndex), max(0, questions.count - 1)) }
    private var currentQuestion: Question? { questions.indices.contains(safeIndex) ? questions[safeIndex] : nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                if let question = currentQuestion, let content = model.content(for: question), let language = model.language {
                    ScrollViewReader { proxy in
                        ScrollView {
                          VStack(alignment: .leading, spacing: 18) {
                              BrandHeader(eyebrow: "SAVED FOR REVIEW", title: "Flash Cards")
                              Text("\(safeIndex + 1) / \(questions.count) cards · \(question.group)")
                                  .font(.subheadline.monospacedDigit()).foregroundStyle(RadioTheme.muted)

                              card(question: question, content: content, language: language)
                                  .id("flash-card")

                              (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))) {
                                  Button("Previous") { move(by: -1) }
                                      .buttonStyle(SecondaryButtonStyle()).disabled(questions.count < 2)
                                  Button("Next") { move(by: 1) }
                                      .buttonStyle(PrimaryButtonStyle()).disabled(questions.count < 2)
                              }

                              Button {
                                  showingAnswer = false
                                  currentIndex = safeIndex
                                  model.toggleFlashcard(for: question)
                                  currentIndex = min(currentIndex, max(0, questions.count - 1))
                              } label: {
                                  Label("Remove from Flash Cards", systemImage: "bookmark.slash")
                              }
                              .buttonStyle(SecondaryButtonStyle())
                          }
                          .padding(16).padding(.bottom, 20)
                          .frame(maxWidth: 820).frame(maxWidth: .infinity)
                        }
                        .onChange(of: showingAnswer) { _, _ in
                            withAnimation { proxy.scrollTo("flash-card", anchor: .top) }
                        }
                    }
                    .id(question.id)
                } else if questions.isEmpty {
                    ContentUnavailableView("No Flash Cards yet", systemImage: "rectangle.on.rectangle",
                                           description: Text("Tap “Add to Flash Cards” on any question in Learn to save it here. Cards are stored on this phone."))
                        .foregroundStyle(RadioTheme.text)
                } else {
                    ContentUnavailableView("Study content unavailable", systemImage: "exclamationmark.triangle",
                                           description: Text(model.loadError ?? "Choose a study language."))
                        .foregroundStyle(RadioTheme.text)
                }
            }
            .navigationTitle("Flash Cards")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: currentQuestion?.id) { _, _ in showingAnswer = false }
        }
    }

    private func card(question: Question, content: AuxiliaryContent, language: AuxiliaryLanguage) -> some View {
        let order = model.learningOptionOrder(for: question)
        return VStack(alignment: .leading, spacing: 20) {
            QuestionHeading(question: question, content: content, language: language)
            if let diagram = question.diagramName { DiagramView(name: diagram) }
            if showingAnswer {
                FeedbackPanel(question: question, content: content, language: language,
                              selectedIndex: question.correct, optionOrder: order)
            } else {
                VStack(spacing: 11) {
                    ForEach(order, id: \.self) { index in
                        AnswerRow(displayLetter: question.displayLetter(for: index, in: order) ?? "—",
                                  english: question.answers[index],
                                  auxiliary: language == .english ? "" : content.answers[index],
                                  isSelected: false, result: nil)
                    }
                }
            }
            Button(showingAnswer ? "Show question" : "Show answer") {
                showingAnswer.toggle()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(20).radioPanel()
    }

    private func move(by offset: Int) {
        guard !questions.isEmpty else { return }
        currentIndex = (safeIndex + offset + questions.count) % questions.count
        showingAnswer = false
    }
}
