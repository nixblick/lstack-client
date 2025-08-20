import QtQuick 2.15
import QtQuick.Controls 2.15

ToolBar {
    RowLayout {
        anchors.fill: parent
        ToolButton { text: "New Incident" }
        ToolButton { text: "Units" }
        ToolButton { text: "Search" }
        Item { Layout.fillWidth: true }
        ToolButton { text: "Settings" }
    }
}
