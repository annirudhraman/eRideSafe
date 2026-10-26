# Learn Swift and SwiftUI through eRideSafe

This guide explains your actual app, starting with the basics. You do not need to understand every word of Swift before understanding how the app works. First learn what each piece is responsible for. Then follow what happens when someone presses a button.

The code links below open your project files. The separate [technical walkthrough][technical] contains deeper implementation details when you want them.

## 1. The whole app in one picture

Your app lets someone identify their bike, look at a map, complete safety lessons, submit reports, and watch their speed during a ride.

To do that, it needs three kinds of code:

| Kind | Simple meaning | Example in your app |
|---|---|---|
| View | Describes what appears on the screen and what buttons do | The map screen or a quiz question |
| Model | Describes the information the app understands | A bike class, a lesson, or a safety report |
| Service | Talks to something outside the screen | The phone's location system or Firebase |

It also needs **state**: the information that can change while the app is being used.

```text
Someone presses a button
           ↓
The app changes a value
           ↓
SwiftUI updates the screen to match that value
```

That last step is the central idea of SwiftUI. You describe what the screen should look like for the current information. SwiftUI handles updating the display when observed information changes.

**Swift** is the programming language. **SwiftUI** is a collection of tools written for building interfaces with Swift. **Xcode** is the program used to edit, build, and run your app. They are related, but they do different jobs.

## 2. How to read a small SwiftUI view

Here is a teaching example. It is not an extra feature added to your app:

```swift
import SwiftUI

struct HelmetCheckView: View {
    @State private var helmetOn = false

    var body: some View {
        VStack {
            Text(helmetOn ? "Helmet ready!" : "Put on your helmet")

            Button("My helmet is on") {
                helmetOn = true
            }
        }
    }
}
```

Read it one piece at a time:

| Code | What it means |
|---|---|
| `import SwiftUI` | Make SwiftUI's screen-building tools available in this file. |
| `struct HelmetCheckView` | Define a new type named `HelmetCheckView`. A struct groups related information and behavior. |
| `: View` | This type follows SwiftUI's rules for describing a view. |
| `@State` | Ask SwiftUI to remember this changing value for this view's identity and observe changes to it. |
| `private` | Keep this property as an implementation detail of this type. |
| `var helmetOn = false` | Create a changeable Boolean value, initially false. |
| `var body: some View` | Describe the interface. The result is a particular combination of views whose full type Swift can infer. |
| `VStack` | Place its child views vertically. |
| `Text(...)` | Display text. |
| `condition ? first : second` | Choose the first value when the condition is true; otherwise choose the second. |
| `Button("...") { ... }` | Display a button and run the code in its action when pressed. |
| `helmetOn = true` | Change the stored value. SwiftUI can then update the text. |

The braces `{ ... }` group code. Sometimes the group defines a type or function; sometimes it is a closure: a block of work supplied to another piece of code.

### Shapes, spacing, and colors

You will often see code like:

```swift
Text("eRideSafe")
    .font(.largeTitle)
    .foregroundStyle(Color.green)
    .padding()
```

The lines beginning with dots are **modifiers**. They describe how a view should look or behave. Here they choose a font, choose a color, and add space around the text. They are why your screen files are long even when the underlying behavior is simple.

`HStack` places views side by side. `ZStack` puts views on top of one another. `ScrollView` lets content scroll. `List` displays rows. `NavigationLink` opens another screen. A `.sheet` presents a screen over the current one.

## 3. Where your app begins

Open [eRideSafeApp.swift][app]. Its most important declaration is:

```swift
@main
@MainActor
struct eRideSafeApp: App {
```

`@main` identifies the app's starting point. `App` is the SwiftUI role for something that describes the app's scenes. `@MainActor` coordinates this code with the main actor, where UI-related work is managed.

The app creates three shared objects:

```swift
@StateObject private var appState = AppState()
@StateObject private var locationManager = LocationManager()
@StateObject private var firebaseBackend = FirebaseBackend()
```

Think of these as three helpers:

- `appState` remembers the rider's choices and progress.
- `locationManager` asks the phone for location and speed information.
- `firebaseBackend` communicates with the online database.

`@StateObject` means SwiftUI owns the object's storage for this container's identity. It prevents ordinary rebuilding of the interface from creating a new helper every time.

The app then makes this decision:

```swift
if appState.hasCompletedBikeSetup {
    RootTabView()
} else {
    OnboardingClassifierView()
}
```

