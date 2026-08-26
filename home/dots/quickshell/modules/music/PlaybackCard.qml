import QtQuick

import "../../Config"

Rectangle {
    id: root

    property var backend: null
    property color accentColor: Colors.green

    radius: Appearance.controlRadius
    color: Colors.surface0

    function scrubPositionFromX(mouseX) {
        if (
            !root.backend
            || root.backend.trackLength <= 0
            || scrubTrack.width <= 0
        ) {
            return 0
        }

        const ratio = Math.max(
            0,
            Math.min(1, mouseX / scrubTrack.width)
        )

        return ratio * root.backend.trackLength
    }

    function beginScrub(mouseX) {
        if (!root.backend || !root.backend.canScrub)
            return

        root.backend.scrubbing = true
        root.backend.scrubPosition = root.scrubPositionFromX(mouseX)
    }

    function updateScrub(mouseX) {
        if (!root.backend || !root.backend.scrubbing)
            return

        root.backend.scrubPosition = root.scrubPositionFromX(mouseX)
    }

    function finishScrub(mouseX) {
        if (
            !root.backend
            || !root.backend.scrubbing
            || !root.backend.player
        ) {
            if (root.backend)
                root.backend.scrubbing = false
            return
        }

        root.backend.scrubPosition = root.scrubPositionFromX(mouseX)
        root.backend.seekTo(root.backend.scrubPosition)
        root.backend.scrubbing = false
    }

    Column {
        anchors {
            fill: parent
            leftMargin: 12 * Appearance.scale
            rightMargin: 12 * Appearance.scale
            topMargin: 10 * Appearance.scale
            bottomMargin: 8 * Appearance.scale
        }

        spacing: 4 * Appearance.scale

        Row {
            width: parent.width
            height: 30 * Appearance.scale
            spacing: 10 * Appearance.scale
            opacity: 1.0

            Text {
                id: currentTimeText

                width: 40 * Appearance.scale
                anchors.verticalCenter: parent.verticalCenter

                text:
                    root.backend
                        ? root.backend.formatTime(root.backend.displayPosition)
                        : "0:00"

                color:
                    root.backend && root.backend.scrubbing
                        ? root.accentColor
                        : Colors.subtext0

                font.pixelSize: Appearance.textSize - 2
                horizontalAlignment: Text.AlignRight

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }

            Item {
                id: scrubTrack

                width:
                    parent.width
                    - currentTimeText.width
                    - durationText.width
                    - parent.spacing * 2

                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: scrubBackground

                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4 * Appearance.scale
                    radius: height / 2
                    color: Colors.surface2
                }

                Rectangle {
                    anchors {
                        left: scrubBackground.left
                        verticalCenter: scrubBackground.verticalCenter
                    }

                    width:
                        scrubBackground.width
                        * (
                            root.backend
                                ? root.backend.progress
                                : 0
                        )

                    height: scrubBackground.height
                    radius: height / 2
                    color: root.accentColor
                }

                Rectangle {
                    id: scrubThumb

                    width:
                        (
                            scrubMouse.containsMouse
                            || (root.backend && root.backend.scrubbing)
                        )
                            ? 14 * Appearance.scale
                            : 11 * Appearance.scale

                    height: width
                    radius: width / 2
                    color: root.accentColor

                    x:
                        Math.max(
                            0,
                            Math.min(
                                scrubTrack.width - width,
                                (
                                    root.backend
                                        ? root.backend.progress
                                        : 0
                                ) * scrubTrack.width - width / 2
                            )
                        )

                    anchors.verticalCenter: parent.verticalCenter

                    scale:
                        root.backend && root.backend.scrubbing
                            ? 1.15
                            : 1.0

                    Behavior on width {
                        NumberAnimation {
                            duration: 130
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.25
                        }
                    }
                }

                MouseArea {
                    id: scrubMouse

                    anchors.fill: parent

                    enabled:
                        root.backend
                        && root.backend.hasPlayer
                        && root.backend.cachedTrackLength > 0

                    hoverEnabled: true
                    preventStealing: true

                    onPressed: mouse => root.beginScrub(mouse.x)

                    onPositionChanged: mouse => {
                        if (root.backend && root.backend.scrubbing)
                            root.updateScrub(mouse.x)
                    }

                    onReleased: mouse => root.finishScrub(mouse.x)

                    onCanceled: {
                        if (root.backend)
                            root.backend.scrubbing = false
                    }
                }
            }

            Text {
                id: durationText

                width: 40 * Appearance.scale
                anchors.verticalCenter: parent.verticalCenter

                text:
                    root.backend && root.backend.trackLength > 0
                        ? root.backend.formatTime(root.backend.trackLength)
                        : "--:--"

                color: Colors.subtext0
                font.pixelSize: Appearance.textSize - 2
                horizontalAlignment: Text.AlignLeft
            }
        }

        Item {
            width: parent.width
            height: 48 * Appearance.scale

            Row {
                anchors.centerIn: parent
                spacing: 30 * Appearance.scale

                Item {
                    width: 38 * Appearance.scale
                    height: width

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: Appearance.iconSize + 2

                        color:
                            previousMouse.containsMouse
                                ? root.accentColor
                                : Colors.text

                        scale:
                            previousMouse.containsMouse
                                ? 1.15
                                : 1.0

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }

                    MouseArea {
                        id: previousMouse
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (root.backend)
                                root.backend.previous()
                        }
                    }
                }

                Item {
                    width: 46 * Appearance.scale
                    height: width

                    Text {
                        anchors.centerIn: parent

                        text:
                            root.backend && root.backend.playing
                                ? "󰏤"
                                : "󰐊"

                        font.family: "Symbols Nerd Font"
                        font.pixelSize: Appearance.iconSize + 8

                        color:
                            playMouse.containsMouse
                                ? root.accentColor
                                : Colors.text

                        scale:
                            playMouse.containsMouse
                                ? 1.15
                                : 1.0

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (root.backend)
                                root.backend.togglePlaying()
                        }
                    }
                }

                Item {
                    width: 38 * Appearance.scale
                    height: width

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: Appearance.iconSize + 2

                        color:
                            nextMouse.containsMouse
                                ? root.accentColor
                                : Colors.text

                        scale:
                            nextMouse.containsMouse
                                ? 1.15
                                : 1.0

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (root.backend)
                                root.backend.next()
                        }
                    }
                }
            }
        }
    }
}
