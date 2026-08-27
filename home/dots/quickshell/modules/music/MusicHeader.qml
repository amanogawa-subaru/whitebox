import QtQuick

import "../../Config"

Item {
    id: root

    property var backend: null
    property bool expanded: false
    property bool closing: false
    property bool hovered: false
    property bool collapseBase: false
    property color accentColor: Colors.green
    property real compactSpacing: 10 * Appearance.scale
    property real expandedHeaderHeight: 48 * Appearance.scale

    implicitHeight:
        root.expanded
            ? root.expandedHeaderHeight
            : Appearance.moduleHeight

    FontMetrics {
        id: musicIconMetrics
        font.family: "Symbols Nerd Font"
        font.pixelSize: Appearance.iconSize
    }

    Text {
        id: musicIcon

        anchors {
            left: parent.left
            leftMargin:
                root.backend && root.backend.hasPlayer
                    ? 14 * Appearance.scale
                    : 0
            verticalCenter: parent.verticalCenter
        }

        width:
            root.backend && root.backend.hasPlayer
                ? musicIconMetrics.advanceWidth(text)
                : parent.width

        text: "󰎈"
        font.family: "Symbols Nerd Font"
        font.pixelSize: Appearance.iconSize
        horizontalAlignment: Text.AlignHCenter

        color: {
            if (!root.backend || !root.backend.hasPlayer)
                return Colors.base

            if (root.hovered && !root.expanded)
                return Colors.base

            if (root.closing || root.collapseBase)
                return root.accentColor

            if (root.expanded)
                return Colors.base

            return root.accentColor
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Text {
        id: headerTrackText

        visible:
            root.backend
            && root.backend.hasPlayer
            && !root.expanded

        anchors {
            left: musicIcon.right
            right: parent.right
            leftMargin: root.compactSpacing
            rightMargin: 14 * Appearance.scale
            verticalCenter: parent.verticalCenter
        }

        text: root.backend ? root.backend.compactText : ""

        color:
            root.hovered
                ? Colors.base
                : Colors.green

        font.pixelSize: Appearance.textSize
        elide: Text.ElideRight
        maximumLineCount: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    AudioVisualizer {
        visible:
            root.expanded
            && !root.closing

        active:
            root.expanded
            && !root.closing
            && root.backend
            && root.backend.hasPlayer

        anchors {
            left: musicIcon.right
            right: parent.right
            leftMargin: 18 * Appearance.scale
            rightMargin: 18 * Appearance.scale
            verticalCenter: parent.verticalCenter
        }

        height: 28 * Appearance.scale
        barColor: Colors.base
    }
}
