import QtQuick
import Quickshell
import Quickshell.Io

import "../Config"

FocusScope {
    id: root

    property color accentColor:
        Colors.pink

    signal closeRequested()

    // ═════════════════════════════════════════
    // State
    // ═════════════════════════════════════════

    property var entries:
        []

    property string query:
        ""

    property bool loading:
        false

    /*
     * Restoring an entry through wl-copy can cause
     * cliphist to re-record it under a new numeric ID.
     * If the restored entry was pinned, migrate that
     * pin to the new ID after the history refresh.
     */
    property string pendingPinnedRestoreId:
        ""

    /*
     * cliphist has no native pin concept, so pins
     * are a lightweight Quickshell-side feature.
     * IDs are persisted in the user's cache and
     * pinned entries are sorted above normal ones.
     */
    property var pinnedIds:
        []

    readonly property string pinStorePath:
        "$HOME/.cache/quickshell/clipboard-pins"

    function isPinned(id) {
        return root.pinnedIds.indexOf(
            String(id)
        ) >= 0
    }

    readonly property var filteredEntries: {
        let visibleEntries =
            root.entries

        if (root.query.trim() !== "") {
            const needle =
                root.query.toLowerCase()

            visibleEntries =
                root.entries.filter(entry =>
                    entry.text
                        .toLowerCase()
                        .includes(needle)
                )
        }

        /*
         * Pins float first. Within pinned and
         * unpinned groups, preserve cliphist's
         * native newest-first order explicitly.
         *
         * Do not return 0 for same-group entries:
         * Qt/QML's JS sort can reorder equal items
         * during model refreshes (image previews
         * made this especially visible).
         */
        return visibleEntries
            .slice()
            .sort((a, b) => {
                const aPinned =
                    root.isPinned(a.id)

                const bPinned =
                    root.isPinned(b.id)

                if (aPinned !== bPinned) {
                    return aPinned
                        ? -1
                        : 1
                }

                return a.recencyIndex
                    - b.recencyIndex
            })
    }


    property real headerHeight:
        48 * Appearance.scale

    property real searchHeight:
        38 * Appearance.scale

    property real rowHeight:
        42 * Appearance.scale

    property real imageRowHeight:
        96 * Appearance.scale

    property real imagePreviewWidth:
        118 * Appearance.scale

    readonly property string previewDirectory:
        "/tmp/whitebox-cliphist-previews"

    function isImagePreviewText(text) {
        /*
         * cliphist's exact placeholder text varies
         * between versions/builds. Do not depend
         * on MIME/format text being present here.
         *
         * We decode every binary entry, then let
         * QML Image.status determine whether the
         * decoded payload is actually an image.
         */
        const value =
            String(text).toLowerCase()

        return /^\[\[\s*binary\s+data\b/.test(value)
    }

    function previewPath(id) {
        return root.previewDirectory
            + "/"
            + String(id)
            + ".img"
    }

    function previewUrl(id, generation) {
        return "file://"
            + root.previewPath(id)
            + "?v="
            + String(generation)
    }

    property real contentMargin:
        14 * Appearance.scale

    property real maximumListHeight:
        330 * Appearance.scale

    readonly property real listHeight:
        Math.min(
            root.maximumListHeight,
            Math.max(
                110 * Appearance.scale,
                filteredColumn.implicitHeight
                + root.contentMargin * 2
            )
        )

    implicitHeight:
        root.headerHeight
        + root.searchHeight
        + root.contentMargin * 2
        + root.listHeight

    height:
        implicitHeight


    // ═════════════════════════════════════════
    // Load history
    // ═════════════════════════════════════════

    function refresh() {
        if (listProcess.running)
            return

        root.loading =
            true

        listProcess.running =
            true
    }

    Process {
        id: listProcess

        command: [
            "cliphist",
            "list"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = []

                const lines =
                    text.split("\n")

                for (
                    let i = 0;
                    i < lines.length;
                    ++i
                ) {
                    const line =
                        lines[i]

                    if (line.trim() === "")
                        continue

                    const tabIndex =
                        line.indexOf("\t")

                    if (tabIndex < 0)
                        continue

                    const id =
                        line.substring(
                            0,
                            tabIndex
                        ).trim()

                    let preview =
                        line.substring(
                            tabIndex + 1
                        )

                    /*
                     * Make multiline clipboard data
                     * usable inside one compact row.
                     */
                    preview =
                        preview
                            .replace(/\s+/g, " ")
                            .trim()

                    result.push({
                        id: id,
                        text: preview,
                        isImage:
                            root.isImagePreviewText(preview),

                        /*
                         * cliphist list is already
                         * newest-first. Record that
                         * position explicitly so our
                         * pin sort never depends on
                         * JS sort stability.
                         */
                        recencyIndex:
                            result.length
                    })
                }

                /*
                 * A restored clipboard item is re-added by
                 * cliphist as the newest entry. Preserve a
                 * pin across that ID change instead of
                 * leaving the pin attached to the stale ID.
                 */
                if (
                    root.pendingPinnedRestoreId !== ""
                    && result.length > 0
                ) {
                    const oldId =
                        root.pendingPinnedRestoreId

                    const newId =
                        String(result[0].id)

                    if (newId !== oldId) {
                        const next =
                            root.pinnedIds
                                .filter(id =>
                                    String(id) !== oldId
                                )

                        if (
                            next.indexOf(newId)
                            < 0
                        ) {
                            next.push(newId)
                        }

                        root.pinnedIds =
                            next

                        root.savePins()
                    }

                    root.pendingPinnedRestoreId =
                        ""
                }

                root.entries =
                    result

                root.loading =
                    false
            }
        }
    }


    // ═════════════════════════════════════════
    // Restore clipboard entry
    // ═════════════════════════════════════════

    function restoreEntry(id) {
        const stringId =
            String(id)

        root.pendingPinnedRestoreId =
            root.isPinned(stringId)
                ? stringId
                : ""

        /*
         * cliphist IDs are numeric, but quote it
         * anyway so this remains harmless if the
         * format ever changes.
         */
        restoreProcess.command = [
            "sh",
            "-c",
            "cliphist decode "
                + "'" + stringId.replace(/'/g, "'\\''") + "'"
                + " | wl-copy"
        ]

        restoreProcess.running =
            true
    }

    Process {
        id: restoreProcess

        onExited:
            restoreRefreshTimer.restart()
    }

    Timer {
        id: restoreRefreshTimer

        interval:
            120

        repeat:
            false

        onTriggered:
            root.refresh()
    }


    // ═════════════════════════════════════════
    // Pins
    // ═════════════════════════════════════════

    function loadPins() {
        if (loadPinsProcess.running)
            return

        loadPinsProcess.running =
            true
    }

    Process {
        id: loadPinsProcess

        command: [
            "sh",
            "-c",
            "cat "
                + root.pinStorePath
                + " 2>/dev/null || true"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const ids =
                    text
                        .split("\n")
                        .map(x => x.trim())
                        .filter(x => x !== "")

                root.pinnedIds =
                    ids
            }
        }
    }

    function savePins() {
        if (savePinsProcess.running)
            savePinsProcess.running =
                false

        const ids =
            root.pinnedIds
                .map(x => String(x))
                .filter(x => /^[0-9]+$/.test(x))

        let command =
            "mkdir -p \"$HOME/.cache/quickshell\"; "
            + ": > "
            + root.pinStorePath

        if (ids.length > 0) {
            command +=
                "; printf '%s\\n' "
                + ids.join(" ")
                + " >> "
                + root.pinStorePath
        }

        savePinsProcess.command = [
            "sh",
            "-c",
            command
        ]

        savePinsProcess.running =
            true
    }

    Process {
        id: savePinsProcess
    }

    function togglePin(id) {
        const stringId =
            String(id)

        const next =
            root.pinnedIds.slice()

        const index =
            next.indexOf(stringId)

        if (index >= 0)
            next.splice(index, 1)
        else
            next.push(stringId)

        root.pinnedIds =
            next

        root.savePins()
    }


    // ═════════════════════════════════════════
    // Delete one clipboard entry
    // ═════════════════════════════════════════

    function deleteEntry(id) {
        if (deleteProcess.running)
            return

        const stringId =
            String(id)

        /*
         * Removing an item also removes its pin.
         */
        const index =
            root.pinnedIds.indexOf(stringId)

        if (index >= 0) {
            const next =
                root.pinnedIds.slice()

            next.splice(index, 1)

            root.pinnedIds =
                next

            root.savePins()
        }

        deleteProcess.command = [
            "sh",
            "-c",
            "printf '%s\\n' "
                + stringId
                + " | cliphist delete; "
                + "rm -f '"
                + root.previewPath(stringId)
                    .replace(/'/g, "'\\''")
                + "'"
        ]

        deleteProcess.running =
            true
    }

    Process {
        id: deleteProcess

        onExited:
            root.refresh()
    }


    // ═════════════════════════════════════════
    // Clear clipboard history
    // ═════════════════════════════════════════

    function clearHistory() {
        if (wipeProcess.running)
            return

        const unpinnedIds =
            root.entries
                .filter(entry =>
                    !root.isPinned(entry.id)
                )
                .map(entry =>
                    String(entry.id)
                )

        /*
         * No pins: use cliphist's native wipe.
         * Pins exist: delete every unpinned ID so
         * pinned history survives Clear All.
         */
        if (root.pinnedIds.length === 0) {
            wipeProcess.command = [
                "cliphist",
                "wipe"
            ]
        } else if (unpinnedIds.length > 0) {
            wipeProcess.command = [
                "sh",
                "-c",
                "printf '%s\\n' "
                    + unpinnedIds.join(" ")
                    + " | cliphist delete"
            ]
        } else {
            root.query =
                ""

            searchInput.text =
                ""

            return
        }

        wipeProcess.running =
            true
    }

    Process {
        id: wipeProcess

        onExited: {
            root.query =
                ""

            searchInput.text =
                ""

            root.refresh()
        }
    }


    // ═════════════════════════════════════════
    // Refresh behavior
    // ═════════════════════════════════════════

    onVisibleChanged: {
        if (visible) {
            root.query =
                ""

            root.loadPins()
            refreshTimer.restart()
        }
    }

    Component.onCompleted:
        root.loadPins()

    Timer {
        id: refreshTimer

        interval:
            80

        repeat:
            false

        onTriggered: {
            root.refresh()

            searchInput.forceActiveFocus()
        }
    }

    /*
     * While Clipboard is open, periodically pick
     * up copies made by another application.
     */
    Timer {
        interval:
            1000

        repeat:
            true

        running:
            root.visible

        onTriggered:
            root.refresh()
    }


    // ═════════════════════════════════════════
    // Header
    // ═════════════════════════════════════════

    Item {
        id: header

        width:
            parent.width

        height:
            root.headerHeight

        Row {
            anchors {
                right:
                    parent.right

                rightMargin:
                    14 * Appearance.scale

                verticalCenter:
                    parent.verticalCenter
            }

            spacing:
                10 * Appearance.scale

            Text {
                anchors.verticalCenter:
                    parent.verticalCenter

                text:
                    root.loading
                        ? "Loading..."
                        : root.filteredEntries.length
                            + " items"

                color:
                    Colors.subtext0

                font.pixelSize:
                    Appearance.textSize - 2
            }

            Item {
                width:
                    28 * Appearance.scale

                height:
                    28 * Appearance.scale

                visible:
                    root.entries.length > 0

                Text {
                    anchors.centerIn:
                        parent

                    text:
                        "󰆴"

                    font.family:
                        "Symbols Nerd Font"

                    font.pixelSize:
                        Appearance.iconSize - 2

                    color:
                        clearMouse.containsMouse
                            ? Colors.red
                            : Colors.subtext0

                    scale:
                        clearMouse.containsMouse
                            ? 1.15
                            : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration:
                                130
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration:
                                180

                            easing.type:
                                Easing.OutBack

                            easing.overshoot:
                                1.35
                        }
                    }
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    acceptedButtons:
                        Qt.LeftButton

                    onClicked:
                        root.clearHistory()
                }
            }
        }
    }


    // ═════════════════════════════════════════
    // Search
    // ═════════════════════════════════════════

    Rectangle {
        id: searchCard

        anchors {
            left:
                parent.left

            right:
                parent.right

            top:
                header.bottom

            leftMargin:
                root.contentMargin

            rightMargin:
                root.contentMargin
        }

        height:
            root.searchHeight

        radius:
            Appearance.controlRadius

        color:
            Colors.surface0

        border.width:
            Appearance.borderWidth / 2

        border.color:
            searchInput.activeFocus
                ? root.accentColor
                : Colors.surface1

        Behavior on border.color {
            ColorAnimation {
                duration:
                    150
            }
        }

        Text {
            anchors {
                left:
                    parent.left

                leftMargin:
                    12 * Appearance.scale

                verticalCenter:
                    parent.verticalCenter
            }

            text:
                "󰍉"

            font.family:
                "Symbols Nerd Font"

            font.pixelSize:
                Appearance.iconSize - 2

            color:
                root.accentColor
        }

        TextInput {
            id: searchInput

            anchors {
                left:
                    parent.left

                right:
                    parent.right

                verticalCenter:
                    parent.verticalCenter

                leftMargin:
                    42 * Appearance.scale

                rightMargin:
                    12 * Appearance.scale
            }

            text:
                root.query

            color:
                Colors.text

            selectionColor:
                root.accentColor

            selectedTextColor:
                Colors.base

            font.pixelSize:
                Appearance.textSize

            clip:
                true

            onTextChanged:
                root.query = text

            Keys.onEscapePressed: event => {
                if (root.query !== "") {
                    root.query =
                        ""

                    searchInput.text =
                        ""

                    event.accepted =
                        true

                    return
                }

                root.closeRequested()

                event.accepted =
                    true
            }
        }

        Text {
            anchors {
                left:
                    searchInput.left

                verticalCenter:
                    parent.verticalCenter
            }

            visible:
                searchInput.text.length === 0
                && !searchInput.activeFocus

            text:
                "Search clipboard..."

            color:
                Colors.overlay0

            font.pixelSize:
                Appearance.textSize
        }

        MouseArea {
            anchors.fill:
                parent

            acceptedButtons:
                Qt.LeftButton

            onClicked:
                searchInput.forceActiveFocus()
        }
    }


    // ═════════════════════════════════════════
    // History
    // ═════════════════════════════════════════

    Item {
        anchors {
            left:
                parent.left

            right:
                parent.right

            top:
                searchCard.bottom

            bottom:
                parent.bottom

            margins:
                root.contentMargin
        }


        // Empty state

        Column {
            visible:
                !root.loading
                && root.filteredEntries.length === 0

            anchors.centerIn:
                parent

            spacing:
                10 * Appearance.scale

            Text {
                anchors.horizontalCenter:
                    parent.horizontalCenter

                text:
                    "󰅇"

                font.family:
                    "Symbols Nerd Font"

                font.pixelSize:
                    38 * Appearance.scale

                color:
                    root.accentColor
            }

            Text {
                anchors.horizontalCenter:
                    parent.horizontalCenter

                text:
                    root.entries.length === 0
                        ? "Clipboard history is empty"
                        : "No matching entries"

                color:
                    Colors.subtext0

                font.pixelSize:
                    Appearance.textSize
            }
        }


        Flickable {
            visible:
                root.filteredEntries.length > 0

            anchors.fill:
                parent

            contentWidth:
                width

            contentHeight:
                filteredColumn.implicitHeight

            clip:
                true

            boundsBehavior:
                Flickable.StopAtBounds

            Column {
                id: filteredColumn

                width:
                    parent.width

                spacing:
                    8 * Appearance.scale

                Repeater {
                    model:
                        root.filteredEntries

                    delegate: Rectangle {
                        id: entryCard

                        required property var modelData

                        width:
                            filteredColumn.width

                        height:
                            (
                                modelData.isImage
                                && imagePreviewArea.actualImage
                            )
                                ? root.imageRowHeight
                                : root.rowHeight

                        radius:
                            Appearance.controlRadius

                        color:
                            entryCard.hovered
                                ? root.accentColor
                                : Colors.surface0

                        border.width:
                            Appearance.borderWidth / 2

                        border.color:
                            entryCard.hovered
                                ? root.accentColor
                                : Colors.surface1

                        scale:
                            entryCard.hovered
                                ? 1.015
                                : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration:
                                    130
                            }
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration:
                                    130
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration:
                                    180

                                easing.type:
                                    Easing.OutBack

                                easing.overshoot:
                                    1.25
                            }
                        }

                        readonly property bool hovered:
                            entryMouse.containsMouse
                            || pinMouse.containsMouse
                            || deleteMouse.containsMouse

                        // Normal text clipboard entry

                        Text {
                            visible:
                                !modelData.isImage

                            anchors {
                                left:
                                    parent.left

                                right:
                                    rowActions.left

                                verticalCenter:
                                    parent.verticalCenter

                                leftMargin:
                                    12 * Appearance.scale

                                rightMargin:
                                    8 * Appearance.scale
                            }

                            text:
                                modelData.text

                            color:
                                entryCard.hovered
                                    ? Colors.base
                                    : Colors.text

                            font.pixelSize:
                                Appearance.textSize - 1

                            elide:
                                Text.ElideRight

                            maximumLineCount:
                                1
                        }


                        // Image clipboard entry

                        Item {
                            id: imagePreviewArea

                            visible:
                                modelData.isImage
                                && imagePreviewArea.actualImage

                            anchors {
                                left:
                                    parent.left

                                right:
                                    rowActions.left

                                top:
                                    parent.top

                                bottom:
                                    parent.bottom

                                leftMargin:
                                    8 * Appearance.scale

                                rightMargin:
                                    8 * Appearance.scale

                                topMargin:
                                    7 * Appearance.scale

                                bottomMargin:
                                    7 * Appearance.scale
                            }

                            property int previewGeneration:
                                0

                            property bool previewReady:
                                false

                            readonly property bool actualImage:
                                previewImage.status === Image.Ready

                            Rectangle {
                                id: thumbnailFrame

                                anchors {
                                    left:
                                        parent.left

                                    top:
                                        parent.top

                                    bottom:
                                        parent.bottom
                                }

                                width:
                                    Math.min(
                                        root.imagePreviewWidth,
                                        imagePreviewArea.width
                                    )

                                radius:
                                    Appearance.controlRadius - 2

                                color:
                                    entryCard.hovered
                                        ? Colors.surface0
                                        : Colors.base

                                clip:
                                    true

                                border.width:
                                    Appearance.borderWidth / 2

                                border.color:
                                    entryCard.hovered
                                        ? Colors.base
                                        : Colors.surface1

                                Image {
                                    id: previewImage

                                    anchors.fill:
                                        parent

                                    anchors.margins:
                                        3 * Appearance.scale

                                    source:
                                        imagePreviewArea.previewReady
                                            ? root.previewUrl(
                                                modelData.id,
                                                imagePreviewArea.previewGeneration
                                            )
                                            : ""

                                    fillMode:
                                        Image.PreserveAspectFit

                                    asynchronous:
                                        true

                                    cache:
                                        false

                                    smooth:
                                        true
                                }

                                Text {
                                    visible:
                                        !imagePreviewArea.previewReady

                                    anchors.centerIn:
                                        parent

                                    text:
                                        "󰋩"

                                    font.family:
                                        "Symbols Nerd Font"

                                    font.pixelSize:
                                        28 * Appearance.scale

                                    color:
                                        entryCard.hovered
                                            ? Colors.base
                                            : root.accentColor
                                }
                            }

                            Column {
                                anchors {
                                    left:
                                        thumbnailFrame.right

                                    right:
                                        parent.right

                                    verticalCenter:
                                        parent.verticalCenter

                                    leftMargin:
                                        10 * Appearance.scale
                                }

                                spacing:
                                    3 * Appearance.scale

                                Text {
                                    text:
                                        "Image"

                                    color:
                                        entryCard.hovered
                                            ? Colors.base
                                            : Colors.text

                                    font.pixelSize:
                                        Appearance.textSize - 1

                                    font.bold:
                                        true
                                }

                                Text {
                                    width:
                                        parent.width

                                    text:
                                        modelData.text
                                            .replace(/^\[\[\s*binary\s+data\s*/i, "")
                                            .replace(/\]\]$/, "")

                                    color:
                                        entryCard.hovered
                                            ? Colors.surface0
                                            : Colors.subtext0

                                    font.pixelSize:
                                        Appearance.textSize - 3

                                    elide:
                                        Text.ElideRight

                                    maximumLineCount:
                                        1
                                }
                            }

                            Process {
                                id: previewProcess

                                command: [
                                    "sh",
                                    "-c",
                                    "mkdir -p "
                                        + root.previewDirectory
                                        + "; "
                                        + "test -s '"
                                        + root.previewPath(modelData.id)
                                            .replace(/'/g, "'\\''")
                                        + "' || cliphist decode '"
                                        + String(modelData.id)
                                            .replace(/'/g, "'\\''")
                                        + "' > '"
                                        + root.previewPath(modelData.id)
                                            .replace(/'/g, "'\\''")
                                        + "'"
                                ]

                                onExited: {
                                    imagePreviewArea.previewReady =
                                        true

                                    imagePreviewArea.previewGeneration +=
                                        1
                                }
                            }

                            Component.onCompleted: {
                                if (modelData.isImage)
                                    previewProcess.running =
                                        true
                            }
                        }

                        Row {
                            id: rowActions

                            z:
                                5

                            anchors {
                                right:
                                    parent.right

                                rightMargin:
                                    7 * Appearance.scale

                                verticalCenter:
                                    parent.verticalCenter
                            }

                            spacing:
                                2 * Appearance.scale

                            // Pin / unpin

                            Item {
                                width:
                                    28 * Appearance.scale

                                height:
                                    28 * Appearance.scale

                                Text {
                                    anchors.centerIn:
                                        parent

                                    text:
                                        "󰐃"

                                    font.family:
                                        "Symbols Nerd Font"

                                    font.pixelSize:
                                        Appearance.iconSize - 4

                                    color: {
                                        if (pinMouse.containsMouse)
                                            return Colors.base

                                        if (root.isPinned(modelData.id))
                                            return entryCard.hovered
                                                ? Colors.base
                                                : root.accentColor

                                        return entryCard.hovered
                                            ? Colors.surface0
                                            : Colors.overlay1
                                    }

                                    rotation:
                                        root.isPinned(modelData.id)
                                            ? 0
                                            : 35

                                    Behavior on color {
                                        ColorAnimation {
                                            duration:
                                                120
                                        }
                                    }

                                    Behavior on rotation {
                                        NumberAnimation {
                                            duration:
                                                180

                                            easing.type:
                                                Easing.OutBack
                                        }
                                    }
                                }

                                MouseArea {
                                    id: pinMouse

                                    anchors.fill:
                                        parent

                                    hoverEnabled:
                                        true

                                    acceptedButtons:
                                        Qt.LeftButton

                                    onClicked:
                                        root.togglePin(
                                            modelData.id
                                        )
                                }
                            }

                            // Delete one item

                            Item {
                                width:
                                    28 * Appearance.scale

                                height:
                                    28 * Appearance.scale

                                Text {
                                    anchors.centerIn:
                                        parent

                                    text:
                                        "󰅖"

                                    font.family:
                                        "Symbols Nerd Font"

                                    font.pixelSize:
                                        Appearance.iconSize - 4

                                    color:
                                        deleteMouse.containsMouse
                                            ? Colors.red
                                            : entryCard.hovered
                                                ? Colors.surface0
                                                : Colors.overlay1

                                    scale:
                                        deleteMouse.containsMouse
                                            ? 1.12
                                            : 1.0

                                    Behavior on color {
                                        ColorAnimation {
                                            duration:
                                                120
                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration:
                                                160

                                            easing.type:
                                                Easing.OutBack
                                        }
                                    }
                                }

                                MouseArea {
                                    id: deleteMouse

                                    anchors.fill:
                                        parent

                                    hoverEnabled:
                                        true

                                    acceptedButtons:
                                        Qt.LeftButton

                                    onClicked:
                                        root.deleteEntry(
                                            modelData.id
                                        )
                                }
                            }
                        }

                        MouseArea {
                            id: entryMouse

                            z:
                                1

                            anchors {
                                left:
                                    parent.left

                                right:
                                    rowActions.left

                                top:
                                    parent.top

                                bottom:
                                    parent.bottom
                            }

                            hoverEnabled:
                                true

                            acceptedButtons:
                                Qt.LeftButton

                            onClicked: {
                                root.restoreEntry(
                                    modelData.id
                                )

                                root.closeRequested()
                            }
                        }
                    }
                }
            }
        }
    }
}
