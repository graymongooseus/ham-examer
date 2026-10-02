import Foundation

enum DataLoadError: LocalizedError {
    case missingResource(String)
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name): "Missing bundled resource: \(name)"
        case .invalidData(let message): message
        }
    }
}

enum QuestionStore {
    static func loadPool(bundle: Bundle = .main) throws -> PoolDocument {
        guard let url = bundle.url(forResource: "questions", withExtension: "json") else {
            throw DataLoadError.missingResource("questions.json")
        }
        return try JSONDecoder().decode(PoolDocument.self, from: Data(contentsOf: url))
    }

    static func loadTranslations(_ language: AuxiliaryLanguage, bundle: Bundle = .main) throws -> [String: AuxiliaryContent] {
        guard let url = bundle.url(forResource: language.rawValue, withExtension: "json", subdirectory: "Translations")
            ?? bundle.url(forResource: language.rawValue, withExtension: "json") else {
            throw DataLoadError.missingResource("\(language.rawValue).json")
        }
        return try JSONDecoder().decode([String: AuxiliaryContent].self, from: Data(contentsOf: url))
    }

    static func validate(pool: PoolDocument, translations: [String: AuxiliaryContent]) throws {
        guard pool.questions.count == pool.meta.questionCount, pool.questions.count == 409 else {
            throw DataLoadError.invalidData("Expected 409 official questions, found \(pool.questions.count).")
        }
        guard Set(pool.questions.map(\.id)).count == pool.questions.count else {
            throw DataLoadError.invalidData("Question IDs are not unique.")
        }
        guard Set(pool.questions.map(\.group)).count == pool.meta.groupCount, pool.meta.groupCount == 35 else {
            throw DataLoadError.invalidData("Expected 35 official question groups.")
        }
        for question in pool.questions {
            guard question.answers.count == 4, (0..<4).contains(question.correct) else {
                throw DataLoadError.invalidData("Invalid answer mapping for \(question.id).")
            }
            guard let content = translations[question.id],
                  !content.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !content.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  content.answers.count == 4,
                  content.answers.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                throw DataLoadError.invalidData("Incomplete auxiliary content for \(question.id).")
            }
        }
        guard translations.count == pool.questions.count else {
            throw DataLoadError.invalidData("Auxiliary language contains unexpected or missing IDs.")
        }
    }
}
