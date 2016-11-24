/* gcompris - DragListItem.qml
 *
 * Copyright (C) 2015 Pulkit Gupta <pulkitgenius@gmail.com>
 *
 * Authors:
 *   Pulkit Gupta <pulkitgenius@gmail.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.1
import QtGraphicalEffects 1.0
import GCompris 1.0
import "../../core"
import "multiple_choice_questions.js" as Activity

Item {
    id: item

    width: tile.width
    height: tile.height

    property double heightInColumn
    property double widthInColumn
    property double tileWidth
    property double tileHeight
    property string imageSound: imgSound
    property alias tileImageGlow: tileImageGlow
    property QtObject answer: tileImage.parent
    property bool isInList: tileImage.parent == tile
    property bool selected: false

    signal pressed

    ParallelAnimation {
        id: tileImageAnimation
        NumberAnimation { 
            target: tileImage
            easing.type: Easing.OutQuad
            properties: "x"; from: 100; duration: 200
            //property: "x"
            to: tileImage.moveImageX
            //duration: 430

        }
        NumberAnimation { 
            target: tileImage
            easing.type: Easing.OutQuad
            properties: "y"; from: 100; duration: 200
            to: tileImage.moveImageY
            //duration: 430

        }
        onStarted: {
            tileImage.anchors.centerIn = undefined
            if(view.showGlow)
                view.showGlow = false
        }
        onStopped: {
            tileImage.parent = tileImage.tileImageParent
            tileImage.anchors.centerIn = tileImage.parent
            view.itemsDropped = view.itemsDropped + tileImage.dropNo
            if(view.itemsDropped == mymodel.count) {
                showOk.start()
                view.okShowed = true
            }
            else if(view.okShowed) {
                hideOk.start()
                view.okShowed = false
            }
            if(!view.okShowed && tileImage.dropNo == 1) 
                view.checkDisplayedGroup()
            if(!view.okShowed && tileImage.dropNo == -1) {
                view.displayedGroup[parseInt(index/view.nbItemsByGroup)] = true
                view.setPreviousNavigation()
                view.setNextNavigation()
            }


        }
    }
    
    Rectangle {
        id: tile
        width: displayWord.width // tileWidth
        height: tileHeight
        color: (parent.selected && tileImage.parent == tile) ? "#33FF294D" : "transparent"
        border.color: (parent.selected && tileImage.parent == tile) ? "white" : "transparent"
        border.width: 3
        radius: 2
        
        property double xCenter: tile.x + tile.width/2
        property double yCenter: tile.y + tile.height/2
        property bool colorChange: true



        Rectangle {
            id: tileImage
            anchors.centerIn: parent
       //     height: Activity.glowEnabled ? heightInColumn * 1.1 : heightInColumn
       //     width: Activity.glowEnabled ? widthInColumn * 1.1 : widthInColumn
   //         fillMode: Image.PreserveAspectFit
   //         source: Activity.url + imgName

            width: displayWord.width
            height: displayWord.fontSize * 5 * Math.ceil(displayWord.implicitWidth / displayWord.width)
            z: 1
            opacity: 0.8
            radius: 10
            border.width: 2
            border.color: "black"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#000" }
                GradientStop { position: 0.9; color: "#666" }
                GradientStop { position: 1.0; color: "#AAA" }
            }


            property QtObject dragTarget
            property QtObject tileImageParent
            property double moveImageX
            property double moveImageY
            property int dropNo
            property bool dropping: false
            property string _possibleAnswer: possibleAnswer
            
            function imageRemove() {
                if(backgroundImage.source == "")
                    leftWidget.z = 1
                
                tileImage.state = "INITIAL"
                var coord = tileImage.parent.mapFromItem(tile, tile.xCenter - tileImage.width/2, 
							tile.yCenter - tileImage.height/2)
                tileImage.moveImageX = coord.x
                tileImage.moveImageY = coord.y
                tileImage.tileImageParent = tile
                tileImage.dragTarget = null
                tile.colorChange = true
                
                if(tileImage.parent != tile)
                    tileImage.dropNo = -1
                else
                    tileImage.dropNo = 0
                
                tileImageAnimation.start()
            }
            

            GCText {
                id: displayWord
                anchors.horizontalCenter: parent.horizontalCenter

        //        property bool firstTime: true
                fontSize: 20
                color: "white"
             //   style: Text.Outline
                styleColor: "black"
        //        horizontalAlignment: Text.AlignHCenter
        //        width: Math.min(implicitWidth, textWidth * displayText.parent.width)
        //        wrapMode: TextEdit.WordWrap
                z: 2
                text: possibleAnswer
             /*   onHeightChanged: {
                    if(firstTime) {
                        displayTxtContainer.height = displayTxt.height * Math.ceil(displayTxt.implicitWidth / displayTxt.width)
                        firstTime = false
                    }
                    else
                        displayTxtContainer.height = displayTxt.height
                }*/
            }


  /*          Rectangle {
                id: displayWordContainer
                anchors.top: displayWord.top
                anchors.horizontalCenter: displayWord.horizontalCenter
             ²
            }*/

            MouseArea {
                id: mouseArea

                width: parent.width; height: parent.height
                anchors.fill: parent
                drag.target: parent
                hoverEnabled: true

                onEntered: {
                    item.pressed()
                    if(toolTipText != "") {
                        toolTip.text = toolTipText
                        toolTip.visible = true
                    }
                }
                onExited: {

                }

                onPressed: {
                    item.pressed()
                    if(toolTipText != "") {
                        toolTip.text = toolTipText
                        toolTip.visible = true
                    }
                    if(tileImage.parent == tile)
                        leftWidget.z = 3
                    else
                        leftWidget.z = 1
                    
                    if(imageSound)
                        activity.audioVoices.play(ApplicationInfo.getAudioFilePath(imageSound))
                    
                    tileImage.anchors.centerIn = undefined
                    if (tileImage.dragTarget != null) {
                        tileImage.dragTarget.parent.dropCircleColor = "pink"
                        tileImage.dragTarget.dragSource = null
                    }
                }

                onReleased: {
                    if(tileImage.Drag.target === null)
                        tileImage.imageRemove()
                    else {
                        tileImage.dragTarget = tileImage.Drag.target
                        tileImage.state = "DROPPED"
                        tile.colorChange = false
                        tileImage.dropping = true
                        var coord = tileImage.parent.mapFromItem(backgroundImage, tileImage.Drag.target.xCenter - 
                                    tileImage.width/2, tileImage.Drag.target.yCenter - tileImage.height/2)
                        tileImage.moveImageX = coord.x
                        tileImage.moveImageY = coord.y
                        tileImage.Drag.target.dropped(tileImage.Drag) // Emit signal manually
                        
                        if(tileImage.parent == tile)
                            tileImage.dropNo = 1
                        else
                            tileImage.dropNo = 0
                        
                        tileImage.tileImageParent = tileImage.Drag.target
                        tileImageAnimation.start()

                    }

                }
            }
            
            Drag.active: mouseArea.drag.active
            Drag.hotSpot.x: tileImage.width/2
            Drag.hotSpot.y: tileImage.height/2

            states: [
                State {
                    name: "INITIAL"
                    PropertyChanges {
                        target: tileImage
                        height: Activity.glowEnabled ? heightInColumn * 1.1 : heightInColumn
                        width: Activity.glowEnabled ? widthInColumn * 1.1 : widthInColumn
                    }
                },
                State {
                    name: "DROPPED"
                    PropertyChanges {
                        target: tileImage
                        
                        height: 100 /*imgHeight ? imgHeight * backgroundImage.height : (backgroundImage.source == "" ?
								backgroundImage.height * tileImage.sourceSize.height/backgroundImage.height : 
                                backgroundImage.height * tileImage.sourceSize.height/backgroundImage.sourceSize.height) */
								
                        width: 100 /*imgWidth ? imgWidth * backgroundImage.width : (backgroundImage.source == "" ?
							   backgroundImage.width * tileImage.sourceSize.width/backgroundImage.width : 
                               backgroundImage.width * tileImage.sourceSize.width/backgroundImage.sourceSize.width)*/
                    }
                }
            ]
            
            Image {
                id: wrongAnswer
                anchors.centerIn: parent
                height: heightInColumn * 0.3
                width: widthInColumn * 0.3
                fillMode: Image.PreserveAspectFit
                source:"qrc:/gcompris/src/activities/babymatch/resource/error.svg"
                visible: view.showGlow && tileImageGlow.setColor == "red"
            }

        }
        
        Glow {
            id: tileImageBorder
            parent: tileImage.parent
            anchors.fill: tileImage
            radius: 0.7
            samples: 2
            color: view.showGlow && Activity.glowEnabled ? "black" : "transparent"
            source: tileImage
            spread: 1.0
        }
        
        Glow {
            id: tileImageGlow
            property string setColor: "transparent"
            parent: tileImage.parent
            anchors.fill: tileImage
            radius: view.showGlow && Activity.glowEnabled ? 9 : 0
            samples: 18
            color: view.showGlow && Activity.glowEnabled ? setColor : "transparent"
            source: tileImage
            spread: 0.95
        }
    }
}
