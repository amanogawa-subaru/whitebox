import QtQuick

import "../Config"

Item {
    id: root

    property date currentTime: new Date()

    property date viewedMonth: new Date(
        currentTime.getFullYear(),
        currentTime.getMonth(),
        1
    )

    property bool hovered: compactHover.hovered
    property bool expanded: false
    property bool contentVisible: false

    property int firstDayOfMonth: new Date(
        viewedMonth.getFullYear(),
        viewedMonth.getMonth(),
        1
    ).getDay()

    property int daysInMonth: new Date(
        viewedMonth.getFullYear(),
        viewedMonth.getMonth() + 1,
        0
    ).getDate()

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

        root.contentVisible = false

        root.viewedMonth = new Date(
            root.currentTime.getFullYear(),
            root.currentTime.getMonth(),
            1
        )

        collapseDelay.restart()
    }

    // ─────────────────────────────────────────
    // Geometry
    // ─────────────────────────────────────────

    width:
        root.expanded
            ? 340 * Appearance.scale
            : Appearance.timeWidth

    height:
        root.expanded
            ? expandedContent.implicitHeight
                + 40 * Appearance.scale
            : Appearance.moduleHeight

    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 300
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
        border.color: Colors.blue

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
    // Clock update
    // ─────────────────────────────────────────

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            root.currentTime = new Date()
        }
    }

    // ─────────────────────────────────────────
    // Compact clock
    // ─────────────────────────────────────────

    Text {
        id: compactClock

        visible: !root.expanded

        anchors.centerIn: parent

        text: Qt.formatDateTime(
            root.currentTime,
            "MMM d  HH:mm"
        )

        color: Colors.text
        font.pixelSize: Appearance.textSize
    }

    HoverHandler {
        id: compactHover
        enabled: !root.expanded
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
    // Expanded content
    // ─────────────────────────────────────────

    Column {
        id: expandedContent

        z: 2

        width:
            root.width
            - 40 * Appearance.scale

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter

            topMargin:
                20 * Appearance.scale
        }

        spacing:
            14 * Appearance.scale

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
        // Time / Date card
        // ─────────────────────────────────────

        Rectangle {
            id: timeCard

            width: parent.width

            implicitHeight:
                timeColumn.implicitHeight
                + 28 * Appearance.scale

            height: implicitHeight

            radius: Appearance.controlRadius
            color: Colors.surface0

            Column {
                id: timeColumn

                anchors.centerIn: parent

                spacing:
                    5 * Appearance.scale

                Text {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    text: Qt.formatDateTime(
                        root.currentTime,
                        "HH:mm"
                    )

                    color: Colors.blue

                    font.pixelSize:
                        Appearance.textSize + 12

                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    text: Qt.formatDateTime(
                        root.currentTime,
                        "dddd, MMMM d"
                    )

                    color: Colors.text
                    font.pixelSize: Appearance.textSize
                }
            }
        }

        // ─────────────────────────────────────
        // Calendar card
        // ─────────────────────────────────────

        Rectangle {
            id: calendarCard

            width: parent.width

            implicitHeight:
                calendarColumn.implicitHeight
                + 24 * Appearance.scale

            height: implicitHeight

            radius: Appearance.controlRadius
            color: Colors.surface0

            Column {
                id: calendarColumn

                width:
                    parent.width
                    - 24 * Appearance.scale

                anchors.centerIn: parent

                spacing:
                    10 * Appearance.scale

                // ─────────────────────────────
                // Month navigation
                // ─────────────────────────────

                Row {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    spacing:
                        12 * Appearance.scale

                    Item {
                        width: 30 * Appearance.scale
                        height: 30 * Appearance.scale

                        Text {
                            anchors.centerIn: parent

                            text: "󰅁"

                            font.family:
                                "Symbols Nerd Font"

                            font.pixelSize:
                                Appearance.iconSize

                            color:
                                previousMonthMouse.containsMouse
                                    ? Colors.blue
                                    : Colors.text

                            scale:
                                previousMonthMouse.containsMouse
                                    ? 1.18
                                    : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.35
                                }
                            }
                        }

                        MouseArea {
                            id: previousMonthMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.viewedMonth = new Date(
                                    root.viewedMonth.getFullYear(),
                                    root.viewedMonth.getMonth() - 1,
                                    1
                                )
                            }
                        }
                    }

                    Text {
                        width:
                            170 * Appearance.scale

                        text: Qt.formatDate(
                            root.viewedMonth,
                            "MMMM yyyy"
                        )

                        color:
                            monthMouse.containsMouse
                                ? Colors.blue
                                : Colors.text

                        font.pixelSize:
                            Appearance.textSize + 1

                        font.bold: true

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        MouseArea {
                            id: monthMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.viewedMonth = new Date(
                                    root.currentTime.getFullYear(),
                                    root.currentTime.getMonth(),
                                    1
                                )
                            }
                        }
                    }

                    Item {
                        width: 30 * Appearance.scale
                        height: 30 * Appearance.scale

                        Text {
                            anchors.centerIn: parent

                            text: "󰅂"

                            font.family:
                                "Symbols Nerd Font"

                            font.pixelSize:
                                Appearance.iconSize

                            color:
                                nextMonthMouse.containsMouse
                                    ? Colors.blue
                                    : Colors.text

                            scale:
                                nextMonthMouse.containsMouse
                                    ? 1.18
                                    : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.35
                                }
                            }
                        }

                        MouseArea {
                            id: nextMonthMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.viewedMonth = new Date(
                                    root.viewedMonth.getFullYear(),
                                    root.viewedMonth.getMonth() + 1,
                                    1
                                )
                            }
                        }
                    }
                }

                // ─────────────────────────────
                // Weekday labels
                // ─────────────────────────────

                Grid {
                    id: weekdayGrid

                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    columns: 7

                    columnSpacing:
                        7 * Appearance.scale

                    rowSpacing:
                        0

                    Repeater {
                        model: [
                            "Su",
                            "Mo",
                            "Tu",
                            "We",
                            "Th",
                            "Fr",
                            "Sa"
                        ]

                        delegate: Text {
                            required property string modelData

                            width:
                                32 * Appearance.scale

                            height:
                                28 * Appearance.scale

                            text:
                                modelData

                            color:
                                Colors.subtext0

                            font.pixelSize:
                                Appearance.textSize - 1

                            horizontalAlignment:
                                Text.AlignHCenter

                            verticalAlignment:
                                Text.AlignVCenter
                        }
                    }
                }

                // ─────────────────────────────
                // Days
                // ─────────────────────────────

                Grid {
                    id: daysGrid

                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    columns: 7

                    columnSpacing:
                        7 * Appearance.scale

                    rowSpacing:
                        6 * Appearance.scale

                    Repeater {
                        model:
                            root.firstDayOfMonth
                            + root.daysInMonth

                        delegate: Item {
                            id: dayItem

                            required property int index

                            width:
                                32 * Appearance.scale

                            height:
                                32 * Appearance.scale

                            property int dayNumber:
                                index
                                - root.firstDayOfMonth
                                + 1

                            property bool validDay:
                                dayNumber > 0

                            property bool isToday:
                                dayNumber
                                    === root.currentTime.getDate()
                                && root.viewedMonth.getMonth()
                                    === root.currentTime.getMonth()
                                && root.viewedMonth.getFullYear()
                                    === root.currentTime.getFullYear()

                            Rectangle {
                                anchors.fill: parent

                                radius:
                                    Appearance.controlRadius

                                visible:
                                    dayItem.validDay

                                color: {
                                    if (dayItem.isToday)
                                        return Colors.blue

                                    if (dayMouse.containsMouse)
                                        return Colors.surface1

                                    return "transparent"
                                }

                                border.width:
                                    !dayItem.isToday
                                    && dayMouse.containsMouse
                                        ? Appearance.borderWidth / 2
                                        : 0

                                border.color:
                                    Colors.blue

                                scale:
                                    dayMouse.containsMouse
                                        ? 1.08
                                        : 1.0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.25
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                visible:
                                    dayItem.validDay

                                text:
                                    dayItem.dayNumber

                                color:
                                    dayItem.isToday
                                        ? Colors.base
                                        : dayMouse.containsMouse
                                            ? Colors.blue
                                            : Colors.text

                                font.pixelSize:
                                    Appearance.textSize

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            MouseArea {
                                id: dayMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                enabled:
                                    dayItem.validDay
                            }
                        }
                    }
                }
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
