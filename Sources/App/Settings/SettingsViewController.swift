import Eureka
import Shared

class SettingsViewController: HAFormViewController {
    struct ContentSection: OptionSet, ExpressibleByIntegerLiteral {
        let rawValue: Int
        init(rawValue: Int) { self.rawValue = rawValue }
        init(integerLiteral value: IntegerLiteralType) { self.init(rawValue: value) }

        static var servers: ContentSection = 0b1
        static var general: ContentSection = 0b10
        static var integrations: ContentSection = 0b100
        static var help: ContentSection = 0b1000
        static var all = ContentSection(rawValue: ~0b0)
    }

    let contentSections: ContentSection
    init(contentSections: ContentSection = .all) {
        self.contentSections = contentSections
        super.init()
    }

    class func serversContents() -> [BaseRow] {
        var rows = [BaseRow]()

        for connection in [Current.apiConnection] {
            rows.append(HomeAssistantAccountRow {
                $0.value = .init(
                    connection: connection,
                    locationName: prefs.string(forKey: "location_name")
                )
                $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                    ConnectionSettingsViewController(connection: connection)
                }, onDismiss: nil)
            })
        }

        rows.append(HomeAssistantAccountRow {
            $0.hidden = .isNotDebug
            $0.presentationMode = .show(controllerProvider: .callback(builder: { () -> UIViewController in
                fatalError()
            }), onDismiss: nil)
        })

        return rows
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Settings.NavigationBar.title

        if !Current.isCatalyst {
            // About is in the Application menu on Catalyst, and closing the button is direct
            navigationItem.leftBarButtonItems = [
                UIBarButtonItem(
                    title: L10n.Settings.NavigationBar.AboutButton.title,
                    style: .plain,
                    target: self,
                    action: #selector(openAbout(_:))
                ),
            ]
        }

        if !Current.sceneManager.supportsMultipleScenes || !Current.isCatalyst {
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(
                    barButtonSystemItem: .done,
                    target: self,
                    action: #selector(closeSettings(_:))
                ),
            ]
        }

        if contentSections.contains(.servers) {
            form +++ Section(Self.serversContents())
        }

        if contentSections.contains(.general) {
            form +++ Section()
                <<< SettingsRootDataSource.Row.general.row
                <<< SettingsRootDataSource.Row.location.row
                <<< SettingsRootDataSource.Row.notifications.row
        }

        if contentSections.contains(.integrations) {
            form +++ Section()
                <<< SettingsRootDataSource.Row.actions.row
                <<< SettingsRootDataSource.Row.sensors.row
                <<< SettingsRootDataSource.Row.complications.row
                <<< SettingsRootDataSource.Row.nfc.row
        }

        if contentSections.contains(.help) {
            form +++ Section()
                <<< SettingsRootDataSource.Row.help.row
                <<< SettingsRootDataSource.Row.privacy.row
                <<< SettingsRootDataSource.Row.debugging.row
        }
    }

    @objc func openAbout(_ sender: UIButton) {
        let aboutView = AboutViewController()

        let navController = UINavigationController(rootViewController: aboutView)
        show(navController, sender: nil)
    }

    @objc func closeSettings(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
