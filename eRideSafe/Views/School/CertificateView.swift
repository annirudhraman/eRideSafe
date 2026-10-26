import SwiftUI

struct CertificateView: View {
    let date: Date

    private var shareText: String {
        "eRideSafe Certified — completed the e-bike safety course and earned 100% on the assessment on \(date.formatted(date: .long, time: .omitted))."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 12) {
                    Image(systemName: "rosette")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.erideGreen)
                    Text("eRideSafe Certified")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Completed all \(CourseContent.lessons.count) lessons and passed the \(QuizContent.questions.count)-question safety assessment with 100%.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.headline)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.erideMint)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.erideGreen, lineWidth: 2)
                        )
                )

                ShareLink(item: shareText) {
                    Label("Share certification", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .background(Color.erideBackground)
        .navigationTitle("Certification")
        .navigationBarTitleDisplayMode(.inline)
    }
}
