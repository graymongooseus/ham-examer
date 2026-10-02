import Foundation

struct PoolDocument: Codable {
    let meta: PoolMeta
    let questions: [Question]
}

struct PoolMeta: Codable {
    let title: String
    let revision: String
    let effective: String
    let expires: String
    let questionCount: Int
    let groupCount: Int
    let passScore: Int
    let diagramCount: Int
    let withdrawnChecked: String
    let withdrawnCount: Int
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let group: String
    let subelement: String
    let correct: Int
    let correctLetter: String
    let refs: String
    let question: String
    let answers: [String]
    let figure: String

    enum CodingKeys: String, CodingKey {
        case id, group, subelement, correct, refs, question, answers, figure
        case correctLetter = "correct_letter"
    }

    var diagramName: String? {
        guard !figure.isEmpty else { return nil }
        return URL(fileURLWithPath: figure).deletingPathExtension().lastPathComponent
    }

    /// Stored answers use original indices; letters belong to the displayed order.
    func displayLetter(for originalIndex: Int, in optionOrder: [Int]) -> String? {
        let letters = ["A", "B", "C", "D"]
        guard answers.indices.contains(originalIndex),
              let displayIndex = optionOrder.firstIndex(of: originalIndex),
              letters.indices.contains(displayIndex) else { return nil }
        return letters[displayIndex]
    }
}

struct AuxiliaryContent: Codable, Hashable {
    let question: String
    let answers: [String]
    let explanation: String
}

enum AuxiliaryLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"
    case korean = "ko"
    case vietnamese = "vi"
    case spanish = "es"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .english: "English"
        case .chinese: "Chinese"
        case .korean: "Korean"
        case .vietnamese: "Vietnamese"
        case .spanish: "Spanish"
        }
    }

    var nativeName: String {
        switch self {
        case .english: "English"
        case .chinese: "中文"
        case .korean: "한국어"
        case .vietnamese: "Tiếng Việt"
        case .spanish: "Español"
        }
    }

    var welcome: String {
        switch self {
        case .english: "Use English explanations"
        case .chinese: "选择解释语言"
        case .korean: "설명 언어 선택"
        case .vietnamese: "Chọn ngôn ngữ giải thích"
        case .spanish: "Elige el idioma de explicación"
        }
    }
}

struct StudyRecord: Codable, Equatable {
    var attempts = 0
    var correctEver = false
    var lastCorrect = false
    var selectedIndex: Int?
    var updatedAt: Int64 = 0

    private enum CodingKeys: String, CodingKey { case attempts, correctEver, lastCorrect, selectedIndex, updatedAt }

    init(attempts: Int = 0, correctEver: Bool = false, lastCorrect: Bool = false, selectedIndex: Int? = nil, updatedAt: Int64 = 0) {
        self.attempts = attempts
        self.correctEver = correctEver
        self.lastCorrect = lastCorrect
        self.selectedIndex = selectedIndex
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        attempts = try values.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        correctEver = try values.decodeIfPresent(Bool.self, forKey: .correctEver) ?? false
        lastCorrect = try values.decodeIfPresent(Bool.self, forKey: .lastCorrect) ?? false
        selectedIndex = try values.decodeIfPresent(Int.self, forKey: .selectedIndex)
        updatedAt = try values.decodeIfPresent(Int64.self, forKey: .updatedAt) ?? 0
    }
}

struct ExamItem: Codable, Equatable, Identifiable {
    let questionID: String
    let optionOrder: [Int]
    var id: String { questionID }
}

struct ExamSession: Codable, Equatable {
    let seed: UInt32
    var items: [ExamItem]
    var answers: [Int?]
    var currentIndex: Int
    let startedAt: Date
    var submittedAt: Date?
    var elapsedAtSubmit: Int?
    var updatedAt: Int64

    var submitted: Bool { submittedAt != nil }

    private enum CodingKeys: String, CodingKey { case seed, items, answers, currentIndex, startedAt, submittedAt, elapsedAtSubmit, updatedAt }

