import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool doNotDisturb: false

    /*
     * Emitted only for genuinely NEW notifications.
     *
     * NotificationModule uses this for its bounce.
     * Later, NotificationPopupLayer can use the
     * exact same signal for popup toasts.
     */
    signal notificationReceived(var notification)
    signal notificationActivated()

    property alias server:
        notificationServer

    readonly property int count:
        notificationServer.trackedNotifications.values.length

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false

        actionsSupported: true
        actionIconsSupported: false

        imageSupported: true
        bodyImagesSupported: false

        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            /*
             * Keep it in notification history.
             */
            notification.tracked = true

            /*
             * keepOnReload causes existing tracked
             * notifications to be re-emitted when
             * Quickshell reloads.
             *
             * lastGeneration lets us distinguish
             * those from genuinely new arrivals.
             */
            if (!notification.lastGeneration) {
                root.notificationReceived(
                    notification
                )
            }
        }
    }


    function activate(notification) {
        if (!notification)
            return

        /*
         * Capture identifying metadata BEFORE invoking the
         * notification action. Some applications dismiss or
         * invalidate their notification immediately when the
         * default action is invoked.
         */
        const windowClass =
            notification.desktopEntry

        /*
         * Let the application handle its own
         * notification-specific action first.
         */
        const actions =
            notification.actions

        for (
            let i = 0;
            i < actions.length;
            ++i
        ) {
            const action =
                actions[i]

            if (
                action.identifier
                === "default"
            ) {
                action.invoke()
                break
            }
        }

        /*
         * Then focus the originating Hyprland window.
         * The tested desktop-entry IDs match the actual
         * Hyprland classes for Firefox and qBittorrent.
         */
        if (windowClass) {
            Quickshell.execDetached([
                "hyprctl",
                "dispatch",
                "hl.dsp.focus({ window = \"class:^"
                    + windowClass
                    + "$\" })"
            ])
        }

        root.notificationActivated()
    }

    function dismiss(notification) {
        if (notification)
            notification.dismiss()
    }

    function clearAll() {
        const notifications =
            notificationServer
                .trackedNotifications
                .values

        /*
         * Iterate backwards because dismiss()
         * mutates the tracked model.
         */
        for (
            let i = notifications.length - 1;
            i >= 0;
            --i
        ) {
            const notification =
                notifications[i]

            if (notification)
                notification.dismiss()
        }
    }

    function toggleDnd() {
        root.doNotDisturb =
            !root.doNotDisturb
    }
}
