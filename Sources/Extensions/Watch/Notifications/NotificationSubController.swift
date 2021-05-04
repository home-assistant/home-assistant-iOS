import PromiseKit
import UserNotifications
import WatchKit

struct NotificationElements {
    var image: WKInterfaceImage
    var map: WKInterfaceMap
    var movie: WKInterfaceInlineMovie

    func hide() {
        image.setHidden(true)
        map.setHidden(true)
        movie.setHidden(true)
    }
}

protocol NotificationSubController: AnyObject {
    init?(notification: UNNotification)
    init?(url: URL)
    func start(with elements: NotificationElements) -> Promise<Void>
    func stop()
}
