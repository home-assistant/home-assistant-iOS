import Intents
import Shared
import SwiftUI
import WidgetKit

struct WidgetActions: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: WidgetActionsIntent.widgetKind,
            intent: WidgetActionsIntent.self,
            provider: WidgetActionsProvider(),
            content: { WidgetActionsContainerView(entry: $0) }
        )
        .configurationDisplayName(L10n.Widgets.Actions.title)
        .description(L10n.Widgets.Actions.description)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
