import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: win
    visible: true
    width: 1280
    height: 800
    title: "LSTack OS – Client (PoC)"

    header: TopBar { }

    footer: StatusBar {
        leftText: "PoC – no DB yet"
        rightText: Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        GroupBox {
            title: "Dashboard"
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            RowLayout {
                anchors.fill: parent
                spacing: 16
                Label { text: "Open Incidents: 0" }
                Label { text: "Active Units: 0" }
                Label { text: "Weather: n/a" }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            border.width: 1
            border.color: "#cccccc"
            color: "#f6f6f6"
            Text {
                anchors.centerIn: parent
                text: "Map placeholder (OSM later)"
                font.pixelSize: 22
                color: "#666666"
            }
        }
    }
}
