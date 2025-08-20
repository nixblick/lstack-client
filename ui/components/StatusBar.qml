import QtQuick 2.15
import QtQuick.Controls 2.15

ToolBar {
    property string leftText: ""
    property string rightText: ""
    RowLayout {
        anchors.fill: parent
        Label { text: leftText }
        Item { Layout.fillWidth: true }
        Label { text: rightText }
    }
}
