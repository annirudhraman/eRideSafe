import MapKit
import SwiftUI

struct SafetyMapView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .region(Self.cityRegion)
    @State private var visibleRegion = Self.cityRegion
    @State private var selectedZone: RideZone?
    @State private var selectedSchool: SchoolSafetyArea?
    @State private var pendingZone: RideZone?
    @State private var pendingSchool: SchoolSafetyArea?
    @State private var showPlaceBrowser = false
    @State private var showCommunityReports = true
    @State private var showRoadCautions = true
    @State private var showLocalRoads = true
    @State private var showSharedPaths = true
    @State private var showRestrictedTrails = true
    @State private var showSchoolAreas = true
    @State private var showTraffic = false
    @State private var satelliteMap = false

    private static let cityRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.615, longitude: -122.045),
        span: MKCoordinateSpan(latitudeDelta: 0.105, longitudeDelta: 0.135)
    )

    private var isStreetDetailVisible: Bool { visibleRegion.span.latitudeDelta < 0.045 }

    private var visibleRoads: [MapRoadFeature] {
        let bounds = MKMapRect(region: visibleRegion)
        return MapRoadFeature.roads.filter {
            ($0.isLocal ? showLocalRoads && isStreetDetailVisible : showRoadCautions)
                && $0.bounds.intersects(bounds)
        }
    }

    private var currentSafetyStatus: SafetyStatus? {
        guard let accuracy = locationManager.horizontalAccuracy,
              accuracy >= 0, accuracy <= 12,
              let coordinate = locationManager.coordinate else { return nil }

        let nearbyContext = SafetyMapData.nearbyContext(to: coordinate)
        if case .schoolArea(let school)? = nearbyContext {
            return SafetyStatus(title: "Near \(school.name)", message: "Watch for children and crossings. Follow posted school-zone signs.", systemImage: "graduationcap.fill", color: .blue)
        }
        if let zone = SammamishZones.nearestZone(to: coordinate) {
            let permission = zone.permission(for: appState.selectedDeviceClass)
            return SafetyStatus(
                title: "Near \(zone.name)",
                message: permission.title + " for " + appState.selectedDeviceClass.shortTitle + ". Check which road or path you are on.",
                systemImage: permission.systemImage,
                color: permission.color
            )
        }
        switch nearbyContext {
        case .schoolArea(let school)?:
            return SafetyStatus(title: "Near \(school.name)", message: "Watch for children and crossings. Follow posted school-zone signs.", systemImage: "graduationcap.fill", color: .blue)
        case .restrictedTrail(let trail)?:
            return SafetyStatus(title: "Natural-surface trail nearby", message: "\(trail.name): e-bikes are restricted on these trails. Confirm your location.", systemImage: "exclamationmark.triangle.fill", color: .orange)
        case .cautionRoad(let road)?:
            return SafetyStatus(title: "Near \(road.name)", message: "Collector or arterial road. Watch for traffic and turning vehicles.", systemImage: "exclamationmark.triangle.fill", color: .orange)
        case nil:
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            classSelector
            map
        }
        .navigationTitle("Ride Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showPlaceBrowser = true } label: {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("Find a road, path, or school")
            }
            ToolbarItem(placement: .topBarTrailing) {
                layersMenu
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.startUpdating()
        }
        .sheet(item: $selectedZone) { zone in
            ZoneDetailView(zone: zone, deviceClass: appState.selectedDeviceClass)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedSchool) { school in
            SchoolMapDetailView(school: school)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlaceBrowser, onDismiss: applyBrowserSelection) {
            MapPlaceBrowser(deviceClass: appState.selectedDeviceClass) { zone in
                pendingZone = zone
                showPlaceBrowser = false
            } onSchoolSelected: { school in
                pendingSchool = school
                showPlaceBrowser = false
            } onClose: {
                showPlaceBrowser = false
            }
        }
    }

    private var map: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(visibleRoads) { feature in
                    let permission = feature.zone.permission(for: appState.selectedDeviceClass)
                    MapPolyline(coordinates: feature.zone.coordinates)
                        .stroke(permission.color.opacity(feature.isLocal ? 0.72 : 0.90), style: StrokeStyle(lineWidth: feature.isLocal ? 3 : 4.5, lineCap: .round, lineJoin: .round))
                        .mapOverlayLevel(level: .aboveRoads)
                }
                if showRestrictedTrails {
                    ForEach(SafetyMapData.restrictedTrails) { trail in
                        MapPolyline(coordinates: trail.coordinates)
                            .stroke(Color.red.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [5, 4]))
                            .mapOverlayLevel(level: .aboveRoads)
                    }
                }
                if showSharedPaths {
                    ForEach(SammamishZones.sharedPaths) { zone in
                        let permission = zone.permission(for: appState.selectedDeviceClass)
                        MapPolyline(coordinates: zone.coordinates)
                            .stroke(permission.color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: permission.isProhibited ? [7, 5] : []))
                            .mapOverlayLevel(level: .aboveRoads)
                        Annotation(zone.name, coordinate: zone.referenceCoordinate) {
                            Button { selectedZone = zone } label: {
                                Image(systemName: "bicycle")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(permission.color, in: Circle())
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(zone.name), \(permission.title) for \(appState.selectedDeviceClass.title). Show class access.")
                        }
                        .annotationTitles(isStreetDetailVisible ? .visible : .hidden)
                    }
                }
                if showSchoolAreas {
                    ForEach(SafetyMapData.schools) { school in
                        Annotation(school.name, coordinate: school.coordinate, anchor: .bottom) {
                            Button { selectedSchool = school } label: {
                                VStack(spacing: 0) {
                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 30)
                                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 9))
                                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white, lineWidth: 2))
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(Color.blue)
                                        .offset(y: -1)
                                }
                                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(school.name). School location; watch for crossings. Show details.")
                        }
                        .annotationTitles(visibleRegion.span.latitudeDelta < 0.012 ? .visible : .hidden)
                    }
                }
                if showCommunityReports {
                    ForEach(Array(appState.reports.prefix(150))) { report in
                        if let latitude = report.latitude, let longitude = report.longitude {
                            Annotation(report.category.rawValue, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) {
                                NavigationLink {
                                    ReportDetailView(report: report)
                                } label: {
                                    Image(systemName: report.category.systemImage)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(7)
                                        .background(Color.red, in: Circle())
                                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                                }
                                .accessibilityLabel("Community report: \(report.category.rawValue)")
                            }
                            .annotationTitles(.hidden)
                        }
                    }
                }
            }
            .mapStyle(satelliteMap
                ? .hybrid(elevation: .realistic, pointsOfInterest: .all, showsTraffic: showTraffic)
                : .standard(elevation: .realistic, emphasis: .automatic, pointsOfInterest: .all, showsTraffic: showTraffic))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
                MapPitchToggle()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
            }
            .onTapGesture { point in
                guard let coordinate = proxy.convert(point, from: .local),
                      let adjacent = proxy.convert(CGPoint(x: point.x + 16, y: point.y), from: .local) else { return }
                let tolerance = min(45, MKMapPoint(coordinate).distance(to: MKMapPoint(adjacent)))
                let candidates = visibleRoads.map(\.zone) + (showSharedPaths ? SammamishZones.sharedPaths : [])
                selectedZone = candidates
                    .map { ($0, $0.distance(to: coordinate)) }
                    .filter { $0.1 <= tolerance }
                    .min { $0.1 < $1.1 }?.0
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                mapFooter
            }
        }
    }

    private var classSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(DeviceClass.allCases) { device in
                    Button {
                        appState.selectedDeviceClass = device
                    } label: {
                        Label(device == .electricMotorcycle ? "E-moto" : device.shortTitle, systemImage: device.systemImage)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .foregroundStyle(appState.selectedDeviceClass == device ? Color.white : Color.primary)
                            .background(appState.selectedDeviceClass == device ? Color.erideNavy : Color(uiColor: .tertiarySystemFill), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show \(device.title) access")
                    .accessibilityAddTraits(appState.selectedDeviceClass == device ? .isSelected : [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var layersMenu: some View {
        Menu {
            Section("Map appearance") {
                Toggle("Satellite + street labels", isOn: $satelliteMap)
                Toggle("Live traffic", isOn: $showTraffic)
            }
            Section("Safety layers") {
                Toggle("Public local roads", isOn: $showLocalRoads)
                Toggle("Caution roads", isOn: $showRoadCautions)
                Toggle("Shared paths", isOn: $showSharedPaths)
                Toggle("Natural-surface trails", isOn: $showRestrictedTrails)
                Toggle("Schools", isOn: $showSchoolAreas)
                Toggle("Community reports", isOn: $showCommunityReports)
            }
            Button {
                cameraPosition = .region(Self.cityRegion)
            } label: {
                Label("Show all Sammamish", systemImage: "arrow.up.left.and.arrow.down.right")
            }
        } label: {
            Image(systemName: "square.3.layers.3d")
        }
        .accessibilityLabel("Map style and layers")
    }

    private var mapFooter: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let status = currentSafetyStatus {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.title).font(.caption.weight(.semibold))
                        Text(status.message).font(.caption2).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: status.systemImage).foregroundStyle(status.color)
                }
                .padding(.horizontal, 14)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if appState.selectedDeviceClass != .electricMotorcycle &&
                        ((showLocalRoads && isStreetDetailVisible) ||
                         (showSharedPaths && (appState.selectedDeviceClass == .class1 || appState.selectedDeviceClass == .class2))) {
                        legendItem(.green, "Access allowed")
                    }
                    if appState.selectedDeviceClass == .electricMotorcycle && (showRoadCautions || (showLocalRoads && isStreetDetailVisible)) {
                        legendItem(.orange, "Conditional road access")
                    } else if showRoadCautions {
                        legendItem(.orange, "Allowed · caution")
                    }
                    if showRestrictedTrails || (showSharedPaths && (appState.selectedDeviceClass == .class3 || appState.selectedDeviceClass == .electricMotorcycle)) {
                        legendItem(.red, "Restricted", dashed: true)
                    }
                    if showSchoolAreas {
                        Label("School", systemImage: "graduationcap.fill").foregroundStyle(Color.blue)
                    }
                    if showCommunityReports && !appState.reports.isEmpty {
                        Label("Report", systemImage: "exclamationmark.bubble.fill").foregroundStyle(Color.red)
                    }
                }
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 14)
            }
            HStack {
                Text(showLocalRoads && !isStreetDetailVisible ? "Zoom in for local roads · Tap a road for class rules" : "Tap a road or school for details · Follow posted signs")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 2)
                Button {
                    cameraPosition = .region(Self.cityRegion)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .frame(width: 30, height: 30)
                }
                .accessibilityLabel("Show all Sammamish")
            }
            .padding(.horizontal, 14)
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(.regularMaterial)
    }

    private func legendItem(_ color: Color, _ label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 5) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in Capsule().fill(color).frame(width: 4, height: 3) }
                }
            } else {
                Capsule().fill(color).frame(width: 16, height: 3)
            }
            Text(label)
        }
    }

    private func applyBrowserSelection() {
        // Set the camera after the sheet leaves so MapKit uses the full viewport.
        if let zone = pendingZone {
            focus(on: zone)
            pendingZone = nil
        }
        if let school = pendingSchool {
            showSchoolAreas = true
            cameraPosition = .region(MKCoordinateRegion(center: school.coordinate, latitudinalMeters: 700, longitudinalMeters: 400))
            pendingSchool = nil
        }
    }

    private func focus(on zone: RideZone) {
        if zone.facility == .pavedSharedUsePath {
            showSharedPaths = true
        } else if zone.level == .green {
            showLocalRoads = true
        } else {
            showRoadCautions = true
        }
        let rect = MKPolyline(coordinates: zone.coordinates, count: zone.coordinates.count).boundingMapRect
        let minimum = MKMapPointsPerMeterAtLatitude(zone.referenceCoordinate.latitude) * 350
        cameraPosition = .rect(rect.insetBy(dx: -max(rect.width * 0.2, minimum), dy: -max(rect.height * 0.2, minimum)))
    }
}

