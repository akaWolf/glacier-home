// This file is part of colorful-home, a nice user experience for touchscreens.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Copyright (c) 2017, Eetu Kahelin
// Copyright (c) 2013, Jolla Ltd <robin.burchell@jollamobile.com>
// Copyright (c) 2012, Timur Kristóf <venemo@fedoraproject.org>
// Copyright (c) 2011, Tom Swindell <t.swindell@rubyx.co.uk>

import QtQuick 2.6
import QtQuick.Controls.Nemo 1.0
import QtQuick.Controls.Styles.Nemo 1.0
import org.nemomobile.lipstick 0.1

MouseArea {
    property bool reordering
    property int newIndex: -1
    property int newFolderIndex: -1
    property real oldY
    property bool isFolder
    property bool notNemoIcon
    property Item parentItem
    property alias slideMoveAnim: slideMoveAnim
    property QtObject folderModel
    property Item folderItem

    id: launcherItem
    parent: parentItem.contentItem
    scale: newFolder && folderIndex == cellIndex && !isFolder ? 0.5 : (reordering || folderIndex == cellIndex ? 1.3 : 1)
    transformOrigin: Item.Center
    onXChanged: moved()
    onYChanged: moved()
    drag.minimumX: parentItem.contentItem.x - width/2
    drag.maximumX: parentItem.contentItem.width + width/2
    drag.minimumY: parentItem.contentItem.y -height/2 -height/4
    drag.maximumY: parentItem.contentItem.height +height/2

    onClicked: {
        // TODO: disallow if close mode enabled
        if (modelData.object.type !== LauncherModel.Folder) {
            var winId = switcher.switchModel.getWindowIdForTitle(modelData.object.title)
            if (winId == 0 || !modelData.object.isLaunching)
                modelData.object.launchApplication()
            else
                Lipstick.compositor.windowToFront(winId)
        }
    }
    onPressed: {
        newIndex = -1
        newFolderIndex = -1
    }

    onPressAndHold: {
        reparent(parentItem)
        reorderItem = launcherItem
        drag.target = launcherItem
        z = 1000
        reordering = true
        parentItem.onUninstall = true

        // don't allow dragging an icon out of pages with a horizontal flick
        pager.interactive = false
    }

    onReleased: {
        if (reordering) {
            reordering = false
            reorderEnded()
            reorderTimer.stop()
            drag.target = null
            reorderItem = null
            pager.interactive = true
            parentItem.onUninstall = false
            deleter.remove.text = qsTr("Remove")
            deleter.uninstall.text = qsTr("Uninstall")
            folderIndex = -1
            reparent(parentItem.contentItem)
            z = parent.z

            slideMoveAnim.start()
        }
    }

    function reparent(newParent) {
        var newPos = mapToItem(newParent, 0, 0)
        parent = newParent
        x = newPos.x - width/2 * (1-scale)
        y = newPos.y - height/2 * (1-scale)
    }

    function moved() {
        if (reordering) {
            var gridViewPos = parentItem.contentItem.mapFromItem(launcherItem, width/2, height/2)
            var item = parentItem.itemAt(gridViewPos.x, gridViewPos.y)
            var idx = -1
            var folderIdx = -1
            var delPos = deleter.remove.mapFromItem(launcherItem, width/2, height/2)
            var isdel = deleter.childAt(delPos.x, delPos.y)
            if (isdel === deleter.remove) {
                deleter.remove.text = qsTr("Removing") + " " + iconCaption
            } else if (isdel === deleter.uninstall) {
                deleter.uninstall.text = qsTr("Uninstalling") + " " + iconCaption
            }
            //When adding new icon to folder or creating new folder
            var offset = gridViewPos.x - item.x
            var folderThreshold = !isFolder ? item.width / 4 : item.width / 2
            if (offset < folderThreshold) {
                if (Math.abs(cellIndex - item.cellIndex) > 1 || cellIndex > item.cellIndex || item.y !== wrapper.offsetY) {
                    idx = cellIndex < item.cellIndex ? item.cellIndex - 1 : item.cellIndex
                    folderItem = null
                }
            } else if (offset >= item.width - folderThreshold) {
                if (Math.abs(cellIndex - item.cellIndex) > 1 || cellIndex < item.cellIndex || item.y !== wrapper.offsetY) {
                    idx = cellIndex > item.cellIndex ? item.cellIndex + 1 : item.cellIndex
                    folderItem = null
                }
            } else if (item.cellIndex !== cellIndex && parent.isRootFolder && !isFolder) {
                folderItem = item
                folderIdx = item.cellIndex
            }
            if (newIndex !== idx) {
                newIndex = idx
                reorderTimer.restart()
            }
            if (newFolderIndex != folderIdx) {
                newFolderIndex = folderIdx
                reorderTimer.restart()
            }
            if (newFolderIndex != folderIndex) {
                folderIndex = -1
            }
        }
    }

    function reorderEnded() {
        //called when icon is released and reordering is true
        if (folderIndex >= 0) {
            if (folderModel.get(folderIndex).type == LauncherModel.Application) {
                var folder = folderModel.createFolder(folderIndex, "folder")
                if (folder) {
                    folderModel.moveToFolder(modelData.object, folder)
                }
            } else {
                folderModel.moveToFolder(modelData.object, folderModel.get(folderIndex))
            }
            folderIndex = -1
            newFolderActive = false
        }
        //To drop appicon out of the folder
        var realY = parseInt(parentItem.mapFromItem(launcherItem, 0, 0).y) + parseInt(((launcherItem.height*launcherItem.scale-launcherItem.height)/2).toFixed(2))
        if (!parent.isRootFolder && (realY < -Math.abs(launcherItem.height/2) || realY > parentItem.height)) {
            var parentFolderIndex = folderModel.parentFolder.indexOf(folderModel)
            folderModel.parentFolder.moveToFolder(modelData.object, folderModel.parentFolder, parentFolderIndex+1)
        }
    }

    Timer {
        id: reorderTimer
        interval: folderItem && folderItem.isFolder ? 10 : 100
        onTriggered: {
            if (newFolderIndex >= 0 && newFolderIndex !== cellIndex) {
                if (!folderItem.isFolder) {
                    newFolderActive = true
                } else {
                    newFolderActive = false
                }
                folderIndex = newFolderIndex
            } else  if (newIndex != -1 && newIndex !== cellIndex) {
                folderModel.move(cellIndex, newIndex)
            }
            newIndex = -1
        }
    }

    Behavior on scale {
        NumberAnimation { easing.type: Easing.InOutQuad; duration: 150 }
    }

    ParallelAnimation {
        id: slideMoveAnim
        NumberAnimation { target: launcherItem; property: "x"; to: wrapper.x; duration: 130; easing.type: Easing.OutQuint }
        NumberAnimation { target: launcherItem; property: "y"; to: wrapper.y; duration: 130; easing.type: Easing.OutQuint }
    }

    Connections {
        target: modelData.object
        ignoreUnknownSignals: true
        onItemRemoved: {
            var modelDataObject = modelData.object
            //If there is only one item in folder, remove the folder
            if (modelDataObject.itemCount === 1) {
                var parentFolderIndex = modelDataObject.parentFolder.indexOf(modelDataObject)
                modelDataObject.parentFolder.moveToFolder(modelDataObject.get(0), modelDataObject.parentFolder, parentFolderIndex)
                modelDataObject.destroyFolder()
            }
        }
    }
}

