import XCTest
@testable import TechnicianRadio

final class TechnicianRadioTests: XCTestCase {
    func testSharedQuestionsUseOfficialChoicesAndStudyLanguageWithoutAnswerKeys() throws {
        let pool = try QuestionStore.loadPool(bundle: Bundle(for: Self.self))
        for question in pool.questions {
            for language in AuxiliaryLanguage.allCases {
                let text = question.shareText(explanationLanguage: language)
                XCTAssertTrue(text.contains(question.id))
                XCTAssertTrue(text.contains(question.question))
                let lines = text.components(separatedBy: "\n")
                let choiceLines = lines.filter { line in
                    ["A. ", "B. ", "C. ", "D. "].contains { line.hasPrefix($0) }
                }
                XCTAssertEqual(choiceLines, zip(["A", "B", "C", "D"], question.answers).map { "\($0). \($1)" }, question.id)
                XCTAssertTrue(text.hasSuffix("Respond in \(language.name)."))
                XCTAssertFalse(text.contains("Correct answer:"))
                XCTAssertFalse(text.contains("Your answer:"))
                if let diagram = question.diagramName {
                    XCTAssertTrue(text.contains("Diagram: \(diagram.uppercased())"))
                } else {
                    XCTAssertFalse(text.contains("Diagram:"))
                }
            }
        }
    }

    @MainActor
    func testLegacyShuffledExamsRestoreOfficialOrderWithoutChangingAnswersOrScores() async throws {
        let suiteName = UUID().uuidString
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { suite.removePersistentDomain(forName: suiteName) }
        let bundle = Bundle(for: Self.self)
        let model = AppModel(bundle: bundle, defaults: suite)
        model.chooseLanguage(.chinese)
        let first = try XCTUnwrap(model.currentQuestion)
        model.selectLearningAnswer(first.correct, for: first)
        model.toggleFlashcard(for: first)
        model.chooseTheme(.light)
        model.startExam(seed: 73)
        let baseline = model.state
        for submitted in [false, true] {
            var legacy = baseline
            var exam = try XCTUnwrap(legacy.exam)
            exam.items = exam.items.enumerated().map { index, item in
                ExamItem(questionID: item.questionID, optionOrder: index.isMultiple(of: 2) ? [3, 2, 1, 0] : [1, 2, 3, 0])
            }
            exam.answers = exam.items.enumerated().map { index, item in
                let question = model.pool.questions.first { $0.id == item.questionID }!
                return index.isMultiple(of: 2) ? question.correct : (question.correct + 1) % 4
            }
            exam.currentIndex = 17
            if submitted {
                exam.submittedAt = exam.startedAt.addingTimeInterval(180)
                exam.elapsedAtSubmit = 180
            }
            legacy.exam = exam
            suite.set(try JSONEncoder().encode(legacy), forKey: "technician-radio-study-state-v1")
            let restored = AppModel(bundle: bundle, defaults: suite)
            let migrated = try XCTUnwrap(restored.state.exam)
            XCTAssertTrue(migrated.items.allSatisfy { $0.optionOrder == [0, 1, 2, 3] })
            XCTAssertEqual(migrated.items.map(\.questionID), exam.items.map(\.questionID))
            XCTAssertEqual(migrated.answers, exam.answers)
            XCTAssertEqual(migrated.seed, exam.seed)
            XCTAssertEqual(migrated.currentIndex, 17)
            XCTAssertEqual(migrated.startedAt, exam.startedAt)
            XCTAssertEqual(migrated.submittedAt, exam.submittedAt)
            XCTAssertEqual(migrated.elapsedAtSubmit, exam.elapsedAtSubmit)
            XCTAssertEqual(migrated.updatedAt, exam.updatedAt)
            XCTAssertEqual(restored.score(for: migrated), 18)
            XCTAssertEqual(restored.state.records, legacy.records)
            XCTAssertEqual(restored.state.flashcardIDs, legacy.flashcardIDs)
            XCTAssertEqual(restored.state.theme, legacy.theme)
            let persisted = try JSONDecoder().decode(PersistedState.self, from: XCTUnwrap(suite.data(forKey: "technician-radio-study-state-v1")))
            XCTAssertEqual(persisted.exam, migrated)
        }
    }

