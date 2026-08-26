import QtQuick
import Quickshell

import "../Config"

Item {
    id: root

    property bool hovered: mouseArea.containsMouse
    property bool expanded: false
    property bool contentVisible: false

    /*
     * false = mouse controls selection
     * true  = keyboard controls selection
     */
    property bool keyboardNavigation: false

    property real contentWidth:
        Appearance.searchWidth

    property real expandedHeight: {
        const headerHeight =
            Appearance.moduleHeight

        const listHeight =
            filteredApps.values.length
            * (
                Appearance.appRowHeight
                + 4 * Appearance.scale
            )

        const cardPadding =
            24 * Appearance.scale

        const outerPadding =
            24 * Appearance.scale

        const spacing =
            12 * Appearance.scale

        const wantedHeight =
            headerHeight
            + spacing
            + listHeight
            + cardPadding
            + outerPadding

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
        root.keyboardNavigation = false

        root.expanded = true
        root.contentVisible = false

        contentDelay.restart()
        focusDelay.restart()
    }

    function close() {
        if (!root.expanded)
            return

        contentDelay.stop()
        focusDelay.stop()

        root.contentVisible = false
        collapseDelay.restart()
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

    width: root.expanded
        ? Appearance.searchWidth
            + 40 * Appearance.scale
        : Appearance.moduleHeight

    height: root.expanded
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

    // ─────────────────────────────────────────
    // Outer shell
    // ─────────────────────────────────────────

    Rectangle {
        id: background

        anchors.fill: parent

        radius: Appearance.moduleRadius

        color: Colors.base

        border.width: Appearance.borderWidth
        border.color: Colors.teal

        /*
         * Preserve our compact module bounce.
         */
        scale:
            root.hovered && !root.expanded
                ? 1.09
                : 1.0

        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.9
            }
        }
    }

    // ─────────────────────────────────────────
    // Compact Search button
    // ─────────────────────────────────────────

    Item {
        id: compactButton

        visible: !root.expanded

        width: Appearance.moduleHeight
        height: Appearance.moduleHeight

        anchors {
            left: parent.left
            top: parent.top
        }

        Text {
            anchors.centerIn: parent

            text: "󰍉"

            font.family: "Symbols Nerd Font"
            font.pixelSize: Appearance.iconSize

            color: Colors.text
        }
    }

    // ─────────────────────────────────────────
    // Expanded content
    // ─────────────────────────────────────────

    Column {
        id: content

        z: 2

        width: root.contentWidth

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter

            topMargin:
                12 * Appearance.scale
        }

        spacing:
            12 * Appearance.scale

        visible: opacity > 0

        opacity:
            root.contentVisible
                ? 1.0
                : 0.0

        transform: Translate {
            y:
                root.contentVisible
                    ? 0
                    : 8

            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // ─────────────────────────────────────
        // Search field card
        // ─────────────────────────────────────

        Rectangle {
            id: searchCard

            width: parent.width
            height: Appearance.moduleHeight

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            border.width:
                Appearance.borderWidth / 2

            border.color:
                searchInput.activeFocus
                    ? Colors.teal
                    : Colors.surface1

            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            Item {
                id: searchIconSlot

                width:
                    Appearance.moduleHeight

                height:
                    parent.height

                anchors {
                    left: parent.left
                    top: parent.top
                }

                Text {
                    anchors.centerIn: parent

                    text: "󰍉"

                    font.family:
                        "Symbols Nerd Font"

                    font.pixelSize:
                        Appearance.iconSize

                    color:
                        Colors.teal
                }
            }

            TextInput {
                id: searchInput

                anchors {
                    left:
                        searchIconSlot.right

                    right:
                        parent.right

                    leftMargin:
                        4 * Appearance.scale

                    rightMargin:
                        14 * Appearance.scale

                    verticalCenter:
                        parent.verticalCenter
                }

                color:
                    Colors.text

                font.pixelSize:
                    Appearance.textSize

                clip: true

                Text {
                    anchors.fill: parent

                    visible:
                        searchInput.text.length === 0

                    text:
                        "Search applications..."

                    color:
                        Colors.overlay0

                    font.pixelSize:
                        Appearance.textSize

                    verticalAlignment:
                        Text.AlignVCenter
                }

                onTextChanged: {
                    appList.currentIndex = 0
                    root.keyboardNavigation = false
                }

                // ─────────────────────────────
                // Keyboard navigation
                // ─────────────────────────────

                Keys.onDownPressed: event => {
                    root.keyboardNavigation = true

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
                    root.keyboardNavigation = true

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

            width:
                parent.width

            height: Math.max(
                48 * Appearance.scale,

                root.expandedHeight
                    - searchCard.height
                    - content.spacing
                    - 24 * Appearance.scale
            )

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            clip: true

            ListView {
                id: appList

                anchors {
                    fill: parent

                    margins:
                        8 * Appearance.scale
                }

                clip: true

                spacing:
                    4 * Appearance.scale

                currentIndex: 0

                model:
                    filteredApps

                /*
                 * We draw our own highlight instead
                 * of coloring every delegate.
                 */
                highlightFollowsCurrentItem: true

                highlightMoveDuration: 160

                highlightMoveVelocity: -1

                highlight: Rectangle {
                    radius:
                        Appearance.controlRadius

                    color:
                        Colors.teal
                }

                delegate: Item {
                    required property var modelData
                    required property int index

                    width:
                        appList.width

                    height:
                        Appearance.appRowHeight

                    /*
                     * This is the row currently underneath
                     * the single sliding highlight.
                     */
                    property bool selected:
                        ListView.isCurrentItem

                    // ─────────────────────────
                    // App icon
                    // ─────────────────────────

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

                        source:
                            Quickshell.iconPath(
                                modelData.icon
                            )

                        fillMode:
                            Image.PreserveAspectFit
                    }

                    // ─────────────────────────
                    // App name
                    // ─────────────────────────

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

                        /*
                         * Invert the text when the
                         * highlight reaches this row.
                         */
                        color:
                            selected
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

                    // ─────────────────────────
                    // Mouse interaction
                    // ─────────────────────────

                    MouseArea {
                        id: appMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        /*
                         * Entering another row moves
                         * currentIndex, which causes the
                         * same highlight to glide there.
                         */
                        onEntered: {
                            root.keyboardNavigation = false

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

            // ─────────────────────────────────
            // Empty results
            // ─────────────────────────────────

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
    // Compact interaction
    // ─────────────────────────────────────────

    MouseArea {
        id: mouseArea

        z: 3

        visible:
            !root.expanded

        enabled:
            !root.expanded

        anchors.fill:
            parent

        hoverEnabled:
            true

        onClicked: {
            root.open()
        }
    }

    // ─────────────────────────────────────────
    // Animation timing
    // ─────────────────────────────────────────

    Timer {
        id: contentDelay

        interval: 280
        repeat: false

        onTriggered: {
            root.contentVisible = true
        }
    }

    Timer {
        id: focusDelay

        interval: 320
        repeat: false

        onTriggered: {
            searchInput.forceActiveFocus()
        }
    }

    Timer {
        id: collapseDelay

        interval: 200
        repeat: false

        onTriggered: {
            root.expanded = false
            root.keyboardNavigation = false
            searchInput.text = ""
        }
    }
}
