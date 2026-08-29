import QtQuick
import QtQuick.Effects

import "../../Config"

Rectangle {
    id: root

    property var backend: null
    property color accentColor: Colors.green

    radius: Appearance.controlRadius
    color: Colors.surface0
    clip: true

    Image {
        id: albumArtSource

        anchors.fill: parent

        source:
            root.backend
                ? root.backend.artworkSource
                : ""

        fillMode: Image.PreserveAspectCrop

        smooth: true
        mipmap: true
        asynchronous: true
        cache: true

        opacity: 0.0
        layer.enabled: true

        onStatusChanged: {
            if (
                status === Image.Error
                && root.backend
            ) {
                root.backend.advanceArtworkStage()
            }
        }
    }

    Rectangle {
        id: albumArtMask

        anchors.fill: parent
        radius: Appearance.controlRadius
        color: "white"
        opacity: 0.0
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent

        source: albumArtSource
        maskEnabled: true
        maskSource: albumArtMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0

        visible:
            albumArtSource.status === Image.Ready
    }

    Text {
        anchors.centerIn: parent

        visible:
            albumArtSource.status !== Image.Ready

        text: "󰝚"
        font.family: "Symbols Nerd Font"
        font.pixelSize: 64 * Appearance.scale
        color: root.accentColor
    }
}
