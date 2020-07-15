import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    func toArray() -> [Double] {
        return [self.latitude, self.longitude]
    }

    func moving(
        distance: Measurement<UnitLength>,
        direction: Measurement<UnitAngle>
    ) -> CLLocationCoordinate2D {
        let latitudeMeasurement: Measurement<UnitAngle> = .init(value: latitude, unit: .degrees)
        let longitudeMeasurement: Measurement<UnitAngle> = .init(value: longitude, unit: .degrees)
        let earthRadius: Measurement<UnitLength> = .init(value: 6_371_000, unit: .meters)

        // sinφ2 = sinφ1⋅cosδ + cosφ1⋅sinδ⋅cosθ
        // tanΔλ = sinθ⋅sinδ⋅cosφ1 / cosδ−sinφ1⋅sinφ2
        // see mathforum.org/library/drmath/view/52049.html for derivation
        // https://www.movable-type.co.uk/scripts/latlong.html

        let θ = direction.converted(to: .radians).value
        let δ = distance.converted(to: .meters).value / earthRadius.converted(to: .meters).value
        let φ1 = latitudeMeasurement.converted(to: .radians).value
        let λ1 = longitudeMeasurement.converted(to: .radians).value

        // everything in here is now in radians

        let sinφ2 = sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ)
        let φ2 = asin(sinφ2)
        let y = sin(θ) * sin(δ) * cos(φ1)
        let x = cos(δ) - sin(φ1) * sinφ2
        let λ2 = λ1 + atan2(y, x)

        let resultLatitudeMeasurement: Measurement<UnitAngle> = .init(value: φ2, unit: .radians)
        let resultLongitudeMeasurement: Measurement<UnitAngle> = .init(value: λ2, unit: .radians)

        return .init(
            latitude: resultLatitudeMeasurement.converted(to: .degrees).value,
            longitude: resultLongitudeMeasurement.converted(to: .degrees).value
        )
    }
}
