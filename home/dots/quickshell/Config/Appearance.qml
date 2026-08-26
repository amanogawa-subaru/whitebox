pragma Singleton

import QtQuick

QtObject {
    // Global UI scale
    readonly property real scale: 1.0
    
    // Spacing
    readonly property real moduleSpacing: 10 * scale
    readonly property real screenMargin: 10 * scale
    readonly property real panelBottomMargin: 0 * scale

    // Borders
    readonly property real borderWidth: 4 * scale

    // Icons / text
    readonly property real iconSize: 22 * scale
    readonly property real textSize: 16 * scale

	// Module geometry
	readonly property real moduleHeight: 56 * scale
	readonly property real moduleRadius: 14 * scale
	readonly property real controlRadius: 6 * scale
    
	// Search module
	readonly property real searchWidth: 270 * scale
	readonly property real searchMaxHeight: 500 * scale
	readonly property real searchEmptyHeight: 110 * scale
	readonly property real appRowHeight: 32 * scale
	readonly property real appIconSize: 24 * scale
	
	// Workspace module
	readonly property real workspaceWidth: 170 * scale
	
	// Time module
	readonly property real timeWidth: 150 * scale
	readonly property real calendarWidth: 320 * scale
	readonly property real calendarHeight: 370 * scale

	// Music module
	readonly property real musicExpandedWidth: 450 * scale
	readonly property real albumArtSize: 190 * scale

	// Power module
	readonly property real powerExpandedWidth: 370 * scale
	readonly property real powerContentWidth: 330 * scale

}