    @MainActor
    func testFlashcardsAndThemePersistWithoutChangingStudyOrExamProgress() async throws {
        let suiteName = UUID().uuidString
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { suite.removePersistentDomain(forName: suiteName) }
        let bundle = Bundle(for: Self.self)
        let model = AppModel(bundle: bundle, defaults: suite)
        model.chooseLanguage(.chinese)
        model.goToQuestion(12)
        let question = try XCTUnwrap(model.currentQuestion)
        model.selectLearningAnswer(question.correct, for: question)
        model.startExam(seed: 42)
        model.selectExamAnswer(2)
        let exam = model.state.exam
        let records = model.state.records
        let order = model.learningOptionOrder(for: question)

        model.toggleFlashcard(for: question)
        model.chooseTheme(.light)
        model.chooseLanguage(.spanish)
        let restored = AppModel(bundle: bundle, defaults: suite)
        XCTAssertEqual(restored.state.theme, .light)
        XCTAssertEqual(restored.flashcardQuestions.map(\.id), [question.id])
        XCTAssertEqual(restored.state.currentQuestionIndex, 12)
        XCTAssertEqual(restored.state.records, records)
        XCTAssertEqual(restored.state.exam, exam)
        XCTAssertEqual(restored.learningOptionOrder(for: question), order)
        XCTAssertEqual(restored.language, .spanish)

        restored.toggleFlashcard(for: question)
        restored.chooseTheme(.dark)
        let removed = AppModel(bundle: bundle, defaults: suite)
        XCTAssertTrue(removed.flashcardQuestions.isEmpty)
        XCTAssertEqual(removed.state.theme, .dark)
        XCTAssertEqual(removed.state.records, records)
        XCTAssertEqual(removed.state.exam, exam)
    }

    func testDisplayLettersForAllQuestionsAndEveryOptionPermutation() throws {
        let pool = try QuestionStore.loadPool(bundle: Bundle(for: Self.self))
        func permutations(_ values: [Int]) -> [[Int]] {
            guard !values.isEmpty else { return [[]] }
            return values.flatMap { first in
                permutations(values.filter { $0 != first }).map { [first] + $0 }
            }
        }
        let orders = permutations([0, 1, 2, 3])
        XCTAssertEqual(orders.count, 24)
        for question in pool.questions {
            for order in orders {
                for (displayIndex, originalIndex) in order.enumerated() {
                    XCTAssertEqual(question.displayLetter(for: originalIndex, in: order), ["A", "B", "C", "D"][displayIndex], question.id)
                }
                let correctPosition = try XCTUnwrap(order.firstIndex(of: question.correct))
                XCTAssertEqual(question.displayLetter(for: question.correct, in: order), ["A", "B", "C", "D"][correctPosition], question.id)
            }
        }
        let first = try XCTUnwrap(pool.questions.first)
        XCTAssertNil(first.displayLetter(for: -1, in: [0, 1, 2, 3]))
        XCTAssertNil(first.displayLetter(for: 4, in: [0, 1, 2, 3]))
        XCTAssertNil(first.displayLetter(for: first.correct, in: []))
    }

