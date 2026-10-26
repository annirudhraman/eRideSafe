import SwiftUI

struct LessonDetailView: View {
    @EnvironmentObject private var appState: AppState
    let lesson: Lesson

    private var isComplete: Bool {
        appState.completedLessonIDs.contains(lesson.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                lessonHeader
                learningGoals

                Text("Lesson content")
                    .font(.title2.bold())
                    .padding(.top, 4)

                ForEach(Array(lesson.sections.enumerated()), id: \.element.id) { index, section in
                    lessonSection(section, number: index + 1)
                }

                ERideCard(tint: Color.erideGold) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Remember this", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundStyle(Color.erideGold)

                        Text(lesson.keyTakeaway)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary)
                    }
                }

                Button {
                    appState.markLessonComplete(lesson.id)
                } label: {
                    Label(
                        isComplete ? "Lesson completed" : "Mark lesson complete",
                        systemImage: isComplete ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isComplete)

                if !isComplete {
                    Text("Complete the lesson after you have read each section and can explain the key takeaway.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .padding(.bottom, 12)
        }
        .background(Color.erideBackground)
        .navigationTitle("Lesson \(lesson.id)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var lessonHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: lesson.systemImage)
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(Color.erideGreen)
                    .frame(width: 62, height: 62)
                    .background(Color.erideMint)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.erideGreen.opacity(0.18), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 7) {
                    Text("eRide School")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.erideGreen)

                    HStack(spacing: 12) {
                        Label("Lesson \(lesson.id)", systemImage: "book.closed.fill")
                        Label("\(lesson.estimatedMinutes) min", systemImage: "clock.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                }

                Spacer(minLength: 8)

                if isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(Color.erideGreen)
                        .accessibilityLabel("Lesson completed")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(lesson.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(lesson.subtitle)
                    .font(.title3)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Capsule()
                .fill(Color.erideGreen)
                .frame(width: 54, height: 4)
        }
        .padding(.horizontal, 3)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private var learningGoals: some View {
        ERideCard(tint: Color.erideBlue) {
            VStack(alignment: .leading, spacing: 12) {
                Label("What you'll learn", systemImage: "scope")
                    .font(.headline)
                    .foregroundStyle(Color.erideBlue)

                ForEach(lesson.learningGoals, id: \.self) { goal in
                    bulletRow(goal, systemImage: "target", color: .erideBlue)
                }
            }
        }
    }

    private func lessonSection(_ section: LessonSection, number: Int) -> some View {
        ERideCard(tint: Color.erideTeal) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    TintedIcon(systemImage: section.systemImage, color: .erideTeal)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("SECTION \(number)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.erideTeal)
                            .tracking(0.8)

                        Text(section.heading)
                            .font(.title3.bold())
                    }
                }

                Text(section.body)
                    .font(.body)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(section.keyPoints, id: \.self) { point in
                        bulletRow(point, systemImage: "checkmark.circle.fill", color: .erideGreen)
                    }
                }
            }
        }
    }

    private func bulletRow(_ text: String, systemImage: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 18)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
