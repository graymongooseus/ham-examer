import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var pool: PoolDocument
    @Published private(set) var translations: [String: AuxiliaryContent] = [:]
    @Published var state: PersistedState
    @Published var loadError: String?

    private static let storageKey = "technician-radio-study-state-v1"
    private let bundle: Bundle
    private let defaults: UserDefaults

    init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        self.bundle = bundle
        self.defaults = defaults
        do {
            pool = try QuestionStore.loadPool(bundle: bundle)
        } catch {
            pool = PoolDocument(
                meta: PoolMeta(title: "Question pool unavailable", revision: "", effective: "", expires: "", questionCount: 0, groupCount: 0, passScore: 26, diagramCount: 0, withdrawnChecked: "", withdrawnCount: 0),
                questions: []
            )
            loadError = error.localizedDescription
        }

        if let data = defaults.data(forKey: Self.storageKey), let restored = try? JSONDecoder().decode(PersistedState.self, from: data) {
            state = restored
        } else {
            state = PersistedState()
        }
        state.currentQuestionIndex = min(max(0, state.currentQuestionIndex), max(0, pool.questions.count - 1))
        if loadError == nil {
            state.flashcardIDs.formIntersection(Set(pool.questions.map(\.id)))
        }
        validateRestoredExam()
        if let language = state.language { load(language) }
    }

    var language: AuxiliaryLanguage? { state.language }
    var currentQuestion: Question? { pool.questions.indices.contains(state.currentQuestionIndex) ? pool.questions[state.currentQuestionIndex] : nil }
    var completedCount: Int { state.records.values.filter { $0.attempts > 0 }.count }
    var correctEverCount: Int { state.records.values.filter(\.correctEver).count }
    var completionFraction: Double { pool.questions.isEmpty ? 0 : Double(completedCount) / Double(pool.questions.count) }
    var flashcardQuestions: [Question] { pool.questions.filter { state.flashcardIDs.contains($0.id) } }

    func chooseTheme(_ theme: AppTheme) {
        state.theme = theme
        persist()
    }

    func toggleFlashcard(for question: Question) {
        guard pool.questions.contains(where: { $0.id == question.id }) else { return }
        if state.flashcardIDs.contains(question.id) {
            state.flashcardIDs.remove(question.id)
        } else {
            state.flashcardIDs.insert(question.id)
        }
        persist()
    }

    func chooseLanguage(_ language: AuxiliaryLanguage) {
        state.language = language
        load(language)
        persist()
    }

    func content(for question: Question) -> AuxiliaryContent? { translations[question.id] }

    func goToQuestion(_ index: Int) {
        guard !pool.questions.isEmpty else { return }
        state.currentQuestionIndex = min(max(0, index), pool.questions.count - 1)
        touchLearning()
        persist()
    }

    func goToQuestion(id: String) -> Bool {
        guard let index = pool.questions.firstIndex(where: { $0.id.caseInsensitiveCompare(id) == .orderedSame }) else { return false }
        goToQuestion(index)
        return true
    }

    func selectLearningAnswer(_ index: Int, for question: Question) {
        guard (0..<question.answers.count).contains(index), state.records[question.id]?.selectedIndex == nil else { return }
        var record = state.records[question.id] ?? StudyRecord()
        let correct = index == question.correct
        record.attempts += 1
        record.lastCorrect = correct
        record.correctEver = record.correctEver || correct
        record.selectedIndex = index
        record.updatedAt = nowMilliseconds
        state.records[question.id] = record
        touchLearning()
        persist()
    }

    func repeatLearningQuestion(_ question: Question) {
        state.records[question.id]?.selectedIndex = nil
        state.records[question.id]?.updatedAt = nowMilliseconds
        touchLearning()
        persist()
    }

    func learningOptionOrder(for question: Question) -> [Int] {
        var generator = Mulberry32(seed: seedFromString("\(question.id):learn"))
        return generator.shuffled(Array(question.answers.indices))
    }

    func startExam(seed: UInt32 = UInt32.random(in: UInt32.min...UInt32.max)) {
        var generator = Mulberry32(seed: seed)
        let groups = Dictionary(grouping: pool.questions, by: \.group)
        var seenGroups = Set<String>()
        let officialGroupOrder = pool.questions.compactMap { question in
            seenGroups.insert(question.group).inserted ? question.group : nil
        }
        let items = officialGroupOrder.compactMap { group -> ExamItem? in
            guard let candidates = groups[group], !candidates.isEmpty else { return nil }
            let question = candidates[generator.index(upperBound: candidates.count)]
            return ExamItem(questionID: question.id, optionOrder: generator.shuffled(Array(question.answers.indices)))
        }
        guard items.count == pool.meta.groupCount else {
            loadError = "Could not generate one question from every official group."
            return
        }
        let now = nowMilliseconds
        state.exam = ExamSession(seed: seed, items: items, answers: Array(repeating: nil, count: items.count), currentIndex: 0, startedAt: Date(), submittedAt: nil, elapsedAtSubmit: nil, updatedAt: now)
        state.examUpdatedAt = now
        state.updatedAt = now
        persist()
    }

    func examQuestion(at index: Int) -> Question? {
        guard let exam = state.exam, exam.items.indices.contains(index) else { return nil }
        return pool.questions.first { $0.id == exam.items[index].questionID }
    }

    func selectExamAnswer(_ originalIndex: Int) {
        guard var exam = state.exam, !exam.submitted,
              exam.answers.indices.contains(exam.currentIndex),
              let question = examQuestion(at: exam.currentIndex),
              question.answers.indices.contains(originalIndex) else { return }
        exam.answers[exam.currentIndex] = originalIndex
        exam.updatedAt = nowMilliseconds
        state.exam = exam
        state.examUpdatedAt = exam.updatedAt
        state.updatedAt = exam.updatedAt
        persist()
    }

    func goToExamQuestion(_ index: Int) {
        guard var exam = state.exam, exam.items.indices.contains(index) else { return }
        exam.currentIndex = index
        exam.updatedAt = nowMilliseconds
        state.exam = exam
        state.examUpdatedAt = exam.updatedAt
        state.updatedAt = exam.updatedAt
        persist()
    }

    func submitExam() {
        guard var exam = state.exam, !exam.submitted else { return }
        let now = Date()
        exam.submittedAt = now
        exam.elapsedAtSubmit = max(0, Int(now.timeIntervalSince(exam.startedAt)))
        exam.updatedAt = nowMilliseconds
        state.exam = exam
        state.examUpdatedAt = exam.updatedAt
        state.updatedAt = exam.updatedAt
        persist()
    }

    func score(for exam: ExamSession) -> Int {
        exam.items.indices.reduce(into: 0) { score, index in
            if exam.answers.indices.contains(index),
               let question = pool.questions.first(where: { $0.id == exam.items[index].questionID }),
               exam.answers[index] == question.correct { score += 1 }
        }
    }

    func elapsedSeconds(now: Date = Date()) -> Int {
        guard let exam = state.exam else { return 0 }
        return exam.elapsedAtSubmit ?? max(0, Int(now.timeIntervalSince(exam.startedAt)))
    }

    func clearExam() {
        state.exam = nil
        state.examUpdatedAt = nowMilliseconds
        state.updatedAt = state.examUpdatedAt
        persist()
    }

    /// Contract-ready projection. Network sync stays disabled until hosted auth offers a supported native credential handoff.
    var webProgressState: WebProgressState {
        let learningRecords = state.records.mapValues {
            WebLearningRecord(attempts: $0.attempts, correctEver: $0.correctEver, lastCorrect: $0.lastCorrect, lastSelected: $0.selectedIndex, updatedAt: $0.updatedAt)
        }
        let activeExam = state.exam.flatMap { exam -> WebExamState? in
            guard !exam.submitted else { return nil }
            return WebExamState(
                seed: exam.seed,
                answers: exam.answers,
                current: exam.currentIndex,
                startTime: Int64(exam.startedAt.timeIntervalSince1970 * 1_000),
                updatedAt: exam.updatedAt
            )
        }
        return WebProgressState(
            version: 2,
            updatedAt: state.updatedAt,
            examUpdatedAt: state.examUpdatedAt,
            learning: WebLearningState(current: state.currentQuestionIndex, byId: learningRecords, updatedAt: state.learningUpdatedAt),
            exam: activeExam
        )
    }

    private func validateRestoredExam() {
        guard var exam = state.exam else { return }
        let questions = exam.items.compactMap { item in pool.questions.first { $0.id == item.questionID } }
        let valid = !exam.items.isEmpty
            && exam.items.count == pool.meta.groupCount
            && questions.count == exam.items.count
            && Set(questions.map(\.group)).count == pool.meta.groupCount
            && exam.answers.count == exam.items.count
            && zip(exam.items, questions).allSatisfy { item, question in
                item.optionOrder.count == question.answers.count
                    && Set(item.optionOrder) == Set(question.answers.indices)
            }
            && zip(exam.answers, questions).allSatisfy { answer, question in
                answer.map { question.answers.indices.contains($0) } ?? true
            }
        guard valid else {
            // Keep learning records when an incompatible exam cannot be resumed safely.
            clearExam()
            return
        }
        exam.currentIndex = min(max(0, exam.currentIndex), exam.items.count - 1)
        state.exam = exam
    }

    private func load(_ language: AuxiliaryLanguage) {
        do {
            let loaded = try QuestionStore.loadTranslations(language, bundle: bundle)
            try QuestionStore.validate(pool: pool, translations: loaded)
            translations = loaded
            loadError = nil
        } catch {
            translations = [:]
            loadError = error.localizedDescription
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    private var nowMilliseconds: Int64 { Int64(Date().timeIntervalSince1970 * 1_000) }

    private func touchLearning() {
        let now = nowMilliseconds
        state.learningUpdatedAt = now
        state.updatedAt = now
    }

    private func seedFromString(_ value: String) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in value.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return hash
    }
}
