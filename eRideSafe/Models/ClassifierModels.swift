import Foundation

struct ClassifierAnswers {
    var hasFunctionalPedals = true
    var hasThrottle = false
    var motorOnlyOver20MPH = false
    var wattage = 750
    var assistedSpeed: AssistedSpeed = .upTo20
    var hasSpeedometer = true
    var hasBeenModified = false
}

enum AssistedSpeed: String, CaseIterable, Identifiable {
    case upTo20 = "20 mph or less"
    case twentyTo28 = "More than 20, up to 28 mph"
    case over28 = "More than 28 mph"

    var id: String { rawValue }
}

struct ClassificationResult {
    let deviceClass: DeviceClass
    let reasons: [String]
}

enum ClassificationEngine {
    static func classify(_ answers: ClassifierAnswers) -> ClassificationResult {
        var motorcycleReasons: [String] = []

        if !answers.hasFunctionalPedals {
            motorcycleReasons.append("It does not have fully functional pedals.")
        }
        if answers.wattage > 750 {
            motorcycleReasons.append("The motor is rated above 750W.")
        }
        if answers.hasThrottle && answers.motorOnlyOver20MPH {
            motorcycleReasons.append("It can exceed 20 mph using motor power alone.")
        }
        if answers.assistedSpeed == .over28 {
            motorcycleReasons.append("Its assisted speed exceeds 28 mph.")
        }
        if answers.hasBeenModified {
            motorcycleReasons.append("It has been modified or software-unlocked to exceed its original limits.")
        }

        if !motorcycleReasons.isEmpty {
            return ClassificationResult(deviceClass: .electricMotorcycle, reasons: motorcycleReasons)
        }

        if answers.hasThrottle {
            return ClassificationResult(
                deviceClass: .class2,
                reasons: ["It has functional pedals, a throttle, motor-only speed at or below 20 mph, and a motor at or below 750W."]
            )
        }

        if answers.assistedSpeed == .twentyTo28 {
            if answers.hasSpeedometer {
                return ClassificationResult(
                    deviceClass: .class3,
                    reasons: ["It is pedal-assist only, reaches up to 28 mph, is at or below 750W, and has a speedometer."]
                )
            }
            return ClassificationResult(
                deviceClass: .electricMotorcycle,
                reasons: ["A Class 3 e-bike must be equipped with a working speedometer."]
            )
        }

        return ClassificationResult(
            deviceClass: .class1,
            reasons: ["It is pedal-assist only, reaches no more than 20 mph, and is at or below 750W."]
        )
    }
}
