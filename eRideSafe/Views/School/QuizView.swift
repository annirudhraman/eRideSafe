import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentIndex = 0
    @State private var selections: [Int: Int] = [:]
    @State private var showResult = false

    private var question: QuizQuestion {
        QuizContent.questions[currentIndex]
    }

    private var isLastQuestion: Bool {
        currentIndex == QuizContent.questions.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            quizProgress

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    questionCard
                    answerChoices
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .id(question.id)

            quizNavigation
        }
        .background(Color.erideBackground)
        .navigationTitle("Certification Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResult) {
            QuizResultView(
                score: score,
                total: QuizContent.questions.count,
                selections: selections
            ) {
                appState.certificateDate = Date()
            } retryAction: {
                currentIndex = 0
                selections = [:]
                showResult = false
            }
            .presentationDetents([.large])
        }
    }

    private var quizProgress: some View {
        VStack(spacing: 9) {
            HStack {
                Text("Question \(currentIndex + 1) of \(QuizContent.questions.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.secondary)

                Spacer()

                Text("\(Int((Double(currentIndex + 1) / Double(QuizContent.questions.count)) * 100))%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.erideGreen)
            }

            ProgressView(
                value: Double(currentIndex + 1),
                total: Double(QuizContent.questions.count)
            )
            .tint(Color.erideGreen)
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
        .background(Color.erideSurface)
    }

    private var questionCard: some View {
        ERideCard(tint: question.isScenario ? Color.erideGold : Color.erideBlue) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(
                        question.isScenario ? "RIDING SCENARIO" : "KNOWLEDGE CHECK",
                        systemImage: question.isScenario ? "road.lanes" : "brain.head.profile"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(question.isScenario ? Color.erideGold : Color.erideBlue)

                    Spacer()

                    Text(question.category)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                }

                if let scenario = question.scenario {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: "location.fill.viewfinder")
                            .foregroundStyle(Color.erideGold)
                            .padding(.top, 2)

                        Text(scenario)
                            .font(.body.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.erideGold.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text(question.prompt)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var answerChoices: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose one answer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 4)

            ForEach(question.answers.indices, id: \.self) { index in
                answerButton(at: index)
            }
        }
    }

    private func answerButton(at index: Int) -> some View {
        let isSelected = selections[question.id] == index

        return Button {
            selections[question.id] = index
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.erideGreen : Color.secondary)

                Text(question.answers[index])
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.erideMint : Color.erideSurface)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.erideGreen : Color.secondary.opacity(0.16), lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Answer \(index + 1): \(question.answers[index])")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var quizNavigation: some View {
        HStack(spacing: 12) {
            if currentIndex > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentIndex -= 1
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                        .frame(minHeight: 48)
                }
                .buttonStyle(.bordered)
            }

            Button {
                if isLastQuestion {
                    showResult = true
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentIndex += 1
                    }
                }
            } label: {
                Label(
                    isLastQuestion ? "Submit quiz" : "Next question",
                    systemImage: isLastQuestion ? "checkmark.seal.fill" : "chevron.right"
                )
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selections[question.id] == nil)
        }
        .padding()
        .background(Color.erideSurface)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var score: Int {
        QuizContent.questions.reduce(0) { partial, question in
            partial + (selections[question.id] == question.correctIndex ? 1 : 0)
        }
    }
}

private struct QuizResultView: View {
    @Environment(\.dismiss) private var dismiss
    let score: Int
    let total: Int
    let selections: [Int: Int]
    let certificationAction: () -> Void
    let retryAction: () -> Void

    private var passed: Bool {
        score == total
    }

    private var missedQuestions: [QuizQuestion] {
        QuizContent.questions.filter { question in
            selections[question.id] != question.correctIndex
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resultHeader

                if !passed {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review your answers")
                            .font(.title2.bold())

                        Text("These explanations show what to revisit before your next attempt.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)

                        ForEach(missedQuestions) { question in
                            missedQuestionCard(question)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(passed ? "Done" : "Retake quiz") {
                    if passed {
                        dismiss()
                    } else {
                        retryAction()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
            .padding(.bottom, 18)
        }
        .background(Color.erideBackground)
        .onAppear {
            if passed {
                certificationAction()
            }
        }
    }

    private var resultHeader: some View {
        VStack(spacing: 13) {
            Image(systemName: passed ? "checkmark.seal.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 62))
                .foregroundStyle(passed ? Color.erideGreen : Color.orange)

            Text(passed ? "Certified" : "Keep learning")
                .font(.largeTitle.bold())

            Text("\(score) / \(total)")
                .font(.title.bold().monospacedDigit())

            Text(
                passed
                    ? "You earned 100% and unlocked the eRideSafe Certified badge."
                    : "Certification requires 100%. Review the missed scenarios, then try again."
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func missedQuestionCard(_ question: QuizQuestion) -> some View {
        ERideCard(tint: Color.erideCoral) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(
                        question.isScenario ? "Scenario" : "Knowledge",
                        systemImage: question.isScenario ? "road.lanes" : "brain.head.profile"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.erideCoral)

                    Spacer()

                    Text(question.category)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                Text(question.prompt)
                    .font(.headline)

                if let selectedIndex = selections[question.id],
                   question.answers.indices.contains(selectedIndex) {
                    answerReviewRow(
                        title: "Your answer",
                        answer: question.answers[selectedIndex],
                        systemImage: "xmark.circle.fill",
                        color: .erideCoral
                    )
                }

                answerReviewRow(
                    title: "Correct answer",
                    answer: question.answers[question.correctIndex],
                    systemImage: "checkmark.circle.fill",
                    color: .erideGreen
                )

                Text(question.explanation)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 2)
            }
        }
    }

    private func answerReviewRow(
        title: String,
        answer: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                Text(answer)
                    .font(.subheadline)
            }
        }
    }
}
