/* GCompris - multiple-choice-questions.qml
 *
 * Copyright (C) 2017 YOUR NAME <xx@yy.org>
 *
 * Authors:
 *   <THE GTK VERSION AUTHOR> (GTK+ version)
 *   YOUR NAME <YOUR EMAIL> (Qt Quick port)
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
import QtQuick 2.6

import "../../core"
import "multiple-choice-questions.js" as Activity
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Private 1.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import GCompris 1.0




ActivityBase {
    id: activity

    onStart: focus = true
    onStop: {}



    pageComponent: Rectangle {
        id: background
        anchors.fill: parent
        color: "#ABCDEF"
        signal start
        signal stop

        Component.onCompleted: {
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        // Add here the QML items you need to access in javascript
        QtObject {
            id: items
            property Item main: activity.main
            property alias background: background
            property alias bar: bar
            property alias bonus: bonus
        }

        onStart: { Activity.start(items) }
        onStop: { Activity.stop() }


        Rectangle {
            id: textAreaDestinationRectBorder
            color: "green"

            property var textAreaDestinationRectleftBorder: background.width/100
            property var textAreaDestinationRectRightBorder: background.width/15
            property var textAreaDestinationRectTopBorder: background.height/100
            property var textAreaDestinationRectBottomBorder: background.height/3

            x: textAreaDestinationRectleftBorder
            y: 10
            width: parent.width - textAreaDestinationRectRightBorder - textAreaDestinationRectleftBorder
            height: parent.height - textAreaDestinationRectBottomBorder

            TextArea {
                Accessible.name: "destDocument"
                id: textAreaDestination

                anchors.fill: parent
                anchors.margins: 2

                property var multipleChoicesElementsArray : []
                property var displayAnswerMarks : Boolean
                property var answersPlacesInserted: Boolean
                property var resultMarkStrInserted: Boolean
                property var answerFieldsPrepared: Boolean
                property var originalText: String

                style: TextAreaStyle {
                    textColor: "#333"
                    selectionColor: "steelblue"
                    selectedTextColor: "#eee"
                    backgroundColor: "steelblue"
                }

                textFormat: Qt.RichText

                Component.onCompleted: {
                    displayAnswerMarks = false
                    answersPlacesInserted = false
                    resultMarkStrInserted = false
                    answerFieldsPrepared = false
                    //startExercice()
                }


                function longestStrInArray(arr) {
                    var lgth = 0;
                    var longest = "";

                    for(var i=0; i < arr.length; i++){
                        if(arr[i].length > lgth){
                            var lgth = arr[i].length;
                            longest = arr[i];
                        }
                    }
                    return longest
                }

                function shuffle(array) {
                    var currentIndex = array.length, temporaryValue, randomIndex;

                    // While there remain elements to shuffle...
                    while (0 !== currentIndex) {

                        // Pick a remaining element...
                        randomIndex = Math.floor(Math.random() * currentIndex);
                        currentIndex -= 1;

                        // And swap it with the current element.
                        temporaryValue = array[currentIndex];
                        array[currentIndex] = array[randomIndex];
                        array[randomIndex] = temporaryValue;
                    }

                    return array;
                }



                function startExercice() {
                    resultMarkStrInserted = false
                    textAreaDestination.prepareAnswerFields()
                    textAreaDestination.insertSpaceForMultipleChoiceBoxes()
                    textAreaDestination.insertMultipleChoiceBoxes()
                }

                function prepareAnswerFields() {

                    answersPlacesInserted = false

                    textAreaDestination.text = textArea.text

                    var openingBracketPos = 0
                    var closingBracketPos = 0
                    var bracketOpened = false

                    var openingBracketPosInDestTextArea = 0
                    var closingBracketPosInDestTextArea = 0

                    var nbOfCharactersRemoved = 0

                    var indexTest = 0

                    multipleChoicesElementsArray = []

                    for (var i = 0; i < textArea.length; i++) {
                        var oneTextChar = textArea.getText(i,i+1)

                        if (oneTextChar == "[" && bracketOpened == true) {
                            errorMessage.text = "Two opening brackets ([) can not follow each other"
                        }

                        if (oneTextChar == "[") {
                            openingBracketPos = i
                            openingBracketPosInDestTextArea = openingBracketPos - nbOfCharactersRemoved
                            bracketOpened = true
                        }

                        //using closing bracket, detects a question and extract its information
                        if (bracketOpened == true && oneTextChar == "]") {
                            closingBracketPos = i
                            closingBracketPosInDestTextArea = closingBracketPos - nbOfCharactersRemoved

                            bracketOpened = false

                            //extract the question, good and bad answers from multiple choices infos
                            var multipleChoiceElementStr = textArea.getText(openingBracketPos+1,closingBracketPos)
                            var questionStr
                            var goodAnswersArray = []
                            var badAnswersArray = []
                            var multipleChoiceElementStrArray = multipleChoiceElementStr.split("|")
                            for (var j = 0; j < multipleChoiceElementStrArray.length; j++) {
                                if (j == 0) {
                                    questionStr = multipleChoiceElementStrArray[0]
                                }
                                else
                                {
                                    if (multipleChoiceElementStrArray[j][multipleChoiceElementStrArray[j].length-1] == "*") {
                                        multipleChoiceElementStrArray[j] = multipleChoiceElementStrArray[j].substr(0,multipleChoiceElementStrArray[j].length-1)
                                        goodAnswersArray.push(multipleChoiceElementStrArray[j])
                                    }
                                    else {
                                        badAnswersArray.push(multipleChoiceElementStrArray[j])
                                    }
                                }
                            }

                            //store the for each question, its position, its good and bad answers
                            var multipleChoiceElement = {posInText:0, posInDestText:0, posInDestTextX:0, posInDestTextY:0, comboboxWidth:0, comboBoxValue:"", comboBoxIndex:0, answerFontFamily:"", answerFontSize:0, question:"", questionLength:0, shuffledPossibleAnswers:[], goodAnswers:[], badAnswers:[], longestChoiceStr:[], userAnswer:""}


                            multipleChoiceElement.posInText = openingBracketPosInDestTextArea
                            multipleChoiceElement.question = questionStr
                            var questionLength = questionStr.length
                            multipleChoiceElement.questionLength = questionLength
                            multipleChoiceElement.goodAnswers = goodAnswersArray
                            multipleChoiceElement.badAnswers = badAnswersArray
                            multipleChoiceElement.shuffledPossibleAnswers = shuffle(goodAnswersArray.concat(badAnswersArray))
                            multipleChoiceElement.longestChoiceStr = longestStrInArray(multipleChoiceElement.shuffledPossibleAnswers)
                            multipleChoicesElementsArray.push(multipleChoiceElement)

                            //remove the open bracket, the bad good and bad answers and the closing bracket
                            textAreaDestination.remove(openingBracketPosInDestTextArea+questionLength+1,closingBracketPosInDestTextArea+1)
                            textAreaDestination.remove(openingBracketPosInDestTextArea,openingBracketPosInDestTextArea+1)

                            //color the "question" text
                            destDocument.selectionStart = openingBracketPosInDestTextArea
                            destDocument.selectionEnd = openingBracketPosInDestTextArea+questionLength
                            destDocument.cursorPosition = openingBracketPosInDestTextArea
                            destDocument.textColor = "blue"

                            nbOfCharactersRemoved = nbOfCharactersRemoved + (closingBracketPos - openingBracketPos - questionLength +1)

                        }
                        scoreScreen.text = "Score : 0/" + multipleChoicesElementsArray.length
                    }
                    answerFieldsPrepared = true
                }


                function deleteAnswerChoices() {
                    for (var i=0; i<textAreaDestination.multipleChoicesElementsArray.length; i++) {

                        //prepare the positions of the questions
                        var currentMultipleChoicesElements = textAreaDestination.multipleChoicesElementsArray[i]
                        var wordStartPos = currentMultipleChoicesElements.posInText// + nbOfChartoAdd
                        var wordEndPos = wordStartPos + currentMultipleChoicesElements.question.length-1

                        //prepare an array containing all the possible answers
        //                var multipleChoicesArray = textAreaDestination.multipleChoicesElementsArray[i].goodAnswers.concat(textAreaDestination.multipleChoicesElementsArray[i].badAnswers)

                        //find what is the longest choice in choicesArray and insert it in the text to prepare the place for the ComboBox
        //                var longestChoiceStr = longestStrInArray(multipleChoicesArray)

                        //delete the dummy answered written to reserve the combo box place
                        textAreaDestination.remove(wordEndPos+1, wordEndPos+1 + textAreaDestination.multipleChoicesElementsArray[i].longestChoiceStr.length+3)

                                      //  console.log("longestChoiceStr: %1 - longestChoiceStrLength: %2".arg(longestChoiceStr).arg(longestChoiceStr.length))

                                      //  textAreaDestination.insert(wordEndPos+1, "#")
                                      //  textAreaDestination.insert(wordEndPos+1 + longestChoiceStr.length+5, "#")
                    }
                    answerChoicesComboBoxesRepeater.model = []
                }


                function insertSuccessAndFailMark(result, choiceNumber) {

                    textAreaDestination.resultMarkStrInserted = true

                    var resultMarkStr = "<span style=\"color:green; font-size:%1pt;\"><pre> &#10004;</pre></span>".arg(textAreaDestination.multipleChoicesElementsArray[choiceNumber].answerFontSize)
                    if (result == false) {
                        resultMarkStr = "<span style=\"color:red; font-size:%1pt;\"><pre> &#10060;</pre></span>".arg(textAreaDestination.multipleChoicesElementsArray[choiceNumber].answerFontSize)
                    }

                    var resultMarkStrPos = textAreaDestination.multipleChoicesElementsArray[choiceNumber].posInDestText + textAreaDestination.multipleChoicesElementsArray[choiceNumber].longestChoiceStr.length + 1

                    //var answerStr = "<span style=\"color:red; font-size:%1pt;\"><pre>%2</pre></span>".arg(fontSize).arg(insertedLongestString)
                    textAreaDestination.insert(resultMarkStrPos, resultMarkStr)

                    // shift the next multiple choices places from two chars: a blanck and the answerMark character
                    for (var i = choiceNumber+1; i<textAreaDestination.multipleChoicesElementsArray.length; i++) {
                        textAreaDestination.multipleChoicesElementsArray[i].posInDestText = textAreaDestination.multipleChoicesElementsArray[i].posInDestText + 2
                    }
                }




                function deleteSuccessAndFailMark() {

                    if (textAreaDestination.resultMarkStrInserted) {
                        for (var i = 0; i<textAreaDestination.multipleChoicesElementsArray.length; i++) {

                            var resultMarkStrPos = textAreaDestination.multipleChoicesElementsArray[i].posInDestText + textAreaDestination.multipleChoicesElementsArray[i].longestChoiceStr.length + 1

                            textAreaDestination.remove(resultMarkStrPos,resultMarkStrPos+2)

                            // shift the next multiple choices places from two chars: a blanck and the answerMark character
                            for (var j = i+1; j<textAreaDestination.multipleChoicesElementsArray.length; j++) {
                                textAreaDestination.multipleChoicesElementsArray[j].posInDestText = textAreaDestination.multipleChoicesElementsArray[j].posInDestText - 2
                            }
                        }
                    }
                    textAreaDestination.resultMarkStrInserted = false
                }


                function checkAnswers() {

                    if (textAreaDestination.resultMarkStrInserted) {
                        textAreaDestination.deleteSuccessAndFailMark()
                    }

                    var score = 0
                    for (var i = 0; i<textAreaDestination.multipleChoicesElementsArray.length; i++) {

                        var goodAnswers = textAreaDestination.multipleChoicesElementsArray[i].goodAnswers
                        var comboBoxValue = textAreaDestination.multipleChoicesElementsArray[i].comboBoxValue
                        var shuffledVar = textAreaDestination.multipleChoicesElementsArray[i].shuffledPossibleAnswers
                     //   console.log("goodAnswers")
                     //   console.log(goodAnswers)
                     //   console.log("comboBoxValue")
                     //   console.log(comboBoxValue)
                        console.log("shuffled var " + i + ":")
                        console.log(shuffledVar)
                        var result = goodAnswers.indexOf(comboBoxValue);
                        if (result != -1) {
                            textAreaDestination.insertSuccessAndFailMark(true, i)
                            score = score + 1
                        }
                        else
                        {
                            textAreaDestination.insertSuccessAndFailMark(false, i)
                        }

                    }
                    textAreaDestination.insertMultipleChoiceBoxes()
                    scoreScreen.text = "Score : " + score + "/" + multipleChoicesElementsArray.length
                }



                function insertSpaceForMultipleChoiceBoxes() {
                    var nbOfCharToAdd = 0
                    for (var i = 0; i<textAreaDestination.multipleChoicesElementsArray.length; i++) {

                            //create character spaces for the combo box

                        //store the question start and end position
                        var currentMultipleChoicesElements = textAreaDestination.multipleChoicesElementsArray[i]
                        var wordStartPos = currentMultipleChoicesElements.posInText
                        var wordEndPos = wordStartPos + currentMultipleChoicesElements.question.length-1

                        //read and store the question characters family and size
                        destDocument.cursorPosition = wordStartPos
                        destDocument.selectionStart = wordStartPos
                        destDocument.selectionEnd = wordEndPos
                        var fontSize = destDocument.fontSize
                        textAreaDestination.multipleChoicesElementsArray[i].answerFontSize = fontSize
                        var fontFamily = destDocument.fontFamily
                        textAreaDestination.multipleChoicesElementsArray[i].answerFontFamily = fontFamily

                        //console.log("+++++++**++++++++" + textAreaDestination.multipleChoicesElementsArray[i].userAnswer)

                        //find what is the longest choice in choicesArray and insert it in the text to prepare the place for the ComboBox
                        var insertedLongestString = " " + textAreaDestination.multipleChoicesElementsArray[i].longestChoiceStr
                        var insertedLongestStringLength = insertedLongestString.length

                        var answerStr = "<span style=\"color:red; font-size:%1pt;\"><pre>%2</pre></span>".arg(fontSize).arg(insertedLongestString)
                        var choiceStrPosition = wordEndPos + 1 + nbOfCharToAdd
                        textAreaDestination.insert(choiceStrPosition, answerStr)
                        textAreaDestination.multipleChoicesElementsArray[i].posInDestText = choiceStrPosition
                        nbOfCharToAdd = nbOfCharToAdd + insertedLongestStringLength
                    }
                }

                function insertMultipleChoiceBoxes() {
                    for (var i = 0; i<textAreaDestination.multipleChoicesElementsArray.length; i++) {

                        //store the multiple choices answers positions in array to be used in model
                        var comboBoxPos = textAreaDestination.multipleChoicesElementsArray[i].posInDestText
                        var rect = textAreaDestination.positionToRectangle(comboBoxPos+1)
                        textAreaDestination.multipleChoicesElementsArray[i].posInDestTextX = rect.x
                        textAreaDestination.multipleChoicesElementsArray[i].posInDestTextY = rect.y

                        //calculate choices answers width to set combobox width
                        destDocument.cursorPosition = comboBoxPos+3
                        destDocument.selectionStart = comboBoxPos +3
                        destDocument.selectionEnd = comboBoxPos+4
                        var stringWidth = destDocument.stringWidth
                        textAreaDestination.multipleChoicesElementsArray[i].comboboxWidth = stringWidth
                    }

                    answerChoicesComboBoxesRepeater.model = textAreaDestination.multipleChoicesElementsArray
                }


                function deleteMultipleChoiceBoxes() {
                    answerChoicesComboBoxesRepeater.model = []
                }




                //Component.onCompleted: forceActiveFocus()


                flickableItem.onContentYChanged: {
                    console.log("xxxxxx")
                    displayAnswerChoices()
                }

                onWidthChanged: {
            //        textAreaDestination.displayAnswerChoices()
                }

                onCursorPositionChanged: {

                    //textAreaDestination.selectWord()
                    var fontFamily = textAreaDestination.font.family
                    //fontFamily = "sens serif"
                    var fontSize = textAreaDestination.font.pointSize
                    //fontSize = 100
                   // console.log("++++++++++++++++++fontFamily: " + fontFamily)
                   // console.log("++++++++++++++++++fontSize: " + fontSize)



                   /* for (var i = 0; i < textAreaDestination.multipleChoicesElementsArray.length; i++) {

                        var currentMultipleChoicesElements = textAreaDestination.multipleChoicesElementsArray[i]
                        var tmp3 = currentMultipleChoicesElements.posInDestText
                        console.log("kkkkkkkk " + i + " :" + tmp3)


                        var rect = textAreaDestination.positionToRectangle(tmp3)
                        console.log("xxxxxxxxxxx " + i + " :" + rect.x)
                        console.log("yyyyyyyyyyy " + i + " :" + rect.y)
        //                var rect = textAreaDestination.positionToRectangle(openingBracketPosInDestTextArea)
                        textAreaDestination.multipleChoicesElementsArray[i].posInTextX = rect.x// - rect.width
                        console.log("posInTextX: " + rect.x)

                        textAreaDestination.multipleChoicesElementsArray[i].posInTextY = rect.y + rect.height //+ / //mainToolBar.height + appWin.height/3 + 24 -100
                   //     console.log("posInTextY: " + textAreaDestination.multipleChoicesElementsArray[i].posInTextY)




                    }*/
        //            var rect2 = textAreaDestination.positionToRectangle(cursorPosition)
        //            errorMessage.text = cursorPosition + "--: " + rect2.x
                }





                Item {
                    id: answerChoicesComboBoxes

                    anchors.top: textAreaDestination.top
                    anchors.left: textAreaDestination.left

                    z: 100

                    Repeater {
                        id: answerChoicesComboBoxesRepeater

                        anchors.top: parent.top
                        anchors.left: parent.left

                        ComboBox {
                            id: box
                            activeFocusOnPress: true
                            currentIndex: textAreaDestination.multipleChoicesElementsArray[index].comboBoxIndex

                            style: ComboBoxStyle {
                                id: comboBox
                                background: Rectangle {
                                    id: rectCategory
                                    radius: 5
                                    border.width: 2
                                    color: "#fff"
                                }
                                label: Text {
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pointSize: modelData.answerFontSize
                                    font.family: modelData.answerFontFamily
                                    font.capitalization: Font.SmallCaps
                                    color: "black"
                                    text: control.currentText
                                }

                                // drop-down customization here
                                property Component __dropDownStyle: MenuStyle {
                                    __maxPopupHeight: 600
                                    __menuItemType: "comboboxitem"

                                    frame: Rectangle {              // background
                                        color: "#fff"
                                        border.width: 2
                                        radius: 5
                                    }

                                    itemDelegate.label:             // an item text
                                        Text {
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pointSize: 15
                                        font.family: "Courier"
                                        font.capitalization: Font.SmallCaps
                                        color: styleData.selected ? "white" : "black"
                                        text: styleData.text
                                    }

                                    itemDelegate.background: Rectangle {  // selection of an item
                                        radius: 2
                                        color: styleData.selected ? "darkGray" : "transparent"
                                    }

                                    __scrollerStyle: ScrollViewStyle { }
                                }

                                property Component __popupStyle: Style {
                                    property int __maxPopupHeight: 400
                                    property int submenuOverlap: 0

                                    property Component frame: Rectangle {
                                        width: (parent ? parent.contentWidth : 0)
                                        height: (parent ? parent.contentHeight : 0)// + 1
                                        border.color: "black"
                                        property real maxHeight: 500
                                        property int margin: 1
                                    }

                                    property Component menuItemPanel: Text {
                                        text: "NOT IMPLEMENTED"
                                        color: "red"
                                        font {
                                            pixelSize: 14
                                            bold: true
                                        }
                                    }

                                    property Component __scrollerStyle: null
                                }
                            }

                            model: modelData.shuffledPossibleAnswers
                            width: modelData.comboboxWidth
                           // currentIndex: modelData.comboBoxValue
                            z: 10000
                            x: modelData.posInDestTextX
                            y: modelData.posInDestTextY-4



                            onCurrentTextChanged: {
                                //console.log("------- modelData: " + index)
                                textAreaDestination.multipleChoicesElementsArray[index].comboBoxValue = currentText
                                textAreaDestination.multipleChoicesElementsArray[index].comboBoxIndex = currentIndex
                                //console.log("------- comboboxvalue" + textAreaDestination.multipleChoicesElementsArray[index].comboBoxValue)
                            }
                        }
                    }
                }
            }


            TextArea {
                Accessible.name: "document"
                id: textArea

                property var borderSize: 100

                frameVisible: false
                width: parent.width - (parent.width/borderSize)*2
                height: parent.height/3 - 20
                x: parent.width/borderSize
                y: parent.height - (parent.height/3)

                //visible: false

                baseUrl: "qrc:/"
                text: document.text
                textFormat: Qt.RichText
                Component.onCompleted: forceActiveFocus()

             /*   Component.onCompleted: {
                    textArea.text = document.text
                }*/

                onTextChanged: {
                    textAreaDestination.startExercice()
                }


            }
        }


        DocumentHandler {
            id: document
            target: textArea
            cursorPosition: textArea.cursorPosition
            selectionStart: textArea.selectionStart
            selectionEnd: textArea.selectionEnd
            textColor: colorDialog.color
//            Component.onCompleted: document.fileUrl = "qrc:/example.html"
   /*         Component.onCompleted: {
                document.fileUrl = "qrc:///gcompris/src/activities/multiple-choice-questions/example.html"

            }*/

         /*   onFontSizeChanged: {
                fontSizeSpinBox.valueGuard = false
                fontSizeSpinBox.value = document.fontSize
                fontSizeSpinBox.valueGuard = true
            }
            onFontFamilyChanged: {
                var index = Qt.fontFamilies().indexOf(document.fontFamily)
                if (index == -1) {
                    fontFamilyComboBox.currentIndex = 0
                    fontFamilyComboBox.special = true
                } else {
                    fontFamilyComboBox.currentIndex = index
                    fontFamilyComboBox.special = false
                }
            }*/
        /*    onError: {
                errorDialog.text = message
                errorDialog.visible = true
            }*/

        }


        DocumentHandler {
            id: destDocument

            target: textAreaDestination
            cursorPosition: textAreaDestination.cursorPosition
            selectionStart: textAreaDestination.selectionStart
            selectionEnd: textAreaDestination.selectionEnd
          //  textColor: colorDialog.color
            Component.onCompleted: {
                //destDocument.fileUrl = "qrc:///gcompris/src/activities/multiple-choice-questions/example.html"
            }
            onError: {
                errorDialog.text = "tttt" //message
                errorDialog.visible = true
            }
         }

        ColorDialog {
            id: colorDialog
            color: "black"
        }

        Action {
            id: cutAction
            text: "Cut"
            shortcut: "ctrl+x"
            iconSource: "images/editcut.png"
            iconName: "edit-cut"
            onTriggered: textArea.cut()
        }

        Action {
            id: copyAction
            text: "Copy"
            shortcut: "Ctrl+C"
            iconSource: "images/editcopy.png"
            iconName: "edit-copy"
            onTriggered: textArea.copy()
        }

        Action {
            id: pasteAction
            text: "Paste"
            shortcut: "ctrl+v"
            iconSource: "qrc:images/editpaste.png"
            iconName: "edit-paste"
            onTriggered: textArea.paste()
        }

        Action {
            id: italicAction
            text: "&Italic"
            iconSource: "images/textitalic.png"
            iconName: "format-text-italic"
            onTriggered: document.italic = !document.italic
            checkable: true
            //checked: document.italic
        }

        Action {
            id: boldAction
            text: "&Bold"
            iconSource: "images/textbold.png"
            iconName: "format-text-bold"
            onTriggered: document.bold = !document.bold
            checkable: true
            //checked: document.bold
        }

        Action {
            id: underlineAction
            text: "&Underline"
            iconSource: "images/textunder.png"
            iconName: "format-text-underline"
            onTriggered: document.underline = !document.underline
            checkable: true
            //checked: document.underline
        }

        FileDialog {
            id: fileDialog
            nameFilters: ["HTML files (*.html *.htm)"]
            onAccepted: {
                if (fileDialog.selectExisting)
                    document.fileUrl = fileUrl
                else
                    document.saveAs(fileUrl, selectedNameFilter)
            }
        }

        Action {
            id: fileOpenAction

            property var exercicesList
           // property var extensionList

            iconSource: "images/fileopen.png"
            iconName: "document-open"
            text: "Open"
            onTriggered: {
             //   fileDialog.selectExisting = true
             //   fileDialog.open()
                var extensionList = ["*.htm", "*.html"]

                console.log("extension list:" + extensionList)
                exercicesList = exercicesDirectory.getFiles("/home/charruau/Development/MyGCompris/GCompris-qt/src/activities/multiple-choice-questions/Exercices",extensionList)
                console.log("exos: " + exercicesList)
                for (var i = 0; i < exercicesList.length; i++) {
                    exercicesListModel.append({exerciceFilename: exercicesList[i], pedagogicObjective: "Adding numbers.", pedagogicApproach: "Adding one, then one, then one."})
                }
                for (var i = 0; i < exercicesList.length; i++) {
                    console.log("test2: " + exercicesListModel.get(i))
                }
                openDialogBox.visible = true
            }
        }


        Action {
            id: fileSaveAsAction
            iconSource: "images/filesave.png"
            iconName: "document-save"
            text: "Save As…"
            onTriggered: {
                fileDialog.selectExisting = false
                fileDialog.open()
            }
        }


        Directory {
            id: exercicesDirectory
        }



        ToolBar {
            id: activityToolbar
            width: grid.childrenRect.width
            height: grid.childrenRect.height

            anchors.left: textAreaDestinationRectBorder.right
            anchors.margins: 10

            //x: textAreaDestinationRectBorder.right
            y: 10

            GridLayout {
                id: grid
                columns: 1
                anchors.top: parent.top
                ComboBox {
                   id: fontFamilyComboBox
                   implicitWidth: 100
                   model: Qt.fontFamilies()
                   property bool special : false
                   onActivated: {
                       if (special == false || index != 0) {
                           document.fontFamily = textAt(index)
                       }
                   }
                }
                SpinBox {
                   id: fontSizeSpinBox
                   activeFocusOnPress: false
                   implicitWidth: 50
                   value: 0
                   property bool valueGuard: true
                   onValueChanged: if (valueGuard) document.fontSize = value
                }

                ToolButton { action: fileOpenAction }
                ToolButton { action: fileSaveAsAction }
                ToolButton { action: copyAction }
                ToolButton { action: cutAction }
                ToolButton { action: pasteAction }
                ToolButton { action: boldAction }
                ToolButton { action: italicAction }
                ToolButton { action: underlineAction }

                ToolButton {
                    id: colorButton
                   // property var color : document.textColor
                    Rectangle {
                        id: colorRect
                        anchors.fill: parent
                        anchors.margins: 8
                        //color: Qt.darker(document.textColor, colorButton.pressed ? 1.4 : 1)
                        color: "red" //Qt.darker(document.textColor, colorButton.pressed ? 1.4 : 1)
                        border.width: 1
                        border.color: Qt.darker(colorRect.color, 2)
                    }
                    onClicked: {
                        colorDialog.color = document.textColor
                        colorDialog.open()
                    }
                }
            }
        }


        ListModel {
            id: exercicesListModel
            ListElement {
                exerciceFilename: ""
                pedagogicObjective: ""
                pedagogicApproach: ""
            }
        }


        Rectangle {
            id: openDialogBox
            anchors.top : textAreaDestinationRectBorder.top //textAreaDestination.anchors.top + textAreaDestinationAnchors.margins
            anchors.left : textAreaDestinationRectBorder.left //parent.left 10//textAreaDestination.anchors.left + textAreaDestinationAnchors.margins

            x: 100
            y: 100
            width: 400;
            height: 400
            z: 1000
            border.color: "black"
            border.width: 5

            Component.onCompleted: {
                visible = false
            }

            Component {
                id: contactDelegate

                Item {
                    width: 180; height: 50
                    Column {
                        id: exercicesSelectionColumn

                        Text { text: '<b>exerciceFilename:</b> ' + exerciceFilename }
                        Text { text: '<b>Pedagogic Objective:</b> ' + pedagogicObjective }
                        Text { text: '<b>pedagogicApproach:</b> ' + pedagogicApproach }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            exercicesListView.currentIndex = index
                            //document.fileUrl = "/home/charruau/Development/MyGCompris/GCompris-qt/src/activities/multiple-choice-questions/Exercices/" + exerciceFilename
                            console.log("111- " + "/home/charruau/Development/MyGCompris/GCompris-qt/src/activities/multiple-choice-questions/Exercices/" + exerciceFilename)
                            //document.fileUrl = "qrc:///gcompris/src/activities/multiple-choice-questions/example.html"
                            console.log("qrc:///gcompris/src/activities/multiple-choice-questions/example.html")
                            document.fileUrl = "qrc:///gcompris/src/activities/multiple-choice-questions/Exercices/" + exerciceFilename
                            openDialogBox.visible = false
                        }
                    }
                }
            }

            Flow {
                  anchors.fill: parent
                  anchors.margins: 4
                  spacing: 10

                  ListView {
                      id: exercicesListView

                      //  anchors.top : textAreaDestination.anchors.top
                      // anchors.fill: textAreaDestination
                      anchors.fill: parent
                      model: exercicesListModel
                      delegate: contactDelegate
                      highlight: Rectangle {
                          width: parent.width
                          color: "lightsteelblue";
                          radius: 5
                      }
                      focus: true
                  }


            }


        }


        DialogHelp {
            id: dialogHelp
            onClose: home()
        }


        Bar {
            id: bar
            content: BarEnumContent { value: help | home}
            onHelpClicked: {
                displayDialog(dialogHelp)
            }
            onPreviousLevelClicked: Activity.previousLevel()
            onNextLevelClicked: Activity.nextLevel()
            onHomeClicked: activity.home()
        }


        BarButton {
          id: okButton
          source: "qrc:/gcompris/src/core/resource/bar_ok.svg"
          sourceSize.width: 66 * bar.barZoom
          anchors {
              right: parent.right
              rightMargin: 10 * ApplicationInfo.ratio
              bottom: parent.bottom
              bottomMargin: parent.width > 420 * ApplicationInfo.ratio ? 10 : bar.height
          }
          width: 66 * ApplicationInfo.ratio
          height: 66 * ApplicationInfo.ratio
          onClicked: {
            //rtextAreaDestination.checkAnswers()
            destDocument.setExerciceFilename()
          }
        }

        Bonus {
            id: bonus
            Component.onCompleted: win.connect(Activity.nextLevel)
        }

        Text {
            id: scoreScreen
            x: 10//textAreaDestination.width + textAreaDestinationAnchors.margins + 10
            y: 10//textAreaDestinationAnchors.margins

            font.family: "Helvetica"
            font.pointSize: 24
            color: "black"
        }

    }

}
