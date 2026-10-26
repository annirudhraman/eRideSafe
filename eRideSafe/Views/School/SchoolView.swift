import SwiftUI

struct SchoolView: View {
    @EnvironmentObject private var appState: AppState

    private var completedLessonCount: Int {
        CourseContent.completedLessonCount(in: appState.completedLessonIDs)
    }

    private var hasCompletedEveryLesson: Bool {
        CourseContent.hasCompletedEveryLesson(in: appState.completedLessonIDs)
    }

    private var estimatedCourseMinutes: Int {
        CourseContent.lessons.reduce(0) { $0 + $1.estimatedMinutes }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Course progress")
                            .font(.headline)
                        Spacer()
                        Text("\(completedLessonCount)/\(CourseContent.lessons.count)")
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(Color.erideGreen)
                    }
                    ProgressView(
                        value: Double(completedLessonCount),
                        total: Double(CourseContent.lessons.count)
                    )
                        .tint(Color.erideGreen)

                    HStack(spacing: 14) {
                        Label("~\(estimatedCourseMinutes) min", systemImage: "clock")
                        Label("\(QuizContent.questions.count) questions", systemImage: "checklist")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)

                    Text("Complete all \(CourseContent.lessons.count) lessons, then earn 100% on the assessment to unlock the certification badge.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Lessons") {
                ForEach(CourseContent.lessons) { lesson in
                    NavigationLink {
                        LessonDetailView(lesson: lesson)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: lesson.systemImage)
                                .frame(width: 32)
                                .font(.title3)
                                .foregroundStyle(appState.completedLessonIDs.contains(lesson.id) ? Color.erideGreen : Color.blue)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(lesson.id). \(lesson.title)")
                                    .font(.headline)
                                Text(lesson.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                Label("\(lesson.estimatedMinutes) min", systemImage: "clock")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.erideTeal)
                            }
                            Spacer()
                            if appState.completedLessonIDs.contains(lesson.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.erideGreen)
                            }
                        }
                    }
                }
            }

            Section("Assessment") {
                NavigationLink {
                    QuizView()
                } label: {
                    Label(
                        "Take the \(QuizContent.questions.count)-question certification quiz",
                        systemImage: "checkmark.seal.fill"
                    )
                }
                .disabled(!hasCompletedEveryLesson)

                if !hasCompletedEveryLesson {
                    Text("Complete every lesson to unlock the quiz. You have \(CourseContent.lessons.count - completedLessonCount) remaining.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                if let date = appState.certificateDate, hasCompletedEveryLesson {
                    NavigationLink {
                        CertificateView(date: date)
                    } label: {
                        Label("View eRideSafe certification", systemImage: "rosette")
                            .foregroundStyle(Color.erideGreen)
                    }
                }
            }
        }
        .navigationTitle("eRide School")
    }
}