    @MainActor
    func testOfficialLearningOrderAndAnswersForEveryQuestion() async throws {
        let suiteName = UUID().uuidString
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { suite.removePersistentDomain(forName: suiteName) }
        let model = AppModel(bundle: Bundle(for: Self.self), defaults: suite)
        model.chooseLanguage(.english)
        for question in model.pool.questions {
            let order = model.learningOptionOrder(for: question)
            XCTAssertEqual(order, [0, 1, 2, 3], question.id)
            XCTAssertEqual(question.displayLetter(for: question.correct, in: order), question.correctLetter, question.id)
            let correctPosition = try XCTUnwrap(order.firstIndex(of: question.correct))
            let wrongPosition = (correctPosition + 1) % order.count
            model.selectLearningAnswer(order[wrongPosition], for: question)
            XCTAssertEqual(model.state.records[question.id]?.lastCorrect, false, question.id)
            model.repeatLearningQuestion(question)
            model.selectLearningAnswer(order[correctPosition], for: question)
            XCTAssertEqual(model.state.records[question.id]?.lastCorrect, true, question.id)
            XCTAssertEqual(model.state.records[question.id]?.selectedIndex, question.correct, question.id)
        }
        let first = try XCTUnwrap(model.pool.questions.first)
        XCTAssertEqual(first.id, "T1A01")
        XCTAssertEqual(first.displayLetter(for: first.correct, in: model.learningOptionOrder(for: first)), "C")
        let restored = AppModel(bundle: Bundle(for: Self.self), defaults: suite)
        XCTAssertEqual(restored.completedCount, 409)
        XCTAssertEqual(restored.correctEverCount, 409)
        for question in restored.pool.questions {
            XCTAssertEqual(restored.learningOptionOrder(for: question), model.learningOptionOrder(for: question))
            XCTAssertEqual(restored.state.records[question.id], model.state.records[question.id])
        }
    }

    @MainActor
    func testOfficialExamOrderScoringAndReviewSurviveRestoration() async throws {
        let suiteName = UUID().uuidString
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { suite.removePersistentDomain(forName: suiteName) }
        let bundle = Bundle(for: Self.self)
        let model = AppModel(bundle: bundle, defaults: suite)
        model.chooseLanguage(.english)
        for seed in UInt32(0)..<16 {
            model.startExam(seed: seed)
            let generated = try XCTUnwrap(model.state.exam)
            for index in generated.items.indices {
                model.goToExamQuestion(index)
                let question = try XCTUnwrap(model.examQuestion(at: index))
                let order = generated.items[index].optionOrder
                XCTAssertEqual(order, [0, 1, 2, 3])
                XCTAssertEqual(question.displayLetter(for: question.correct, in: order), question.correctLetter)
                let correctPosition = try XCTUnwrap(order.firstIndex(of: question.correct))
                let position = index.isMultiple(of: 2) ? correctPosition : (correctPosition + 1) % order.count
                model.selectExamAnswer(order[position])
                XCTAssertEqual(model.state.exam?.answers[index], order[position])
            }
            let answered = try XCTUnwrap(model.state.exam)
            model.selectExamAnswer(99)
            XCTAssertEqual(model.state.exam, answered, "Invalid answer indices must be rejected")
            XCTAssertEqual(model.score(for: answered), 18)
            for language in AuxiliaryLanguage.allCases {
                model.chooseLanguage(language)
                XCTAssertEqual(model.state.exam, answered)
                XCTAssertEqual(model.score(for: answered), 18)
            }
            let restored = AppModel(bundle: bundle, defaults: suite)
            XCTAssertEqual(restored.state.exam, answered, "Review must use the exact saved option order")
            XCTAssertEqual(restored.score(for: answered), 18)
            restored.submitExam()
            let submitted = try XCTUnwrap(restored.state.exam)
            restored.selectExamAnswer(0)
            XCTAssertEqual(restored.state.exam, submitted, "Submitted answers cannot change")
            restored.clearExam()
            XCTAssertEqual(restored.score(for: submitted), 18, "Scoring must use the supplied session")
        }
    }

