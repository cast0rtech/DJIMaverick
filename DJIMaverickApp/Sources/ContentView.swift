import SwiftUI

/// Universal App Root View: Dynamically switches between iPadOS (Command Center Split-View)
/// and iOS (Compact Mobile Flight HUD)
public struct ContentView: View {
    @StateObject private var telemetry = TelemetryState()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // IPADOS COMMAND CENTER LAYOUT
                IPadOSCommandCenterView(telemetry: telemetry, selectedTab: $selectedTab)
            } else {
                // IOS (IPHONE) COMPACT HUD LAYOUT
                IOSCompactHUDView(telemetry: telemetry, selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - IPADOS COMMAND CENTER (SPLIT VIEW / MULTI-COLUMN)
struct IPadOSCommandCenterView: View {
    @ObservedObject var telemetry: TelemetryState
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // TOP AVIONICS TELEMETRY BAR
            TopAvionicsHeaderView(telemetry: telemetry)
            
            // MAIN WORKSPACE (SIDEBAR + INSPECTOR DRAWER + MAP VIEWPORT)
            HStack(spacing: 0) {
                // Persistent Primary Navigation Bar
                VStack(spacing: 8) {
                    IPadNavTab(icon: "airplane.circle", title: "Planificación", subtitle: "3D Waypoints", isSelected: selectedTab == 0) { selectedTab = 0 }
                    IPadNavTab(icon: "square.grid.3x3", title: "Fotogrametría", subtitle: "Grid & DEM", isSelected: selectedTab == 1) { selectedTab = 1 }
                    IPadNavTab(icon: "location.north.circle", title: "On-The-Fly", subtitle: "Follow-Me", isSelected: selectedTab == 2) { selectedTab = 2 }
                    IPadNavTab(icon: "gamecontroller", title: "Simulación", subtitle: "Virtual Sticks", isSelected: selectedTab == 3) { selectedTab = 3 }
                    IPadNavTab(icon: "folder.badge.gearshape", title: "Flotas", subtitle: "Repositorios", isSelected: selectedTab == 4) { selectedTab = 4 }
                    
                    Spacer()
                    
                    // Hardware tag
                    Text("DJI SDK v4.16.2\niPadOS Bridge")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                }
                .frame(width: 140)
                .background(Color(red: 0.04, green: 0.05, blue: 0.08))
                .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.white.opacity(0.08)), alignment: .trailing)
                
                // Secondary Contextual Drawer
                Group {
                    switch selectedTab {
                    case 0: PreplanningView(telemetry: telemetry)
                    case 1: PhotogrammetryView(telemetry: telemetry)
                    case 2: OnTheFlyView(telemetry: telemetry)
                    case 3: SimulationSafetyView(telemetry: telemetry)
                    case 4: FleetRepositoriesView(telemetry: telemetry)
                    default: PreplanningView(telemetry: telemetry)
                    }
                }
                .frame(width: 340)
                .background(Color(red: 0.06, green: 0.08, blue: 0.12))
                .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.white.opacity(0.08)), alignment: .trailing)
                
                // Central Tactical Flight Viewport
                TacticalHUDMapView(telemetry: telemetry)
            }
            
            // BOTTOM RUNTIME EXECUTION & SCRUBBER BAR
            BottomRuntimeScrubberView(telemetry: telemetry)
        }
        .background(Color(red: 0.03, green: 0.04, blue: 0.06))
    }
}

// MARK: - IOS COMPACT HUD (IPHONE ADAPTIVE LAYOUT)
struct IOSCompactHUDView: View {
    @ObservedObject var telemetry: TelemetryState
    @Binding var selectedTab: Int
    @State private var showModuleSheet: Bool = false
    
