import QtQuick

import "../Config"
import "controls"

Item {
    id: root

    property bool hovered:
        compactMouse.containsMouse

    property bool expanded: false
    property bool contentVisible: false

    /*
     * Optional avatar.
     *
     * Later, if you create:
     * ~/.config/quickshell/assets/avatar.png
     *
     * you can use:
     *
     * property url avatarSource:
     *     Qt.resolvedUrl("../assets/avatar.png")
     */
    property url avatarSource: ""

    // ─────────────────────────────────────────
    // Open / Close
    // ─────────────────────────────────────────

    function open() {
        collapseDelay.stop()

        root.expanded = true
        root.contentVisible = false

        contentDelay.restart()
    }

    function close() {
        if (!root.expanded)
            return

        contentDelay.stop()

        outputSelector.expanded = false
        inputSelector.expanded = false

        root.contentVisible = false

        collapseDelay.restart()
    }

    // ─────────────────────────────────────────
    // Geometry
    // ─────────────────────────────────────────

	width: root.expanded
		? Appearance.powerExpandedWidth
		: Appearance.moduleHeight

	height: root.expanded
		? controlContent.implicitHeight
			+ 40 * Appearance.scale
		: Appearance.moduleHeight

	Behavior on width {
		NumberAnimation {
			duration: 300
			easing.type: Easing.OutCubic
		}
	}



    // ─────────────────────────────────────────
    // Main background
    // ─────────────────────────────────────────

    Rectangle {
        id: background

        anchors.fill: parent

        radius: Appearance.moduleRadius

        color: Colors.base

        border.width: Appearance.borderWidth
        border.color: Colors.red

        /*
         * KEEP the original compact Power bounce.
         */
        scale: root.hovered && !root.expanded
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
    // Compact Power icon
    // ─────────────────────────────────────────

    Text {
        id: powerIcon

        visible: !root.expanded

        anchors.centerIn: parent

        text: "󰐥"

        font.family: "Symbols Nerd Font"
        font.pixelSize: Appearance.iconSize

        color: Colors.text
    }

    MouseArea {
        id: compactMouse

        z: 3

        visible: !root.expanded
        enabled: !root.expanded

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            root.open()
        }
    }

    // ─────────────────────────────────────────
    // Expanded UI
    // ─────────────────────────────────────────

    Column {
        id: controlContent

        z: 2

        width: Appearance.powerContentWidth

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter

            topMargin: 20 * Appearance.scale
        }

        spacing: 12 * Appearance.scale

        visible: opacity > 0

        opacity: root.contentVisible
            ? 1.0
            : 0.0

        transform: Translate {
            y: root.contentVisible
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
        // User card
        // ─────────────────────────────────────

        UserHeader {
            width: parent.width

            avatarSource: root.avatarSource
        }

        // ─────────────────────────────────────
        // Brightness card
        // ─────────────────────────────────────

        Rectangle {
            width: parent.width
            height: 64 * Appearance.scale

            radius: Appearance.controlRadius
            color: Colors.surface0

            BrightnessSlider {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter

                    leftMargin: 14 * Appearance.scale
                    rightMargin: 14 * Appearance.scale
                }

                height: 32 * Appearance.scale
            }
        }

        // ─────────────────────────────────────
        // Volume card
        // ─────────────────────────────────────

        Rectangle {
			id: volumeCard

			width: parent.width

			implicitHeight:
				volumeColumn.implicitHeight
				+ 24 * Appearance.scale

			height: implicitHeight

			radius: Appearance.controlRadius
			color: Colors.surface0

			Column {
				id: volumeColumn

				anchors {
					left: parent.left
					right: parent.right
					top: parent.top

					margins: 12 * Appearance.scale
				}

				spacing: 10 * Appearance.scale

				VolumeControl {
					width: parent.width
					height: 32 * Appearance.scale
				}

				AudioDeviceSelector {
					id: outputSelector

					width: parent.width

					deviceType: "sink"
					accentColor: Colors.pink

					onAboutToOpen: {
						inputSelector.expanded = false
					}
				}
			}
		}

        // ─────────────────────────────────────
        // Microphone card
        // ─────────────────────────────────────

		Rectangle {
			id: micCard

			width: parent.width

			implicitHeight:
				micColumn.implicitHeight
				+ 24 * Appearance.scale

			height: implicitHeight

			radius: Appearance.controlRadius
			color: Colors.surface0

			Column {
				id: micColumn

				anchors {
					left: parent.left
					right: parent.right
					top: parent.top

					margins: 12 * Appearance.scale
				}

				spacing: 10 * Appearance.scale

				MicControl {
					width: parent.width
					height: 32 * Appearance.scale
				}

				AudioDeviceSelector {
					id: inputSelector

					width: parent.width

					deviceType: "source"
					accentColor: Colors.mauve

					onAboutToOpen: {
						outputSelector.expanded = false
					}
				}
			}
		}

        // ─────────────────────────────────────
        // Power actions
        // ─────────────────────────────────────

        PowerActions {
            width: parent.width

            onCloseRequested: {
                root.close()
            }
        }
    }

    // ─────────────────────────────────────────
    // Animation timing
    // ─────────────────────────────────────────

    Timer {
        id: contentDelay

        interval: 300
        repeat: false

        onTriggered: {
            root.contentVisible = true
        }
    }

    Timer {
        id: collapseDelay

        interval: 200
        repeat: false

        onTriggered: {
            root.expanded = false
        }
    }
}
