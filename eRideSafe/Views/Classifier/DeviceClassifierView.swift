import SwiftUI

struct OnboardingClassifierView: View {
    @EnvironmentObject private var appState: AppState
    @State private var result: ClassificationResult?

    var body: some View {
        ZStack {
            LinearGradient.erideOnboarding
                .ignoresSafeArea()

            Circle()
                .fill(Color.erideGreen.opacity(0.16))
                .frame(width: 290, height: 290)
                .blur(radius: 3)
                .offset(x: 175, y: -320)

            ScrollView {
                VStack(spacing: 22) {
                    onboardingHeader

                    ClassifierQuizFlow {
                        result = $0
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 24)
            }
        }
        .sheet(item: $result) { result in
            OnboardingResultView(result: result) {
                appState.saveDeviceClass(result.deviceClass)
            }
            .interactiveDismissDisabled()
        }
    }

    private var onboardingHeader: some View {
        VStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 76, height: 76)

                Image(systemName: "bicycle")
                    .font(.system(size: 38, weight: .bold))
            }

            Text("eRideSafe")
                .font(.system(size: 48, weight: .black, design: .rounded))

            Text("Identify your ride")
                .font(.title3.weight(.semibold))

            Text("Answer one question at a time. Your result is saved privately on this device and used to personalize the map, rules, and Ride Mode.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.72))
                .padding(.horizontal, 12)
        }
        .foregroundStyle(Color.white)
    }
}

struct DeviceClassifierView: View {
    @EnvironmentObject private var appState: AppState
    @State private var result: ClassificationResult?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ERideCard(tint: Color.erideBlue) {
                    HStack(spacing: 13) {
                        TintedIcon(systemImage: "questionmark.diamond.fill", color: Color.erideBlue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Classify your device")
                                .font(.headline)
                            Text("Answer each question using the manufacturer's label whenever possible. Your new result will replace the class saved on this device.")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }

                ClassifierQuizFlow {
                    let classification = $0
                    appState.saveDeviceClass(classification.deviceClass)
                    result = classification
                }
            }
            .padding()
        }
        .background(Color.erideBackground)
        .navigationTitle("Device Class Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $result) { result in
            ClassificationResultView(result: result)
                .presentationDetents([.medium, .large])
        }
    }
}

private enum ClassifierQuizStep: String, Hashable {
    case pedals
    case throttle
    case motorOnlySpeed
    case wattage
    case assistedSpeed
    case speedometer
    case modified

    var title: String {
        switch self {
        case .pedals:
            return "Does your ride have fully functional pedals?"
        case .throttle:
            return "Can the motor power the ride without pedaling?"
        case .motorOnlySpeed:
            return "Can motor power alone take it over 20 mph?"
        case .wattage:
            return "What is the motor's rated wattage?"
        case .assistedSpeed:
            return "What is the maximum assisted speed?"
        case .speedometer:
            return "Does it have a working speedometer?"
        case .modified:
            return "Has the ride been modified or software-unlocked?"
        }
    }

    var explanation: String {
        switch self {
        case .pedals:
            return "Foot pegs do not count. The pedals must be installed and capable of moving the bike."
        case .throttle:
            return "A throttle lets the motor propel the ride even when you are not pedaling."
        case .motorOnlySpeed:
            return "Answer based on throttle-only speed, without any pedaling."
        case .wattage:
            return "Look for W or watts on the permanent manufacturer label near the frame, motor, or battery."
        case .assistedSpeed:
            return "Choose the highest speed at which the motor continues providing assistance while you pedal."
        case .speedometer:
            return "A Class 3 e-bike must be equipped with a working speedometer."
        case .modified:
            return "Examples include a software speed unlock, aftermarket controller, or settings that allow the ride to exceed its original limits."
        }
    }

