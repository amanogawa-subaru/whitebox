import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    // ═════════════════════════════════════════
    // Paths
    // ═════════════════════════════════════════

    readonly property string homeDirectory:
        Quickshell.env("HOME") || ""

    /*
     * Runtime-facing wallpaper directory.
     *
     * Home Manager exposes the Whitebox wallpapers here,
     * so Quickshell does not need to know where the repo
     * itself lives.
     */
    readonly property string wallpaperDirectory:
        root.homeDirectory
        + "/.config/hypr/wallpapers"

    readonly property string stateDirectory:
        root.homeDirectory
        + "/.local/state/whitebox"

    readonly property string stateFile:
        root.stateDirectory
        + "/wallpaper"

    readonly property string defaultWallpaper:
        root.wallpaperDirectory
        + "/92501787_p0_1440.jpg"

    // ═════════════════════════════════════════
    // State
    // ═════════════════════════════════════════

    property var wallpapers: []

    property string currentWallpaper: ""
    property string pendingWallpaper: ""

    property bool pendingPersist: false

    property int restoreRetryCount: 0

    readonly property int maxRestoreRetries:
        12

    signal wallpaperApplied(string path)

    // ═════════════════════════════════════════
    // Public API
    // ═════════════════════════════════════════

    function refreshWallpapers() {
        listProcess.exec([
            "find",
            "-H",
            root.wallpaperDirectory,
            "-maxdepth",
            "1",
            "-type",
            "f",
            "(",
            "-iname",
            "*.jpg",
            "-o",
            "-iname",
            "*.jpeg",
            "-o",
            "-iname",
            "*.png",
            "-o",
            "-iname",
            "*.webp",
            ")",
            "-print"
        ])
    }

    function restore() {
        restoreProcess.exec([
            "sh",
            "-c",
            [
                'state="$1"',
                'fallback="$2"',
                'state_dir="$3"',
                'selected=""',
                '',
                'if [ -f "$state" ]; then',
                '    IFS= read -r selected < "$state" || true',
                'fi',
                '',
                'if [ -z "$selected" ] || [ ! -f "$selected" ]; then',
                '    selected="$fallback"',
                'fi',
                '',
                'if [ ! -f "$selected" ]; then',
                '    exit 1',
                'fi',
                '',
                'mkdir -p "$state_dir"',
                'printf "%s\\n" "$selected" > "$state"',
                'printf "%s" "$selected"'
            ].join("\n"),
            "whitebox-wallpaper-restore",
            root.stateFile,
            root.defaultWallpaper,
            root.stateDirectory
        ])
    }

    function setWallpaper(path) {
        const selected =
            String(path || "").trim()

        if (selected.length === 0)
            return

        root.restoreRetryCount = 0

        root.applyWallpaper(
            selected,
            true
        )
    }

    function applyWallpaper(path, persist) {
        root.pendingWallpaper =
            path

        root.pendingPersist =
            persist

        applyProcess.exec([
            "hyprctl",
            "hyprpaper",
            "wallpaper",
            ", " + path + ", cover"
        ])
    }

    // ═════════════════════════════════════════
    // Wallpaper discovery
    // ═════════════════════════════════════════

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const raw =
                    text.trim()

                if (raw.length === 0) {
                    root.wallpapers = []
                    return
                }

                root.wallpapers =
                    raw
                        .split("\n")
                        .filter(path =>
                            path.length > 0
                        )
                        .sort()
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.wallpapers = []

                console.warn(
                    "WallpaperBackend: "
                    + "could not enumerate wallpapers"
                )
            }
        }
    }

    // ═════════════════════════════════════════
    // Restore saved wallpaper
    // ═════════════════════════════════════════

    Process {
        id: restoreProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const path =
                    text.trim()

                if (path.length === 0)
                    return

                root.restoreRetryCount = 0

                root.applyWallpaper(
                    path,
                    false
                )
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn(
                    "WallpaperBackend: "
                    + "no valid saved/default wallpaper"
                )
            }
        }
    }

    // ═════════════════════════════════════════
    // Hyprpaper IPC
    // ═════════════════════════════════════════

    Process {
        id: applyProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.currentWallpaper =
                    root.pendingWallpaper

                root.restoreRetryCount =
                    0

                if (root.pendingPersist) {
                    persistProcess.exec([
                        "sh",
                        "-c",
                        [
                            'state_dir="$1"',
                            'state="$2"',
                            'wallpaper="$3"',
                            '',
                            'mkdir -p "$state_dir"',
                            'printf "%s\\n" "$wallpaper" > "$state"'
                        ].join("\n"),
                        "whitebox-wallpaper-save",
                        root.stateDirectory,
                        root.stateFile,
                        root.pendingWallpaper
                    ])
                }

                root.wallpaperApplied(
                    root.currentWallpaper
                )

                return
            }

            /*
             * Quickshell and Hyprpaper may start at nearly
             * the same time. Retry startup restoration for
             * a few seconds, but never retry an interactive
             * selection indefinitely.
             */
            if (
                !root.pendingPersist
                && root.restoreRetryCount
                    < root.maxRestoreRetries
            ) {
                root.restoreRetryCount += 1

                restoreRetryTimer.restart()

                return
            }

            console.warn(
                "WallpaperBackend: "
                + "Hyprpaper rejected wallpaper: "
                + root.pendingWallpaper
            )
        }
    }

    // ═════════════════════════════════════════
    // Persist runtime selection
    // ═════════════════════════════════════════

    Process {
        id: persistProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn(
                    "WallpaperBackend: "
                    + "could not save wallpaper state"
                )
            }
        }
    }

    // ═════════════════════════════════════════
    // Startup timing
    // ═════════════════════════════════════════

    Timer {
        id: restoreRetryTimer

        interval:
            250

        repeat:
            false

        onTriggered: {
            root.applyWallpaper(
                root.pendingWallpaper,
                false
            )
        }
    }

    Timer {
        id: initialRestoreTimer

        interval:
            350

        repeat:
            false

        onTriggered:
            root.restore()
    }

    Component.onCompleted: {
        root.refreshWallpapers()

        initialRestoreTimer.start()
    }
}
