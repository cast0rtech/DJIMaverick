import SwiftUI

// MARK: - 1. PRE-PLANNING & COMPONENT TREE VIEW
public struct PreplanningView: View {
    @ObservedObject var telemetry: TelemetryState
    @State private var cruiseSpeed: Double = 7.5
    @State private var cornerRadius: Double = 12.0
    @State private var gimbalMode: Int = 0
    
    let missionTree = MissionNode(
        name: "Misión: Solar Park North - Cluster B",
        subtitle: "Kinematic Virtual Sticks • 3.4 km",
        type: .root,
        children: [
            MissionNode(name: "1. Despegue Vertical", subtitle: "Ascenso a 60m AGL • Yaw 045°", type: .takeoff),
            MissionNode(name: "2. Ruta Curvada con POI", subtitle: "Enfoque a Subestación • 12 Waypoints", type: .path),
            MissionNode(name: "3. Órbita Cilíndrica 360°", subtitle: "Radio 25m • Gimbal -28°", type: .orbit),
            MissionNode(name: "4. Regla de Telemetría", subtitle: "SI Batería < 25% -> RTH Checkpoint", type: .conditional)
        ]
    )
    
    public init(telemetry: TelemetryState) {
        self.telemetry = telemetry
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("MÓDULO 1")
                        .font(.caption2.bold())
                        .foregroundStyle(.cyan)
                    Text("Automatización 3D")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                // Hierarchical Component Tree Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("ÁRBOL DE COMPONENTES")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("4 Nodos")
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    
                    VStack(spacing: 8) {
                        ComponentNodeRow(node: missionTree, isRoot: true)
                        ForEach(missionTree.children) { child in
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 2)
                                    .padding(.leading, 14)
                                ComponentNodeRow(node: child, isRoot: false)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Flight Parameters
                VStack(alignment: .leading, spacing: 14) {
                    Text("PARÁMETROS CINEMÁTICOS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Velocidad de Crucero")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.1f m/s", cruiseSpeed))
                                .font(.caption.monospaced().bold())
                                .foregroundStyle(.cyan)
                        }
                        Slider(value: $cruiseSpeed, in: 2.0...15.0, step: 0.5)
                            .tint(.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Radio de Esquinas (Curvature)")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f m", cornerRadius))
                                .font(.caption.monospaced().bold())
                                .foregroundStyle(.cyan)
                        }
                        Slider(value: $cornerRadius, in: 0...25, step: 1.0)
                            .tint(.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Control de Orientación Gimbal")
                            .font(.caption)
                        Picker("Gimbal Mode", selection: $gimbalMode) {
                            Text("Hacia POI").tag(0)
                            Text("Rumbo Ruta").tag(1)
                            Text("Manual").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

struct ComponentNodeRow: View {
    let node: MissionNode
    let isRoot: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: node.type.iconName)
                .font(.system(size: 13))
                .foregroundStyle(node.type.tintColor)
                .frame(width: 28, height: 28)
                .background(node.type.tintColor.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(node.subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isRoot {
                Text("Válido")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
            }
        }
        .padding(8)
        .background(isRoot ? Color.cyan.opacity(0.08) : Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 2. PHOTOGRAMMETRY & SURVEY VIEW
public struct PhotogrammetryView: View {
    @ObservedObject var telemetry: TelemetryState
    @State private var selectedSensorIndex: Int = 0
    @State private var patternType: Int = 0 // 0: Grid, 1: Crosshatch, 2: Corridor, 3: Facade
    @State private var altitudeAGL: Double = 65.0
    @State private var frontOverlap: Double = 80.0
    @State private var sideOverlap: Double = 75.0
    @State private var terrainFollow: Bool = true
    
    let sensors = PhotogrammetryEngine.availableSensors
    
    public init(telemetry: TelemetryState) {
        self.telemetry = telemetry
    }
    
    var computedResults: PhotogrammetryResult {
        let sensor = sensors[selectedSensorIndex]
        return PhotogrammetryEngine.compute(
            sensor: sensor,
            altitudeAGLMeters: altitudeAGL,
            frontOverlapPercent: frontOverlap,
            sideOverlapPercent: sideOverlap,
            cruiseSpeedMps: 7.5,
            areaHectares: 14.6,
            isCrosshatch: (patternType == 1)
        )
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("MÓDULO 2")
                        .font(.caption2.bold())
                        .foregroundStyle(.cyan)
                    Text("Mapeo & Fotogrametría")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                // Pattern Selector
                Picker("Patrón", selection: $patternType) {
                    Text("Grid 2D").tag(0)
                    Text("Cruzado 3D").tag(1)
                    Text("Corredor").tag(2)
                    Text("Fachada").tag(3)
                }
                .pickerStyle(.segmented)
                
                // Camera Preset Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("SENSOR & CÁMARA")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    Picker("Sensor", selection: $selectedSensorIndex) {
                        ForEach(0..<sensors.count, id: \.self) { idx in
                            Text(sensors[idx].name).tag(idx)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.cyan)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Sliders
                VStack(alignment: .leading, spacing: 14) {
                    Text("PARÁMETROS DE RESOLUCIÓN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Altitud de Vuelo AGL")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f m", altitudeAGL))
                                .font(.caption.monospaced().bold())
                                .foregroundStyle(.cyan)
                        }
                        Slider(value: $altitudeAGL, in: 20...150, step: 5)
                            .tint(.cyan)
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Solap. Frontal")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.0f%%", frontOverlap))
                                    .font(.caption.monospaced().bold())
                                    .foregroundStyle(.cyan)
                            }
                            Slider(value: $frontOverlap, in: 50...90, step: 5)
                                .tint(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Solap. Lateral")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.0f%%", sideOverlap))
                                    .font(.caption.monospaced().bold())
                                    .foregroundStyle(.cyan)
                            }
                            Slider(value: $sideOverlap, in: 40...85, step: 5)
                                .tint(.cyan)
                        }
                    }
                    
                    Toggle(isOn: $terrainFollow) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seguimiento de Terreno (DEM)")
                                .font(.caption.bold())
                            Text("Ajusta AGL constante con curvas de nivel SRTM")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.cyan)
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Computed Photogrammetry Metrics
                VStack(alignment: .leading, spacing: 10) {
                    Text("MÉTRICAS FOTOGRAMÉTRICAS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricBox(label: "GSD (Resolución)", value: String(format: "%.2f cm/px", computedResults.gsdCentimetersPerPixel), color: .cyan)
                        MetricBox(label: "Área de Cobertura", value: String(format: "%.1f ha", computedResults.coverageAreaHectares), color: .white)
                        MetricBox(label: "Disparos Estimados", value: "\(computedResults.estimatedPhotoCount) fotos", color: .orange)
                        MetricBox(label: "Tiempo Estimado", value: "\(computedResults.estimatedFlightTimeSeconds / 60)m \(computedResults.estimatedFlightTimeSeconds % 60)s", color: .green)
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

struct MetricBox: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 3. ON-THE-FLY & REAL TIME VIEW
public struct OnTheFlyView: View {
    @ObservedObject var telemetry: TelemetryState
    @State private var followDistance: Double = 18.0
    @State private var followMode: Int = 0
    
    public init(telemetry: TelemetryState) {
        self.telemetry = telemetry
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MÓDULO 3")
                        .font(.caption2.bold())
                        .foregroundStyle(.pink)
                    Text("Acciones On-The-Fly")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                // Follow Me Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("MODO SÍGUEME DINÁMICO (FOLLOW-ME)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Distancia de Offset")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f m", followDistance))
                                .font(.caption.monospaced().bold())
                                .foregroundStyle(.cyan)
                        }
                        Slider(value: $followDistance, in: 5...50, step: 5)
                            .tint(.cyan)
                    }
                    
                    Picker("Modo", selection: $followMode) {
                        Text("Detrás (Lead)").tag(0)
                        Text("Lateral").tag(1)
                        Text("Órbita Cont.").tag(2)
                    }
                    .pickerStyle(.segmented)
                    
                    Button {
                        // Activate follow me
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("ACTIVAR FOLLOW-ME")
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.cyan.opacity(0.2))
                        .foregroundStyle(.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan, lineWidth: 1))
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Live Drop Pin
                VStack(alignment: .leading, spacing: 12) {
                    Text("MARCACIÓN DE WAYPOINTS EN VIVO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    Button {
                        // Tag current position
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text("MARCAR WAYPOINT AQUÍ (DROP PIN)")
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        // Quick orbit
                    } label: {
                        HStack {
                            Image(systemName: "circle.dashed")
                            Text("GENERAR ÓRBITA RÁPIDA INSTANTÁNEA")
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white.opacity(0.06))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

// MARK: - 4. SIMULATION & SAFETY VIEW
public struct SimulationSafetyView: View {
    @ObservedObject var telemetry: TelemetryState
    
    public init(telemetry: TelemetryState) {
        self.telemetry = telemetry
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MÓDULO 4")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                    Text("Simulación & Palancas Virtuales")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                // Virtual Sticks Crosshairs Monitor
                VStack(alignment: .leading, spacing: 12) {
                    Text("MONITOR CINEMÁTICO DE PALANCAS (10 Hz)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        // Right Stick (Pitch / Roll)
                        VStack(spacing: 6) {
                            Text("STICK DERECHO (P/R)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    .frame(width: 80, height: 80)
                                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 80, height: 1)
                                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 80)
                                
                                Circle()
                                    .fill(Color.cyan)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: .cyan, radius: 6)
                                    .offset(x: CGFloat(telemetry.stickRoll * 5), y: CGFloat(-telemetry.stickPitch * 5))
                            }
                            
                            Text(String(format: "P: %.1f | R: %.1f m/s", telemetry.stickPitch, telemetry.stickRoll))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Left Stick (Throttle / Yaw)
                        VStack(spacing: 6) {
                            Text("STICK IZQUIERDO (T/Y)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    .frame(width: 80, height: 80)
                                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 80, height: 1)
                                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 80)
                                
                                Circle()
                                    .fill(Color.cyan)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: .cyan, radius: 6)
                                    .offset(x: CGFloat(telemetry.stickYawRate * 1.5), y: CGFloat(-telemetry.stickThrottle * 5))
                            }
                            
                            Text(String(format: "T: %.1f | Y: %.1f°/s", telemetry.stickThrottle, telemetry.stickYawRate))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Battery Swap Checkpoint Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("REANUDACIÓN POR BATERÍA (SWAP)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("CHECKPOINT ACTIVO")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Componente: #2 Grid Mapeo Norte")
                            .font(.caption.monospaced())
                        Text("Distancia recorrida: 1,840 m (54% completado)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text("Fotos capturadas: 168 / 312")
                            .font(.caption.monospaced())
                            .foregroundStyle(.orange)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button {
                        // Resume mission
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("REANUDAR MISIÓN CON NUEVA BATERÍA")
                        }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

// MARK: - 5. FLEET & REPOSITORIES VIEW
public struct FleetRepositoriesView: View {
    @ObservedObject var telemetry: TelemetryState
    
    public init(telemetry: TelemetryState) {
        self.telemetry = telemetry
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MÓDULO 5")
                        .font(.caption2.bold())
                        .foregroundStyle(.purple)
                    Text("Flotas & Repositorios")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                // Repositories
                VStack(alignment: .leading, spacing: 10) {
                    Text("REPOSITORIOS COMPARTIDOS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        RepoRow(name: "Inspecciones Solar Iberia 2026", desc: "8 Misiones • 4 Pilotos", synced: true)
                        RepoRow(name: "Corredor Gasoducto Norte", desc: "12 Misiones • Linear Mapping", synced: false)
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Aircraft Fleet
                VStack(alignment: .leading, spacing: 10) {
                    Text("AERONAVES DE LA FLOTA")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        DroneRow(name: "Mavic 3E #01", sn: "SN: 1581F48002", status: "En Línea", isOnline: true)
                        DroneRow(name: "Matrice 300 RTK", sn: "SN: 1581F92003", status: "Hangar", isOnline: false)
                    }
                }
                .padding(14)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

struct RepoRow: View {
    let name: String
    let desc: String
    let synced: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.cyan)
                .frame(width: 28, height: 28)
                .background(Color.cyan.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(synced ? "Sincronizado" : "Local")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(synced ? .green : .secondary)
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DroneRow: View {
    let name: String
    let sn: String
    let status: String
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "airplane")
                .foregroundStyle(isOnline ? .green : .secondary)
                .frame(width: 28, height: 28)
                .background(isOnline ? Color.green.opacity(0.15) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(sn)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(status)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(isOnline ? .green : .secondary)
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
