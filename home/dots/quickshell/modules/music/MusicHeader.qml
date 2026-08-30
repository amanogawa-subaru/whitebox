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
            /*
             * Active close wins so the persistent icon
             * transitions base -> accent without vanishing.
             */
            if (root.closing)
                return root.accentColor

            /*
             * Once close has finished, hover must outrank
             * collapseBase. collapseBase intentionally
             * remains true in compact state, and letting it
             * win would produce accent-on-accent after the
             * first open/close cycle.
             */
            if (root.hovered && !root.expanded)
                return Colors.base

            /*
             * No-player compact state uses an accent shell,
             * so the persistent icon must be base-colored.
             * This must outrank stale collapseBase from the
             * previous close cycle.
             */
            if (!root.backend || !root.backend.hasPlayer)
                return Colors.base

            if (root.collapseBase)
                return root.accentColor

            if (root.expanded)
                return Colors.base

            return root.accentColor
        }

        Behavior on color {
            /*
             * Do not cross-fade the compact music icon
             * against the shell during hover.
             *
             * The shell animates base <-> accent while
             * this icon wants accent <-> base; animating
             * both continuously makes them pass through
             * the same midpoint color and visually vanish.
             *
             * Hover contrast changes immediately; closing
             * and normal state changes retain the smooth
             * color animation.
             */
            enabled:
                !root.hovered
                || root.expanded
                || root.closing

            ColorAnimation {
                duration: 150
            }
        }
    }

    FontMetrics {
        id: trackMetrics
        font: headerTrackText.font
    }
    
    Text {
        id: headerTrackText

        visible:
            root.backend
            && root.backend.hasPlayer
            && !root.expanded

        opacity:
            visible
                ? 1.0
                : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        anchors {
            left: musicIcon.right
            right: parent.right
            leftMargin: root.compactSpacing
            rightMargin: 14 * Appearance.scale
            verticalCenter: parent.verticalCenter
        }

        anchors.verticalCenterOffset: {
            const bounds =
                trackMetrics.tightBoundingRect(text)

            const glyphCenter =
                baselineOffset
                + bounds.y
                + bounds.height / 2

            return implicitHeight / 2
                - glyphCenter
        }
        
        text:
            root.backend
                ? root.backend.compactText
                : ""
        
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
