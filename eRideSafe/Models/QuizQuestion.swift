import Foundation

struct QuizQuestion: Identifiable {
    let id: Int
    let category: String
    let scenario: String?
    let prompt: String
    let answers: [String]
    let correctIndex: Int
    let explanation: String

    var isScenario: Bool {
        scenario != nil
    }
}

enum QuizContent {
    static let questions: [QuizQuestion] = [
        .init(
            id: 1,
            category: "Know Your Ride",
            scenario: nil,
            prompt: "Which motor rating exceeds the Washington e-bike limit used by eRideSafe?",
            answers: ["500W", "750W", "1,000W", "250W"],
            correctIndex: 2,
            explanation: "An electric-assisted bicycle motor must be rated at no more than 750W."
        ),
        .init(
            id: 2,
            category: "Know Your Ride",
            scenario: "A friend offers you a bicycle-style device with no working pedals and a 1,500W motor. They say it is an e-bike because it has a bicycle seat.",
            prompt: "What is the safest conclusion before riding it in public?",
            answers: [
                "It is Class 1 because it looks like a bicycle",
                "It is Class 2 because it has a motor",
                "It falls outside e-bike limits and should be treated as an electric motorcycle",
                "It is legal on trails if you stay below 15 mph"
            ],
            correctIndex: 2,
            explanation: "A legal e-bike needs fully operative pedals and a motor of no more than 750W. Appearance and voluntary speed do not change the device's classification."
        ),
        .init(
            id: 3,
            category: "Know Your Ride",
            scenario: nil,
            prompt: "What is the minimum age to operate a Class 3 e-bike in Washington?",
            answers: ["No minimum", "14", "16", "18"],
            correctIndex: 2,
            explanation: "A person must be at least 16 to operate a Class 3 e-bike in Washington."
        ),
        .init(
            id: 4,
            category: "Sammamish Smart Riding",
            scenario: "You are riding a Class 1 e-bike on the East Lake Sammamish Trail. The path ahead is clear and your display reads 18 mph.",
            prompt: "What should you do?",
            answers: [
                "Continue because Class 1 assistance stops at 20 mph",
                "Slow to 15 mph or below and stay ready to reduce speed for other users",
                "Move to the gravel shoulder to keep your speed",
                "Speed limits apply only to cars"
            ],
            correctIndex: 1,
            explanation: "The East Lake Sammamish Trail speed limit is 15 mph. Conditions may require an even slower speed."
        ),
        .init(
            id: 5,
            category: "Rules of the Road",
            scenario: "You approach a family walking across most of a shared path. A child and dog are moving unpredictably.",
            prompt: "What is the safest way to pass?",
            answers: [
                "Accelerate so you spend less time beside them",
                "Ring your bell continuously and pass immediately",
                "Slow down, warn them early, and wait until there is enough clear space",
                "Leave the path and pass on the grass"
            ],
            correctIndex: 2,
            explanation: "Children and pets can change direction suddenly. Slow first, communicate, and pass only when you have safe clearance."
        ),
        .init(
            id: 6,
            category: "Speed = Danger",
            scenario: nil,
            prompt: "If your speed doubles, impact energy becomes approximately:",
            answers: ["The same", "Two times as great", "Three times as great", "Four times as great"],
            correctIndex: 3,
            explanation: "Kinetic energy rises with the square of speed, so doubling speed produces roughly four times the impact energy."
        ),
        .init(
            id: 7,
            category: "Gear Up",
            scenario: "Rain starts near dusk and visibility drops while you are preparing to ride home.",
            prompt: "Which response gives you the best safety margin?",
            answers: [
                "Use a phone flashlight and ride at your normal speed",
                "Use a white front light and red rear light or reflector, then slow for the conditions",
                "Wear dark clothing so reflections do not distract drivers",
                "Turn off the lights to save battery for the motor"
            ],
            correctIndex: 1,
            explanation: "Proper front and rear visibility equipment helps others see you, and lower speed gives you more stopping distance on wet surfaces."
        ),
        .init(
            id: 8,
            category: "Sammamish Smart Riding",
            scenario: nil,
            prompt: "Class 3 e-bikes are always allowed on Washington sidewalks.",
            answers: ["True", "False"],
            correctIndex: 1,
            explanation: "Class 3 sidewalk riding is generally prohibited. A limited exception may apply when there is no alternative for a sidewalk segment that is part of a bicycle or pedestrian path, or when a local rule allows it."
        ),
        .init(
            id: 9,
            category: "Defensive Riding",
            scenario: "You are riding beside a row of parked cars. One car is occupied and you cannot tell whether its door will open.",
            prompt: "Where should you position yourself?",
            answers: [
                "Close to the doors so moving traffic has more room",
                "Outside the door zone, in a visible and predictable line",
                "On the sidewalk at full speed",
                "Between the parked cars whenever traffic approaches"
            ],
            correctIndex: 1,
            explanation: "An opening door can leave no reaction time. Stay outside the door zone and hold a predictable line where drivers can see you."
        ),
        .init(
            id: 10,
            category: "Defensive Riding",
            scenario: "A car passes you just before an intersection, slows, and turns on its right signal while you are still approaching on its right.",
            prompt: "What is the safest response?",
            answers: [
                "Accelerate past the car on its right before it turns",
                "Brake, create space, and fall behind the turning car",
                "Move closer so the driver can hear your motor",
                "Ignore the signal because you have the right of way"
            ],
            correctIndex: 1,
            explanation: "This is a possible right-hook conflict. Do not race the car into the intersection; slow down and let the turning vehicle clear your path."
        ),
        .init(
            id: 11,
            category: "Defensive Riding",
            scenario: "A driver is waiting at a side street and appears to look toward you, but the car's front wheels begin to move.",
            prompt: "What should you do?",
            answers: [
                "Assume eye contact means the driver will stop",
                "Speed up to clear the driveway first",
                "Cover the brakes, reduce speed, and prepare to stop until the driver's action is clear",
                "Swerve into the next lane without checking"
            ],
            correctIndex: 2,
            explanation: "Eye contact is not a guarantee. Vehicle movement is a stronger warning, so preserve time and prepare for the driver to enter your path."
        ),
        .init(
            id: 12,
            category: "Defensive Riding",
            scenario: "You reach a red light beside a truck that is signaling right. You cannot see the driver's mirrors clearly.",
            prompt: "Where is the safest place to wait?",
            answers: [
                "Alongside the truck's right rear wheels",
                "Directly in the truck's blind spot",
                "Behind the truck, where you are visible and outside its turning path",
                "On the crosswalk in front of pedestrians"
            ],
            correctIndex: 2,
            explanation: "Large vehicles can turn across space beside them, and their rear wheels track inward. Stay out of the blind spot and turning path."
        ),
        .init(
            id: 13,
            category: "Speed = Danger",
            scenario: "You are descending toward a wet curve with painted lane markings across it.",
            prompt: "How should you manage speed and traction?",
            answers: [
                "Brake hard while leaned over on the paint",
                "Accelerate through the curve to increase grip",
                "Brake early while upright, enter slowly, and make smooth steering inputs",
                "Turn sharply so you spend less time on the wet surface"
            ],
            correctIndex: 2,
            explanation: "Wet paint may have little grip. Reduce speed before the turn and avoid abrupt braking or steering while the bike is leaned."
        ),
        .init(
            id: 14,
            category: "Defensive Riding",
            scenario: "You are following an SUV downhill. Riding close blocks your view of the road and leaves little room to stop.",
            prompt: "What should you change?",
            answers: [
                "Follow closer so no car can enter the gap",
                "Increase following distance so you can see hazards and keep an escape route",
                "Ride beside the SUV in the same lane",
                "Watch only the SUV's rear bumper"
            ],
            correctIndex: 1,
            explanation: "More following distance improves sight distance, reaction time, and braking space—especially downhill, where speed builds quickly."
        ),
        .init(
            id: 15,
            category: "Defensive Riding",
            scenario: "After a close pass, you want to report the driver and check your camera footage.",
            prompt: "When should you use your phone?",
            answers: [
                "Immediately while riding so you do not forget details",
                "Only after stopping completely in a safe place away from traffic",
                "While coasting with one hand",
                "At the next intersection while the light is red"
            ],
            correctIndex: 1,
            explanation: "Do not let a near miss create another hazard. Stop in a safe location before using your phone or making a report."
        )
    ]
}
