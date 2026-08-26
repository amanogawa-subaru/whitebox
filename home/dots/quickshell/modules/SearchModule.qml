import QtQuick
import Quickshell

import "../Config"

Item {
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

    /*
     * Once the closing wipe has completed,
     * keep the underlying shell base-colored.
     *
     * This prevents teal from being exposed
     * during/after the geometry collapse.
     */
    property bool collapseBase: false

    // ─────────────────────────────────────────
    // Design
    // ─────────────────────────────────────────

    property color accentColor:
        Colors.teal

    property real expandedHeaderHeight:
        48 * Appearance.scale

    property real expandedEdgeThickness:
        Appearance.borderWidth

    property real expandedWidth:
        Appearance.searchWidth
        + 40 * Appearance.scale

    property real closeFillTop:
        root.expandedHeaderHeight

    property real closeBounceScale:
        1.0

    // ─────────────────────────────────────────
    // Expanded height
    // ─────────────────────────────────────────

    property real expandedHeight: {
        const rowHeight =
            Appearance.appRowHeight
            + 4 * Appearance.scale

        const listHeight =
            filteredApps.values.length
            * rowHeight

        const resultsPadding =
            16 * Appearance.scale

        const wantedHeight =
            root.expandedHeaderHeight
            + listHeight
            + resultsPadding
            + root.expandedEdgeThickness

        return Math.max(
            Appearance.searchEmptyHeight,
            Math.min(
                wantedHeight,
                Appearance.searchMaxHeight
            )
        )
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

        resultsContent.opacity =
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

    onExpandedChanged: {
        if (root.expanded)
            appList.currentIndex = 0
    }

    // ─────────────────────────────────────────
    // Geometry
    // ─────────────────────────────────────────

    width:
        root.expanded
        && !root.shrinking
            ? root.expandedWidth
            : Appearance.moduleHeight

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
                /*
                 * Genuine compact hover must win.
                 */
                if (
                    root.hovered
                    && !root.expanded
                ) {
                    return root.accentColor
                }

                /*
                 * Keep the compact/collapsing shell
                 * base-colored after the wipe.
                 */
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

        // ─────────────────────────────────────
        // Persistent search icon
        // ─────────────────────────────────────

        Item {
            id: searchIconSlot

            z: 6

            width:
                Appearance.moduleHeight

            height:
                Appearance.moduleHeight

            anchors {
                left:
                    parent.left

                top:
                    parent.top
            }

            Text {
                anchors.centerIn:
                    parent

                text:
                    "󰍉"

                font.family:
                    "Symbols Nerd Font"

                font.pixelSize:
                    Appearance.iconSize

                color: {
                    /*
                     * Compact hover:
                     *
                     * teal background -> base icon
                     */
                    if (
                        root.hovered
                        && !root.expanded
                    ) {
                        return Colors.base
                    }

                    /*
                     * Closing / compact idle:
                     *
                     * base background -> teal icon
                     */
                    if (
                        root.closing
                        || root.collapseBase
                    ) {
                        return root.accentColor
                    }

                    /*
                     * Expanded teal header:
                     *
                     * base icon
                     */
                    if (root.expanded)
                        return Colors.base

                    /*
                     * Normal compact idle:
                     *
                     * teal icon
                     */
                    return root.accentColor
                }

                scale:
                    root.hovered
                    && !root.expanded
                        ? 1.05
                        : 1.0

                Behavior on color {
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
                            1.3
                    }
                }
            }
        }

        // ─────────────────────────────────────
        // Expanded header
        // ─────────────────────────────────────

        Item {
            id: expandedHeader

            z: 5

            visible:
                root.expanded

            anchors {
                left:
                    parent.left

                right:
                    parent.right

                top:
                    parent.top
            }

            height:
                root.expandedHeaderHeight

            opacity:
                root.closing
                    ? 0.0
                    : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 90
                    easing.type: Easing.OutCubic
                }
            }

            TextInput {
                id: searchInput

                x:
                    Appearance.moduleHeight
                    + 2 * Appearance.scale

                y:
                    0

                width:
                    Math.max(
                        0,
                        expandedHeader.width
                        - x
                        - 20 * Appearance.scale
                    )

                height:
                    expandedHeader.height

                horizontalAlignment:
                    Text.AlignLeft

                verticalAlignment:
                    Text.AlignVCenter

                LayoutMirroring.enabled:
                    false

                LayoutMirroring.childrenInherit:
                    false

                color:
                    Colors.base

                font.pixelSize:
                    Appearance.textSize + 2

                clip:
                    true

                selectionColor:
                    Colors.base

                selectedTextColor:
                    root.accentColor

                // ─────────────────────────────
                // Placeholder
                // ─────────────────────────────

                Text {
                    anchors.fill:
                        parent

                    visible:
                        searchInput.text.length === 0

                    text:
                        "search"

                    horizontalAlignment:
                        Text.AlignLeft

                    verticalAlignment:
                        Text.AlignVCenter

                    color:
                        Colors.base

                    opacity:
                        0.82

                    font.pixelSize:
                        Appearance.textSize + 2

                    LayoutMirroring.enabled:
                        false
                }

                onTextChanged: {
                    appList.currentIndex = 0

                }

                // ─────────────────────────────
                // Keyboard navigation
                // ─────────────────────────────

                Keys.onDownPressed: event => {
                    if (appList.count > 0) {
                        appList.currentIndex =
                            Math.min(
                                appList.currentIndex + 1,
                                appList.count - 1
                            )

                        appList.positionViewAtIndex(
                            appList.currentIndex,
                            ListView.Contain
                        )
                    }

                    event.accepted = true
                }

                Keys.onUpPressed: event => {
                    if (appList.count > 0) {
                        appList.currentIndex =
                            Math.max(
                                appList.currentIndex - 1,
                                0
                            )

                        appList.positionViewAtIndex(
                            appList.currentIndex,
                            ListView.Contain
                        )
                    }

                    event.accepted = true
                }

                Keys.onReturnPressed: event => {
                    if (appList.count > 0) {
                        filteredApps
                            .values[
                                appList.currentIndex
                            ]
                            .execute()

                        root.close()
                    }

                    event.accepted = true
                }

                Keys.onEnterPressed: event => {
                    if (appList.count > 0) {
                        filteredApps
                            .values[
                                appList.currentIndex
                            ]
                            .execute()

                        root.close()
                    }

                    event.accepted = true
                }

                Keys.onEscapePressed: event => {
                    root.close()

                    event.accepted = true
                }
            }
        }

        // ─────────────────────────────────────
        // Results card
        // ─────────────────────────────────────

        Rectangle {
            id: resultsCard

            z: 3

            visible:
                root.expanded

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
                id: resultsContent

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

                ListView {
                    id: appList

                    anchors {
                        fill:
                            parent

                        margins:
                            10 * Appearance.scale
                    }

                    clip:
                        true

                    spacing:
                        4 * Appearance.scale

                    currentIndex:
                        0

                    model:
                        filteredApps

                    highlightFollowsCurrentItem:
                        true

                    highlightMoveDuration:
                        160

                    highlightMoveVelocity:
                        -1

                    highlight: Rectangle {
                        radius:
                            Appearance.controlRadius

                        color:
                            root.accentColor
                    }

                    delegate: Item {
                        id: appDelegate

                        required property var modelData
                        required property int index

                        width:
                            appList.width

                        height:
                            Appearance.appRowHeight

                        property bool selected:
                            ListView.isCurrentItem

                        Image {
                            id: appIcon

                            anchors {
                                left:
                                    parent.left

                                leftMargin:
                                    10 * Appearance.scale

                                verticalCenter:
                                    parent.verticalCenter
                            }

                            width:
                                Appearance.appIconSize

                            height:
                                Appearance.appIconSize

                            source: {
                                // Prefer the icon explicitly supplied
                                // by the desktop entry.
                                if (
                                    modelData.icon
                                    && modelData.icon.length > 0
                                ) {
                                    return Quickshell.iconPath(
                                        modelData.icon,
                                        true
                                    )
                                }

                                // Some desktop entries expose no icon
                                // through DesktopEntries. Try their ID
                                // as the freedesktop icon name instead.
                                if (
                                    modelData.id
                                    && modelData.id.length > 0
                                ) {
                                    return Quickshell.iconPath(
                                        modelData.id,
                                        true
                                    )
                                }

                                return ""
                            }

                            fillMode:
                                Image.PreserveAspectFit

                            smooth:
                                true

                            scale:
                                appMouse.containsMouse
                                    ? 1.06
                                    : 1.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180

                                    easing.type:
                                        Easing.OutBack

                                    easing.overshoot:
                                        1.25
                                }
                            }
                        }

                        Text {
                            anchors {
                                left:
                                    appIcon.right

                                right:
                                    parent.right

                                leftMargin:
                                    10 * Appearance.scale

                                rightMargin:
                                    10 * Appearance.scale

                                verticalCenter:
                                    parent.verticalCenter
                            }

                            text:
                                modelData.name

                            color:
                                appDelegate.selected
                                    ? Colors.base
                                    : Colors.text

                            font.pixelSize:
                                Appearance.textSize

                            elide:
                                Text.ElideRight

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }

                        MouseArea {
                            id: appMouse

                            anchors.fill:
                                parent

                            hoverEnabled:
                                true

                            onEntered: {
                                appList.currentIndex =
                                    index
                            }

                            onClicked: {
                                modelData.execute()
                                root.close()
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn:
                        parent

                    visible:
                        filteredApps.values.length === 0

                    text:
                        "No applications found"

                    color:
                        Colors.overlay0

                    font.pixelSize:
                        Appearance.textSize
                }
            }
        }

        // ─────────────────────────────────────
        // Closing base fill
        // ─────────────────────────────────────

        Rectangle {
            id: closeFill

            z: 4

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

        z: 20

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
    // Application filtering
    // ─────────────────────────────────────────

    ScriptModel {
        id: filteredApps

        values:
            DesktopEntries
                .applications
                .values
                .filter(app => {
                    const query =
                        searchInput
                            .text
                            .toLowerCase()

                    if (query === "")
                        return true

                    return app
                        .name
                        .toLowerCase()
                        .includes(query)
                })
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
            resultsContent.opacity =
                1.0
        }
    }

    Timer {
        id: focusDelay

        interval:
            290

        repeat:
            false

        onTriggered: {
            searchInput.forceActiveFocus()
        }
    }

    // ═════════════════════════════════════════
    // Close choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: closeAnimation

        // ─────────────────────────────────────
        // 1. Fade list
        // ─────────────────────────────────────

        NumberAnimation {
            target:
                resultsContent

            property:
                "opacity"

            to:
                0.0

            duration:
                90

            easing.type:
                Easing.OutCubic
        }

        // ═════════════════════════════════════
        // 2. WIPE + BOUNCE TOGETHER
        // ═════════════════════════════════════

        ParallelAnimation {

            // Base rises through teal header

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

            // Whole-module bounce

            SequentialAnimation {

                // anticipation squash

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

                // spring outward

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

        // Base has now fully taken over.

        ScriptAction {
            script: {
                root.collapseBase =
                    true
            }
        }

        // ═════════════════════════════════════
        // 3. RECOVERY + SHRINK TOGETHER
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
        // 4. Compact state
        // ═════════════════════════════════════

        ScriptAction {
            script: {
                /*
                 * Don't instantly treat the cursor
                 * already sitting over Search as a
                 * fresh hover.
                 */
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

                resultsContent.opacity =
                    0.0

                searchInput.text =
                    ""
            }
        }
    }
}
