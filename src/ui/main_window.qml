// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright © 2021-2022 Adrian <adrian.eddy at gmail>

import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC
import QtQuick.Controls.Material
import Qt.labs.settings

import "components/"

Window {
    id: main_window;
    width: Math.min(Screen.width, 1650 * dpiScale);
    height: Math.min(Screen.height, 950 * dpiScale);
    visible: true;
    color: styleBackground;

    title: "Gyroflow v" + version;

    onVisibilityChanged: {
        Qt.callLater(() => {
            if (main_window.visibility != 0)
                sett.visibility = main_window.visibility;
        });
    }

    Settings {
        id: sett;
        property alias x: main_window.x;
        property alias y: main_window.y;
        property alias width: main_window.width;
        property alias height: main_window.height;
        property int visibility: 0;
    }

    Material.theme: Material.Dark;
    Material.accent: Material.Blue;

    function getApp(): App {
        for (let i = 0; i < contentItem.children.length; ++i) {
            let x = contentItem.children[i];
            if (x instanceof Loader) x = x.item;
            if (x.objectName == "App") return x;
        }
        return null;
    }

    Component.onCompleted: {
        ui_tools.set_icon(main_window);
        if (Qt.platform.os != "android" && Qt.platform.os != "ios") {
                 if (sett.visibility == Window.FullScreen) main_window.showFullScreen();
            else if (sett.visibility == Window.Maximized)  main_window.showMaximized();
            else {
                Qt.callLater(() => {
                    width = width + 1;
                    height = height;
                });
            }
        }
    }
    property bool isLandscape: width > height;
    onIsLandscapeChanged: {
        if (Qt.platform.os == "android" || Qt.platform.os == "ios") {
            Qt.callLater(() => {
                main_window.width = main_window.width + 1;
                main_window.height = main_window.height + 1;
                main_window.showFullScreen();
            });
        }
    }

    property bool closeConfirmationModal: false;
    property bool closeConfirmed: false;
    onClosing: (close) => {
        let app = getApp();
        if (app) {
            close.accepted = closeConfirmed || !app.wasModified;
            if (close.accepted) ui_tools.closing();
            if (!close.accepted && !closeConfirmationModal) {
                closeConfirmationModal = true;
                app.messageBox(Modal.NoIcon, qsTr("Are you sure you want to exit?"), [
                    { text: qsTr("Yes"), accent: true, clicked: () => { main_window.closeConfirmed = true; main_window.close(); } },
                    { text: qsTr("No"), clicked: () => { main_window.closeConfirmationModal = false; } }
                ]);
            }
        }
    }

    Loader {
        id: appLoader;
        objectName: "AppLoader";
        anchors.fill: parent;
        asynchronous: true;
        opacity: appLoader.status == Loader.Ready? 1 : 0.5;
        Ease on opacity { }
        sourceComponent: Component {
            App { objectName: "App"; }
        }
    }
    QQC.BusyIndicator {
        anchors.centerIn: parent;
        running: appLoader.status != Loader.Ready;
        onRunningChanged: if (!running) destroy(700);
    }
}