    var systemImage: String {
        switch self {
        case .pedals:
            return "bicycle"
        case .throttle:
            return "hand.tap.fill"
        case .motorOnlySpeed:
            return "gauge.with.dots.needle.67percent"
        case .wattage:
            return "bolt.fill"
        case .assistedSpeed:
            return "speedometer"
        case .speedometer:
            return "gauge.open.with.lines.needle.33percent"
        case .modified:
            return "wrench.and.screwdriver.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .pedals:
            return Color.erideGreen
        case .throttle:
            return Color.erideBlue
        case .motorOnlySpeed:
            return Color.erideCoral
        case .wattage:
            return Color.erideGold
        case .assistedSpeed:
            return Color.erideTeal
        case .speedometer:
            return Color.erideGold
        case .modified:
            return Color.erideCoral
        }
    }
}

private struct ClassifierQuizFlow: View {
    let onComplete: (ClassificationResult) -> Void

    @State private var answers = ClassifierAnswers()
    @State private var answeredSteps: Set<ClassifierQuizStep> = []
    @State private var currentIndex = 0

    private var steps: [ClassifierQuizStep] {
        var quizSteps: [ClassifierQuizStep] = [.pedals, .throttle]

        if answeredSteps.contains(.throttle), answers.hasThrottle {
            quizSteps.append(.motorOnlySpeed)
        }

        quizSteps.append(.wattage)
        quizSteps.append(.assistedSpeed)

        if answeredSteps.contains(.assistedSpeed),
           !answers.hasThrottle,
           answers.assistedSpeed == .twentyTo28 {
            quizSteps.append(.speedometer)
        }

        quizSteps.append(.modified)
        return quizSteps
    }

    private var safeIndex: Int {
        min(currentIndex, max(steps.count - 1, 0))
    }

    private var currentStep: ClassifierQuizStep {
        steps[safeIndex]
    }

    private var currentStepIsAnswered: Bool {
        answeredSteps.contains(currentStep)
    }

    private var isLastQuestion: Bool {
        safeIndex == steps.count - 1
    }

    var body: some View {
        VStack(spacing: 18) {
            progressHeader

            VStack(alignment: .leading, spacing: 20) {
                questionHeader

                answerControls
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                navigationButtons

                Text("Posted signs and official government guidance always take priority over information shown in the app.")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(currentStep.accentColor.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.13), radius: 20, y: 10)
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 9) {
            HStack {
                Text("QUESTION \(safeIndex + 1) OF \(steps.count)")
                    .font(.caption.weight(.heavy))
                    .tracking(1.1)
                    .foregroundStyle(currentStep.accentColor)

                Spacer()

                Text("\(Int((Double(safeIndex + 1) / Double(steps.count)) * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.secondary)
            }

            ProgressView(value: Double(safeIndex + 1), total: Double(steps.count))
                .tint(currentStep.accentColor)
                .scaleEffect(x: 1, y: 1.45, anchor: .center)
        }
        .padding(.horizontal, 4)
    }

    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(currentStep.accentColor.opacity(0.12))
                    .frame(width: 58, height: 58)

                Image(systemName: currentStep.systemImage)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(currentStep.accentColor)
            }

