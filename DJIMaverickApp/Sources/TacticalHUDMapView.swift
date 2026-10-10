import SwiftUI

/// Tactical 2D flight map with avionics HUD, drone heading frustum, and elevation profile
public struct TacticalHUDMapView: View {
    @ObservedObject var telemetry: TelemetryState
    @State private var selectedLayer: Int = 0
    @State private var isRadialOpen: Bool = false
    
    let waypoints: [CGPoint] = [
        CGPoint(x: 60, y: 80),
        CGPoint(x: 120, y: 70),
        CGPoint(x: 180, y: 60),
        CGPoint(x: 340, y: 60),
        CGPoint(x: 340, y: 100),
        CGPoint(x: 180, y: 100),
        CGPoint(x: 180, y: 140),
        CGPoint(x: 340, y: 140),
        CGPoint(x: 340, y: 180),
        CGPoint(x: 180, y: 180),
        CGPoint(x: 120, y: 220),
        CGPoint(x: 60, y: 200)
    ]
    
    public init(telemetry: TelemetryState) {
        self.telemetry = telemetry
    }
    
    public var body: some View {
        ZStack {
            // Dark Tactical Map Canvas
            Canvas { context, size in
                // 1. Background
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.03, green: 0.04, blue: 0.06)))
                
                // 2. Topographic and grid markings
                var gridPath = Path()
                let step: CGFloat = 40
                for x in stride(from: 0, to: size.width, by: step) {
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, to: size.height, by: step) {
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(gridPath, with: .color(Color.white.opacity(0.025)), lineWidth: 1)
                
                // 3. Survey polygon area
                let polygonRect = CGRect(x: 160, y: 50, width: 200, height: 150)
                context.fill(Path(polygonRect), with: .color(Color.cyan.opacity(0.06)))
                context.stroke(Path(polygonRect), with: .color(Color.cyan.opacity(0.4)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                
                // 4. Flight path spline
                var flightPath = Path()
                if let first = waypoints.first {
                    flightPath.move(to: first)
                    for pt in waypoints.dropFirst() {
                        flightPath.addLine(to: pt)
                    }
                }
                context.stroke(flightPath, with: .color(Color.cyan.opacity(0.85)), lineWidth: 2.5)
                
                // 5. Waypoint nodes
                for (idx, pt) in waypoints.enumerated() {
                    let dotRect = CGRect(x: pt.x - 3.5, y: pt.y - 3.5, width: 7, height: 7)
                    context.fill(Path(ellipseIn: dotRect), with: .color(idx == 0 ? .green : .cyan))
                    context.stroke(Path(ellipseIn: dotRect), with: .color(.white), lineWidth: 1)
                }
                
                // 6. Drone Position & Camera FOV cone
                let dronePos = CGPoint(x: 240, y: 100)
                
                // Camera FOV frustum cone
                var conePath = Path()
                conePath.move(to: dronePos)
                conePath.addLine(to: CGPoint(x: dronePos.x + 35, y: dronePos.y - 20))
                conePath.addLine(to: CGPoint(x: dronePos.x + 40, y: dronePos.y + 15))
                conePath.closeSubpath()
                context.fill(conePath, with: .color(Color.cyan.opacity(0.2)))
                
                // Drone circle
                let droneRect = CGRect(x: dronePos.x - 6, y: dronePos.y - 6, width: 12, height: 12)
                context.fill(Path(ellipseIn: droneRect), with: .color(Color(red: 0.05, green: 0.08, blue: 0.12)))
                context.stroke(Path(ellipseIn: droneRect), with: .color(.cyan), lineWidth: 2)
            }
            
            // Map Top-Left Pill Controls
            VStack {
                HStack {
                    HStack(spacing: 4) {
                        MapPillButton(title: "Satélite", isSelected: selectedLayer == 0) { selectedLayer = 0 }
                        MapPillButton(title: "Relieve DEM", isSelected: selectedLayer == 1) { selectedLayer = 1 }
                        MapPillButton(title: "3D Vista", isSelected: selectedLayer == 2) { selectedLayer = 2 }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Floating Compass & Wind Card
                    HStack(spacing: 8) {
                        Image(systemName: "safari.fill")
                            .foregroundStyle(.cyan)
                            .rotationEffect(.degrees(telemetry.headingDegrees))
                        Text(String(format: "%03.0f° NE", telemetry.headingDegrees))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                
                Spacer()
                
                // Floating Radial Action Wheel (Dronelink quick action)
                HStack {
                    // FPV PIP mini preview
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 5, height: 5)
                            Text("FPV LIVE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(colors: [.blue.opacity(0.4), .black], startPoint: .top, endPoint: .bottom))
                                .frame(width: 110, height: 65)
                            Rectangle().fill(Color.cyan.opacity(0.7)).frame(width: 50, height: 1)
                        }
                    }
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    // Radial Wheel Trigger Button
                    Button {
                        isRadialOpen.toggle()
                    } label: {
                        Image(systemName: isRadialOpen ? "xmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: .cyan.opacity(0.5), radius: 8)
                    }
                }
                .padding()
                
                // Bottom Terrain Elevation Profile (DEM / Terrain Follow)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 10))
                            .foregroundStyle(.cyan)
                        Text("SEGUIMIENTO AGL / PERFIL DE RELIEVE DEM")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Spacer()
                        Text("Delta Elevación: 42m • Pendiente: 14°")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    
                    // DEM cross-section mini graph
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geo.size.height * 0.7))
                            path.addQuadCurve(to: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.4), control: CGPoint(x: geo.size.width * 0.25, y: geo.size.height * 0.8))
                            path.addQuadCurve(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.6), control: CGPoint(x: geo.size.width * 0.75, y: geo.size.height * 0.3))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(colors: [Color.orange.opacity(0.4), Color.black], startPoint: .top, endPoint: .bottom))
                        
                        // AGL Constant Drone Line
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height * 0.3))
                            path.addQuadCurve(to: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.15), control: CGPoint(x: geo.size.width * 0.25, y: geo.size.height * 0.4))
                            path.addQuadCurve(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.25), control: CGPoint(x: geo.size.width * 0.75, y: geo.size.height * 0.1))
                        }
                        .stroke(Color.cyan, lineWidth: 1.5)
                    }
                    .frame(height: 35)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.85))
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.1)), alignment: .top)
            }
        }
    }
}

struct MapPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.cyan : Color.clear)
                .foregroundStyle(isSelected ? Color.black : Color.white)
                .clipShape(Capsule())
        }
    }
}