If setup is finished, show the main tabs. Otherwise, show the bike questionnaire. The first launch starts with setup unfinished.

The `.environmentObject(...)` lines make the helpers available to screens below this point. A child view asks for one using `@EnvironmentObject`, instead of creating another copy.

The file also contains `FirebaseAppDelegate`. It checks for the Firebase configuration file and configures Firebase when that resource exists. Later, `.task` begins the backend's asynchronous startup.

## 4. What state means in your app

Open [AppState.swift][state]. This is your app's shared collection of remembered values.

```swift
@Published var selectedDeviceClass: DeviceClass {
    didSet {
        UserDefaults.standard.set(
            selectedDeviceClass.rawValue,
            forKey: Keys.deviceClass
        )
    }
}
```

This actual property does two jobs:

1. `@Published` tells observers when the selected bike class changes, so screens using it can update.
2. `didSet` runs after assignment and writes the choice to `UserDefaults`, a storage system on the device.

Those are separate jobs. Updating a screen does not automatically mean saving information for the next launch.

`DeviceClass` is an **enum**: a type with a fixed set of named choices. Your choices are `.class1`, `.class2`, `.class3`, and `.electricMotorcycle`. `rawValue` gives the string used to store a choice. The initializer reads that string back when the app starts.

The app's main save method is small:

```swift
func saveDeviceClass(_ deviceClass: DeviceClass) {
    selectedDeviceClass = deviceClass
    deviceClassSavedAt = Date()
    hasCompletedBikeSetup = true
}
```

`func` defines a function: a named piece of work. This one receives a bike class, stores it, records the current time, and marks setup complete. The underscore means callers can write `saveDeviceClass(.class1)` without writing a parameter label.

After it runs, the app's `if` condition changes. SwiftUI can replace onboarding with the main tabs. No code needs to manually paint the entire new screen.

### Which values are remembered?

`AppState` saves the setup flag, bike class, class-save date, completed lesson IDs, certificate date, alert preferences, and reports. Completed lessons use a `Set<Int>`, which is a collection of unique integers. Completing lesson 1 twice still leaves one entry for lesson 1.

Reports are an array of `SafetyReport` values. They are converted to JSON data for local storage. `upsertReport` means “update the report if its ID already exists; otherwise insert it.” The array is then sorted newest first.

### The property wrappers you will see

| Wrapper | Meaning in this app |
|---|---|
| `@State` | This screen remembers a small changing value, such as the current quiz question. |
| `@StateObject` | This container owns a helper object that SwiftUI observes. |
| `@EnvironmentObject` | This screen uses a shared object provided by an ancestor. |
| `@Published` | An observable object announces changes to this property. |
| `@Environment(\.dismiss)` | Get SwiftUI's action for closing this presented screen. |

You also see `$`, as in `Toggle(isOn: $helmet)`. This makes a **binding**: a connection allowing a control to read and change the original value. Without that connection, the toggle would not know where to write its new value.

## 5. All 26 Swift files, explained by job

These tables cover every application Swift file. You can learn them in groups rather than reading the directory alphabetically.

### Starting and organizing the app

| File | What each main part does |
|---|---|
| [eRideSafeApp.swift][app] | Creates the shared helpers, starts Firebase, chooses onboarding versus main tabs, and asks the backend to save profile changes. Its app delegate configures Firebase. |
| [AppState.swift][state] | Stores shared rider data and writes it locally. Its methods save a class, restart setup, complete lessons, and add/update/remove/merge reports. Its alert enums define preference choices. |
| [RootTabView.swift][root] | Creates the five tabs. `AppNavigationRoot` gives each tab navigation and a Settings button. `SettingsView` displays profile/progress/sync information and lets setup restart. |

### Describing the information

| File | What each main part does |
|---|---|
| [DeviceClass.swift][device] | Defines the four device categories and their names, icons, colors, summaries, and requirement text. |
| [ClassifierModels.swift][classifier-model] | Defines questionnaire answers and results. `ClassificationEngine.classify` checks answers in a fixed order and returns a category plus reasons. |
| [RideZone.swift][zone] | Defines road/path types, permission results, and mapped zones. It contains access rules, distances to line segments, two shared paths, road-zone creation, and nearest-zone selection. |
| [SafetyMapData.swift][map-data] | Stores roads, trails, and school locations. Decoders turn compressed coordinate strings into points. Proximity helpers find nearby schools/trails/roads. Most of this large file is repeated data records. |
| [Lesson.swift][lessons] | Defines a lesson and section, stores six lessons, and calculates which current lessons are complete. |
| [QuizQuestion.swift][questions] | Defines the information in one assessment question and stores 15 questions, choices, correct answers, and explanations. |
| [SafetyReport.swift][report-model] | Defines report categories and a report containing ID, notes, location, time, optional photo, and optional owner information. |