    @MainActor
    func testIncompatibleExamRestorationKeepsLearningProgress() async throws {
        let suiteName = UUID().uuidString
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { suite.removePersistentDomain(forName: suiteName) }
        let bundle = Bundle(for: Self.self)
        let model = AppModel(bundle: bundle, defaults: suite)
        model.chooseLanguage(.chinese)
        let first = try XCTUnwrap(model.currentQuestion)
        model.selectLearningAnswer(first.correct, for: first)
        model.startExam(seed: 73)
        let baseline = model.state
        let baselineExam = try XCTUnwrap(baseline.exam)
        var malformed: [PersistedState] = []
        var state = baseline
        state.exam?.answers = []
        malformed.append(state)
        state = baseline
        state.exam?.items[0] = ExamItem(questionID: baselineExam.items[0].questionID, optionOrder: [0, 0, 2, 3])
        malformed.append(state)
        state = baseline
        state.exam?.answers[0] = 99
        malformed.append(state)
        state = baseline
        state.exam?.items[0] = ExamItem(questionID: "missing", optionOrder: [0, 1, 2, 3])
        malformed.append(state)
        state = baseline
        state.exam?.items[1] = baselineExam.items[0]
        malformed.append(state)
        for broken in malformed {
            suite.set(try JSONEncoder().encode(broken), forKey: "technician-radio-study-state-v1")
            let restored = AppModel(bundle: bundle, defaults: suite)
            XCTAssertNil(restored.state.exam)
            XCTAssertEqual(restored.state.records, baseline.records)
            XCTAssertEqual(restored.language, baseline.language)
        }
        state = baseline
        state.exam?.currentIndex = 99
        suite.set(try JSONEncoder().encode(state), forKey: "technician-radio-study-state-v1")
        let restored = AppModel(bundle: bundle, defaults: suite)
        XCTAssertEqual(restored.state.exam?.currentIndex, 34)
        XCTAssertEqual(restored.state.exam?.items, baselineExam.items)
        XCTAssertEqual(restored.state.exam?.answers, baselineExam.answers)
    }

    func testPoolAndEveryLanguageAreComplete() throws {
        let bundle = Bundle(for: Self.self)
        let pool = try QuestionStore.loadPool(bundle: bundle)
        XCTAssertEqual(pool.questions.count, 409)
        XCTAssertEqual(Set(pool.questions.map(\.group)).count, 35)
        XCTAssertEqual(Set(pool.questions.compactMap(\.diagramName)), Set(["t-1", "t-2", "t-3"]))
        XCTAssertEqual(pool.meta.passScore, 26)

        for language in AuxiliaryLanguage.allCases {
            let translations = try QuestionStore.loadTranslations(language, bundle: bundle)
            XCTAssertNoThrow(try QuestionStore.validate(pool: pool, translations: translations), language.name)
            if language == .english {
                XCTAssertTrue(translations.values.allSatisfy { $0.explanation.count >= 50 }, "English explanations must be substantive")
                for question in pool.questions {
                    XCTAssertEqual(translations[question.id]?.question, question.question)
                    XCTAssertEqual(translations[question.id]?.answers, question.answers)
                }
            }
        }
    }

    @MainActor
    func testMockExamHasOneQuestionPerOfficialGroupAndKeepsMappings() async throws {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        let model = AppModel(bundle: Bundle(for: Self.self), defaults: suite)
        model.chooseLanguage(.chinese)
        model.startExam(seed: 73)
        let exam = try XCTUnwrap(model.state.exam)
        XCTAssertEqual(exam.items.count, 35)
        let questions = exam.items.compactMap { item in model.pool.questions.first { $0.id == item.questionID } }
        XCTAssertEqual(Set(questions.map(\.group)).count, 35)
        XCTAssertEqual(questions.first?.group, "T1A")
        XCTAssertEqual(questions.last?.group, "T0C")
        XCTAssertTrue(exam.items.allSatisfy { $0.optionOrder == [0, 1, 2, 3] })
        XCTAssertTrue(exam.answers.allSatisfy { $0 == nil })
        model.startExam(seed: 73)
        XCTAssertEqual(model.state.exam?.items, exam.items, "A saved seed must reproduce the same exam questions")
        model.startExam(seed: 74)
        XCTAssertNotEqual(model.state.exam?.items, exam.items, "Exam questions should still vary between seeds")
    }

