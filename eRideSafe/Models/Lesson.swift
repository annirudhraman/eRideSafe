import Foundation

struct Lesson: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let systemImage: String
    let estimatedMinutes: Int
    let learningGoals: [String]
    let sections: [LessonSection]
    let keyTakeaway: String
}

struct LessonSection: Identifiable {
    let id = UUID()
    let heading: String
    let systemImage: String
    let body: String
    let keyPoints: [String]
}

enum CourseContent {
    static var lessonIDs: Set<Int> {
        Set(lessons.map(\.id))
    }

    static func completedLessonCount(in completedIDs: Set<Int>) -> Int {
        completedIDs.intersection(lessonIDs).count
    }

    static func hasCompletedEveryLesson(in completedIDs: Set<Int>) -> Bool {
        lessonIDs.isSubset(of: completedIDs)
    }

    static let lessons: [Lesson] = [
        Lesson(
            id: 1,
            title: "Know Your Ride",
            subtitle: "Classes, labels, and legal e-bike limits",
            systemImage: "questionmark.circle.fill",
            estimatedMinutes: 5,
            learningGoals: [
                "Find the class, motor rating, and assisted-speed label.",
                "Tell a legal e-bike from an electric motorcycle.",
                "Recognize modifications that can change a bike's classification."
            ],
            sections: [
                .init(
                    heading: "Start with the label",
                    systemImage: "tag.fill",
                    body: "A compliant e-bike should have a permanent label showing its class, top assisted speed, and motor wattage. Read that label before borrowing, buying, or riding a bike in public.",
                    keyPoints: [
                        "Class 1: pedal assist stops at 20 mph.",
                        "Class 2: throttle or motor-only assistance stops at 20 mph.",
                        "Class 3: pedal assist stops at 28 mph and the bike has a speedometer."
                    ]
                ),
                .init(
                    heading: "Know the e-bike boundaries",
                    systemImage: "gauge.with.dots.needle.67percent",
                    body: "Under Washington's e-bike definitions, an electric-assisted bicycle has fully operative pedals and a motor rated at no more than 750 watts. Each class also has a specific assisted-speed limit.",
                    keyPoints: [
                        "More than 750W does not fit the state's e-bike definition.",
                        "Throttle assistance above 20 mph is not Class 2.",
                        "Pedal assistance above 28 mph is not Class 3."
                    ]
                ),
                .init(
                    heading: "Modifications matter",
                    systemImage: "wrench.and.screwdriver.fill",
                    body: "A speed unlock, replacement controller, high-power motor, or removed pedals can move a device outside e-bike limits even if the original sticker still says Class 1, 2, or 3.",
                    keyPoints: [
                        "Classify the bike as it operates now, not only as it left the store.",
                        "Do not change limiters or safety equipment you do not understand.",
                        "Use eRideSafe's classifier when the label and current setup disagree."
                    ]
                ),
                .init(
                    heading: "Why classification matters",
                    systemImage: "building.columns.fill",
                    body: "Where you may ride, whether a license or registration is required, and which safety rules apply can change when a device is legally a motorcycle rather than an e-bike.",
                    keyPoints: [
                        "A bicycle-style frame does not guarantee bicycle status.",
                        "Check posted signs because local access rules may be more restrictive.",
                        "When uncertain, stay off public trails and verify before riding."
                    ]
                )
            ],
            keyTakeaway: "Read the label, check the actual equipment and speed capability, and never assume a bicycle-looking device is legally an e-bike."
        ),
        Lesson(
            id: 2,
            title: "Rules of the Road",
            subtitle: "Signals, signs, lane position, and yielding",
            systemImage: "signpost.right.fill",
            estimatedMinutes: 6,
            learningGoals: [
                "Ride predictably and follow traffic controls.",
                "Communicate turns and lane changes early.",
                "Share paths without surprising people walking or riding."
            ],
            sections: [
                .init(
                    heading: "Ride with traffic",
                    systemImage: "arrow.up",
                    body: "On the road, travel in the same direction as other vehicles and obey lights, signs, and lane markings. Predictability gives drivers more time to see and respond to you.",
                    keyPoints: [
                        "Stop at red lights and stop signs.",
                        "Avoid weaving between the road, sidewalk, and parked cars.",
                        "Hold a steady line instead of making sudden side-to-side moves."
                    ]
                ),
                .init(
                    heading: "Signal before you move",
                    systemImage: "hand.raised.fill",
                    body: "Look behind you, signal, and check again before turning or changing lane position. A signal communicates your plan; it does not guarantee that a driver has seen you or will yield.",
                    keyPoints: [
                        "Signal early enough for others to react.",
                        "Keep control of the bike while signaling.",
                        "Make the move only after confirming the space is clear."
                    ]
                ),
                .init(
                    heading: "Be visible and predictable",
                    systemImage: "eye.fill",
                    body: "Ride where you can be seen. At driveways and intersections, avoid approaching so fast or from such an unexpected position that a turning driver has little time to notice you.",
                    keyPoints: [
                        "Use lights in darkness, rain, fog, and other low visibility.",
                        "Do not linger beside a large vehicle where the driver may not see you.",
                        "Treat eye contact as a clue, not proof that it is safe to go."
                    ]
                ),
                .init(
                    heading: "Yield on shared paths",
                    systemImage: "figure.walk",
                    body: "People walking can change direction without warning. Reduce speed before reaching them, give an audible warning, and pass only when there is enough room.",
                    keyPoints: [
                        "Pass at a slow, controlled speed.",
                        "Use your voice or bell before passing, not as you pass.",
                        "Give children, pets, and groups extra space."
                    ]
                )
            ],
            keyTakeaway: "The safest rider is easy to see and easy to understand: follow the rules, signal early, and make smooth, predictable moves."
        ),
        Lesson(
            id: 3,
            title: "Speed = Danger",
            subtitle: "Reaction time, grip, impact, and stopping distance",
            systemImage: "speedometer",
            estimatedMinutes: 5,
            learningGoals: [
                "Understand why a small speed increase can greatly raise risk.",
                "Choose a speed that preserves time and traction.",
                "Brake smoothly before hazards and turns."
            ],
            sections: [
                .init(
                    heading: "Impact energy rises quickly",
                    systemImage: "bolt.trianglebadge.exclamationmark.fill",
                    body: "Kinetic energy increases with the square of speed. If speed doubles, impact energy is roughly four times as great, before accounting for other crash factors.",
                    keyPoints: [
                        "A few extra miles per hour can make injuries more severe.",
                        "Higher e-bike weight can add to impact energy.",
                        "Slow down before the situation becomes urgent."
                    ]
                ),
                .init(
                    heading: "Reaction takes distance",
                    systemImage: "brain.head.profile",
                    body: "You continue moving while noticing a hazard, deciding what to do, and reaching the brakes. At higher speed, the bike covers more ground during every part of that reaction.",
                    keyPoints: [
                        "Scan far ahead instead of staring just in front of the wheel.",
                        "Cover the brake levers near driveways and intersections.",
                        "Leave more following distance as speed or uncertainty increases."
                    ]
                ),
                .init(
                    heading: "Traction is limited",
                    systemImage: "drop.triangle.fill",
                    body: "Wet leaves, paint, metal covers, gravel, and ice can sharply reduce tire grip. Braking or turning hard on a slippery surface can use more grip than the tires have.",
                    keyPoints: [
                        "Brake earlier and more gently when grip is uncertain.",
                        "Keep the bike as upright as possible across slick surfaces.",
                        "Avoid abrupt acceleration, braking, or steering."
                    ]
                ),
                .init(
                    heading: "Build a safety margin",
                    systemImage: "ruler.fill",
                    body: "A safe speed is one that lets you stop within the distance you can clearly see. Blind corners, hills, parked cars, crowds, and poor weather all shrink that visible space.",
                    keyPoints: [
                        "Enter turns at a speed you already know you can manage.",
                        "Increase space when descending because speed builds quickly.",
                        "Posted limits are maximums, not targets for every condition."
                    ]
                )
            ],
            keyTakeaway: "Speed spends your safety margin. Slow early enough to keep time, space, and traction available for the unexpected."
        ),
        Lesson(
            id: 4,
            title: "Gear Up",
            subtitle: "Helmet fit, visibility, brakes, tires, and batteries",
            systemImage: "shield.checkered",
            estimatedMinutes: 6,
            learningGoals: [
                "Fit a helmet so it can protect you correctly.",
                "Complete a fast pre-ride mechanical check.",
                "Charge, store, and inspect the battery safely."
            ],
            sections: [
                .init(
                    heading: "Fit the helmet",
                    systemImage: "person.crop.circle.badge.checkmark",
                    body: "Wear a properly sized bicycle helmet level and low on your forehead. The side straps should form a V below each ear, and the chin strap should be snug.",
                    keyPoints: [
                        "The helmet should not rock far forward, backward, or sideways.",
                        "Fasten it on every ride, including short trips.",
                        "Replace a helmet after a significant impact or when the manufacturer says it has expired."
                    ]
                ),
                .init(
                    heading: "Be seen",
                    systemImage: "lightbulb.max.fill",
                    body: "Use a white front light and a red rear light or reflector at night and whenever visibility is poor. Bright or reflective clothing helps drivers detect you sooner.",
                    keyPoints: [
                        "Aim lights to help you see without blinding others.",
                        "Check that bags and clothing do not block the lights.",
                        "Carry enough battery power for the whole trip."
                    ]
                ),
                .init(
                    heading: "Run an ABC check",
                    systemImage: "checklist",
                    body: "Before moving, check Air, Brakes, and Chain or cranks, then inspect the quick releases or axles and take a short test ride in a safe area.",
                    keyPoints: [
                        "Air: tires feel firm and have no visible damage.",
                        "Brakes: both levers work and do not pull to the handlebar.",
                        "Controls: bars, wheels, battery, and cargo are secure."
                    ]
                ),
                .init(
                    heading: "Respect the battery",
                    systemImage: "battery.75percent",
                    body: "Use the charger intended for the battery, inspect the pack and cable for damage, and charge where heat can escape. A damaged, unusually hot, swollen, or smoking battery needs immediate attention.",
                    keyPoints: [
                        "Do not use a damaged charger or battery.",
                        "Keep charging equipment away from exits and flammable clutter.",
                        "If a battery smokes or catches fire, move away and call emergency services."
                    ]
                )
            ],
            keyTakeaway: "A fitted helmet and a two-minute equipment check cannot prevent every crash, but they can prevent a small problem from becoming a serious one."
        ),
        Lesson(
            id: 5,
            title: "Sammamish Smart Riding",
            subtitle: "Local trails, school zones, and posted limits",
            systemImage: "map.fill",
            estimatedMinutes: 5,
            learningGoals: [
                "Know the basic access rules for local paved and soft-surface trails.",
                "Adjust speed and attention in school zones.",
                "Use signs and current official guidance as the final authority."
            ],
            sections: [
                .init(
                    heading: "Paved paths and the ELST",
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill",
                    body: "Class 1 and 2 e-bikes may use Sammamish paved trails unless posted otherwise. The East Lake Sammamish Trail has a 15 mph speed limit; Class 3 e-bikes are not allowed on shared-use paths unless specifically authorized.",
                    keyPoints: [
                        "Slow below the limit whenever people, pets, or sight distance require it.",
                        "Keep right except when passing.",
                        "Temporary closures and signs override the app."
                    ]
                ),
                .init(
                    heading: "Soft surfaces and boardwalks",
                    systemImage: "leaf.fill",
                    body: "Sammamish prohibits bicycles of any kind and electric or small motorized devices on maintained soft-surface trails, sensitive areas, and boardwalks unless an exception is posted.",
                    keyPoints: [
                        "Do not ride around a gate or prohibition sign.",
                        "Use the paved route or dismount and follow posted instructions.",
                        "Restrictions protect trail users and sensitive ground."
                    ]
                ),
                .init(
                    heading: "Class 3 and sidewalks",
                    systemImage: "figure.walk.motion",
                    body: "Washington generally prohibits Class 3 e-bikes on sidewalks unless there is no alternative for the sidewalk segment as part of a bicycle or pedestrian path, or a local rule specifically allows it.",
                    keyPoints: [
                        "Class 3 riders must be at least 16 years old.",
                        "Class 3 access differs from Class 1 and 2 access.",
                        "When a connection is unclear, slow down, dismount, and check the sign or official guidance."
                    ]
                ),
                .init(
                    heading: "School-zone awareness",
                    systemImage: "school.fill",
                    body: "Expect students to enter from sidewalks, buses, driveways, and between parked cars. Reduce speed before the school zone and keep your phone stored or secured.",
                    keyPoints: [
                        "Watch crossing guards and obey their directions.",
                        "Do not pass a stopped school bus when its red lights are flashing and stop paddle is extended.",
                        "Choose control and visibility over saving a few seconds."
                    ]
                )
            ],
            keyTakeaway: "Local access can change by facility and by class. Follow posted signs, ride below 15 mph on the ELST, and give school zones your full attention."
        ),
        Lesson(
            id: 6,
            title: "Defensive Riding",
            subtitle: "See cars early, prevent conflicts, and keep an escape route",
            systemImage: "car.side.rear.and.collision.and.car.side.front",
            estimatedMinutes: 8,
            learningGoals: [
                "Spot the car movements most likely to cross your path.",
                "Position yourself to be visible and outside common danger zones.",
                "Create time and an escape route before a conflict develops."
            ],
            sections: [
                .init(
                    heading: "Scan, predict, prepare",
                    systemImage: "eye.trianglebadge.exclamationmark.fill",
                    body: "Defensive riding means noticing a possible conflict early enough to avoid it. Scan far ahead, near your path, and behind you; then ask what each driver, pedestrian, or rider might do next.",
                    keyPoints: [
                        "Watch front wheels, turn signals, brake lights, and gaps in traffic.",
                        "Cover the brakes when a vehicle could cross your path.",
                        "Keep space beside you so you have somewhere safe to move."
                    ]
                ),
                .init(
                    heading: "Own a visible position",
                    systemImage: "road.lanes",
                    body: "Do not trade visibility for a few inches of space. Ride far enough from the curb to avoid debris and far enough from parked cars to avoid an opening door. Move into a clear, visible lane position when a narrow lane makes an unsafe pass likely.",
                    keyPoints: [
                        "Stay outside the door zone of parked vehicles.",
                        "Do not squeeze between a moving vehicle and the curb.",
                        "Avoid riding beside trucks and buses, especially near turns."
                    ]
                ),
                .init(
                    heading: "Defend intersections and driveways",
                    systemImage: "arrow.triangle.branch",
                    body: "Many conflicts happen when a driver turns across a rider's path or enters from a side street. Reduce speed, look for a response from the driver, and be ready to stop even when you have the right of way.",
                    keyPoints: [
                        "A car waiting to turn may not have seen you.",
                        "Watch for a vehicle that passes and then slows for a right turn.",
                        "At a red light, wait where turning drivers can see you rather than beside a large vehicle."
                    ]
                ),
                .init(
                    heading: "Use time, space, and an escape route",
                    systemImage: "shield.lefthalf.filled",
                    body: "Following distance gives you time to brake smoothly and reveals hazards hidden by the vehicle ahead. An escape route is an open, safer space you could use if stopping alone will not prevent a crash.",
                    keyPoints: [
                        "Leave more distance downhill, at night, and in wet weather.",
                        "Do not follow a vehicle so closely that it blocks your view.",
                        "If a driver acts unpredictably, slow down and let the conflict move away from you."
                    ]
                ),
                .init(
                    heading: "When a car threatens your path",
                    systemImage: "exclamationmark.octagon.fill",
                    body: "Your first goal is to reduce impact risk, not prove who has the right of way. Brake firmly and progressively while keeping the bike controlled, steer toward a clear escape only if it is safer, and use your voice or bell when it may help someone notice you.",
                    keyPoints: [
                        "Look toward the clear path you want to take, not at the obstacle.",
                        "Avoid an abrupt swerve into another lane without checking it.",
                        "After a near miss, stop somewhere safe before reporting or using your phone."
                    ]
                )
            ],
            keyTakeaway: "Assume others can make mistakes. See conflicts early, stay visible, protect your space, and always keep enough time and room to choose a safe response."
        )
    ]
}
