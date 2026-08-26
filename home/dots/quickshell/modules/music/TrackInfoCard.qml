import QtQuick

import "../../Config"

Rectangle {
    id: root

    property var backend: null
    property color accentColor: Colors.green

    radius: Appearance.controlRadius
    color: Colors.surface0

    Column {
        width:
            parent.width
            - 28 * Appearance.scale

        anchors.centerIn: parent
        spacing: 7 * Appearance.scale

        Text {
            width: parent.width

            text:
                root.backend && root.backend.title.length > 0
                    ? root.backend.title
                    : "Unknown track"

            horizontalAlignment: Text.AlignHCenter
            color: Colors.text
            font.pixelSize: Appearance.textSize + 2
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            width: parent.width

            text:
                root.backend && root.backend.artist.length > 0
                    ? root.backend.artist
                    : "Unknown artist"

            horizontalAlignment: Text.AlignHCenter
            color: root.accentColor
            font.pixelSize: Appearance.textSize
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
