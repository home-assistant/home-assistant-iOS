//
//  ComplicationController.swift
//  WatchApp Extension
//
//  Created by Robert Trencheny on 9/24/18.
//  Copyright © 2018 Robbie Trencheny. All rights reserved.
//

import ClockKit
import RealmSwift
import Shared

class ComplicationController: NSObject, CLKComplicationDataSource {

    // Helpful resources
    // https://github.com/LoopKit/Loop/issues/816
    // https://crunchybagel.com/detecting-which-complication-was-tapped/

    private func template(for complication: CLKComplication) -> CLKComplicationTemplate? {
        Iconic.registerMaterialDesignIcons()

        let model: WatchComplication?

        if #available(watchOS 7, *), complication.identifier != CLKDefaultComplicationIdentifier {
            // existing complications that were configured pre-7 have no identifier set
            // so we can only access the value if it's a valid one. otherwise, fall back to old matching behavior.
            model = Current.realm().object(ofType: WatchComplication.self, forPrimaryKey: complication.identifier)
        } else {
            // we migrate pre-existing complications, and when still using watchOS 6 create new ones,
            // with the family as the identifier, so we can rely on this code path for older OS and older complications
            let matchedFamily = ComplicationGroupMember(family: complication.family)
            model = Current.realm().object(ofType: WatchComplication.self, forPrimaryKey: matchedFamily.rawValue)
        }

        return model?.CLKComplicationTemplate(family: complication.family)
    }

    // MARK: - Timeline Configuration

    func getPrivacyBehavior(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void
    ) {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        Current.Log.verbose {
            if #available(watchOS 7, *) {
                return "Providing template for \(complication.identifier) family \(complication.family.description)"
            } else {
                return "Providing template for \(complication.family.description)"
            }
        }

        let template: CLKComplicationTemplate

        if let fromComplication = self.template(for: complication) {
            template = fromComplication
        } else {
            Current.Log.error("failed to get template, providing error")
            template = ComplicationGroupMember(family: complication.family).errorTemplate
        }

        let date = Date().encodedForComplication(family: complication.family) ?? Date()
        handler(.init(date: date, complicationTemplate: template))
    }

    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        handler(template(for: complication))
    }

    // MARK: - Complication Descriptors

    @available(watchOS 7.0, *)
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        handler(Current.realm().objects(WatchComplication.self).map(\.complicationDescriptor))
    }
}

extension CLKComplicationFamily {
    var description: String {
        switch self {
        case .circularSmall:
            return "Circular Small"
        case .extraLarge:
            return "Extra Large"
        case .graphicBezel:
            return "Graphic Bezel"
        case .graphicCircular:
            return "Graphic Circular"
        case .graphicCorner:
            return "Graphic Corner"
        case .graphicRectangular:
            return "Graphic Rectangular"
        case .modularLarge:
            return "Modular Large"
        case .modularSmall:
            return "Modular Small"
        case .utilitarianLarge:
            return "Utilitarian Large"
        case .utilitarianSmall:
            return "Utilitarian Small"
        case .utilitarianSmallFlat:
            return "Utilitarian Small Flat"
        default:
            return "unknown"
        }
    }
}