### Talking to the phone and the internet

| File | What each main part does |
|---|---|
| [LocationManager.swift][location] | Requests location permission, starts/stops updates, handles location callbacks, rejects unsuitable speed measurements, smooths speed, and converts it to mph. |
| [RideMotionManager.swift][motion] | Reads phone motion, calculates movement strength, and labels it steady/normal/rough/sudden. It counts sudden-motion events with a cooldown. |
| [RideAlertService.swift][alerts] | Plays vibration patterns and builds short sound tones. The event selects a vibration pattern; preferences select whether to vibrate, play sound, or both. |
| [FirebaseBackend.swift][backend] | Creates/reuses an anonymous account, writes a profile, uploads old local reports, listens for reports, uploads/fetches photos, deletes owned reports, and exposes connection status. |

### Drawing screens

| File | What each main part does |
|---|---|
| [HomeView.swift][home] | Shows the saved class, lesson progress, map preview, and a safety notice. Its cards link to School and Map screens. |
| [DeviceClassifierView.swift][classifier-view] | Contains the onboarding screen, the retake screen, the changing sequence of questions, answer buttons, and result screens. It gathers answers; the model's engine decides the result. |
| [SafetyMapView.swift][map-view] | Draws map layers, class choices, schools, roads, paths, and report pins. It handles taps, local place search, camera movement, a status footer, and detail sheets. |
| [RideModeView.swift][ride] | Shows the pre-ride checklist and live dashboard. It starts/stops sensors, compares speed with a mapped limit, keeps top speed, triggers alerts, and shares a location link. |
| [SchoolView.swift][school] | Lists lessons and progress. It unlocks the assessment after every current lesson is complete and links to the earned certificate. |
| [LessonDetailView.swift][lesson-detail] | Displays one lesson's goals, sections, and takeaway. Its completion button saves the lesson's ID. |
| [QuizView.swift][quiz] | Shows assessment questions, remembers selected answers, moves backward/forward, computes the score, shows missed-answer explanations, and awards completion after 100%. |
| [CertificateView.swift][certificate] | Draws the earned badge/date and shares a text message about completion. |
| [ReportsView.swift][reports] | Shows reports in a list or map, connection status, CSV-style text export, and a button to open the report form. Private helper views draw rows and map circles. |
| [NewReportView.swift][new-report] | Gathers category, notes, location, and an optional photo. It compresses the photo, saves the report locally if Firebase is absent, or submits it online when configured. |
| [ReportDetailView.swift][report-detail] | Displays a report, map position, and photo. It fetches a photo when needed and lets the owner delete the report. |
| [DesignSystem.swift][design] | Provides shared colors, gradients, cards, icons, status labels, and button styling. These are reusable appearance pieces. |

## 6. Follow the features from beginning to end

### Identifying a bike

The screen asks questions such as whether the bike has pedals, a throttle, and a motor over the app's wattage threshold. The answers are kept in `ClassifierAnswers` while the questionnaire is open.

Some questions depend on earlier answers. For example, a bike without a throttle does not need a throttle-only speed question.

`ClassificationEngine.classify` checks the answers like a checklist. First it collects reasons the answers fall outside the app's e-bike categories. If it finds any, it returns the electric-motorcycle result. Otherwise it checks throttle, then higher pedal-assist speed and speedometer, then the Class 1 default. This is ordinary `if` logic; there is no AI deciding the result.

During first setup, the user saves the result on the result screen. During a later retake, the new result is saved immediately when the questionnaire finishes. Only the selected class and its date are remembered; the app does not save the individual questionnaire answers.

### Showing the map

MapKit supplies the Apple map. Your code draws extra lines and symbols on top.

A road is stored as a list of latitude/longitude points. Connecting neighboring points creates its line. Your app bundles 2,562 road pieces, two shared paths, 93 restricted-trail pieces, and 17 school markers.

The app checks the selected bike class against a facility's type to choose an access message and color. The same path can therefore change color when the selected class changes.

