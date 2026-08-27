import QtQuick
import Quickshell.Hyprland

import "../Config"

FocusScope {
    id: root

    // ─────────────────────────────────────────
    // State
    // ─────────────────────────────────────────

    property bool suppressHover: false

    property bool hovered:
        compactMouse.containsMouse
        && !root.suppressHover

    property bool expanded: false
    property bool closing: false
    property bool shrinking: false
    property bool collapseBase: false

    // ─────────────────────────────────────────
    // Workspace data
    // ─────────────────────────────────────────

    property int workspaceCount: 5

    property real workspaceItemSize:
        20 * Appearance.scale

    property real indicatorSize:
        10 * Appearance.scale

    property real workspaceSpacing:
        Appearance.moduleSpacing

    property int activeWorkspaceId:
        Hyprland.focusedWorkspace
            ? Hyprland.focusedWorkspace.id
            : 1

    property int activeIndex:
        Math.max(
            0,
            Math.min(
                root.workspaceCount - 1,
                root.activeWorkspaceId - 1
            )
        )

    // ─────────────────────────────────────────
    // Design
    // ─────────────────────────────────────────

    property color accentColor:
        Colors.peach

    property real expandedHeaderHeight:
        48 * Appearance.scale

    property real expandedEdgeThickness:
        Appearance.borderWidth

    property real expandedWidth:
        360 * Appearance.scale

    property real expandedHeight:
        250 * Appearance.scale

    property real closeFillTop:
        root.expandedHeaderHeight

    property real closeBounceScale:
        1.0

    // ─────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────

    function workspaceOccupied(workspaceId) {
        for (
            let i = 0;
            i < Hyprland.workspaces.values.length;
            i++
        ) {
            if (
                Hyprland.workspaces.values[i].id
                === workspaceId
            ) {
                return true
            }
        }

        return false
    }

    function switchWorkspace(workspaceId) {
        Hyprland.dispatch(
            'hl.dsp.focus({ workspace = "'
            + workspaceId
            + '" })'
        )
    }

    function switchAndClose(workspaceId) {
        root.switchWorkspace(workspaceId)
        root.close()
    }

    // ─────────────────────────────────────────
    // Open / Close
    // ─────────────────────────────────────────

    function open() {
        closeAnimation.stop()

        root.suppressHover = false

        root.closing = false
        root.shrinking = false
        root.collapseBase = false

        root.closeFillTop =
            root.expandedHeaderHeight

        root.closeBounceScale =
            1.0

        overviewContent.opacity =
            0.0

        root.expanded =
            true

        contentDelay.restart()
        focusDelay.restart()
    }

    function close() {
        if (
            !root.expanded
            || root.closing
        ) {
            return
        }

        contentDelay.stop()
        focusDelay.stop()

        root.closing =
            true

        root.shrinking =
            false

        root.collapseBase =
            false

        root.closeFillTop =
            root.expandedHeaderHeight

        root.closeBounceScale =
            1.0

        closeAnimation.restart()
    }

    function toggle() {
        if (root.expanded)
            root.close()
        else
            root.open()
    }

    // ─────────────────────────────────────────
    // Escape closes
    // ─────────────────────────────────────────

    Keys.onEscapePressed: event => {
        if (root.expanded) {
            root.close()
            event.accepted = true
        }
    }

    // ─────────────────────────────────────────
    // Geometry
    // ─────────────────────────────────────────

    width:
        root.expanded
        && !root.shrinking
            ? root.expandedWidth
            : Appearance.workspaceWidth

    height:
        root.expanded
        && !root.shrinking
            ? root.expandedHeight
            : Appearance.moduleHeight

    Behavior on width {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    // ═════════════════════════════════════════
    // Entire visual module
    // ═════════════════════════════════════════

    Item {
        id: visualRoot

        anchors.fill:
            parent

        scale: {
            if (root.closing)
                return root.closeBounceScale

            if (
                root.hovered
                && !root.expanded
            ) {
                return 1.09
            }

            return 1.0
        }

        transformOrigin:
            Item.Center

        Behavior on scale {
            enabled:
                !root.closing

            NumberAnimation {
                duration: 300

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
            id: outerShell

            anchors.fill:
                parent

            radius:
                Appearance.moduleRadius

            color: {
                if (
                    root.hovered
                    && !root.expanded
                ) {
                    return root.accentColor
                }

                if (root.collapseBase)
                    return Colors.base

                if (root.expanded)
                    return root.accentColor

                return Colors.base
            }

            border.width:
                Appearance.borderWidth

            border.color:
                root.accentColor

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }
            }
        }

        // ═════════════════════════════════════
        // Persistent workspace strip
        // ═════════════════════════════════════

        Item {
            id: workspaceStrip

            z: 7

            width:
                root.workspaceCount
                * root.workspaceItemSize
                + (
                    root.workspaceCount - 1
                )
                * root.workspaceSpacing

            height:
                root.workspaceItemSize

            anchors {
                left:
                    parent.left

                top:
                    parent.top

                leftMargin:
                    (
                        Appearance.workspaceWidth
                        - width
                    ) / 2

                topMargin:
                    (
                        Appearance.moduleHeight
                        - height
                    ) / 2
            }

            // ─────────────────────────────────
            // Sliding active indicator
            // ─────────────────────────────────

            Rectangle {
                id: activeIndicator

                z:
                    2

                visible:
                    root.activeWorkspaceId >= 1
                    && root.activeWorkspaceId
                        <= root.workspaceCount

                width:
                    root.indicatorSize

                height:
                    root.indicatorSize

                radius:
                    width / 2

                /*
                 * COMPACT:
                 * peach on base
                 *
                 * COMPACT HOVER:
                 * base on peach
                 *
                 * EXPANDED:
                 * base on peach
                 *
                 * CLOSING:
                 * peach on base
                 */
                color: {
                    if (root.closing)
                        return root.accentColor

                    if (
                        root.expanded
                        || root.hovered
                    ) {
                        return Colors.base
                    }

                    return root.accentColor
                }

                y:
                    (
                        workspaceStrip.height
                        - height
                    ) / 2

                x:
                    root.activeIndex
                    * (
                        root.workspaceItemSize
                        + root.workspaceSpacing
                    )
                    + (
                        root.workspaceItemSize
                        - width
                    ) / 2

                Behavior on x {
                    NumberAnimation {
                        duration: 220

                        easing.type:
                            Easing.OutBack

                        easing.overshoot:
                            1.25
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            // ─────────────────────────────────
            // Other workspace indicators
            // ─────────────────────────────────

            Repeater {
                model:
                    root.workspaceCount

                delegate: Item {
                    id: headerWorkspace

                    required property int index

                    property int workspaceId:
                        index + 1

                    property bool active:
                        root.activeWorkspaceId
                            === workspaceId

                    property bool occupied:
                        root.workspaceOccupied(
                            workspaceId
                        )

                    x:
                        index
                        * (
                            root.workspaceItemSize
                            + root.workspaceSpacing
                        )

                    width:
                        root.workspaceItemSize

                    height:
                        root.workspaceItemSize

                    Rectangle {
                        anchors.centerIn:
                            parent

                        width:
                            root.indicatorSize

                        height:
                            root.indicatorSize

                        radius:
                            width / 2

                        visible:
                            !headerWorkspace.active

                        /*
                         * EXPANDED HEADER:
                         *
                         * active   = handled above / base
                         * occupied = gray
                         * empty    = white
                         *
                         * Compact keeps the old visual
                         * language.
                         */
                        color: {
                            if (root.closing) {
                                if (
                                    headerWorkspace.occupied
                                ) {
                                    return Colors.lavender
                                }

                                return Colors.surface0
                            }

							if (
								root.expanded
								|| root.hovered
							) {
								if (
									headerWorkspace.occupied
								) {
									return Colors.overlay0
								}

								return Colors.text
							}

                            if (
                                headerWorkspace.occupied
                            ) {
                                return Colors.lavender
                            }

                            return Colors.surface0
                        }

                        scale:
                            headerMouse.containsMouse
                            && root.expanded
                                ? 1.25
                                : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 180

                                easing.type:
                                    Easing.OutBack

                                easing.overshoot:
                                    1.35
                            }
                        }
                    }

                    MouseArea {
                        id: headerMouse

                        anchors.fill:
                            parent

                        enabled:
                            root.expanded
                            && !root.closing

                        hoverEnabled:
                            true

                        onClicked: {
                            root.switchAndClose(
                                headerWorkspace.workspaceId
                            )
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════
        // Expanded overview card
        // ═════════════════════════════════════

        Rectangle {
            id: overviewCard

            z:
                6

            visible:
                root.expanded
                && !root.shrinking

            x:
                root.expandedEdgeThickness

            y:
                root.expandedHeaderHeight

            width:
                Math.max(
                    0,
                    visualRoot.width
                    - root.expandedEdgeThickness * 2
                )

            height:
                Math.max(
                    0,
                    visualRoot.height
                    - root.expandedHeaderHeight
                    - root.expandedEdgeThickness
                )

            radius:
                Math.max(
                    0,
                    Appearance.moduleRadius
                    - root.expandedEdgeThickness
                )

            color:
                Colors.base

            clip:
                true

            Item {
                id: overviewContent

                anchors.fill:
                    parent

                opacity:
                    0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                Grid {
                    id: workspaceGrid

                    anchors.centerIn:
                        parent

                    columns:
                        3

                    columnSpacing:
                        10 * Appearance.scale

                    rowSpacing:
                        10 * Appearance.scale

                    Repeater {
                        model:
                            root.workspaceCount

                        delegate: Rectangle {
                            id: workspaceCard

                            required property int index

                            property int workspaceId:
                                index + 1

                            property bool active:
                                root.activeWorkspaceId
                                    === workspaceId

                            property bool occupied:
                                root.workspaceOccupied(
                                    workspaceId
                                )

                            width:
                                96 * Appearance.scale

                            height:
                                72 * Appearance.scale

                            radius:
                                Appearance.controlRadius

                            // ─────────────────
                            // State through fill
                            // ─────────────────

                            color:
                                workspaceCard.active
                                    ? root.accentColor
                                    : Colors.base

                            // ─────────────────
                            // State through edge
                            //
                            // active:
                            // filled peach
                            //
                            // occupied:
                            // peach border
                            //
                            // empty:
                            // inactive border
                            // ─────────────────

                            border.width:
                                workspaceCard.active
                                    ? 0
                                    : Appearance.borderWidth

                            border.color: {
                                if (
                                    workspaceCard.occupied
                                ) {
                                    return root.accentColor
                                }

                                if (
                                    cardMouse.containsMouse
                                ) {
                                    return Colors.overlay1
                                }

                                return Colors.surface1
                            }

                            scale:
                                cardMouse.containsMouse
                                    ? 1.055
                                    : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200

                                    easing.type:
                                        Easing.OutBack

                                    easing.overshoot:
                                        1.35
                                }
                            }

                            // ─────────────────
                            // Workspace number
                            // ─────────────────

                            Text {
                                anchors.centerIn:
                                    parent

                                text:
                                    workspaceCard.workspaceId

                                color: {
                                    if (
                                        workspaceCard.active
                                    ) {
                                        return Colors.base
                                    }

                                    if (
                                        workspaceCard.occupied
                                    ) {
                                        return root.accentColor
                                    }

                                    if (
                                        cardMouse.containsMouse
                                    ) {
                                        return Colors.text
                                    }

                                    return Colors.overlay0
                                }

                                font.pixelSize:
                                    Appearance.textSize + 10

                                font.bold:
                                    true

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse

                                anchors.fill:
                                    parent

                                hoverEnabled:
                                    true

                                onClicked: {
                                    root.switchAndClose(
                                        workspaceCard.workspaceId
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════
        // Closing base wipe
        // ═════════════════════════════════════

        Rectangle {
            id: closeFill

            z:
                5

            visible:
                root.closing

            x:
                root.expandedEdgeThickness

            y:
                root.closeFillTop

            width:
                Math.max(
                    0,
                    visualRoot.width
                    - root.expandedEdgeThickness * 2
                )

            height:
                Math.max(
                    0,
                    visualRoot.height
                    - root.closeFillTop
                    - root.expandedEdgeThickness
                )

            radius:
                Math.max(
                    0,
                    Appearance.moduleRadius
                    - root.expandedEdgeThickness
                )

            color:
                Colors.base
        }
    }

    // ═════════════════════════════════════════
    // Compact interaction
    // ═════════════════════════════════════════

    MouseArea {
        id: compactMouse

        z:
            20

        visible:
            !root.expanded

        enabled:
            !root.expanded

        anchors.fill:
            parent

        hoverEnabled:
            true

        onExited: {
            root.suppressHover =
                false
        }

        onClicked: {
            root.suppressHover =
                false

            root.open()
        }
    }

    // ─────────────────────────────────────────
    // Opening timers
    // ─────────────────────────────────────────

    Timer {
        id: contentDelay

        interval:
            210

        repeat:
            false

        onTriggered: {
            overviewContent.opacity =
                1.0
        }
    }

    /*
     * Give the PanelWindow a moment to request
     * keyboard focus before focusing this module.
     */
    Timer {
        id: focusDelay

        interval:
            50

        repeat:
            false

        onTriggered: {
            root.forceActiveFocus()
        }
    }

    // ═════════════════════════════════════════
    // Close choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: closeAnimation

        // ═════════════════════════════════════
        // 1. Content fade + base wipe + bounce
        //
        // Matches UtilityModule: expanded content
        // dissolves visibly while the base rises
        // underneath the persistent header/icon.
        // ═════════════════════════════════════

        ParallelAnimation {
            NumberAnimation {
                target:
                    overviewContent

                property:
                    "opacity"

                from:
                    1.0

                to:
                    0.0

                duration:
                    220

                easing.type:
                    Easing.InOutCubic
            }

            NumberAnimation {
                target:
                    root

                property:
                    "closeFillTop"

                from:
                    root.expandedHeaderHeight

                to:
                    root.expandedEdgeThickness

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

        // Base is fully established under the
        // persistent icon/header before shrink.

        ScriptAction {
            script: {
                root.collapseBase =
                    true
            }
        }

        // ═════════════════════════════════════
        // 2. Bounce recovery + shrink together
        // ═════════════════════════════════════

        ParallelAnimation {
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
                    280

                easing.type:
                    Easing.OutCubic
            }

            SequentialAnimation {
                ScriptAction {
                    script: {
                        root.shrinking =
                            true
                    }
                }

                PauseAnimation {
                    duration:
                        280
                }
            }
        }

        // ═════════════════════════════════════
        // 3. Compact state
        // ═════════════════════════════════════

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

                root.collapseBase =
                    true

                root.closeFillTop =
                    root.expandedHeaderHeight

                root.closeBounceScale =
                    1.0

                overviewContent.opacity =
                    0.0

            }
        }
    }
}