    init(seed: UInt32, items: [ExamItem], answers: [Int?], currentIndex: Int, startedAt: Date, submittedAt: Date?, elapsedAtSubmit: Int?, updatedAt: Int64) {
        self.seed = seed
        self.items = items
        self.answers = answers
        self.currentIndex = currentIndex
        self.startedAt = startedAt
        self.submittedAt = submittedAt
        self.elapsedAtSubmit = elapsedAtSubmit
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let legacySeed = try values.decode(UInt64.self, forKey: .seed)
        seed = UInt32(truncatingIfNeeded: legacySeed)
        items = try values.decode([ExamItem].self, forKey: .items)
        answers = try values.decode([Int?].self, forKey: .answers)
        currentIndex = try values.decodeIfPresent(Int.self, forKey: .currentIndex) ?? 0
        startedAt = try values.decode(Date.self, forKey: .startedAt)
        submittedAt = try values.decodeIfPresent(Date.self, forKey: .submittedAt)
        elapsedAtSubmit = try values.decodeIfPresent(Int.self, forKey: .elapsedAtSubmit)
        updatedAt = try values.decodeIfPresent(Int64.self, forKey: .updatedAt) ?? Int64(startedAt.timeIntervalSince1970 * 1_000)
    }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case light, dark

    var id: String { rawValue }
    var name: String { self == .light ? "Day · 白天" : "Night · 黑夜" }
    var symbol: String { self == .light ? "sun.max" : "moon" }
}

struct PersistedState: Codable {
    var language: AuxiliaryLanguage?
    var currentQuestionIndex = 0
    var records: [String: StudyRecord] = [:]
    var exam: ExamSession?
    var updatedAt: Int64 = 0
    var learningUpdatedAt: Int64 = 0
    var examUpdatedAt: Int64 = 0
    var theme: AppTheme = .dark
    var flashcardIDs: Set<String> = []

    private enum CodingKeys: String, CodingKey { case language, currentQuestionIndex, records, exam, updatedAt, learningUpdatedAt, examUpdatedAt, theme, flashcardIDs }

    init(language: AuxiliaryLanguage? = nil, currentQuestionIndex: Int = 0, records: [String: StudyRecord] = [:], exam: ExamSession? = nil, updatedAt: Int64 = 0, learningUpdatedAt: Int64 = 0, examUpdatedAt: Int64 = 0) {
        self.language = language
        self.currentQuestionIndex = currentQuestionIndex
        self.records = records
        self.exam = exam
        self.updatedAt = updatedAt
        self.learningUpdatedAt = learningUpdatedAt
        self.examUpdatedAt = examUpdatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        language = try values.decodeIfPresent(AuxiliaryLanguage.self, forKey: .language)
        currentQuestionIndex = try values.decodeIfPresent(Int.self, forKey: .currentQuestionIndex) ?? 0
        records = try values.decodeIfPresent([String: StudyRecord].self, forKey: .records) ?? [:]
        exam = try values.decodeIfPresent(ExamSession.self, forKey: .exam)
        updatedAt = try values.decodeIfPresent(Int64.self, forKey: .updatedAt) ?? 0
        learningUpdatedAt = try values.decodeIfPresent(Int64.self, forKey: .learningUpdatedAt) ?? updatedAt
        examUpdatedAt = try values.decodeIfPresent(Int64.self, forKey: .examUpdatedAt) ?? exam?.updatedAt ?? 0
        theme = try values.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .dark
        flashcardIDs = try values.decodeIfPresent(Set<String>.self, forKey: .flashcardIDs) ?? []
    }
}

/// Bit-for-bit port of the website's mulberry32 generator.
struct Mulberry32 {
    private var state: UInt32

    init(seed: UInt32) {
        state = seed
    }

    mutating func nextUnit() -> Double {
        state &+= 0x6D2B79F5
        var value = state
        value = (value ^ (value >> 15)) &* (value | 1)
        value ^= value &+ ((value ^ (value >> 7)) &* (value | 61))
        return Double(value ^ (value >> 14)) / 4_294_967_296
    }

    mutating func index(upperBound: Int) -> Int {
        Int(nextUnit() * Double(upperBound))
    }

    mutating func shuffled(_ values: [Int]) -> [Int] {
        var result = values
        guard result.count > 1 else { return result }
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            result.swapAt(index, self.index(upperBound: index + 1))
        }
        return result
    }
}

// Exact JSON shape accepted by the companion website's verified v2 progress API.
struct WebProgressState: Codable, Equatable {
    let version: Int
    let updatedAt: Int64
    let examUpdatedAt: Int64
    let learning: WebLearningState
    let exam: WebExamState?
}

struct WebLearningState: Codable, Equatable {
    let current: Int
    let byId: [String: WebLearningRecord]
    let updatedAt: Int64
}

struct WebLearningRecord: Codable, Equatable {
    let attempts: Int
    let correctEver: Bool
    let lastCorrect: Bool
    let lastSelected: Int?
    let updatedAt: Int64
}

struct WebExamState: Codable, Equatable {
    let seed: UInt32
    let answers: [Int?]
    let current: Int
    let startTime: Int64
    let updatedAt: Int64
}