private struct MapRoadFeature: Identifiable {
    let zone: RideZone
    let bounds: MKMapRect
    var id: UUID { zone.id }
    var isLocal: Bool { zone.level == .green }

    static let roads = SammamishZones.roadways.map {
        // Give perfectly horizontal/vertical segments nonempty bounds for culling.
        MapRoadFeature(zone: $0, bounds: MKPolyline(coordinates: $0.coordinates, count: $0.coordinates.count).boundingMapRect.insetBy(dx: -1, dy: -1))
    }
}

private extension MKMapRect {
    init(region: MKCoordinateRegion) {
        let northWest = MKMapPoint(CLLocationCoordinate2D(latitude: region.center.latitude + region.span.latitudeDelta / 2, longitude: region.center.longitude - region.span.longitudeDelta / 2))
        let southEast = MKMapPoint(CLLocationCoordinate2D(latitude: region.center.latitude - region.span.latitudeDelta / 2, longitude: region.center.longitude + region.span.longitudeDelta / 2))
        self.init(x: northWest.x, y: northWest.y, width: max(southEast.x - northWest.x, 1), height: max(southEast.y - northWest.y, 1))
    }
}

private struct SafetyStatus {
    let title: String
    let message: String
    let systemImage: String
    let color: Color
}

private struct ZoneDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let zone: RideZone
    let deviceClass: DeviceClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Label(zone.name, systemImage: zone.facility == .roadway ? "road.lanes" : "bicycle")
                        .font(.title2.bold())
                    Spacer(minLength: 8)
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel("Close details")
                }
                Text(zone.facility.title).font(.subheadline).foregroundStyle(.secondary)
                let permission = zone.permission(for: deviceClass)
                StatusPill(text: "\(deviceClass.shortTitle): \(permission.title)", systemImage: permission.systemImage, color: permission.color)
                Text(permission.message).font(.subheadline)
                Divider()
                Text("Bike class access").font(.headline)
                ForEach(DeviceClass.allCases) { device in
                    let access = zone.permission(for: device)
                    HStack {
                        Label(device.shortTitle, systemImage: device.systemImage)
                        Spacer()
                        Label(access.title, systemImage: access.systemImage)
                            .foregroundStyle(access.color)
                    }
                    .font(.caption.weight(device == deviceClass ? .bold : .regular))
                    .accessibilityElement(children: .combine)
                }
                Divider()
                Text(zone.detail).font(.footnote).foregroundStyle(.secondary)
                if let speed = zone.speedLimitMPH {
                    LabeledContent("Path speed limit", value: "\(Int(speed)) mph").font(.footnote)
                }
                if zone.facility == .roadway {
                    Link("Geometry: City street inventory (2021)", destination: SafetyMapData.streetGeometrySourceURL)
                        .font(.caption)
                } else {
                    Text(zone.geometrySource).font(.caption2).foregroundStyle(.secondary)
                }
                Link(destination: zone.permissionSourceURL) {
                    Label(zone.permissionSourceTitle, systemImage: "arrow.up.right.square")
                }
                .font(.footnote)
                Text("Access does not rate a road’s safety. Follow posted signs, closures, and current local rules.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(22)
        }
    }
}