To guess which facility is close to the phone, the code measures the shortest distance from the location to the mapped line. It requires a reasonably accurate GPS location and refuses to choose when a nearby road and parallel path are too hard to distinguish.

Road/path information is stored inside the app. Community report pins come from its report list. Apple's optional traffic layer comes from MapKit and does not change your app's access rules.

One detail to remember: pressing a class button on the map changes the shared saved bike class. Other screens then use that new choice too.

### Measuring a ride

The rider checks five preparation items and presses Start Ride Mode. The view asks `LocationManager` and `RideMotionManager` to start.

The location system gives speed in meters per second. Your code checks whether the measurement is usable, blends it with the previous measurement to reduce jumping numbers, and multiplies it by about 2.237 to get miles per hour.

For example, when blending uses 45% of a new 12 m/s sample and 55% of a previous 10 m/s value:

```text
new displayed estimate = 0.45 × 12 + 0.55 × 10
                       = 10.9 meters per second
                       ≈ 24.4 miles per hour
```

Motion is a different measurement. It describes how strongly the phone accelerates. Your app checks movement 25 times per second and can alert for sudden motion. It does not use those movements to calculate steady riding speed.

The view compares the filtered speed with a mapped limit. The two explicitly modeled shared paths have 15 mph stored; roads have no stored limit. For a 15 mph limit, the display is approaching at 12.75 through 15 mph and over above 15 mph. The overspeed alert happens when crossing into the over state, rather than repeating continuously.

Ending the ride explicitly stops both sensor services. Sharing a ride location creates an Apple Maps link containing the current point; it does not send a continuously updating journey.

### Finishing School

The lesson text is already bundled in `Lesson.swift`. Opening a lesson displays that information. Pressing Mark Complete inserts its ID into the saved set. There is no timer checking how long someone read it.

After all six lessons are marked complete, School enables the 15-question assessment. Quiz selections are stored as pairs: question ID → selected answer number. Grading compares each selected answer with the question's stored correct answer.

All 15 must be correct. A passing result saves the current date in `certificateDate`. The certificate screen uses that date to draw the badge. A failed result shows the missed questions and their explanations.

### Sending a report

The user opens `NewReportView`, chooses a category, writes notes, and optionally picks a photo. The form uses the phone's location; it currently requires a coordinate before Submit is enabled.

The code compresses the photo, creates a report with a unique ID, and asks `FirebaseBackend` to send it. Firebase is an online service. Firestore is its document database: a place to save records made of named fields.

The backend uses three collections:

```text
users        -> rider profile information
reports      -> report notes, location, owner, time, and photo flag
reportPhotos -> the photo bytes for a report
```

The photo and report use the same report ID so they can be connected. The photo is written first, then the report record. When the app receives an updated report list from Firebase, it replaces the cloud part of its local list and SwiftUI updates the report screens.

The app signs in anonymously: Firebase supplies a user identity without a visible username/password form. That identity is used to decide which reports the current user may delete.

If Firebase is not configured, a report can be saved just on this device. If Firebase is configured but the network is unavailable, the behavior differs: the form waits for the backend's write completion or reports an error. It does not automatically choose the same local-only fallback.

Profile information currently goes from this device to Firebase. The app does not contain a matching step that loads a saved cloud profile into `AppState`. Community reports do have an incoming update listener.

## 7. The other files around the Swift code

| File or folder | Why it exists |
|---|---|
| `Resources/Info.plist` | App settings such as permission explanations and allowed screen orientations. It tells iOS why your app wants location or motion access. |
| `Resources/GoogleService-Info.plist` | Tells Firebase which configured project/app this client belongs to. |
| `Resources/GoogleService-Info.plist.example` | An example configuration file. |
| `Resources/Assets.xcassets` | Pictures and asset settings, including the app icon and accent color. |
| `eRideSafe.xcodeproj` | Instructions Xcode uses to build the app and include the right files and libraries. |
| `Package.resolved` | Records specific versions of external libraries so builds use the recorded dependencies. |
| [firebase/firestore.rules][rules] | Rules checked by the database to decide who can read/write which records, when this file is deployed. |
| [firebase/firebase.json][firebase-config] | Tells Firebase's deployment tools where the rules file is. |
| [scripts/update_safety_map_roads.py][importer] | A developer tool that downloads/cleans city road geometry and writes compressed data into the Swift source. The phone app does not run this Python script. |
| [scripts/map-model-tests.swift][tests] | Checks map rules and distance behavior using the actual model code. |
| [scripts/test-map-models.sh][test-runner] | Builds and runs those checks in a temporary directory. |
| [docs/map-data.md][map-notes] | Explains where the map data came from and what was checked previously. |
| `.codex-work` | Existing temporary builds, cached dependencies, and past testing materials. |
| Presentation deck | Material for presenting the project; it does not run as part of the app. |

