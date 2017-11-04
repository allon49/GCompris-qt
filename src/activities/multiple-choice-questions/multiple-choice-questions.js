/* GCompris - multiple-choice-questions.js
 *
 * Copyright (C) 2017 YOUR NAME <xx@yy.org>
 *
 * Authors:
 *   <THE GTK VERSION AUTHOR> (GTK+ version)
 *   "YOUR NAME" <YOUR EMAIL> (Qt Quick port)
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
.pragma library
.import QtQuick 2.6 as Quick

var currentLevel = 0
var numberOfLevel = 4
var items

var multipleChoicesElementsArray = []
var displayAnswerMarks = false
var answersPlacesInserted = false
var resultMarkStrInserted = false
var answerFieldsPrepared = false
var originalText = ""


function start(items_) {
    items = items_
    currentLevel = 0
    initLevel()
}

function stop() {
}

function initLevel() {
    items.bar.level = currentLevel + 1
}

function nextLevel() {
    if(numberOfLevel <= ++currentLevel ) {
        currentLevel = 0
    }
    initLevel();
}

function previousLevel() {
    if(--currentLevel < 0) {
        currentLevel = numberOfLevel - 1
    }
    initLevel();
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
    prepareAnswerFields()
    insertSpaceForMultipleChoiceBoxes()
    insertMultipleChoiceBoxes()
}

function prepareAnswerFields() {

    answersPlacesInserted = false

    items.textAreaDestination.text = items.textArea.text

    var openingBracketPos = 0
    var closingBracketPos = 0
    var bracketOpened = false

    var openingBracketPosInDestTextArea = 0
    var closingBracketPosInDestTextArea = 0

    var nbOfCharactersRemoved = 0

    var indexTest = 0

    multipleChoicesElementsArray = []

    for (var i = 0; i < items.textArea.length; i++) {
        var oneTextChar = items.textArea.getText(i,i+1)

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
            var multipleChoiceElementStr = items.textArea.getText(openingBracketPos+1,closingBracketPos)
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
            items.textAreaDestination.remove(openingBracketPosInDestTextArea+questionLength+1,closingBracketPosInDestTextArea+1)
            items.textAreaDestination.remove(openingBracketPosInDestTextArea,openingBracketPosInDestTextArea+1)

            //color the "question" text
            items.destDocument.selectionStart = openingBracketPosInDestTextArea
            items.destDocument.selectionEnd = openingBracketPosInDestTextArea+questionLength
            items.destDocument.cursorPosition = openingBracketPosInDestTextArea
            items.destDocument.textColor = "blue"

            nbOfCharactersRemoved = nbOfCharactersRemoved + (closingBracketPos - openingBracketPos - questionLength +1)

        }
        items.scoreScreen.text = "Score : 0/" + multipleChoicesElementsArray.length
    }
    answerFieldsPrepared = true
}


function deleteAnswerChoices() {
    for (var i=0; i<multipleChoicesElementsArray.length; i++) {

        //prepare the positions of the questions
        var currentMultipleChoicesElements = multipleChoicesElementsArray[i]
        var wordStartPos = currentMultipleChoicesElements.posInText// + nbOfChartoAdd
        var wordEndPos = wordStartPos + currentMultipleChoicesElements.question.length-1

        //prepare an array containing all the possible answers
//                var multipleChoicesArray = textAreaDestination.multipleChoicesElementsArray[i].goodAnswers.concat(textAreaDestination.multipleChoicesElementsArray[i].badAnswers)

        //find what is the longest choice in choicesArray and insert it in the text to prepare the place for the ComboBox
//                var longestChoiceStr = longestStrInArray(multipleChoicesArray)

        //delete the dummy answered written to reserve the combo box place
        items.textAreaDestination.remove(wordEndPos+1, wordEndPos+1 + multipleChoicesElementsArray[i].longestChoiceStr.length+3)

                      //  console.log("longestChoiceStr: %1 - longestChoiceStrLength: %2".arg(longestChoiceStr).arg(longestChoiceStr.length))

                      //  textAreaDestination.insert(wordEndPos+1, "#")
                      //  textAreaDestination.insert(wordEndPos+1 + longestChoiceStr.length+5, "#")
    }
    answerChoicesComboBoxesRepeater.model = []
}


function insertSuccessAndFailMark(result, choiceNumber) {

    resultMarkStrInserted = true

    var resultMarkStr = "<span style=\"color:green; font-size:%1pt;\"><pre> &#10004;</pre></span>".arg(multipleChoicesElementsArray[choiceNumber].answerFontSize)
    if (result == false) {
        resultMarkStr = "<span style=\"color:red; font-size:%1pt;\"><pre> &#10060;</pre></span>".arg(multipleChoicesElementsArray[choiceNumber].answerFontSize)
    }

    var resultMarkStrPos = multipleChoicesElementsArray[choiceNumber].posInDestText + multipleChoicesElementsArray[choiceNumber].longestChoiceStr.length + 1

    //var answerStr = "<span style=\"color:red; font-size:%1pt;\"><pre>%2</pre></span>".arg(fontSize).arg(insertedLongestString)
    items.textAreaDestination.insert(resultMarkStrPos, resultMarkStr)

    // shift the next multiple choices places from two chars: a blanck and the answerMark character
    for (var i = choiceNumber+1; i<multipleChoicesElementsArray.length; i++) {
        multipleChoicesElementsArray[i].posInDestText = multipleChoicesElementsArray[i].posInDestText + 2
    }
}




function deleteSuccessAndFailMark() {

    if (resultMarkStrInserted == true) {
        for (var i = 0; i<multipleChoicesElementsArray.length; i++) {

            var resultMarkStrPos = multipleChoicesElementsArray[i].posInDestText + multipleChoicesElementsArray[i].longestChoiceStr.length + 1

            textAreaDestination.remove(resultMarkStrPos,resultMarkStrPos+2)

            // shift the next multiple choices places from two chars: a blanck and the answerMark character
            for (var j = i+1; j<multipleChoicesElementsArray.length; j++) {
                multipleChoicesElementsArray[j].posInDestText = multipleChoicesElementsArray[j].posInDestText - 2
            }
        }
    }
    resultMarkStrInserted = false
}


function checkAnswers() {

    if (resultMarkStrInserted == true) {
        deleteSuccessAndFailMark()
    }

    var score = 0
    for (var i = 0; i<multipleChoicesElementsArray.length; i++) {

        var goodAnswers = multipleChoicesElementsArray[i].goodAnswers
        var comboBoxValue = multipleChoicesElementsArray[i].comboBoxValue
        var shuffledVar = multipleChoicesElementsArray[i].shuffledPossibleAnswers
     //   console.log("goodAnswers")
     //   console.log(goodAnswers)
     //   console.log("comboBoxValue")
     //   console.log(comboBoxValue)
        console.log("shuffled var " + i + ":")
        console.log(shuffledVar)
        var result = goodAnswers.indexOf(comboBoxValue);
        if (result != -1) {
            insertSuccessAndFailMark(true, i)
            score = score + 1
        }
        else
        {
            insertSuccessAndFailMark(false, i)
        }

    }
    insertMultipleChoiceBoxes()
    scoreScreen.text = "Score : " + score + "/" + multipleChoicesElementsArray.length
}



function insertSpaceForMultipleChoiceBoxes() {
    var nbOfCharToAdd = 0
    for (var i = 0; i<multipleChoicesElementsArray.length; i++) {

            //create character spaces for the combo box

        //store the question start and end position
        var currentMultipleChoicesElements = multipleChoicesElementsArray[i]
        var wordStartPos = currentMultipleChoicesElements.posInText
        var wordEndPos = wordStartPos + currentMultipleChoicesElements.question.length-1

        //read and store the question characters family and size
        items.destDocument.cursorPosition = wordStartPos
        items.destDocument.selectionStart = wordStartPos
        items.destDocument.selectionEnd = wordEndPos
        var fontSize = items.destDocument.fontSize
        multipleChoicesElementsArray[i].answerFontSize = fontSize
        var fontFamily = items.destDocument.fontFamily
        multipleChoicesElementsArray[i].answerFontFamily = fontFamily

        //console.log("+++++++**++++++++" + textAreaDestination.multipleChoicesElementsArray[i].userAnswer)

        //find what is the longest choice in choicesArray and insert it in the text to prepare the place for the ComboBox
        var insertedLongestString = " " + multipleChoicesElementsArray[i].longestChoiceStr
        var insertedLongestStringLength = insertedLongestString.length

        var answerStr = "<span style=\"color:red; font-size:%1pt;\"><pre>%2</pre></span>".arg(fontSize).arg(insertedLongestString)
        var choiceStrPosition = wordEndPos + 1 + nbOfCharToAdd
        items.textAreaDestination.insert(choiceStrPosition, answerStr)
        multipleChoicesElementsArray[i].posInDestText = choiceStrPosition
        nbOfCharToAdd = nbOfCharToAdd + insertedLongestStringLength
    }
}

function insertMultipleChoiceBoxes() {
    for (var i = 0; i<multipleChoicesElementsArray.length; i++) {

        //store the multiple choices answers positions in array to be used in model
        var comboBoxPos = multipleChoicesElementsArray[i].posInDestText
        var rect = items.textAreaDestination.positionToRectangle(comboBoxPos+1)
        multipleChoicesElementsArray[i].posInDestTextX = rect.x
        multipleChoicesElementsArray[i].posInDestTextY = rect.y

        //calculate choices answers width to set combobox width
        items.destDocument.cursorPosition = comboBoxPos+3
        items.destDocument.selectionStart = comboBoxPos +3
        items.destDocument.selectionEnd = comboBoxPos+4
        var stringWidth = items.destDocument.stringWidth
        multipleChoicesElementsArray[i].comboboxWidth = stringWidth
    }

    items.answerChoicesComboBoxesRepeater.model = multipleChoicesElementsArray
}


function deleteMultipleChoiceBoxes() {
    items.answerChoicesComboBoxesRepeater.model = []
}
