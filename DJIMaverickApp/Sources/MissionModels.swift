import Foundation
import SwiftUI

/// Hierarchical mission components equivalent to Dronelink Component Tree
public enum MissionComponentType: String, CaseIterable, Identifiable {
    case root = "Misión Raíz"
    case takeoff = "Despegue & Ascenso"
    case path = "Trayectoria Curvada"
    case poi = "Punto de Interés (POI)"
    case orbit = "Órbita 360°"
    case grid = "Malla Fotogramétrica"
    case conditional = "Condición de Telemetría"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .root: return "network"
        case .takeoff: return "airplane.departure"
        case .path: return "point.topleft.down.curvedto.point.bottomright.up"
        case .poi: return "scope"
        case .orbit: return "circle.dashed"
        case .grid: return "square.grid.3x3.fill"
        case .conditional: return "arrow.triangle.branch"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .root: return .cyan
        case .takeoff: return .purple
        case .path: return .blue
        case .poi: return .indigo
        case .orbit: return .orange
        case .grid: return .green
        case .conditional: return .pink
        }
    }
}

public struct MissionNode: Identifiable {
    public let id = UUID()
    public var name: String
    public var subtitle: String
    public var type: MissionComponentType
    public var isValid: Bool
    public var children: [MissionNode]
    
    public init(name: String, subtitle: String, type: MissionComponentType, isValid: Bool = true, children: [MissionNode] = []) {
        self.name = name
        self.subtitle = subtitle
        self.type = type
        self.isValid = isValid
        self.children = children
    }
}

public struct MapWaypoint: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var altitudeAGL: Double
    public var label: String
    public var isKeyframe: Bool
}
