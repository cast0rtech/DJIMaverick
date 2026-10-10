import Foundation

/// Mathematical calculation engine for UAV photogrammetry, surveying and sensor optics
public struct CameraSensorPreset: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let sensorWidthMM: Double
    public let sensorHeightMM: Double
    public let focalLengthMM: Double
    public let imageWidthPx: Double
    public let imageHeightPx: Double
    
    public var aspectRatio: Double {
        imageWidthPx / imageHeightPx
    }
}

public struct PhotogrammetryResult {
    public let gsdCentimetersPerPixel: Double
    public let groundFootprintWidthMeters: Double
    public let groundFootprintHeightMeters: Double
    public let photoSpacingMeters: Double
    public let flightLineSpacingMeters: Double
    public let estimatedPhotoCount: Int
    public let estimatedFlightTimeSeconds: Int
    public let coverageAreaHectares: Double
}

public class PhotogrammetryEngine {
    public static let availableSensors: [CameraSensorPreset] = [
        CameraSensorPreset(id: "m3e", name: "DJI Mavic 3E (4/3\" 20MP, 24mm eq)", sensorWidthMM: 17.3, sensorHeightMM: 13.0, focalLengthMM: 12.3, imageWidthPx: 5280, imageHeightPx: 3956),
        CameraSensorPreset(id: "m3t", name: "DJI Mavic 3T (1/2\" 48MP Wide)", sensorWidthMM: 6.4, sensorHeightMM: 4.8, focalLengthMM: 4.5, imageWidthPx: 8000, imageHeightPx: 6000),
        CameraSensorPreset(id: "m2pro", name: "DJI Mavic 2 Pro (1\" Hasselblad 20MP)", sensorWidthMM: 13.2, sensorHeightMM: 8.8, focalLengthMM: 10.3, imageWidthPx: 5472, imageHeightPx: 3648),
        CameraSensorPreset(id: "p1", name: "Zenmuse P1 Full-Frame (35mm, 45MP)", sensorWidthMM: 35.9, sensorHeightMM: 24.0, focalLengthMM: 35.0, imageWidthPx: 8192, imageHeightPx: 5460)
    ]
    
    public static func compute(
        sensor: CameraSensorPreset,
        altitudeAGLMeters: Double,
        frontOverlapPercent: Double,
        sideOverlapPercent: Double,
        cruiseSpeedMps: Double,
        areaHectares: Double,
        isCrosshatch: Bool
    ) -> PhotogrammetryResult {
        // GSD formula: (SensorWidth_mm * Altitude_m * 100) / (FocalLength_mm * ImageWidth_px)
        let gsd = (sensor.sensorWidthMM * altitudeAGLMeters * 100.0) / (sensor.focalLengthMM * sensor.imageWidthPx)
        
        let footprintW = (sensor.sensorWidthMM * altitudeAGLMeters) / sensor.focalLengthMM
        let footprintH = (sensor.sensorHeightMM * altitudeAGLMeters) / sensor.focalLengthMM
        
        let photoSpacing = footprintH * (1.0 - (frontOverlapPercent / 100.0))
        let lineSpacing = footprintW * (1.0 - (sideOverlapPercent / 100.0))
        
        let areaSqMeters = areaHectares * 10000.0
        let totalFlightDistance = (areaSqMeters / max(lineSpacing, 1.0)) * 1.15
        
        var photos = Int(round(totalFlightDistance / max(photoSpacing, 4.0)))
        if isCrosshatch {
            photos = Int(Double(photos) * 1.85)
        }
        
        let flightTimeSec = Int(totalFlightDistance / max(cruiseSpeedMps, 1.0)) + Int(Double(photos) * 0.4)
        
        return PhotogrammetryResult(
            gsdCentimetersPerPixel: gsd,
            groundFootprintWidthMeters: footprintW,
            groundFootprintHeightMeters: footprintH,
            photoSpacingMeters: photoSpacing,
            flightLineSpacingMeters: lineSpacing,
            estimatedPhotoCount: photos,
            estimatedFlightTimeSeconds: flightTimeSec,
            coverageAreaHectares: areaHectares
        )
    }
}
