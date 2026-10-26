import SwiftUI

enum DeviceClass: String, CaseIterable, Identifiable, Codable, Equatable {
    case class1
    case class2
    case class3
    case electricMotorcycle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .class1: "Class 1"
        case .class2: "Class 2"
        case .class3: "Class 3"
        case .electricMotorcycle: "Electric Motorcycle"
        }
    }

    var shortTitle: String {
        switch self {
        case .class1: "Class 1"
        case .class2: "Class 2"
        case .class3: "Class 3"
        case .electricMotorcycle: "E-Motorcycle"
        }
    }

    var systemImage: String {
        switch self {
        case .class1: "bicycle"
        case .class2: "bolt.fill"
        case .class3: "gauge.with.dots.needle.67percent"
        case .electricMotorcycle: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .class1: Color.green
        case .class2: Color.blue
        case .class3: Color.orange
        case .electricMotorcycle: Color.red
        }
    }

    var summary: String {
        switch self {
        case .class1:
            "Pedal-assist only, fully functional pedals, up to 20 mph, and no more than 750W."
        case .class2:
            "Throttle-capable, fully functional pedals, up to 20 mph on motor power, and no more than 750W."
        case .class3:
            "Pedal-assist only, up to 28 mph, no more than 750W, and equipped with a speedometer."
        case .electricMotorcycle:
            "The device exceeds one or more e-bike limits, such as wattage, throttle speed, assisted speed, pedals, or modification status."
        }
    }

    var requirements: [String] {
        switch self {
        case .class1:
            ["No statewide age minimum", "Helmet recommended", "Yield to pedestrians on shared paths"]
        case .class2:
            ["No statewide age minimum", "Helmet recommended", "Motor-only speed must stay at or below 20 mph"]
        case .class3:
            ["Rider must be 16 or older", "Banned from Sammamish sidewalks and shared-use trails", "Speedometer required"]
        case .electricMotorcycle:
            ["Driver license with motorcycle endorsement", "Registration and insurance", "Not permitted on trails or sidewalks"]
        }
    }
}