            Text(currentStep.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            Text(currentStep.explanation)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var answerControls: some View {
        switch currentStep {
        case .pedals:
            yesNoChoices(
                yesTitle: "Yes, it has working pedals",
                yesSubtitle: "The pedals can move the bike",
                noTitle: "No, it does not",
                noSubtitle: "It has foot pegs, decorative pedals, or no pedals",
                selectedValue: answeredSteps.contains(.pedals) ? answers.hasFunctionalPedals : nil
            ) { value in
                answers.hasFunctionalPedals = value
                answeredSteps.insert(.pedals)
            }

        case .throttle:
            yesNoChoices(
                yesTitle: "Yes, it has a throttle",
                yesSubtitle: "The motor can propel it without pedaling",
                noTitle: "No, pedal-assist only",
                noSubtitle: "The motor works only while I pedal",
                selectedValue: answeredSteps.contains(.throttle) ? answers.hasThrottle : nil
            ) { value in
                answers.hasThrottle = value
                if !value {
                    answers.motorOnlyOver20MPH = false
                    answeredSteps.remove(.motorOnlySpeed)
                }
                answeredSteps.insert(.throttle)
            }

        case .motorOnlySpeed:
            yesNoChoices(
                yesTitle: "Yes, over 20 mph",
                yesSubtitle: "Using the motor alone",
                noTitle: "No, 20 mph or less",
                noSubtitle: "Using the motor alone",
                selectedValue: answeredSteps.contains(.motorOnlySpeed) ? answers.motorOnlyOver20MPH : nil
            ) { value in
                answers.motorOnlyOver20MPH = value
                answeredSteps.insert(.motorOnlySpeed)
            }

        case .wattage:
            VStack(spacing: 11) {
                ForEach(WattageOption.options) { option in
                    ClassifierChoiceButton(
                        title: option.title,
                        subtitle: option.subtitle,
                        systemImage: option.systemImage,
                        tint: currentStep.accentColor,
                        isSelected: answeredSteps.contains(.wattage) && answers.wattage == option.value
                    ) {
                        answers.wattage = option.value
                        answeredSteps.insert(.wattage)
                    }
                }
            }

        case .assistedSpeed:
            VStack(spacing: 11) {
                ClassifierChoiceButton(
                    title: "20 mph or less",
                    subtitle: "Motor assistance stops by 20 mph",
                    systemImage: "20.circle.fill",
                    tint: currentStep.accentColor,
                    isSelected: answeredSteps.contains(.assistedSpeed) && answers.assistedSpeed == .upTo20
                ) {
                    answers.assistedSpeed = .upTo20
                    answers.hasSpeedometer = true
                    answeredSteps.remove(.speedometer)
                    answeredSteps.insert(.assistedSpeed)
                }

                ClassifierChoiceButton(
                    title: "More than 20, up to 28 mph",
                    subtitle: "Motor assistance continues above 20 mph",
                    systemImage: "28.circle.fill",
                    tint: currentStep.accentColor,
                    isSelected: answeredSteps.contains(.assistedSpeed) && answers.assistedSpeed == .twentyTo28
                ) {
                    answers.assistedSpeed = .twentyTo28
                    answeredSteps.insert(.assistedSpeed)
                }

                ClassifierChoiceButton(
                    title: "More than 28 mph",
                    subtitle: "Motor assistance continues beyond 28 mph",
                    systemImage: "exclamationmark.triangle.fill",
                    tint: currentStep.accentColor,
                    isSelected: answeredSteps.contains(.assistedSpeed) && answers.assistedSpeed == .over28
                ) {
                    answers.assistedSpeed = .over28
                    answers.hasSpeedometer = true
                    answeredSteps.remove(.speedometer)
                    answeredSteps.insert(.assistedSpeed)
                }
            }

        case .speedometer:
            yesNoChoices(
                yesTitle: "Yes, it has a speedometer",
                yesSubtitle: "It displays my current speed",
                noTitle: "No speedometer",
                noSubtitle: "There is no working speed display",
                selectedValue: answeredSteps.contains(.speedometer) ? answers.hasSpeedometer : nil
            ) { value in
                answers.hasSpeedometer = value
                answeredSteps.insert(.speedometer)
            }

        case .modified:
            yesNoChoices(
                yesTitle: "Yes, it has been modified",
                yesSubtitle: "Software unlock, controller change, or another performance modification",
                noTitle: "No, it is factory-standard",
                noSubtitle: "No speed or power modifications",
                selectedValue: answeredSteps.contains(.modified) ? answers.hasBeenModified : nil
            ) { value in
                answers.hasBeenModified = value
                answeredSteps.insert(.modified)
            }
        }
    }

    private func yesNoChoices(
        yesTitle: String,
        yesSubtitle: String,
        noTitle: String,
        noSubtitle: String,
        selectedValue: Bool?,
        selection: @escaping (Bool) -> Void
    ) -> some View {
        VStack(spacing: 11) {
            ClassifierChoiceButton(
                title: yesTitle,
                subtitle: yesSubtitle,
                systemImage: "checkmark.circle.fill",
                tint: currentStep.accentColor,
                isSelected: selectedValue == true
            ) {
                selection(true)
            }

            ClassifierChoiceButton(
                title: noTitle,
                subtitle: noSubtitle,
                systemImage: "xmark.circle.fill",
                tint: currentStep.accentColor,
                isSelected: selectedValue == false
            ) {
                selection(false)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if safeIndex > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        currentIndex = max(0, safeIndex - 1)
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.erideSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button {
                advance()
            } label: {
                HStack {
                    Text(isLastQuestion ? "See my result" : "Continue")
                    Image(systemName: isLastQuestion ? "checkmark.shield.fill" : "chevron.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!currentStepIsAnswered)
            .opacity(currentStepIsAnswered ? 1 : 0.42)
        }
        .padding(.top, 2)
    }

    private func advance() {
        guard currentStepIsAnswered else { return }

        if isLastQuestion {
            onComplete(ClassificationEngine.classify(answers))
            return
        }

        withAnimation(.easeInOut(duration: 0.24)) {
            currentIndex = min(safeIndex + 1, steps.count - 1)
        }
    }
}

private struct WattageOption: Identifiable {
    let value: Int
    let title: String
    let subtitle: String
    let systemImage: String

    var id: Int { value }

    static let options: [WattageOption] = [
        WattageOption(value: 250, title: "250W", subtitle: "Common lower-power motor", systemImage: "bolt.circle"),
        WattageOption(value: 500, title: "500W", subtitle: "At or below the e-bike limit", systemImage: "bolt.circle.fill"),
        WattageOption(value: 750, title: "750W", subtitle: "Maximum motor rating for these e-bike classes", systemImage: "bolt.shield.fill"),
        WattageOption(value: 1_000, title: "More than 750W", subtitle: "Examples include 1,000W, 1,500W, or higher", systemImage: "exclamationmark.triangle.fill")
    ]
}

private struct ClassifierChoiceButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : tint)
                    .frame(width: 43, height: 43)
                    .background(isSelected ? tint : tint.opacity(0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? tint : Color.secondary.opacity(0.45))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? tint.opacity(0.10) : Color.erideSurface.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(isSelected ? tint : Color.secondary.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension ClassificationResult: Identifiable {
    var id: String { deviceClass.rawValue + reasons.joined() }
}

private struct OnboardingResultView: View {
    let result: ClassificationResult
    let saveAction: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: result.deviceClass.systemImage)
                        .font(.system(size: 68, weight: .bold))
                        .foregroundStyle(result.deviceClass.color)
                        .frame(width: 116, height: 116)
                        .background(result.deviceClass.color.opacity(0.12))
                        .clipShape(Circle())
                        .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text("Your ride is classified as")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        Text(result.deviceClass.title)
                            .font(.largeTitle.bold())
                    }

                    Text(result.deviceClass.summary)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)

                    ERideCard(tint: result.deviceClass.color) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What this means")
                                .font(.headline)
                            ForEach(result.deviceClass.requirements, id: \.self) { requirement in
                                Label(requirement, systemImage: "checkmark.shield.fill")
                                    .font(.subheadline)
                            }
                        }
                    }

                    Button("Save class and enter eRideSafe") {
                        saveAction()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
            .background(Color.erideBackground)
        }
    }
}

