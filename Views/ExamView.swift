import SwiftUI

struct ExamView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmSubmit = false
    private let gridScrollID = "exam-question-grid"

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                Group {
                    if let exam = model.state.exam {
                        if exam.submitted { resultView(exam) } else { runningView(exam) }
                    } else {
                        startView
                    }
                }
            }
            .navigationTitle("Mock Exam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { languageMenu }
            .confirmationDialog("Submit this mock exam now?", isPresented: $confirmSubmit, titleVisibility: .visible) {
                Button("Submit and score", role: .destructive) { model.submitExam() }
                Button("Keep answering", role: .cancel) {}
            } message: {
                let unanswered = model.state.exam?.answers.filter { $0 == nil }.count ?? 0
                Text(unanswered == 0 ? "Answers cannot be changed after grading." : "\(unanswered) questions are unanswered. They will count as incorrect.")
            }
        }
    }

    private var startView: some View {
        ScrollView {
            VStack(spacing: 28) {
                BrandHeader()
                VStack(spacing: 18) {
                    Text("OFFICIAL BLUEPRINT").font(.caption.weight(.heavy)).tracking(1.4).foregroundStyle(RadioTheme.amber)
                    Text("35 groups. One question each.").font(.largeTitle.bold()).foregroundStyle(RadioTheme.text).multilineTextAlignment(.center)
                    Text("Choices follow the official question pool order. Correct answers remain hidden until you submit.")
                        .font(.body).foregroundStyle(RadioTheme.muted).multilineTextAlignment(.center)
                    HStack(spacing: 0) {
                        examFact("35", "questions")
                        Divider().overlay(RadioTheme.line)
                        examFact("26", "to pass")
                        Divider().overlay(RadioTheme.line)
                        examFact("LIVE", "elapsed time")
                    }
                    .frame(maxWidth: 600)
                    Button("Generate Mock Exam") { model.startExam() }.buttonStyle(PrimaryButtonStyle()).frame(maxWidth: 420)
                    Text("There is no invented time limit. Your in-progress exam is saved on this device.")
                        .font(.footnote).foregroundStyle(RadioTheme.muted)
                }
                .padding(.vertical, 54).padding(.horizontal, 24)
                .radioPanel()
            }
            .padding(16).frame(maxWidth: 820).frame(maxWidth: .infinity)
        }
    }

    private func examFact(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.monospacedDigit().bold()).foregroundStyle(RadioTheme.amber)
            Text(label).font(.caption).foregroundStyle(RadioTheme.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
    }

    private func runningView(_ exam: ExamSession) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    examToolbar(exam)
                    navigator(exam, proxy: proxy).id(gridScrollID)
                    if let question = model.examQuestion(at: exam.currentIndex), let content = model.content(for: question), let language = model.language {
                        examQuestionCard(exam: exam, question: question, content: content, language: language).id(question.id)
                    }
                    HStack(spacing: 12) {
                        Button("Previous") { moveExam(to: exam.currentIndex - 1, proxy: proxy) }
                            .buttonStyle(SecondaryButtonStyle()).disabled(exam.currentIndex == 0)
                        Button(exam.currentIndex == exam.items.count - 1 ? "Review grid" : "Next") {
                            if exam.currentIndex < exam.items.count - 1 {
                                moveExam(to: exam.currentIndex + 1, proxy: proxy)
                            } else {
                                withAnimation { proxy.scrollTo(gridScrollID, anchor: .top) }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    Button("Submit and score") { confirmSubmit = true }.buttonStyle(PrimaryButtonStyle()).padding(.top, 4)
                }
                .padding(16).padding(.bottom, 20).frame(maxWidth: 820).frame(maxWidth: .infinity)
            }
        }
    }

    private func examToolbar(_ exam: ExamSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PRACTICE EXAM").font(.caption.weight(.heavy)).tracking(1.3).foregroundStyle(RadioTheme.amber)
                Text("\(exam.currentIndex + 1) / 35 · \(exam.answers.compactMap { $0 }.count) answered")
                    .font(.subheadline).foregroundStyle(RadioTheme.muted)
            }
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Label(formatDuration(model.elapsedSeconds()), systemImage: "timer")
                    .font(.headline.monospacedDigit()).foregroundStyle(RadioTheme.amber)
            }
        }
        .padding(16).radioPanel()
    }

    private func navigator(_ exam: ExamSession, proxy: ScrollViewProxy) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 7), spacing: 7) {
            ForEach(exam.items.indices, id: \.self) { index in
                Button { moveExam(to: index, proxy: proxy) } label: {
                    Text("\(index + 1)").font(.caption.weight(.heavy)).frame(maxWidth: .infinity, minHeight: 38)
                        .foregroundStyle(exam.answers[index] == nil ? RadioTheme.muted : RadioTheme.onAccent)
                        .background(exam.answers[index] == nil ? RadioTheme.ink2 : RadioTheme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(index == exam.currentIndex ? RadioTheme.amber : RadioTheme.line, lineWidth: index == exam.currentIndex ? 2 : 1))
                }
                .buttonStyle(.plain).accessibilityLabel("Question \(index + 1), \(exam.answers[index] == nil ? "unanswered" : "answered")")
            }
        }
        .padding(14).radioPanel()
    }

    private func examQuestionCard(exam: ExamSession, question: Question, content: AuxiliaryContent, language: AuxiliaryLanguage) -> some View {
        let item = exam.items[exam.currentIndex]
        return VStack(alignment: .leading, spacing: 20) {
            QuestionHeading(question: question, content: content, language: language)
            if let diagram = question.diagramName { DiagramView(name: diagram) }
            VStack(spacing: 11) {
                ForEach(item.optionOrder, id: \.self) { originalIndex in
                    Button { model.selectExamAnswer(originalIndex) } label: {
                        AnswerRow(displayLetter: question.displayLetter(for: originalIndex, in: item.optionOrder) ?? "—", english: question.answers[originalIndex], auxiliary: language == .english ? "" : content.answers[originalIndex], isSelected: exam.answers[exam.currentIndex] == originalIndex, result: nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20).radioPanel()
    }

    private func resultView(_ exam: ExamSession) -> some View {
        let score = model.score(for: exam)
        return ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Text("RESULT").font(.caption.weight(.heavy)).tracking(1.4).foregroundStyle(RadioTheme.amber)
                    Text(score >= model.pool.meta.passScore ? "Passing score" : "Keep studying")
                        .font(.largeTitle.bold()).foregroundStyle(score >= model.pool.meta.passScore ? RadioTheme.green : RadioTheme.red)
                    Text("\(score) / 35").font(.system(.largeTitle, design: .monospaced, weight: .heavy)).foregroundStyle(RadioTheme.text)
                    Text("Pass line: 26 · Time: \(formatDuration(model.elapsedSeconds()))").foregroundStyle(RadioTheme.muted)
                    Button("Generate another exam") { model.clearExam(); model.startExam() }.buttonStyle(PrimaryButtonStyle()).frame(maxWidth: 420)
                }
                .padding(28).radioPanel()

                HStack { Text("COMPLETE REVIEW").font(.caption.weight(.heavy)).tracking(1.4).foregroundStyle(RadioTheme.amber); Spacer() }
                ForEach(exam.items.indices, id: \.self) { index in
                    if let question = model.examQuestion(at: index), let content = model.content(for: question) {
                        reviewItem(number: index + 1, question: question, content: content, language: model.language ?? .english, selected: exam.answers[index], optionOrder: exam.items[index].optionOrder)
                    }
                }
            }
            .padding(16).padding(.bottom, 24).frame(maxWidth: 820).frame(maxWidth: .infinity)
        }
    }

    private func reviewItem(number: Int, question: Question, content: AuxiliaryContent, language: AuxiliaryLanguage, selected: Int?, optionOrder: [Int]) -> some View {
        let correct = selected == question.correct
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(number). \(question.id)").font(.caption.monospaced().weight(.heavy)).foregroundStyle(RadioTheme.amber)
                Spacer()
                Label(correct ? "Correct" : "Incorrect", systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption.weight(.bold)).foregroundStyle(correct ? RadioTheme.green : RadioTheme.red)
            }
            QuestionShareButton(question: question, language: language)
            Text(question.question).font(.headline).foregroundStyle(RadioTheme.text)
            if language != .english {
                Text(content.question).font(.subheadline).foregroundStyle(RadioTheme.muted)
            }
            if let diagram = question.diagramName { DiagramView(name: diagram) }
            VStack(spacing: 11) {
                ForEach(optionOrder, id: \.self) { originalIndex in
                    AnswerRow(
                        displayLetter: question.displayLetter(for: originalIndex, in: optionOrder) ?? "—",
                        english: question.answers[originalIndex],
                        auxiliary: language == .english ? "" : content.answers[originalIndex],
                        isSelected: selected == originalIndex,
                        result: originalIndex == question.correct ? .correct : selected == originalIndex ? .wrong : nil
                    )
                }
            }
            if let selected {
                Text("Your answer: \(question.displayLetter(for: selected, in: optionOrder) ?? "—") · \(question.answers[selected])").font(.subheadline).foregroundStyle(correct ? RadioTheme.green : RadioTheme.red)
            } else {
                Text("Your answer: Unanswered").font(.subheadline).foregroundStyle(RadioTheme.red)
            }
            Text("Correct answer: \(question.displayLetter(for: question.correct, in: optionOrder) ?? "—") · \(question.answers[question.correct])")
                .font(.subheadline.weight(.bold)).foregroundStyle(RadioTheme.amber2)
            if language != .english {
                Text(content.answers[question.correct]).font(.subheadline).foregroundStyle(RadioTheme.muted)
            }
            Text(content.explanation).font(.body).foregroundStyle(RadioTheme.text)
        }
        .padding(18).radioPanel()
    }

    private func moveExam(to index: Int, proxy: ScrollViewProxy) {
        model.goToExamQuestion(index)
        DispatchQueue.main.async { if let question = model.examQuestion(at: index) { withAnimation { proxy.scrollTo(question.id, anchor: .top) } } }
    }

    private func formatDuration(_ total: Int) -> String {
        let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
        return hours > 0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
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
            .accessibilityLabel("Change explanation language")
        }
    }
}
