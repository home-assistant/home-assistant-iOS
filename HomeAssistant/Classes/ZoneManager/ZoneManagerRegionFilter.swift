import Foundation
import CoreLocation
import Shared

protocol ZoneManagerRegionFilter {
    func regions(for zones: AnySequence<RLMZone>, lastLocation: CLLocation?) -> Set<CLRegion>
}

class ZoneManagerRegionFilterImpl: ZoneManagerRegionFilter {
    struct Counts: Comparable {
        var beacon: Int
        var circular: Int

        static func < (lhs: Counts, rhs: Counts) -> Bool {
            lhs.beacon < rhs.beacon && lhs.circular < rhs.circular
        }

        init(beacon: Int, circular: Int) {
            self.beacon = beacon
            self.circular = circular
        }

        init<T: Sequence>(_ sequence: T) where T.Element == CLRegion {
            let counts = sequence.reduce(into: (beacon: 0, circular: 0)) { counts, region in
                if region is CLCircularRegion {
                    counts.circular += 1
                } else if region is CLBeaconRegion {
                    counts.beacon += 1
                } else {
                    // what is it like in the future?
                    Current.Log.error("unknown region type: \(type(of: region))")
                }
            }

            self.beacon = counts.beacon
            self.circular = counts.circular
        }

        func shouldReduce(option: Self, comparedTo limit: Self) -> Bool {
            if option.beacon > 0, limit.beacon < beacon {
                return true
            }

            if option.circular > 0, limit.circular < circular {
                return true
            }

            return false
        }

        var eventPayload: [String: String] { [
            "beacon": String(beacon),
            "circular": String(circular)
        ] }
    }

    let limits: Counts

    init(limits: Counts = Counts(beacon: 20, circular: 20)) {
        self.limits = limits
    }

    func regions(for zones: AnySequence<RLMZone>, lastLocation: CLLocation?) -> Set<CLRegion> {
        var segmented = Dictionary(uniqueKeysWithValues: zones.map { ($0, $0.regionsForMonitoring) })

        let startRegions = segmented.values.flatMap({ $0 })
        let startCounts = Counts(startRegions)

        if startCounts < limits {
            // We're starting out with a small enough count
            return Set(startRegions)
        }

        // We've exceeded the limit, so we need to start reducing.
        // We aim to clip off the ones that are further away.
        let sourceLocation = lastLocation ?? zones.first(where: \.isHome)?.location

        let sorted = segmented.sorted { lhs, rhs in
            if let sourceLocation = sourceLocation {
                // We have a location to compare against, so do distance
                return lhs.key.location.distance(from: sourceLocation) < rhs.key.location.distance(from: sourceLocation)
            } else {
                // We have neither a location nor a home zone, so just like...strip the bigger ones?
                return lhs.key.Radius < rhs.key.Radius
            }
        }

        // just used for logging
        var strippedZones = [RLMZone]()

        for option in sorted.reversed() {
            let currentCount = Counts(segmented.values.flatMap { $0 })
            let optionCount = Counts(option.value)

            if currentCount.shouldReduce(option: optionCount, comparedTo: limits) {
                // We strip off entire zones at a time if they contain any region which exceeds the count.
                strippedZones.append(option.key)
                segmented[option.key] = nil
            }
        }

        logError(counts: startCounts, allZones: Array(zones), strippedZones: strippedZones)

        return Set(segmented.values.flatMap { $0 })
    }

    private func logError(counts: Counts, allZones: [RLMZone], strippedZones: [RLMZone]) {
        Current.logError?(ReportedError(
            code: .exceededRegionCount,
            regionCount: (beacon: counts.beacon, circular: counts.circular, zone: allZones.count)
        ).asNsError())

        Current.clientEventStore.addEvent(ClientEvent(
            text: "Exceeded maximum monitored regions",
            type: .locationUpdate, payload: [
                "counts": counts.eventPayload,
                "limits": limits.eventPayload,
                "total_zones": allZones.count,
                "stripped_zones": strippedZones.map { $0.ID }
            ]
        ))
    }
}

private struct ReportedError {
    enum Code: Int {
        case exceededRegionCount = 0
    }

    private static let domain = "ZoneManagerRegionFilterError"

    let code: Code
    // swiftlint:disable:next large_tuple
    let regionCount: (beacon: Int, circular: Int, zone: Int)

    func asNsError() -> NSError {
        return NSError(domain: Self.domain, code: code.rawValue, userInfo: [
            "count_beacon": regionCount.beacon,
            "count_circular": regionCount.circular,
            "count_zone": regionCount.zone
        ])
    }
}
