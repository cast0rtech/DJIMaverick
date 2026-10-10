import SwiftUI
import Combine

/// Real-time UAV telemetry representation matching DJI Mobile SDK & Dronelink feeds
@MainActor
public class TelemetryState: ObservableObject {
    @Published public var aircraftModel: String = "DJI Mavic 3 Enterprise"
    @Published public var isConnected: Bool = true
    @Published public var signalStrengthPercent: Int = 98
    @Published public var signalRSSI: Int = -62
    
    // GNSS & RTK
    @Published public var rtkFixed: Bool = true
    @Published public var satelliteCount: Int = 29
    @Published public var hdop: Double = 0.6
    @Published public var latitude: Double = 37.7749
    @Published public var longitude: Double = -122.4194
    
    // Altitude & Velocity (Kinematics)
    @Published public var altitudeAGL: Double = 65.0
    @Published public var altitudeMSL: Double = 142.5
    @Published public var horizontalSpeed: Double = 8.5
    @Published public var verticalSpeed: Double = 0.0
    @Published public var headingDegrees: Double = 45.0
    
    // Battery & Failsafe
    @Published public var batteryPercent: Int = 86
    @Published public var batteryVoltage: Double = 22.8
    @Published public var flightTimeRemainingMinutes: Int = 26
    @Published public var smartRTHThreshold: Int = 24
    
    // Gimbal
    @Published public var gimbalPitch: Double = -45.0
    @Published public var gimbalYawRelativeToAircraft: Double = 0.0
    
    // Virtual Sticks (10-20 Hz closed-loop outputs)
    @Published public var stickPitch: Double = 2.4     // m/s
    @Published public var stickRoll: Double = -1.1      // m/s
    @Published public var stickThrottle: Double = 0.0  // m/s
    @Published public var stickYawRate: Double = 15.2   // deg/s
    
    // Mission Status
    @Published public var activeMissionName: String = "Solar Park North - Cluster B"
    @Published public var missionProgress: Double = 0.25
    @Published public var distanceFlownMeters: Double = 850
    @Published public var totalMissionDistanceMeters: Double = 3420
    @Published public var photosCaptured: Int = 78
    @Published public var totalPhotosTarget: Int = 312
    @Published public var isExecutingMission: Bool = false
    @Published public var isSimulating: Bool = false
    @Published public var kernelStatus: String = "EN TRAYECTORIA"
    
    public init() {}
    
    public func toggleSimulation() {
        isSimulating.toggle()
        if isSimulating {
            kernelStatus = "SIMULACIÓN 10Hz ACTIVA"
        } else {
            kernelStatus = "EN ESPERA (HOLD)"
        }
    }
    
    public func triggerEmergencyHold() {
        isSimulating = false
        isExecutingMission = false
        horizontalSpeed = 0.0
        stickPitch = 0.0
        stickRoll = 0.0
        stickThrottle = 0.0
        stickYawRate = 0.0
        kernelStatus = "EMERGENCY HOVER (HOLD)"
    }
}
