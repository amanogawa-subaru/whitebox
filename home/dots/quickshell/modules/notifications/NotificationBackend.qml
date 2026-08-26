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
