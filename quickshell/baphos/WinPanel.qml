// Окно-виджет в стиле Win98: выпуклая рамка, тёмно-красный заголовок с шахматкой и значком.
import QtQuick

Bevel {
    id: win
    property string title: ""
    property string icon: ""
    default property alias body: content.data

    implicitWidth: 260
    implicitHeight: content.childrenRect.height + 22 + inset * 2 + 8

    Rectangle {
        id: titleBar
        x: 0; y: 0
        width: parent.width; height: 22
        color: Theme.blood
        Image { anchors.fill: parent; source: Theme.asset("ui/checker.png"); fillMode: Image.Tile; smooth: false; opacity: 0.5 }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#c0000000" }
            }
        }
        Row {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 4
            Image { visible: win.icon !== ""; source: win.icon ? Theme.icon(win.icon, "bone") : ""; width: 24; height: 24; smooth: false; anchors.verticalCenter: parent.verticalCenter }
            PixelText { text: win.title; color: Theme.text; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    Item {
        id: content
        anchors { left: parent.left; right: parent.right; top: titleBar.bottom; margins: 7 }
        height: childrenRect.height
    }
}
