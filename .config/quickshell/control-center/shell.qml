import Quickshell
import "personalize" as Personalize
import "monitors" as Monitors
import "bar" as DesktopBar

ShellRoot {
    readonly property var notificationService: Notifications
    DeviceWatcher {}
    Variants {
        model: Quickshell.screens
        delegate: Monitors.DisplayWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: PowerMenu {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: DesktopBar.WorkspaceOverview {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: DesktopBar.CommandsWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: DesktopBar.BarWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: DesktopBar.CalendarWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: ControlWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: OsdWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: NotificationWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Personalize.PersonalizeWindow {
            required property var modelData
            screen: modelData
            outputName: modelData.name
        }
    }
}