The existing map checks passed when run for this walkthrough. That checks the map models, not every screen or the live Firebase service.

## 8. Swift words you can look up while reading

| Word | Plain meaning |
|---|---|
| `let` | A value you do not reassign after initialization. |
| `var` | A value you can change. |
| `Bool` | True or false. |
| `String` | Text. |
| `Int` / `Double` | A whole number / a floating-point number. |
| `struct` | A type whose values are treated as separate values when copied and changed. |
| `class` | A reference type: multiple places can refer to the same object. |
| `enum` | A named set of possible cases, sometimes carrying extra values. |
| `func` | A named piece of work. |
| `init` | Code for constructing a new value or object. |
| `nil` | No value is present. `Date?` means a date might be absent. |
| `if let` | Use an optional value only if it exists. |
| `guard ... else { return }` | Stop this function early unless a requirement is met. |
| `switch` | Pick behavior based on which case/value you have. |
| `ForEach` | Ask SwiftUI to produce content for identifiable items in a collection. |
| `map` | Turn each item in a collection into another value. This is unrelated to the map screen. |
| `filter` | Keep only items that pass a condition. |
| `async` / `await` | Describe work that may pause, and a point where it may wait for a result without blocking the thread. |
| `throws` / `try` / `catch` | A function can fail; attempt it; handle the failure. |
| `Task` | Start asynchronous work. It does not automatically mean all its code runs on a background thread. |
| `Codable` | The type supports turning values into stored/transmitted data and back. |
| `Identifiable` | The value provides an identity, useful for lists and selections. |

## 9. A useful first reading session

Read `eRideSafeApp.swift`, then `AppState.swift`, then the first part of `RootTabView.swift`. Find the condition choosing onboarding, the method saving the class, and the tabs shown afterward.

Then follow one lesson: `SchoolView` → `LessonDetailView` → `appState.markLessonComplete` → the progress number on School. This is a small, complete example of the pattern used across your app: a view reads data, an action changes state, the change is saved, and the interface updates.

Once that feels familiar, follow classification, reports, and Ride Mode using the same questions: **What information does this code read? What changes it? Where is it saved? Which screen observes it?**

[technical]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /docs/technical-walkthrough.md:1>
[app]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/App/eRideSafeApp.swift:1>
[root]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/App/RootTabView.swift:1>
[state]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/App/AppState.swift:61>
[device]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Models/DeviceClass.swift:1>
[classifier-model]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Models/ClassifierModels.swift:1>
[classifier-view]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Classifier/DeviceClassifierView.swift:1>
[zone]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Models/RideZone.swift:1>
[map-data]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Models/SafetyMapData.swift:1>
[map-notes]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /docs/map-data.md:1>
[map-view]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Map/SafetyMapView.swift:1>
[home]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Home/HomeView.swift:1>
[location]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Services/LocationManager.swift:1>
[motion]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Services/RideMotionManager.swift:1>
[alerts]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Services/RideAlertService.swift:1>
[ride]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Ride/RideModeView.swift:1>
[lessons]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Models/Lesson.swift:1>
[questions]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Models/QuizQuestion.swift:1>
[school]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/School/SchoolView.swift:1>
[lesson-detail]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/School/LessonDetailView.swift:1>
[quiz]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/School/QuizView.swift:1>
[certificate]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/School/CertificateView.swift:1>
[report-model]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Models/SafetyReport.swift:1>
[new-report]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Reports/NewReportView.swift:1>
[reports]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Reports/ReportsView.swift:1>
[report-detail]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Reports/ReportDetailView.swift:1>
[backend]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Services/FirebaseBackend.swift:1>
[rules]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /firebase/firestore.rules:1>
[firebase-config]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /firebase/firebase.json:1>
[design]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /eRideSafe/Views/Components/DesignSystem.swift:1>
[importer]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /scripts/update_safety_map_roads.py:1>
[tests]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /scripts/map-model-tests.swift:1>
[test-runner]: </Users/annirudhraman/Desktop/Coding Projects/eRideSafe Project /scripts/test-map-models.sh:1>
