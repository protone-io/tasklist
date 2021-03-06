import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQml.Models 2.12
import "../common"
import "../popups"

import AppData 1.0

AppStackPage {
    id: root

    property var clist: AppData.currentList
    property bool hideCompleted: clist ? clist.hideCompleted : false
    property bool sortList: clist ? clist.sortByDueDate : false
//    property string ordering: "custom"

    title: clist ? clist.name : qsTr("No list")

    leftButton: Action {
        icon.source: "image://icon/menu"
        onTriggered: navDrawer.open()
    }

    rightButtons: [
        Action {
            icon.source: "image://icon/more_vert"
            onTriggered: optionsMenu.open()
        }
    ]

    Loader {
        id: listViewLoader
        anchors.fill: parent
        source: !sortList ? //ordering == "custom" ?
                    Qt.resolvedUrl("DragDropListView.qml") :
                    Qt.resolvedUrl("SortedListView.qml")
    }

    LabelBody {
        anchors.centerIn: parent
        text: {
            if (clist) {
                if (clist.tasks.count === 0)
                    qsTr("The list is empty")
                else if (clist.completedTasks > 1)
                    qsTr("%1 completed tasks not shown").arg(clist.completedTasks)
                else
                    qsTr("One completed task not shown")
            } else
                qsTr("No list")
        }
        visible: clist === null || (clist.tasks.count - (hideCompleted ? clist.completedTasks : 0) < 1)
    }

    Menu {
        id: taskMenu

        property var task

        modal: true
        dim: false
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        transformOrigin: Menu.Center

        MenuItem {
            text: qsTr("Delete task")
            onTriggered: clist.tasks.remove(taskMenu.task)
        }
    }

    Menu {
        id: optionsMenu
        modal: true
        dim: false
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        x: parent.width - width - 6
        y: -appToolBar.height + 6
        transformOrigin: Menu.TopRight

        onAboutToShow: enabled = true
        onAboutToHide: currentIndex = -1 // reset highlighting

        MenuItem {
            enabled: clist
            text: qsTr("Add task")
            onTriggered: addNewTaskPopup.open()
        }
        MenuItem {
            enabled: clist && clist.completedTasks > 0
            text: qsTr("Remove completed")
            onTriggered: popupConfirmCleanChecked.open()
        }
        MenuItem {
            enabled: clist && clist.tasks.count
            text: qsTr("Remove all")
            onTriggered: popupConfirmClearAll.open()
        }
        MenuItem {
            enabled: clist && clist.tasks.count
            text: sortList ? qsTr("Custom order") : qsTr("Sort by due date")
            onTriggered: clist.sortByDueDate = !clist.sortByDueDate
        }

        MenuItem {
            enabled: clist && clist.tasks.count
            text: hideCompleted ? qsTr("Show completed") : qsTr("Hide completed")
            onTriggered: clist.hideCompleted = !clist.hideCompleted
        }
    }

    Connections {
        target: AppData
        onSpeechRecognized: inputField.text = result
    }

    Popup {
        id: addNewTaskPopup

        height: 70
        width: parent.width
        y: 0
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        modal: true
        dim: false
        focus: true

        background: Rectangle {
            anchors.fill: parent
            color: "gray"
            opacity: 0.4
        }

        onAboutToShow: inputField.text = ""

        RowLayout {
            anchors.fill: parent

            Rectangle {
                radius: inputField.height / 2
                color: Material.background
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    TextField {
                        id: inputField

                        focus: true
                        leftPadding: 10
                        selectByMouse: true
                        placeholderText: qsTr("Insert task name here")
                        onEditingFinished: addNewTaskPopup.close()
                        inputMethodHints: Qt.ImhNoPredictiveText
                        color: Material.foreground
                        background: null
                        Layout.fillWidth: true
                    }

                    ToolButton {
                        icon.source: "image://icon/clear"
                        icon.color: Material.foreground
                        focusPolicy: Qt.NoFocus
                        visible: inputField.displayText.length > 0
                        onClicked: {
                            Qt.inputMethod.commit()
                            inputField.text = ""
                        }
                        Layout.rightMargin: 0
                    }
                }
            }

            ToolButton {
                icon.source: inputField.displayText.length > 0
                                         ? "image://icon/send"
                                         : "image://icon/mic"
                icon.color: textOnPrimary
                focusPolicy: Qt.NoFocus

                background: Rectangle {
                    color: Material.primary
                    radius: height / 2
                }

                onClicked: {
                    if (inputField.displayText.length > 0) {
                        Qt.inputMethod.commit()
                        Qt.inputMethod.hide()
                        if (clist.newTask(inputField.text)) {
                            showToast(qsTr("Added %1 to list").arg(inputField.text))
                            inputField.text = ""
                        } else {
                            showError(qsTr("%1 is already in list").arg(inputField.text))
                        }
                    } else {
                        AppData.startSpeechRecognizer();
                    }
                }
            }
        }
    }

    PopupConfirm {
        id: popupConfirmCleanChecked
        text: qsTr("Do you want to clear the selected tasks?\n\n")
        onAboutToHide: {
            stopTimer()
            if (isConfirmed) {
                showToast(clist.completedTasks === 1 ?
                              qsTr("One completed task removed") :
                              qsTr("%1 completed tasks removed").arg(clist.completedTasks))
                clist.removeChecked()
                isConfirmed = false
            }
        }
    }

    PopupConfirm {
        id: popupConfirmClearAll
        text: qsTr("Do you want to clear the list?\n\n")
        onAboutToHide: {
            stopTimer()
            if (isConfirmed) {
                showToast(qsTr("List cleared"))
                clist.removeAll()
                isConfirmed = false
            }
        }
    }
}
