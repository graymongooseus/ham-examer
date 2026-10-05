import SwiftUI
import UIKit

struct QuestionHeading: View {
    let question: Question
    let content: AuxiliaryContent
    let language: AuxiliaryLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(question.id)
                    .font(.caption.monospaced().weight(.heavy)).tracking(1)
                    .foregroundStyle(RadioTheme.amber)
                if !question.refs.isEmpty {
                    Text(question.refs).font(.caption2).foregroundStyle(RadioTheme.muted)
                        .padding(.horizontal, 8).padding(.vertical, 4).background(.white.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            Text(question.question)
                .font(.title3.weight(.bold))
                .foregroundStyle(RadioTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if language != .english {
                VStack(alignment: .leading, spacing: 6) {
                    Text("UNOFFICIAL \(language.name.uppercased()) STUDY AID")
                        .font(.caption2.weight(.heavy)).tracking(1).foregroundStyle(RadioTheme.cyan)
                    Text(content.question)
                        .font(.body)
                        .foregroundStyle(RadioTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
            QuestionShareButton(question: question, language: language)
        }
    }
}

struct QuestionShareButton: View {
    let question: Question
    let language: AuxiliaryLanguage

    var body: some View {
        ShareLink(item: question.shareText(explanationLanguage: language)) {
            Label("Share question", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel("Share question \(question.id)")
        .accessibilityHint("Share the question and choices as text to ask for an explanation")
    }
}

struct DiagramView: View {
    let name: String

    var body: some View {
        Group {
            if let image = UIImage(named: name) ?? UIImage(named: "\(name).jpg") {
                VStack(spacing: 8) {
                    Image(uiImage: image).resizable().scaledToFit()
                    Text("Official NCVEC diagram \(name.uppercased())")
                        .font(.caption).foregroundStyle(Color(red: 48/255, green: 66/255, blue: 80/255))
                }
                .padding(14)
                .background(Color(red: 245/255, green: 245/255, blue: 241/255))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

struct AnswerRow: View {
    let displayLetter: String
    let english: String
    let auxiliary: String
    let isSelected: Bool
    let result: AnswerResult?

    enum AnswerResult: Equatable { case correct, wrong }

    private var border: Color {
        if result == .correct { return RadioTheme.green }
        if result == .wrong { return RadioTheme.red }
        if isSelected { return RadioTheme.cyan }
        return RadioTheme.line
    }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Text(displayLetter)
                .font(.subheadline.monospaced().weight(.heavy))
                .foregroundStyle(result == nil ? RadioTheme.cyan : RadioTheme.onAccent)
                .frame(width: 34, height: 34)
                .background(result == .correct ? RadioTheme.green : result == .wrong ? RadioTheme.red : RadioTheme.cyan.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                Text(english).font(.headline).foregroundStyle(RadioTheme.text).fixedSize(horizontal: false, vertical: true)
                if !auxiliary.isEmpty {
                    Text(auxiliary).font(.subheadline).foregroundStyle(RadioTheme.muted).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if isSelected { Image(systemName: "checkmark.circle.fill").foregroundStyle(result == .wrong ? RadioTheme.red : RadioTheme.cyan) }
        }
        .padding(15)
        .background(border.opacity(result == nil ? 0.06 : 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border, lineWidth: result == nil && !isSelected ? 1 : 1.5))
        .contentShape(Rectangle())
    }
}

struct FeedbackPanel: View {
    let question: Question
    let content: AuxiliaryContent
    let language: AuxiliaryLanguage
    let selectedIndex: Int
    let optionOrder: [Int]

    private var isCorrect: Bool { selectedIndex == question.correct }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isCorrect ? "Correct" : "Take another look")
                .font(.headline.weight(.heavy)).foregroundStyle(isCorrect ? RadioTheme.green : RadioTheme.red)
            Text("Correct answer: \(question.displayLetter(for: question.correct, in: optionOrder) ?? "—") · \(question.answers[question.correct])")
                .font(.headline).foregroundStyle(RadioTheme.amber2)
            if language != .english {
                Text(content.answers[question.correct])
                    .font(.subheadline).foregroundStyle(RadioTheme.muted)
            }
            Divider().overlay(RadioTheme.line)
            Text("WHY").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(RadioTheme.cyan)
            Text(content.explanation).font(.body).foregroundStyle(RadioTheme.text).fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background((isCorrect ? RadioTheme.green : RadioTheme.red).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) { Rectangle().fill(isCorrect ? RadioTheme.green : RadioTheme.red).frame(width: 4).clipShape(Capsule()) }
        .accessibilityElement(children: .combine)
    }
}
