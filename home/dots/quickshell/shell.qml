//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "Config"
import "modules"

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 1000
    
    exclusiveZone: Appearance.moduleHeight + Appearance.screenMargin + Appearance.panelBottomMargin
    
	focusable: true
	
	WlrLayershell.keyboardFocus: searchModule.expanded
		? WlrKeyboardFocus.OnDemand
		: WlrKeyboardFocus.None
		
    color: "transparent"
    
	mask: Region {
		Region {
			x: leftModules.x
			y: leftModules.y
			width: leftModules.width
			height: leftModules.height
		}

		Region {
			x: timeModule.x
			y: timeModule.y
			width: timeModule.width
			height: timeModule.height
		}

		Region {
			x: rightModules.x
			y: rightModules.y
			width: rightModules.width
			height: rightModules.height
		}
	}
    
    Row {
		id: leftModules

		anchors {
			left: parent.left
			top: parent.top

			leftMargin: Appearance.screenMargin
			topMargin: Appearance.screenMargin
		}

		spacing: Appearance.moduleSpacing

		SearchModule {
			id: searchModule
		}

		WorkspaceModule {
			id: workspaceModule
		}
	}
	
	TimeModule {
		id: timeModule

		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
			topMargin: Appearance.screenMargin
		}
	}
    
	Row {
		id: rightModules

		anchors {
			right: parent.right
			top: parent.top

			rightMargin: Appearance.screenMargin
			topMargin: Appearance.screenMargin
		}

		spacing: Appearance.moduleSpacing

		MusicModule {
			id: musicModule
		}
		
		SystrayModule {
			id: systrayModule
		}		

		PowerModule {
			id: powerModule
		}
	}
    
    HyprlandFocusGrab {
		id: searchFocusGrab

		windows: [root]
		active: searchModule.expanded

		onCleared: {
			searchModule.close ()
		}
	}
	
	HyprlandFocusGrab {
		id: timeFocusGrab

		windows: [root]
		active: timeModule.expanded

		onCleared: {
			timeModule.close()
		}
	}
	
	HyprlandFocusGrab {
		id: powerFocusGrab

		windows: [root]
		active: powerModule.expanded

		onCleared: {
			powerModule.close()
		}
	}
	
	HyprlandFocusGrab {
		id: musicFocusGrab

		windows: [root]
		active: musicModule.expanded

		onCleared: {
			musicModule.close()
		}
	}
	
	IpcHandler {
        target: "search"

        function toggle(): void {
            searchModule.toggle()
        }
    }
}