    @MainActor
    func testLearningScoringSubmissionAndStateRestoration() async throws {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        let model = AppModel(bundle: Bundle(for: Self.self), defaults: suite)
        model.chooseLanguage(.spanish)
        let first = try XCTUnwrap(model.currentQuestion)
        model.selectLearningAnswer(first.correct, for: first)
        XCTAssertEqual(model.state.records[first.id]?.lastCorrect, true)

        model.startExam(seed: 2026)
        for index in 0..<35 {
            model.goToExamQuestion(index)
            model.selectExamAnswer(try XCTUnwrap(model.examQuestion(at: index)).correct)
        }
        let beforeSubmit = try XCTUnwrap(model.state.exam)
        XCTAssertFalse(beforeSubmit.submitted)
        XCTAssertEqual(model.score(for: beforeSubmit), 35)
        model.submitExam()
        let submitted = try XCTUnwrap(model.state.exam)
        XCTAssertTrue(submitted.submitted)
        XCTAssertEqual(model.score(for: submitted), 35)
        XCTAssertEqual(try JSONDecoder().decode(PersistedState.self, from: JSONEncoder().encode(model.state)).exam, submitted)

        let restored = AppModel(bundle: Bundle(for: Self.self), defaults: suite)
        XCTAssertEqual(restored.language, .spanish)
        XCTAssertEqual(restored.state.records[first.id], model.state.records[first.id])
        XCTAssertEqual(restored.state.exam, submitted)
        XCTAssertEqual(restored.webProgressState.version, 2)
        XCTAssertNil(restored.webProgressState.exam, "A submitted exam projects as a v2 exam tombstone, not as an active exam")
        XCTAssertEqual(restored.webProgressState.learning.byId[first.id]?.lastSelected, first.correct)
    }

    @MainActor
    func testLanguageSwitchPreservesLearningAndActiveExamState() async throws {
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        let model = AppModel(bundle: Bundle(for: Self.self), defaults: suite)
        model.chooseLanguage(.chinese)
        let first = try XCTUnwrap(model.currentQuestion)
        model.selectLearningAnswer(first.correct, for: first)
        model.startExam(seed: 2_030)
        model.goToExamQuestion(7)
        model.selectExamAnswer(2)

        let examBefore = try XCTUnwrap(model.state.exam)
        let recordBefore = model.state.records[first.id]
        let elapsedBefore = model.elapsedSeconds(now: examBefore.startedAt.addingTimeInterval(45))

        for language in AuxiliaryLanguage.allCases {
            model.chooseLanguage(language)
            let examAfter = try XCTUnwrap(model.state.exam)
            XCTAssertEqual(examAfter, examBefore)
            XCTAssertFalse(examAfter.submitted)
            XCTAssertEqual(model.state.records[first.id], recordBefore)
            XCTAssertEqual(model.elapsedSeconds(now: examBefore.startedAt.addingTimeInterval(45)), elapsedBefore)
            XCTAssertFalse(try XCTUnwrap(model.content(for: first)).explanation.isEmpty)
        }
    }

    func testLegacyStateDecodesWithoutNewTimestamps() throws {
        let legacy = #"{"language":"zh-Hans","currentQuestionIndex":12,"records":{"T1A01":{"attempts":2,"correctEver":true,"lastCorrect":false,"selectedIndex":1}},"exam":{"seed":4294967298,"items":[{"questionID":"T1A01","optionOrder":[0,1,2,3]}],"answers":[1],"currentIndex":0,"startedAt":0,"submittedAt":null,"elapsedAtSubmit":null}}"#
        let state = try JSONDecoder().decode(PersistedState.self, from: Data(legacy.utf8))
        XCTAssertEqual(state.language, .chinese)
        XCTAssertEqual(state.currentQuestionIndex, 12)
        XCTAssertEqual(state.records["T1A01"]?.attempts, 2)
        XCTAssertEqual(state.records["T1A01"]?.updatedAt, 0)
        XCTAssertEqual(state.exam?.seed, 2)
        XCTAssertEqual(state.exam?.answers, [1])
        XCTAssertEqual(state.examUpdatedAt, state.exam?.updatedAt)
        XCTAssertEqual(state.theme, .dark)
        XCTAssertTrue(state.flashcardIDs.isEmpty)
    }
}
