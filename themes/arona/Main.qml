import QtQuick
import SddmComponents

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1a1a2e"

    property string videoPath: "/opt/arona-wallpaper/arona-video.mp4"
    property string wallpaperPath: "/usr/share/backgrounds/kali/arona-wallpaper.png"

    Component.onCompleted: {
        if (sddm.hasOwnProperty("videoPath")) {
            videoPath = sddm.videoPath
        }
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: wallpaperPath
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#00000000"

        Repeater {
            model: 40

            Rectangle {
                property real startX: Math.random() * root.width
                property real startY: Math.random() * root.height
                property real duration: 8000 + Math.random() * 6000
                property real particleSize: 2 + Math.random() * 4
                property real opacityVal: 0.2 + Math.random() * 0.4

                x: startX
                y: startY
                width: particleSize
                height: particleSize
                radius: particleSize / 2
                color: "#5c8ec4"
                opacity: opacityVal

                ParallelAnimation {
                    running: true
                    loops: -1

                    NumberAnimation {
                        target: parent
                        property: "y"
                        from: parent.startY
                        to: parent.startY - 60 - Math.random() * 40
                        duration: parent.duration
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        target: parent
                        property: "opacity"
                        from: parent.opacityVal
                        to: 0
                        duration: parent.duration
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: parent
                        property: "x"
                        from: parent.startX
                        to: parent.startX + (Math.random() - 0.5) * 30
                        duration: parent.duration
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        Rectangle {
            id: scanLine
            width: parent.width
            height: 2
            color: "#5c8ec4"
            opacity: 0.08

            NumberAnimation on y {
                from: 0
                to: root.height
                duration: 6000
                loops: -1
            }
        }
    }

    Rectangle {
        id: loginBox
        width: 380
        height: 420
        anchors.centerIn: parent
        color: "#1a1a2e"
        opacity: 0.82
        radius: 12
        clip: true
        z: 10

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 18

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "KALI GNU/LINUX"
                color: "#5c8ec4"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
                color: "#888888"
                font.pixelSize: 13
            }

            Item { width: 1; height: 8 }

            Column {
                spacing: 8

                Text {
                    text: "User"
                    color: "#aaaaaa"
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 280
                    height: 36
                    color: "#0d0d1a"
                    radius: 4
                    border.color: "#3a3a5c"
                    border.width: 1

                    TextInput {
                        id: userEntry
                        anchors.fill: parent
                        anchors.margins: 8
                        color: "#ffffff"
                        font.pixelSize: 14
                        text: sddm.userName
                        verticalAlignment: Text.AlignVCenter
                        focus: true
                        KeyNavigation.tab: passwordEntry

                        onTextChanged: sddm.userName = text
                    }
                }
            }

            Column {
                spacing: 8

                Text {
                    text: "Password"
                    color: "#aaaaaa"
                    font.pixelSize: 12
                }

                Rectangle {
                    width: 280
                    height: 36
                    color: "#0d0d1a"
                    radius: 4
                    border.color: "#3a3a5c"
                    border.width: 1

                    TextInput {
                        id: passwordEntry
                        anchors.fill: parent
                        anchors.margins: 8
                        color: "#ffffff"
                        font.pixelSize: 14
                        echoMode: TextInput.Password
                        verticalAlignment: Text.AlignVCenter
                        KeyNavigation.tab: loginButton

                        Keys.onReturnPressed: sddm.login(userEntry.text, passwordEntry.text)
                    }
                }
            }

            Item { width: 1; height: 4 }

            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: loginButton
                    width: 90
                    height: 32
                    color: "#2a2a4a"
                    radius: 4
                    border.color: "#3a3a5c"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Login"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.login(userEntry.text, passwordEntry.text)
                        hoverEnabled: true
                        onEntered: parent.color = "#3a6ea5"
                        onExited: parent.color = "#2a2a4a"
                    }
                }

                Rectangle {
                    width: 90
                    height: 32
                    color: "#2a2a4a"
                    radius: 4
                    border.color: "#3a3a5c"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Shutdown"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.powerOff()
                        hoverEnabled: true
                        onEntered: parent.color = "#3a6ea5"
                        onExited: parent.color = "#2a2a4a"
                    }
                }

                Rectangle {
                    width: 90
                    height: 32
                    color: "#2a2a4a"
                    radius: 4
                    border.color: "#3a3a5c"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Reboot"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.reboot()
                        hoverEnabled: true
                        onEntered: parent.color = "#3a6ea5"
                        onExited: parent.color = "#2a2a4a"
                    }
                }
            }

            Item { width: 1; height: 8 }

            Column {
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter

                ComboBox {
                    id: sessionCombo
                    width: 280
                    height: 30
                    model: sessionModel
                    index: sessionModel.lastIndex

                    onValueChanged: {
                        var item = sessionModel.get(sessionCombo.index)
                        if (item) {
                            sddm.session = item.file
                        }
                    }
                }

                ComboBox {
                    id: layoutCombo
                    width: 280
                    height: 30
                    model: keyboardModel
                    onValueChanged: {
                        var item = keyboardModel.get(layoutCombo.index)
                        if (item) {
                            sddm.layout = item.shortName
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: clockBox
        anchors.horizontalCenter: parent.horizontalCenter
        y: 60
        z: 5

        Text {
            id: clockText
            anchors.centerIn: parent
            color: "#000000"
            font.pixelSize: 36
            font.bold: true

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm:ss")
            }

            Component.onCompleted: clockText.text = Qt.formatDateTime(new Date(), "HH:mm:ss")
        }
    }

    Rectangle {
        id: pulseBorder
        anchors.fill: loginBox
        color: "transparent"
        radius: 12
        z: 9
        border.color: "#5c8ec4"
        border.width: 2
        opacity: 0.3

        SequentialAnimation on opacity {
            loops: -1
            NumberAnimation { from: 0.15; to: 0.5; duration: 2000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.5; to: 0.15; duration: 2000; easing.type: Easing.InOutSine }
        }
    }
}