    var body: some View {
        ZStack {
            // Fullscreen Map Viewport
            TacticalHUDMapView(telemetry: telemetry)
            
            VStack {
                // Compact Top Telemetry Strip
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Mavic 3E")
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                    Text("RTK FIX")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                    Text("BAT 86%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                    Text("AGL 65m")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.cyan)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, 40)
                .padding(.horizontal)
                
                Spacer()
                
                // iPhone Quick Bottom Drawer Trigger
                HStack(spacing: 12) {
                    Button {
                        showModuleSheet.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("MENÚ DE MISIÓN (5 MÓDULOS)")
                        }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.cyan)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                    }
                    
                    Button {
                        telemetry.toggleSimulation()
                    } label: {
                        Image(systemName: telemetry.isSimulating ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showModuleSheet) {
            NavigationStack {
                VStack(spacing: 0) {
                    Picker("Módulo", selection: $selectedTab) {
                        Text("Plan").tag(0)
                        Text("Survey").tag(1)
                        Text("Live").tag(2)
                        Text("Sticks").tag(3)
                        Text("Flota").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    Group {
                        switch selectedTab {
                        case 0: PreplanningView(telemetry: telemetry)
                        case 1: PhotogrammetryView(telemetry: telemetry)
                        case 2: OnTheFlyView(telemetry: telemetry)
                        case 3: SimulationSafetyView(telemetry: telemetry)
                        case 4: FleetRepositoriesView(telemetry: telemetry)
                        default: PreplanningView(telemetry: telemetry)
                        }
                    }
                }
                .navigationTitle("DJI Maverick Control")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Listo") { showModuleSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - COMMON AVIONICS HEADER
struct TopAvionicsHeaderView: View {
    @ObservedObject var telemetry: TelemetryState
    
    var body: some View {
        HStack(spacing: 14) {
            // Brand
            HStack(spacing: 8) {
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 1) {
                    Text("DJI MAVERICK PRO GCS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("Kinematic Virtual Sticks • iPadOS")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Telemetry Chips
            TelemChip(title: "AERONAVE", value: telemetry.aircraftModel, valueColor: .white)
            TelemChip(title: "ENLACE O3 (10Hz)", value: "\(telemetry.signalStrengthPercent)% / \(telemetry.signalRSSI) dBm", valueColor: .cyan)
            TelemChip(title: "RTK FIX", value: "\(telemetry.satelliteCount) Sats (HDOP \(String(format: "%.1f", telemetry.hdop)))", valueColor: .green)
            TelemChip(title: "BATERÍA (SMART RTH)", value: "\(telemetry.batteryPercent)% • \(String(format: "%.1fV", telemetry.batteryVoltage)) (\(telemetry.flightTimeRemainingMinutes)m)", valueColor: .orange)
            TelemChip(title: "AGL / VEL", value: "AGL \(String(format: "%.1f", telemetry.altitudeAGL))m • \(String(format: "%.1f", telemetry.horizontalSpeed)) m/s", valueColor: .cyan)
            
            Spacer()
            
            // Flight Action Buttons
            HStack(spacing: 6) {
                Button {
                    telemetry.toggleSimulation()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("SIMULAR 3D")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Button {
                    telemetry.triggerEmergencyHold()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                        Text("HOLD")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.2))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.05, green: 0.06, blue: 0.09))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.08)), alignment: .bottom)
    }
}

struct TelemChip: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct IPadNavTab: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(isSelected ? Color.black : Color.cyan)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color.cyan : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
                Text(subtitle)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.cyan : Color.secondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(isSelected ? Color.cyan.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - BOTTOM RUNTIME SCRUBBER
struct BottomRuntimeScrubberView: View {
    @ObservedObject var telemetry: TelemetryState
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                telemetry.toggleSimulation()
            } label: {
                Image(systemName: telemetry.isSimulating ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
                    .background(Color.cyan)
                    .clipShape(Circle())
            }
            
            Text("04:10 / 16:40")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(telemetry.missionProgress), height: 5)
                }
            }
            .frame(height: 5)
            
            HStack(spacing: 12) {
                Text("DIST: 850m / 3.4km")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("FOTOS: \(telemetry.photosCaptured) / \(telemetry.totalPhotosTarget)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.orange)
                Text(telemetry.kernelStatus)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.04, green: 0.05, blue: 0.07))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.08)), alignment: .top)
    }
}
