import MapKit
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    @State private var previewCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.6140, longitude: -122.0410),
            span: MKCoordinateSpan(latitudeDelta: 0.106, longitudeDelta: 0.13)
        )
    )

    private var completedLessons: Int {
        CourseContent.completedLessonCount(in: appState.completedLessonIDs)
    }

    private var schoolProgress: Double {
        Double(completedLessons) / Double(CourseContent.lessons.count)
    }

    // Local street segments appear when exploring the full map at street scale.
    private static let previewZones = SammamishZones.roadways.filter { $0.level != .green }
        + SammamishZones.sharedPaths

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                schoolSection
                mapSection
                safetyNotice
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 26)
        }
        .background(Color.erideBackground)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.erideHero

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: 135, y: -70)

            Image(systemName: "bicycle")
                .font(.system(size: 86, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.10))
                .offset(x: 215, y: 35)

            VStack(alignment: .leading, spacing: 10) {
                Text("eRideSafe")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("Sammamish e-bike safety")
                    .font(.headline)
                    .foregroundStyle(Color.white.opacity(0.86))

                StatusPill(
                    text: appState.selectedDeviceClass.shortTitle,
                    systemImage: appState.selectedDeviceClass.systemImage,
                    color: Color.white
                )
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .padding(.top, 3)
            }
            .padding(22)
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.erideNavy.opacity(0.22), radius: 16, y: 8)
    }

    private var schoolSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("eRide School", systemImage: "graduationcap.fill")

            NavigationLink {
                SchoolView()
            } label: {
                ERideCard(tint: Color.erideGold) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(appState.certificateDate == nil ? "Course progress" : "Certified")
                                .font(.headline)
                                .foregroundStyle(Color.primary)

                            Spacer()

                            Text("\(completedLessons)/\(CourseContent.lessons.count)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color.erideGreen)
                        }

                        ProgressView(value: schoolProgress)
                            .tint(Color.erideGreen)
                            .scaleEffect(x: 1, y: 1.35, anchor: .center)

                        HStack {
                            Text(appState.certificateDate == nil ? "Continue learning" : "View certificate")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.secondary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.bold))

                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("Safety Map", systemImage: "map.fill")

            NavigationLink {
                SafetyMapView()
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Map(position: $previewCameraPosition) {
                        ForEach(SafetyMapData.restrictedTrails) { trail in
                            MapPolyline(coordinates: trail.coordinates)
                                .stroke(
                                    Color.red.opacity(0.78),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 5])
                                )
                                .mapOverlayLevel(level: .aboveRoads)
                        }

                        ForEach(Self.previewZones) { zone in
                            let permission = zone.permission(for: appState.selectedDeviceClass)

                            MapPolyline(coordinates: zone.coordinates)
                                .stroke(
                                    permission.color,
                                    style: StrokeStyle(
                                        lineWidth: zone.facility == .roadway ? 3 : 4,
                                        lineCap: .round,
                                        lineJoin: .round,
                                        dash: permission.isProhibited ? [8, 6] : []
                                    )
                                )
                                .mapOverlayLevel(level: .aboveRoads)
                        }

                        ForEach(SafetyMapData.schools) { school in
                            Annotation(school.name, coordinate: school.coordinate) {
                                Image(systemName: "figure.child.and.line.vertical.and.figure.child")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 22, height: 22)
                                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 6))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white, lineWidth: 1.5)
                                    }
                                    .accessibilityLabel("School: \(school.name)")
                            }
                            .annotationTitles(.hidden)
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
                    .allowsHitTesting(false)

                    LinearGradient(
                        colors: [Color.clear, Color.erideNavy.opacity(0.72)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Can I ride here?")
                                .font(.headline)
                            Text("\(appState.selectedDeviceClass.shortTitle) access in Sammamish")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.82))
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.title2)
                    }
                    .foregroundStyle(Color.white)
                    .padding(15)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.erideTeal.opacity(0.20), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 5)
            }
            .buttonStyle(.plain)

            Text("Road and path colors follow your selected class. Blue icons mark schools.")
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 2)
        }
    }

    private var safetyNotice: some View {
        ERideCard(tint: Color.erideCoral) {
            Label {
                Text("Set up the app before riding and rely on audio or haptic alerts while moving. Never hold or operate your phone during a ride.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            } icon: {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(Color.erideCoral)
            }
        }
    }

    private func sectionHeading(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.bold())
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 2)
    }
}