private struct ClassificationResultView: View {
    @Environment(\.dismiss) private var dismiss
    let result: ClassificationResult

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: result.deviceClass.systemImage)
                        .font(.system(size: 58))
                        .foregroundStyle(result.deviceClass.color)
                        .padding(.top, 14)

                    Text(result.deviceClass.title)
                        .font(.largeTitle.bold())

                    Text("Saved to this device")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.erideGreen)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color.erideGreen.opacity(0.12))
                        .clipShape(Capsule())

                    Text(result.deviceClass.summary)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)

                    ERideCard(tint: result.deviceClass.color) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Why")
                                .font(.headline)
                            ForEach(result.reasons, id: \.self) { reason in
                                Label(reason, systemImage: "checkmark.circle")
                                    .font(.subheadline)
                            }
                        }
                    }

                    ERideCard(tint: result.deviceClass.color) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What this means")
                                .font(.headline)
                            ForEach(result.deviceClass.requirements, id: \.self) { requirement in
                                Label(requirement, systemImage: "circle.fill")
                                    .font(.subheadline)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                    }

                    if result.deviceClass == .electricMotorcycle {
                        Text("Warning: before operating an electric motorcycle on public roads, follow all applicable licensing, motorcycle endorsement, registration, insurance, and equipment requirements.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.red)
                            .padding()
                            .background(Color.red.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .background(Color.erideBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
