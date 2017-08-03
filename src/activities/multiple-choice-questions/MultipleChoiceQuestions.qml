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

        TextArea {
            Accessible.name: "destDocument"
            id: textAreaDestination

            property var multipleChoicesElementsArray : []
            property var displayAnswerMarks : Boolean
            property var answersPlacesInserted: Boolean
            property var resultMarkStrInserted: Boolean
            property var answerFieldsPrepared: Boolean
            property var originalText: String

            width: parent.width - (parent.width/5)

            anchors {
                id: textAreaDestinationAnchors
                left: parent.left
                top: parent.top
                bottom: bar.top
                margins: 50
            }

            textFormat: Qt.RichText

            Component.onCompleted: {
                displayAnswerMarks = false
                answersPlacesInserted = false
                resultMarkStrInserted = false
                answerFieldsPrepared = false
                startExercice()
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


          /*  flickableItem.onContentYChanged: {
                console.log("xxxxxx")
                displayAnswerChoices()
            }*/

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

 /*       ColorDialog {
            id: colorDialog
            color: "black"
        }*/


        TextArea {
            Accessible.name: "document"
            id: textArea



            width: parent.width - (parent.width/3)
            height: parent.height/3 - 20
            x: parent.width/3
            y: parent.height - (parent.height/3)

            //visible: false

            baseUrl: "qrc:/"

            textFormat: Qt.RichText
         //   Component.onCompleted: forceActiveFocus()

            Component.onCompleted: {
                textArea.text = destDocument.text
            }

            onTextChanged: {
                textAreaDestination.startExercice()
            }


        }



        DocumentHandler {
            id: destDocument

            target: textAreaDestination
            cursorPosition: textAreaDestination.cursorPosition
            selectionStart: textAreaDestination.selectionStart
            selectionEnd: textAreaDestination.selectionEnd
          //  textColor: colorDialog.color
            Component.onCompleted: {
                destDocument.fileUrl = "qrc:///gcompris/src/activities/multiple-choice-questions/example.html"

            }
            onError: {
                errorDialog.text = "tttt" //message
                errorDialog.visible = true
            }
         }

        Item {
            id: editorTools
            width: 252
            height: 252
            property variant colorArray: ["#00bde3", "#67c111", "#ea7025"]

            x: textAreaDestination.width + textAreaDestinationAnchors.margins + 10
            y: textAreaDestinationAnchors.margins + scoreScreen.height + 10
            Grid{
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                Repeater {
                    model: 16
                    Rectangle {
                        width: 42; height: 56
                        property int colorIndex: Math.floor(Math.random()*3)
                        color: editorTools.colorArray[colorIndex]
                        border.color: Qt.lighter(color)
                        Text {
                            anchors.centerIn: parent
                            color: "#f0f0f0"
                            text: "Cell " + index
                        }
                    }
                }
            }
        }

        ListModel {
            id: keyWordList
            ListElement {
                name: "Bill Smith"
                number: "555 3264"
            }
            ListElement {
                name: "John Brown"
                number: "555 8426"
            }
            ListElement {
                name: "Sam Wise"
                number: "555 0473"
            }
        }


        Rectangle {
            id: keywordsListView

            width: 180; height: 200

            Component {
                id: contactDelegate
                Item {
                    width: 180; height: 40
                    Column {
                        Text { text: '<b>Name:</b> ' + name }
                        Text { text: '<b>Number:</b> ' + number }
                    }
                }
            }

            ListView {
                anchors.fill: parent
                model: keyWordList
                delegate: contactDelegate
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                focus: true
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
            textAreaDestination.checkAnswers()
            destDocument.setExerciceFilename()
          }
        }

        Bonus {
            id: bonus
            Component.onCompleted: win.connect(Activity.nextLevel)
        }

        Text {
            id: scoreScreen
            x: textAreaDestination.width + textAreaDestinationAnchors.margins + 10
            y: textAreaDestinationAnchors.margins

            font.family: "Helvetica"
            font.pointSize: 24
            color: "black"
        }

    }

}
