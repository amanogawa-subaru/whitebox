import QtQuick

import "../Config"

FocusScope {
    id: root

    // ─────────────────────────────────────────
    // Time / Calendar state
    // ─────────────────────────────────────────

    property date currentTime:
        new Date()

    property date viewedMonth:
        new Date(
            currentTime.getFullYear(),
            currentTime.getMonth(),
            1
        )

    property int firstDayOfMonth:
        new Date(
            viewedMonth.getFullYear(),
            viewedMonth.getMonth(),
            1
        ).getDay()

    property int daysInMonth:
        new Date(
            viewedMonth.getFullYear(),
            viewedMonth.getMonth() + 1,
            0
        ).getDate()

    // ─────────────────────────────────────────
    // Module state
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
    // Design
    // ─────────────────────────────────────────

    property color accentColor:
        Colors.blue

    property real expandedHeaderHeight:
        48 * Appearance.scale

    property real expandedEdgeThickness:
        Appearance.borderWidth

    property real expandedWidth:
        340 * Appearance.scale

    property real expandedHeight:
        390 * Appearance.scale

    property real closeFillTop:
        root.expandedHeaderHeight

    property real closeBounceScale:
        1.0

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

        calendarContent.opacity =
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

        /*
         * Always reset calendar view after close.
         */
        root.viewedMonth =
            new Date(
                root.currentTime.getFullYear(),
                root.currentTime.getMonth(),
                1
            )

        closeAnimation.restart()
    }

    function toggle() {
        if (root.expanded)
            root.close()
        else
            root.open()
    }

    // ─────────────────────────────────────────
    // Escape
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
            : Appearance.timeWidth

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
        // Blue outer shell
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
        // Persistent clock
        //
        // Same physical text object in compact
        // and expanded modes.
        // ═════════════════════════════════════

		Item {
			id: clockSlot

			z: 7

			width:
				visualRoot.width

			/*
			 * Keep the persistent clock slot at compact
			 * height at all times. In expanded mode it is
			 * vertically centered inside the taller header,
			 * then smoothly returns to y=0 while shrinking.
			 *
			 * This avoids the final-frame position jump
			 * caused by changing the slot's height only
			 * after expanded becomes false.
			 */
			height:
				Appearance.moduleHeight

			anchors.left:
				parent.left

			y:
				root.expanded
				&& !root.shrinking
					? (
						root.expandedHeaderHeight
						- Appearance.moduleHeight
					) / 2
					: 0

			Behavior on y {
				NumberAnimation {
					duration:
						280

					easing.type:
						Easing.OutCubic
				}
			}

			Text {
				id: clockText

				anchors.centerIn:
					parent

				text:
					Qt.formatDateTime(
						root.currentTime,
						"MMM d  HH:mm"
					)

				color: {
					if (
						root.hovered
						&& !root.expanded
					) {
						return Colors.base
					}

					if (
						root.closing
						|| root.collapseBase
					) {
						return root.accentColor
					}

					if (root.expanded)
						return Colors.base

					return Colors.text
				}

				font.pixelSize:
					Appearance.textSize

				scale:
					root.expanded
					&& !root.closing
						? 1.06
						: 1.0

				Behavior on color {
					ColorAnimation {
						duration: 150
					}
				}

				Behavior on scale {
					NumberAnimation {
						duration: 220
						easing.type: Easing.OutBack
						easing.overshoot: 1.3
					}
				}
			}
		}

        // ═════════════════════════════════════
        // Calendar inset
        // ═════════════════════════════════════

        Rectangle {
            id: calendarCard

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
                id: calendarContent

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

                Column {
                    id: calendarColumn

                    width:
                        parent.width
                        - 28 * Appearance.scale

                    anchors.centerIn:
                        parent

                    spacing:
                        12 * Appearance.scale

                    // ─────────────────────────
                    // Month navigation
                    // ─────────────────────────

                    Row {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        spacing:
                            12 * Appearance.scale

                        // Previous

                        Item {
                            width:
                                30 * Appearance.scale

                            height:
                                30 * Appearance.scale

                            Rectangle {
                                anchors.fill:
                                    parent

                                radius:
                                    Appearance.controlRadius

                                color:
                                    previousMonthMouse.containsMouse
                                        ? Colors.surface1
                                        : "transparent"

                                scale:
                                    previousMonthMouse.containsMouse
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

                                        easing.type:
                                            Easing.OutBack

                                        easing.overshoot:
                                            1.3
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn:
                                    parent

                                text:
                                    "󰅁"

                                font.family:
                                    "Symbols Nerd Font"

                                font.pixelSize:
                                    Appearance.iconSize

                                color:
                                    previousMonthMouse.containsMouse
                                        ? root.accentColor
                                        : Colors.text

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            MouseArea {
                                id: previousMonthMouse

                                anchors.fill:
                                    parent

                                hoverEnabled:
                                    true

                                onClicked: {
                                    root.viewedMonth =
                                        new Date(
                                            root.viewedMonth.getFullYear(),
                                            root.viewedMonth.getMonth() - 1,
                                            1
                                        )
                                }
                            }
                        }

                        // Month / year

                        Text {
                            width:
                                190 * Appearance.scale

                            height:
                                30 * Appearance.scale

                            text:
                                Qt.formatDate(
                                    root.viewedMonth,
                                    "MMMM yyyy"
                                )

                            color:
                                monthMouse.containsMouse
                                    ? root.accentColor
                                    : Colors.text

                            font.pixelSize:
                                Appearance.textSize + 2

                            font.bold:
                                true

                            horizontalAlignment:
                                Text.AlignHCenter

                            verticalAlignment:
                                Text.AlignVCenter

                            scale:
                                monthMouse.containsMouse
                                    ? 1.025
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
                                    easing.overshoot: 1.2
                                }
                            }

                            MouseArea {
                                id: monthMouse

                                anchors.fill:
                                    parent

                                hoverEnabled:
                                    true

                                onClicked: {
                                    root.viewedMonth =
                                        new Date(
                                            root.currentTime.getFullYear(),
                                            root.currentTime.getMonth(),
                                            1
                                        )
                                }
                            }
                        }

                        // Next

                        Item {
                            width:
                                30 * Appearance.scale

                            height:
                                30 * Appearance.scale

                            Rectangle {
                                anchors.fill:
                                    parent

                                radius:
                                    Appearance.controlRadius

                                color:
                                    nextMonthMouse.containsMouse
                                        ? Colors.surface1
                                        : "transparent"

                                scale:
                                    nextMonthMouse.containsMouse
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

                                        easing.type:
                                            Easing.OutBack

                                        easing.overshoot:
                                            1.3
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn:
                                    parent

                                text:
                                    "󰅂"

                                font.family:
                                    "Symbols Nerd Font"

                                font.pixelSize:
                                    Appearance.iconSize

                                color:
                                    nextMonthMouse.containsMouse
                                        ? root.accentColor
                                        : Colors.text

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            MouseArea {
                                id: nextMonthMouse

                                anchors.fill:
                                    parent

                                hoverEnabled:
                                    true

                                onClicked: {
                                    root.viewedMonth =
                                        new Date(
                                            root.viewedMonth.getFullYear(),
                                            root.viewedMonth.getMonth() + 1,
                                            1
                                        )
                                }
                            }
                        }
                    }

                    // ─────────────────────────
                    // Weekday labels
                    // ─────────────────────────

                    Grid {
                        id: weekdayGrid

                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        columns:
                            7

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

                    // ─────────────────────────
                    // Days
                    // ─────────────────────────

                    Grid {
                        id: daysGrid

                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        columns:
                            7

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
                                    anchors.fill:
                                        parent

                                    radius:
                                        Appearance.controlRadius

                                    visible:
                                        dayItem.validDay

                                    color: {
                                        if (dayItem.isToday)
                                            return root.accentColor

                                        if (
                                            dayMouse.containsMouse
                                        ) {
                                            return Colors.surface1
                                        }

                                        return "transparent"
                                    }

                                    border.width:
                                        !dayItem.isToday
                                        && dayMouse.containsMouse
                                            ? Appearance.borderWidth / 2
                                            : 0

                                    border.color:
                                        root.accentColor

                                    scale:
                                        dayMouse.containsMouse
                                            ? 1.05
                                            : 1.0

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 180

                                            easing.type:
                                                Easing.OutBack

                                            easing.overshoot:
                                                1.2
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn:
                                        parent

                                    visible:
                                        dayItem.validDay

                                    text:
                                        dayItem.dayNumber

                                    color:
                                        dayItem.isToday
                                            ? Colors.base
                                            : dayMouse.containsMouse
                                                ? root.accentColor
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

                                    anchors.fill:
                                        parent

                                    hoverEnabled:
                                        true

                                    enabled:
                                        dayItem.validDay
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
    // Clock update
    // ─────────────────────────────────────────

    Timer {
        interval:
            1000

        running:
            true

        repeat:
            true

        onTriggered: {
            root.currentTime =
                new Date()
        }
    }

    // ─────────────────────────────────────────
    // Opening
    // ─────────────────────────────────────────

    Timer {
        id: contentDelay

        interval:
            210

        repeat:
            false

        onTriggered: {
            calendarContent.opacity =
                1.0
        }
    }

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
                    calendarContent

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

                calendarContent.opacity =
                    0.0

            }
        }
    }
}