private struct SchoolMapDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let school: SchoolSafetyArea

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    Label(school.name, systemImage: "graduationcap.fill").font(.title2.bold())
                    Spacer(minLength: 8)
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel("Close details")
                }
                StatusPill(text: "Watch for children and crossings", systemImage: "figure.walk", color: .blue)
                Text("Slow down near school entrances, look for crossing guards, and give pedestrians room at driveways and intersections.")
                Text("This pin marks the school location. Posted signs and flashing beacons define the active school speed zone; the map does not draw an assumed boundary.")
                    .font(.footnote).foregroundStyle(.secondary)
                Link("City school-zone guidance", destination: URL(string: "https://www.sammamish.us/government/public-works/traffic-engineering/school-zone-safety/")!)
                    .font(.footnote)
            }
            .padding(22)
        }
    }
}

private struct MapPlaceBrowser: View {
    let deviceClass: DeviceClass
    let onZoneSelected: (RideZone) -> Void
    let onSchoolSelected: (SchoolSafetyArea) -> Void
    let onClose: () -> Void
    @State private var query = ""

    // Keep disconnected street pieces separate on the map, but list each street once.
    private var roads: [RideZone] {
        var names = Set<String>()
        return SammamishZones.roadways.filter { names.insert($0.name).inserted && matches($0.name) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Shared paths") {
                    ForEach(SammamishZones.sharedPaths.filter { matches($0.name) }) { zone in
                        routeRow(zone)
                    }
                }
                Section("Schools") {
                    ForEach(SafetyMapData.schools.filter { matches($0.name) }) { school in
                        Button {
                            onSchoolSelected(school)
                        } label: {
                            Label(school.name, systemImage: "graduationcap.fill").foregroundStyle(Color.primary)
                        }
                    }
                }
                Section("Public roads · \(deviceClass.shortTitle)") {
                    ForEach(roads) { zone in routeRow(zone) }
                }
            }
            .searchable(text: $query, prompt: "Road, path, or school")
            .navigationTitle("Explore the map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done", action: onClose) }
            }
            .overlay {
                if !query.isEmpty && roads.isEmpty && !SammamishZones.sharedPaths.contains(where: { matches($0.name) }) && !SafetyMapData.schools.contains(where: { matches($0.name) }) {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
    }

    private func matches(_ name: String) -> Bool { query.isEmpty || name.localizedStandardContains(query) }

    private func routeRow(_ zone: RideZone) -> some View {
        let access = zone.permission(for: deviceClass)
        return Button {
            onZoneSelected(zone)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: access.systemImage).foregroundStyle(access.color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(zone.name).foregroundStyle(Color.primary)
                    Text(access.title).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
