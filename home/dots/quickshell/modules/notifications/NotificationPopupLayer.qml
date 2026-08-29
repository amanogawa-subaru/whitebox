import QtQuick
import Quickshell

import "../../Config"

Scope {
    id: root

    required property var backend
    required property var anchorItem

    property color accentColor:
        Colors.sapphire

    // ═════════════════════════════════════════
    // Popup geometry
    // ═════════════════════════════════════════

    /*
     * Width of the actual visible notification
     * card.
     */
    property real popupWidth:
        340 * Appearance.scale

    /*
     * Transparent space surrounding the cards.
     *
     * The cards scale beyond popupWidth during
     * their bounce animation. Because PopupWindow
     * is a real native surface, anything outside
     * its bounds gets clipped.
     *
     * This padding gives the bounce room to render.
     */
    property real bouncePadding:
        24 * Appearance.scale

    property real popupSpacing:
        10 * Appearance.scale

    property int maximumPopups:
        4

    /*
     * Source data.
     *
     * ScriptModel sits between this JS array and
     * the Repeater so unchanged delegates remain
     * alive when another notification arrives.
     */
    property var popupEntries:
        []

    // ═════════════════════════════════════════
    // Stable popup model
    // ═════════════════════════════════════════

    ScriptModel {
        id: popupModel

        values:
            root.popupEntries

        objectProp:
            "notificationId"
    }

    // ═════════════════════════════════════════
    // Helpers
    // ═════════════════════════════════════════

    function containsNotificationId(notificationId) {
        for (
            let i = 0;
            i < root.popupEntries.length;
            ++i
        ) {
            if (
                root.popupEntries[i].notificationId
                === notificationId
            ) {
                return true
            }
        }

        return false
    }

    function addNotification(notification) {
        if (
            !notification
            || root.backend.doNotDisturb
        ) {
            return
        }

        /*
         * Capture the ID while the Notification
         * object is definitely alive.
         */
        const notificationId =
            notification.id

        if (
            root.containsNotificationId(
                notificationId
            )
        ) {
            return
        }

        const next =
            root.popupEntries.slice()

        /*
         * Newest notification at the top.
         */
        next.unshift({
            notification:
                notification,

            notificationId:
                notificationId
        })

        /*
         * Cap only the transient popup stack.
         *
         * Older notifications remain available
         * in notification history.
         */
        if (
            next.length
            > root.maximumPopups
        ) {
            next.pop()
        }

        root.popupEntries =
            next

        if (popupWindow.anchor)
            popupWindow.anchor.updateAnchor()
    }

    function removeNotificationById(notificationId) {
        const next = []

        for (
            let i = 0;
            i < root.popupEntries.length;
            ++i
        ) {
            const entry =
                root.popupEntries[i]

            /*
             * Compare only our safe copied ID.
             *
             * Do not inspect entry.notification
             * during cleanup.
             */
            if (
                entry.notificationId
                !== notificationId
            ) {
                next.push(
                    entry
                )
            }
        }

        root.popupEntries =
            next
    }

    function clearPopups() {
        root.popupEntries =
            []
    }

    // ═════════════════════════════════════════
    // Backend
    // ═════════════════════════════════════════

    Connections {
        target:
            root.backend

        function onNotificationReceived(notification) {
            root.addNotification(
                notification
            )
        }

        function onDoNotDisturbChanged() {
            /*
             * Preserve our current DND behavior:
             *
             * notifications still enter history,
             * but transient popups are suppressed.
             */
            if (
                root.backend
                && root.backend.doNotDisturb
            ) {
                root.clearPopups()
            }
        }
    }

    // ═════════════════════════════════════════
    // Popup window
    // ═════════════════════════════════════════

    PopupWindow {
        id: popupWindow

        /*
         * A closing popup remains in popupModel
         * until its bounce-out has completely
         * finished.
         *
         * Therefore even the last notification
         * keeps this window alive for its entire
         * exit animation.
         */
        visible:
            root.popupEntries.length > 0
            && root.backend
            && !root.backend.doNotDisturb

        color:
            "transparent"

        /*
         * IMPORTANT:
         *
         * The native surface is wider than the
         * actual notification card.
         *
         * The extra transparent area on both sides
         * prevents the 1.08 / 1.07 bounce scales
         * from being clipped by the PopupWindow.
         */
        implicitWidth:
            root.popupWidth
            + root.bouncePadding * 2

        /*
         * Vertical padding is included too.
         *
         * Our popup scales around its center, so
         * the bounce also extends slightly above
         * and below its normal bounds.
         */
        implicitHeight:
            Math.max(
                1,
                popupColumn.implicitHeight
                + root.bouncePadding * 2
            )

        // ═════════════════════════════════════
        // Anchor
        // ═════════════════════════════════════

        anchor {
            item:
                root.anchorItem

            /*
             * Compensate for the transparent
             * padding added to the right side of
             * the card.
             *
             * This keeps the VISIBLE card in the
             * same resting position it had before
             * the PopupWindow became wider.
             */
            rect.x:
                root.anchorItem
                    ? root.anchorItem.width
                      + root.bouncePadding
                    : 0

            rect.y:
                root.anchorItem
                    ? root.anchorItem.height
                        + 10 * Appearance.scale
                    : 0

            rect.width:
                1

            rect.height:
                1

            edges:
                Edges.Top
                | Edges.Left

            gravity:
                Edges.Bottom
                | Edges.Left
        }

        // ═════════════════════════════════════
        // Popup stack
        // ═════════════════════════════════════

        Column {
            id: popupColumn

            /*
             * The Column itself remains exactly
             * popupWidth wide.
             *
             * Only the surrounding native window
             * has grown.
             */
            width:
                root.popupWidth

            /*
             * Centering gives every card exactly
             * bouncePadding worth of transparent
             * rendering space on both sides.
             */
            anchors {
                horizontalCenter:
                    parent.horizontalCenter

                top:
                    parent.top

                topMargin:
                    root.bouncePadding
            }

            spacing:
                root.popupSpacing

            Repeater {
                id: popupRepeater

                model:
                    popupModel

                delegate: NotificationPopup {
                    required property var modelData

                    /*
                     * Explicit card width.
                     *
                     * Do NOT use popupWindow.width
                     * here. The extra width belongs
                     * only to the transparent bounce
                     * canvas.
                     */
                    width:
                        root.popupWidth

                    backend:
                        root.backend

                    notification:
                        modelData.notification

                    notificationId:
                        modelData.notificationId

                    accentColor:
                        root.accentColor

                    /*
                     * NotificationPopup emits this
                     * only AFTER its complete
                     * bounce-out animation.
                     */
                    onRemovalRequested:
                        notificationId => {
                            root.removeNotificationById(
                                notificationId
                            )
                        }
                }
            }
        }
    }
}
