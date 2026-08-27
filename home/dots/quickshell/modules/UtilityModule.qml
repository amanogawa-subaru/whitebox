import QtQuick
import Quickshell
import Quickshell.Io

import "../Config"

FocusScope {
    id: root

    required property var backend

    // ═════════════════════════════════════════
    // Public state
    // ═════════════════════════════════════════

    property bool expanded:
        false

    property bool closing:
        false

    property bool shrinking:
        false

    property bool collapseBase:
        false

    /*
     * During close, the expanded header disappears
     * while the base wipe rises. Once the wipe has
     * completed, the same header contents return in
     * compact colors before geometry shrinks.
     */
    property bool compactHeaderMode:
        false

    /*
     * Locking is deferred until the normal close
     * choreography has fully completed. This avoids
     * Hyprlock freezing Quickshell while width/height
     * Behaviors are still mid-shrink.
     */
    property bool lockPending:
        false

    property bool suppressHover:
        false

    property string activeTab:
        ""

    property string hoveredTab:
        ""

    property alias notificationAnchor:
        notificationButton

    /*
     * Exposed to shell.qml so the focus grab can
     * distinguish a tray menu from an actual
     * click outside.
     */
    readonly property bool systrayMenuGrace:
        systrayModule.menuGraceActive


    // ═════════════════════════════════════════
    // Hover
    // ═════════════════════════════════════════

    readonly property bool hovered:
        (
            utilityMouse.containsMouse
            || systrayModule.hovered
            || clipboardButton.hovered
            || notificationButton.hovered
            || powerButton.hovered
        )
        && !root.suppressHover

    readonly property int notificationCount:
        root.backend
            ? root.backend.count
            : 0


    // ═════════════════════════════════════════
    // Design
    // ═════════════════════════════════════════

    property color clipboardAccent:
        Colors.pink

    property color notificationAccent:
        Colors.sapphire

    property color powerAccent:
        Colors.red

    property color neutralIconColor:
        Colors.subtext0

    property real closeBounceScale:
        1.0

    readonly property color activeAccent: {
        if (root.activeTab === "clipboard")
            return root.clipboardAccent

        if (root.activeTab === "notifications")
            return root.notificationAccent

        if (root.activeTab === "power")
            return root.powerAccent

        return Colors.mauve
    }

    readonly property color displayedAccent: {
        if (!root.expanded) {
            if (root.hoveredTab === "clipboard")
                return root.clipboardAccent

            if (root.hoveredTab === "notifications")
                return root.notificationAccent

            if (root.hoveredTab === "power")
                return root.powerAccent

            return Colors.mauve
        }

        return root.activeAccent
    }

    property real tabWidth:
        Appearance.moduleHeight

    property real expandedWidth:
        Appearance.powerExpandedWidth
    readonly property real headerHeight:
        Appearance.moduleHeight

    property real closeFillTop:
        root.headerHeight

    readonly property real compactWidth:
        systrayModule.width
        + root.tabWidth * 3

    readonly property real contentHeight: {
        if (root.activeTab === "notifications")
            return notificationModule.implicitHeight

        if (root.activeTab === "power")
            return powerModule.implicitHeight

        if (root.activeTab === "clipboard")
            return clipboardModule.implicitHeight

        return 0
    }

    readonly property real expandedHeight:
        root.headerHeight
        + Appearance.borderWidth
        + root.contentHeight


    // ═════════════════════════════════════════
    // Tabs
    // ═════════════════════════════════════════

    function openTab(tab) {
        closeAnimation.stop()

        root.suppressHover =
            false

        root.closing =
            false

        root.shrinking =
            false

        root.closeBounceScale =
            1.0

        root.collapseBase =
            false

        root.compactHeaderMode =
            false

        header.opacity =
            1.0

        root.closeFillTop =
            root.headerHeight

        if (root.expanded) {
            if (root.activeTab === tab) {
                root.close()
                return
            }

            root.activeTab =
                tab

            root.forceActiveFocus()

            return
        }

        root.activeTab =
            tab

        root.expanded =
            true

        focusDelay.restart()
    }

    function close() {
        if (
            !root.expanded
            || root.closing
        ) {
            return
        }

        root.closing =
            true

        root.shrinking =
            false

        root.closeBounceScale =
            1.0

        root.collapseBase =
            false

        root.compactHeaderMode =
            false

        header.opacity =
            1.0

        root.closeFillTop =
            root.headerHeight

        closeAnimation.restart()
    }

    function closeImmediately() {
        closeAnimation.stop()

        root.expanded =
            false

        root.closing =
            false

        root.shrinking =
            false

        root.activeTab =
            ""

        root.hoveredTab =
            ""

        root.closeBounceScale =
            1.0

        root.collapseBase =
            false

        root.closeFillTop =
            root.headerHeight

        root.suppressHover =
            true
    }

    function openClipboard() {
        root.openTab(
            "clipboard"
        )
    }

    function openNotifications() {
        root.openTab(
            "notifications"
        )
    }

    function openPower() {
        root.openTab(
            "power"
        )
    }


    // ═════════════════════════════════════════
    // Lock
    // ═════════════════════════════════════════

    function lockSession() {
        if (root.lockPending)
            return

        root.lockPending =
            true

        /*
         * Let UtilityModule finish the exact same
         * close animation used everywhere else.
         * Hyprlock is launched by closeAnimation's
         * completion handler below.
         */
        if (root.expanded) {
            root.close()
            return
        }

        lockDelay.restart()
    }

    Process {
        id: lockProcess

        command: [
            "hyprlock"
        ]
    }

    Timer {
        id: lockDelay

        interval:
            30

        repeat:
            false

        onTriggered: {
            root.lockPending =
                false

            lockProcess.running =
                true
        }
    }


    // ═════════════════════════════════════════
    // Notification bounce
    // ═════════════════════════════════════════

    property real notificationBounce:
        1.0

    Connections {
        target:
            root.backend

        function onNotificationReceived(notification) {
            notificationBounceAnimation.restart()
        }
    }

    SequentialAnimation {
        id: notificationBounceAnimation

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            from:
                1.0

            to:
                1.18

            duration:
                90

            easing.type:
                Easing.OutCubic
        }

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            to:
                0.94

            duration:
                90

            easing.type:
                Easing.InOutCubic
        }

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            to:
                1.08

            duration:
                110

            easing.type:
                Easing.OutCubic
        }

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            to:
                1.0

            duration:
                140

            easing.type:
                Easing.OutCubic
        }
    }


    // ═════════════════════════════════════════
    // Keyboard
    // ═════════════════════════════════════════

    Keys.onEscapePressed: event => {
        if (root.expanded) {
            root.close()

            event.accepted =
                true
        }
    }


    // ═════════════════════════════════════════
    // Geometry
    // ═════════════════════════════════════════

    width:
        root.expanded
        && !root.shrinking
            ? root.expandedWidth
            : root.compactWidth

    height:
        root.expanded
        && !root.shrinking
            ? root.expandedHeight
            : Appearance.moduleHeight

    Behavior on width {
        NumberAnimation {
            duration:
                280

            easing.type:
                Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration:
                280

            easing.type:
                Easing.OutCubic
        }
    }


    // ═════════════════════════════════════════
    // Visual root
    // ═════════════════════════════════════════

    Item {
        id: visualRoot

        anchors.fill:
            parent

        scale: {
            /*
             * Close choreography has priority.
             */
            if (root.closing)
                return root.closeBounceScale

            /*
             * Whole collapsed module swell.
             */
            if (
                root.hovered
                && !root.expanded
            ) {
                return 1.06
            }

            return 1.0
        }

        transformOrigin:
            Item.Center

        Behavior on scale {
            enabled:
                !root.closing

            NumberAnimation {
                duration:
                    300

                easing.type:
                    Easing.OutBack

                easing.overshoot:
                    1.9
            }
        }


        // ─────────────────────────────────────
        // Outer shell
        // ─────────────────────────────────────

        Rectangle {
            anchors.fill:
                parent

            radius:
                Appearance.moduleRadius

            border.width:
                Appearance.borderWidth

            border.color:
                root.displayedAccent

            color: {
                if (
                    !root.expanded
                    && root.hoveredTab !== ""
                ) {
                    return root.displayedAccent
                }

                if (root.collapseBase)
                    return Colors.base

                if (root.expanded)
                    return root.activeAccent

                return Colors.base
            }

            Behavior on color {
                ColorAnimation {
                    duration:
                        150
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration:
                        150
                }
            }
        }


        // ═════════════════════════════════════
        // Header
        // ═════════════════════════════════════

        Item {
            id: header

            z:
                10

            width:
                parent.width

            height:
                root.headerHeight

            opacity:
                1.0


            SystrayModule {
                id: systrayModule

                anchors {
                    left:
                        parent.left

                    top:
                        parent.top
                }

                height:
                    Appearance.moduleHeight

                embedded:
                    true
            }


            Row {
                anchors {
                    right:
                        parent.right

                    top:
                        parent.top
                }

                height:
                    Appearance.moduleHeight


                UtilityTabButton {
                    id: clipboardButton

                    width:
                        root.tabWidth

                    height:
                        parent.height

                    tabName:
                        "clipboard"

                    icon:
                        "󰅇"

                    accent:
                        root.clipboardAccent

                    neutralColor:
                        root.neutralIconColor

                    active:
                        root.activeTab
                        === "clipboard"

                    sharedExpanded:
                        root.expanded
                        && !root.compactHeaderMode

                    sharedHoveredTab:
                        root.hoveredTab

                    onHoveredChanged: {
                        if (hovered) {
                            root.suppressHover =
                                false

                            root.hoveredTab =
                                "clipboard"
                        } else if (
                            root.hoveredTab
                            === "clipboard"
                        ) {
                            root.hoveredTab =
                                ""
                        }
                    }

                    onClicked:
                        root.openTab(
                            "clipboard"
                        )
                }


                UtilityTabButton {
                    id: notificationButton

                    width:
                        root.tabWidth

                    height:
                        parent.height

                    tabName:
                        "notifications"

                    icon:
                        root.backend
                        && root.backend.doNotDisturb
                            ? "󰂛"
                            : (
                                root.notificationCount > 0
                                    ? "󰂞"
                                    : "󰂚"
                            )

                    accent:
                        root.notificationAccent

                    neutralColor:
                        root.neutralIconColor

                    active:
                        root.activeTab
                        === "notifications"

                    sharedExpanded:
                        root.expanded
                        && !root.compactHeaderMode

                    sharedHoveredTab:
                        root.hoveredTab

                    extraScale:
                        root.notificationBounce

                    badgeCount:
                        root.notificationCount

                    onHoveredChanged: {
                        if (hovered) {
                            root.suppressHover =
                                false

                            root.hoveredTab =
                                "notifications"
                        } else if (
                            root.hoveredTab
                            === "notifications"
                        ) {
                            root.hoveredTab =
                                ""
                        }
                    }

                    onClicked:
                        root.openTab(
                            "notifications"
                        )
                }


                UtilityTabButton {
                    id: powerButton

                    width:
                        root.tabWidth

                    height:
                        parent.height

                    tabName:
                        "power"

                    icon:
                        "󰐥"

                    accent:
                        root.powerAccent

                    neutralColor:
                        root.neutralIconColor

                    active:
                        root.activeTab
                        === "power"

                    sharedExpanded:
                        root.expanded
                        && !root.compactHeaderMode

                    sharedHoveredTab:
                        root.hoveredTab

                    onHoveredChanged: {
                        if (hovered) {
                            root.suppressHover =
                                false

                            root.hoveredTab =
                                "power"
                        } else if (
                            root.hoveredTab
                            === "power"
                        ) {
                            root.hoveredTab =
                                ""
                        }
                    }

                    onClicked:
                        root.openTab(
                            "power"
                        )
                }
            }

        }


        // ═════════════════════════════════════
        // Expanded body
        // ═════════════════════════════════════

        Rectangle {
            id: body

            // Keep the base body alive during the close shrink.
            // As the module height contracts, this lets the base-colored
            // body disappear upward naturally instead of exposing the
            // accent-colored outer shell for a frame.
            visible:
                root.expanded

            x:
                Appearance.borderWidth

            y:
                root.headerHeight

            width:
                Math.max(
                    0,
                    parent.width
                    - Appearance.borderWidth * 2
                )

            height:
                Math.max(
                    0,
                    parent.height
                    - root.headerHeight
                    - Appearance.borderWidth
                )

            radius:
                Math.max(
                    0,
                    Appearance.moduleRadius
                    - Appearance.borderWidth
                )

            color:
                Colors.base

            clip:
                true


            Item {
                id: contentContainer

                anchors.fill:
                    parent

                opacity:
                    1.0


                ClipboardModule {
                    id: clipboardModule

                    visible:
                        root.activeTab
                        === "clipboard"

                    anchors {
                        left:
                            parent.left

                        right:
                            parent.right

                        top:
                            parent.top
                    }

                    accentColor:
                        root.clipboardAccent

                    onCloseRequested:
                        root.close()
                }


                NotificationModule {
                    id: notificationModule

                    visible:
                        root.activeTab
                        === "notifications"

                    anchors {
                        left:
                            parent.left

                        right:
                            parent.right

                        top:
                            parent.top
                    }

                    backend:
                        root.backend

                    accentColor:
                        root.notificationAccent

                    onCloseRequested:
                        root.close()
                }


                PowerModule {
                    id: powerModule

                    visible:
                        root.activeTab
                        === "power"

                    anchors {
                        left:
                            parent.left

                        right:
                            parent.right

                        top:
                            parent.top
                    }

                    accentColor:
                        root.powerAccent

                    onCloseRequested:
                        root.close()

                    onLockRequested:
                        root.lockSession()
                }
            }
        }

        // ═════════════════════════════════════
        // Closing base wipe
        //
        // Mirrors TimeModule: a dedicated base
        // layer grows upward over the active
        // accent before the module shrinks.
        // ═════════════════════════════════════

        Rectangle {
            id: closeFill

            z:
                5

            visible:
                root.closing

            x:
                Appearance.borderWidth

            y:
                root.closeFillTop

            width:
                Math.max(
                    0,
                    visualRoot.width
                    - Appearance.borderWidth * 2
                )

            height:
                Math.max(
                    0,
                    visualRoot.height
                    - root.closeFillTop
                    - Appearance.borderWidth
                )

            radius:
                Math.max(
                    0,
                    Appearance.moduleRadius
                    - Appearance.borderWidth
                )

            color:
                Colors.base
        }
    }


    // ═════════════════════════════════════════
    // Passive hover detector
    // ═════════════════════════════════════════

    MouseArea {
        id: utilityMouse

        anchors.fill:
            parent

        hoverEnabled:
            true

        acceptedButtons:
            Qt.NoButton

        z:
            -1

        onEntered:
            root.suppressHover = false

        onExited: {
            if (
                !clipboardButton.hovered
                && !notificationButton.hovered
                && !powerButton.hovered
            ) {
                root.hoveredTab =
                    ""
            }
        }
    }


    // ═════════════════════════════════════════
    // Focus
    // ═════════════════════════════════════════

    Timer {
        id: focusDelay

        interval:
            50

        repeat:
            false

        onTriggered:
            root.forceActiveFocus()
    }


    // ═════════════════════════════════════════
    // CLOSE CHOREOGRAPHY
    //
    // Same basic feel as the old standalone
    // modules:
    //
    // content fades
    // 1.0 -> .965 -> 1.075
    // shell shrinks
    // settles to 1.0
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: closeAnimation

        /*
         * Lock requests wait here instead of using a
         * hard-coded animation duration. By this point
         * the module is fully compact and all geometry
         * Behaviors have settled.
         */
        onFinished: {
            if (root.lockPending)
                lockDelay.restart()
        }

        // 1. Expanded content and expanded header disappear together.

        ParallelAnimation {
            NumberAnimation {
                target:
                    contentContainer

                property:
                    "opacity"

                to:
                    0.0

                duration:
                    90

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    header

                property:
                    "opacity"

                to:
                    0.0

                duration:
                    90

                easing.type:
                    Easing.OutCubic
            }
        }

        // 2. Base wipe + anticipation/pop.

        ParallelAnimation {
            NumberAnimation {
                target:
                    root

                property:
                    "closeFillTop"

                from:
                    root.headerHeight

                to:
                    Appearance.borderWidth

                duration:
                    260

                easing.type:
                    Easing.InOutCubic
            }

            SequentialAnimation {
                NumberAnimation {
                    target:
                        root

                    property:
                        "closeBounceScale"

                    from:
                        1.0

                    to:
                        0.965

                    duration:
                        70

                    easing.type:
                        Easing.InCubic
                }

                NumberAnimation {
                    target:
                        root

                    property:
                        "closeBounceScale"

                    from:
                        0.965

                    to:
                        1.075

                    duration:
                        190

                    easing.type:
                        Easing.OutBack

                    easing.overshoot:
                        1.45
                }
            }
        }

        // Base is fully established. Switch the header to compact colors.

        ScriptAction {
            script: {
                root.collapseBase =
                    true

                root.compactHeaderMode =
                    true
            }
        }

        // 3. Reveal compact header while the module
        //    immediately begins shrinking. This removes
        //    the visible "hang" between reveal and collapse.

        ParallelAnimation {
            NumberAnimation {
                target:
                    header

                property:
                    "opacity"

                from:
                    0.0

                to:
                    1.0

                duration:
                    95

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    root

                property:
                    "closeBounceScale"

                from:
                    1.075

                to:
                    1.0

                duration:
                    220

                easing.type:
                    Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation {
                    duration:
                        20
                }

                ScriptAction {
                    script: {
                        root.shrinking =
                            true
                    }
                }

                PauseAnimation {
                    duration:
                        200
                }
            }
        }

        // 4. Compact state.

        ScriptAction {
            script: {
                root.suppressHover =
                    true

                root.expanded =
                    false

                root.closing =
                    false

                root.shrinking =
                    false

                root.activeTab =
                    ""

                root.hoveredTab =
                    ""

                root.closeBounceScale =
                    1.0

                root.collapseBase =
                    true

                root.compactHeaderMode =
                    false

                root.closeFillTop =
                    root.headerHeight

                header.opacity =
                    1.0

                contentContainer.opacity =
                    1.0
            }
        }
    }


    // ═════════════════════════════════════════
    // Tab component
    // ═════════════════════════════════════════

    component UtilityTabButton: Item {
        id: tabRoot

        property string tabName:
            ""

        property string icon:
            ""

        property color accent:
            Colors.text

        property color neutralColor:
            Colors.subtext0

        property bool active:
            false

        property bool sharedExpanded:
            false

        property string sharedHoveredTab:
            ""

        property real extraScale:
            1.0

        property int badgeCount:
            0

        readonly property bool hovered:
            tabMouse.containsMouse

        readonly property bool anyTabHovered:
            tabRoot.sharedHoveredTab !== ""

        readonly property bool thisTabHovered:
            tabRoot.sharedHoveredTab
                === tabRoot.tabName
            || tabRoot.hovered

        signal clicked()


        Text {
            anchors.centerIn:
                parent

            text:
                tabRoot.icon

            font.family:
                "Symbols Nerd Font"

            font.pixelSize:
                Appearance.iconSize

            color: {
                // Collapsed

                if (!tabRoot.sharedExpanded) {
                    if (!tabRoot.anyTabHovered)
                        return tabRoot.accent

                    if (tabRoot.thisTabHovered)
                        return Colors.base

                    return tabRoot.neutralColor
                }


                // Expanded

                if (
                    tabRoot.active
                    && tabRoot.thisTabHovered
                ) {
                    return Colors.base
                }

                if (
                    tabRoot.thisTabHovered
                    && !tabRoot.active
                ) {
                    return Colors.base
                }

                if (tabRoot.anyTabHovered)
                    return tabRoot.neutralColor

                if (tabRoot.active)
                    return Colors.base

                return tabRoot.neutralColor
            }

            scale:
                (
                    tabRoot.thisTabHovered
                        ? 1.25
                        : 1.0
                )
                * tabRoot.extraScale

            Behavior on color {
                ColorAnimation {
                    duration:
                        150
                }
            }

            Behavior on scale {
                enabled:
                    tabRoot.extraScale
                    === 1.0

                NumberAnimation {
                    duration:
                        220

                    easing.type:
                        Easing.OutBack

                    easing.overshoot:
                        1.6
                }
            }
        }


        Rectangle {
            visible:
                tabRoot.badgeCount > 0

            anchors {
                right:
                    parent.right

                top:
                    parent.top

                rightMargin:
                    3 * Appearance.scale

                topMargin:
                    3 * Appearance.scale
            }

            width:
                14 * Appearance.scale

            height:
                width

            radius:
                width / 2

            color:
                tabRoot.sharedExpanded
                    ? Colors.base
                    : tabRoot.accent

            Text {
                anchors.centerIn:
                    parent

                text:
                    tabRoot.badgeCount > 9
                        ? "9+"
                        : tabRoot.badgeCount
                            .toString()

                color:
                    tabRoot.sharedExpanded
                        ? tabRoot.accent
                        : Colors.base

                font.pixelSize:
                    8 * Appearance.scale

                font.bold:
                    true
            }
        }


        MouseArea {
            id: tabMouse

            anchors.fill:
                parent

            hoverEnabled:
                true

            onClicked:
                tabRoot.clicked()
        }
    }
}
