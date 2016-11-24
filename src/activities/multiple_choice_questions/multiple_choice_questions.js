/* GCompris - babymatch.js
 *
 * Copyright (C) 2015 Pulkit Gupta
 *
 * Authors:
 *   Bruno Coudoin <bruno.coudoin@gcompris.net> (GTK+ version)
 *   Pulkit Gupta <pulkitgenius@gmail.com> (Qt Quick port)
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
.import QtQuick 2.0 as Quick

var currentLevel = 1
var currentSubLevel = 0
var numberOfLevel
var numberOfSubLevel
var items
var mySentenceItems
var url
var glowEnabled
var glowEnabledDefault
var spots = []
var showText = []
var displayDropCircle


var PLAIN_TEXT = 0
var TEXT_TO_ANALYSE = 1
var MULTI_CHOICES = 2

var sentenceSegments = [[]]

function start(items_, url_, levelCount_, answerGlow_, displayDropCircle_) {
    items = items_
    url = url_
    numberOfLevel = levelCount_
    glowEnabledDefault = answerGlow_
    displayDropCircle = displayDropCircle_
    currentLevel = 1
    currentSubLevel = 0
    numberOfSubLevel = 0
    spots = []
    showText = []
    initLevel()
}

function onSentenceItemCompleted(mySentenceItems_) {
    mySentenceItems = mySentenceItems_
}


function stop() {
    for(var i = 0 ; i < spots.length ; ++ i)
        spots[i].destroy()
}

function initLevel() {
    items.bar.level = currentLevel
    var filename = url + "board" + "/" + "board" + currentLevel + "_" + currentSubLevel + ".qml"
    items.dataset.source = filename
    var levelData = items.dataset.item

    items.availablePieces.model.clear()
    for(var i = 0 ; i < spots.length ; ++ i)
        spots[i].destroy()
    spots = []

    for(var i = 0 ; i < showText.length ; ++ i)
        showText[i].destroy()
    showText = []

    items.backgroundPiecesModel.clear()
    items.backgroundImage.source = ""

    items.availablePieces.view.currentDisplayedGroup = 0
    items.availablePieces.view.itemsDropped = 0
    items.availablePieces.view.previousNavigation = 1
    items.availablePieces.view.nextNavigation = 1
    items.availablePieces.view.okShowed = false
    items.availablePieces.view.showGlow = false
    items.availablePieces.view.ok.height = 0

    var dropWordAnswerItemComponent = Qt.createComponent("qrc:/gcompris/src/activities/multiple_choice_questions/DropWordAnswerItem.qml")
    var textItemComponent = Qt.createComponent("qrc:/gcompris/src/activities/multiple_choice_questions/TextItem.qml")
    var sentenceItemComponent = Qt.createComponent("qrc:/gcompris/src/activities/multiple_choice_questions/SentenceItem.qml")
    var wordItemComponent = Qt.createComponent("qrc:/gcompris/src/activities/multiple_choice_questions/WordItem.qml")



    //print(dropItemComponent.errorString())

    if(currentSubLevel == 0 && levelData.numberOfSubLevel != undefined)
        numberOfSubLevel = levelData.numberOfSubLevel

    items.score.currentSubLevel = currentSubLevel + 1
    items.score.numberOfSubLevels = numberOfSubLevel + 1

    if(levelData.glow == undefined)
        glowEnabled = glowEnabledDefault
    else
        glowEnabled = levelData.glow

    if(levelData.instruction == undefined) {
        items.instruction.opacity = 0
        items.instruction.text = ""
    } else if(!displayDropCircle) {
        items.instruction.opacity = 0
        items.instruction.text = levelData.instruction
    }
    else {
        items.instruction.opacity = 1
        items.instruction.text = levelData.instruction
    }

    // Fill available pieces
    var arr=[], levelDataLength = levelData.levels.length
    for(var i=0 ; i < levelDataLength ; i++)
        arr[i] = i

    var i = 0, j = 0, k = 0, n = 0
    while(levelDataLength--) {

        //Randomize the order of pieces
        var rand = Math.floor(Math.random() * levelDataLength)
        i = arr[rand]
        arr.splice(rand,1)


        //Create answer pieces
        if(levelData.levels[i].type === undefined) {
            items.availablePieces.model.append( {
                "imgName": levelData.levels[i].pixmapfile,
                "textDummy": levelData.levels[i].text,
                "imgSound": levelData.levels[i].sound ? levelData.levels[i].sound : "",
                "imgHeight": levelData.levels[i].height == undefined ? 0 : levelData.levels[i].height,
                "imgWidth": levelData.levels[i].width == undefined ? 0 : levelData.levels[i].width * 10,
                "toolTipText":
                   // We remove the text before the pipe symbol if any (translation disembiguation)
                   levelData.levels[i].toolTipText == undefined ?
                                                       "" :
                                                       (levelData.levels[i].toolTipText.split('|').length > 1 ?
                                                        levelData.levels[i].toolTipText.split('|')[1] :
                                                        levelData.levels[i].toolTipText),
                "pressSound": levelData.levels[i].soundFile == undefined ?
                              "qrc:/gcompris/src/core/resource/sounds/bleep.wav" : url + levelData.levels[i].soundFile
            });

         /*   spots[j++] = dropItemComponent.createObject(
                         items.backgroundImage, {
                            "posX": levelData.levels[i].x,
                            "posY": levelData.levels[i].y,
                            "imgHeight": levelData.levels[i].height == undefined ? 0 : levelData.levels[i].height,
                            "imgWidth": levelData.levels[i].width == undefined ? 0 : levelData.levels[i].width,
                            "dropAreaSize": levelData.levels[i].dropAreaSize == undefined ? 15 : levelData.levels[i].dropAreaSize,
                            "imageName" : levelData.levels[i].pixmapfile
                         });*/
        }
        //Create Text pieces for the level which has to display additional information
        else if(levelData.levels[i].type == "DisplayText") {
            showText[k++] = textItemComponent.createObject(
                            items.backgroundImage, {
                                "posX": levelData.levels[i].x,
                                "posY": levelData.levels[i].y,
                                "textWidth": levelData.levels[i].width,
                                "showText" : levelData.levels[i].text

                            });
        }
     /*   else if(levelData.levels[i].type == "textAnswer") {
            items.availablePieces.model.append( {
                "imgName": levelData.levels[i].pixmapfile,
                "textDummy": levelData.levels[i].text,
                "imgSound": levelData.levels[i].sound ? levelData.levels[i].sound : "",
                "imgHeight": levelData.levels[i].height == undefined ? 0 : levelData.levels[i].height,
                "imgWidth": levelData.levels[i].width == undefined ? 0 : levelData.levels[i].width * 10,
                "toolTipText":
                   // We remove the text before the pipe symbol if any (translation disembiguation)
                   levelData.levels[i].toolTipText == undefined ?
                                                       "" :
                                                       (levelData.levels[i].toolTipText.split('|').length > 1 ?
                                                        levelData.levels[i].toolTipText.split('|')[1] :
                                                        levelData.levels[i].toolTipText),
                "pressSound": levelData.levels[i].soundFile == undefined ?
                              "qrc:/gcompris/src/core/resource/sounds/bleep.wav" : url + levelData.levels[i].soundFile
            });
        }*/

        //split the sentence in group of words. Normal words, words to analyses and multiple choices words.
        //to do this I split first by group of normal words + multiple choices items
        //ex "J’ai vu [un écureuil|*COD|COI], sur [un sapin|*CCL|CCM] en face de la maison."
        //will be splitted in two parts
        //1- J’ai vu [un écureuil|*COD|COI]
        //2- , sur [un sapin|*CCL|CCM] en face de la maison.
        //then each part is splitted in three parts.
        //1- plain group of words: J’ai vu
        //2- words to analyse: un écureuil
        //3- then mutilple choices words : *COD|COI
        else if(levelData.levels[i].type == "MultipleChoiceSentence") {
            var sentenceWords = levelData.levels[i].sentence
            console.log("++++++++sentenceWords " + sentenceWords)   //// to remove ++++++++++++++++++++++++++++++++++++++++

            var wordsToAnalyse
            var str = "I have seen [a squiral|*name|adjective], on a [red|name|*adjective] tree in front of the house.";
            var sentenceSegmentIndex = 0
            var elementsBetweenBrackets = []
            var multipleChoicesElementsArray = [[]]
            var re = /\[([^[]+)\]/g
            var plainTextFirstCharPos = 0

            sentenceSegments.clear
            while ((elementsBetweenBrackets = re.exec(str)) != null) {
                console.log("--------Group of words number: " + sentenceSegmentIndex + 1)

                // extract all the words before the multiple choices [wordsToAnalyse|xxx|yyy] to set them to plainText
                console.log("match found at " + elementsBetweenBrackets.index)
                var plainText = str.substring(plainTextFirstCharPos, elementsBetweenBrackets.index);
                console.log("plainText: " + plainText);
                sentenceSegments.push([PLAIN_TEXT,plainText])

                // split the multiple choices [wordsToAnalyse|xxx|yyy] and set them in multipleChoicesElements array
                var multipleChoicesElements = elementsBetweenBrackets[1].split("|")


                // remove the first element of the set and set it to wordsToAnalyse
                wordsToAnalyse = multipleChoicesElements.shift()
                sentenceSegments.push([TEXT_TO_ANALYSE,wordsToAnalyse])
                console.log("wordsToAnalyse: " + wordsToAnalyse)

                console.log("multipleChoicesElements[0]: " + multipleChoicesElements[0])
                console.log("multipleChoicesElements[1]: " + multipleChoicesElements[1])


                //push the multiple choices elements array (ex COD,COI,CCM,CCL) to the sub array multipleChoicesElementsArray
                multipleChoicesElementsArray[sentenceSegmentIndex] = multipleChoicesElements
                console.log("MultipleChoicesElements: " + multipleChoicesElements)
                sentenceSegments.push([MULTI_CHOICES,multipleChoicesElements])
                //sentenceSegments.push([MULTI_CHOICES,"...."])

                //prepare the index of the begining of the next plain text
                plainTextFirstCharPos = elementsBetweenBrackets.index + elementsBetweenBrackets[1].length + 2

                sentenceSegmentIndex++
            }

            //extract the last plain text sentence segment
            var lastPlainTextSegment = str.substring(plainTextFirstCharPos, str.length);
            console.log("lastPlainTextSegment " + lastPlainTextSegment)
            sentenceSegments.push([PLAIN_TEXT,lastPlainTextSegment])

            //trace sentenceSegments
            console.log("sentenceSegments " + sentenceSegments)

            //trace of multipleChoicesElementsArray
            console.log("multipleChoicesElementsArray " + multipleChoicesElementsArray)

            //display the possible answers in listwidget
            for (var j=0; j<multipleChoicesElementsArray.length; j++) {
                for (var k=0; k<multipleChoicesElementsArray[j].length; k++) {
                    items.availablePieces.model.append( {
                        "imgName": levelData.levels[i].pixmapfile,
                        "possibleAnswer": multipleChoicesElementsArray[j][k],
                        "imgSound": levelData.levels[i].sound ? levelData.levels[i].sound : "",
                        "imgHeight": levelData.levels[i].height == undefined ? 0 : levelData.levels[i].height,
                        "imgWidth": levelData.levels[i].width == undefined ? 0 : levelData.levels[i].width * 10,
                        "toolTipText":
                           // We remove the text before the pipe symbol if any (translation disembiguation)
                           levelData.levels[i].toolTipText == undefined ?
                                                               "" :
                                                               (levelData.levels[i].toolTipText.split('|').length > 1 ?
                                                                levelData.levels[i].toolTipText.split('|')[1] :
                                                                levelData.levels[i].toolTipText),
                        "pressSound": levelData.levels[i].soundFile == undefined ?
                                      "qrc:/gcompris/src/core/resource/sounds/bleep.wav" : url + levelData.levels[i].soundFile
                    });
                }
            }

            //display the sentence in main window
            var sentenceItem = sentenceItemComponent.createObject(
                                                items.backgroundImage, {
                                                    "sentenceSegments": sentenceSegments
                                                })
            for (var i=1; i<sentenceSegments.length; i++) {
                console.log("segments " + sentenceSegments[i][0] + "   " + sentenceSegments[i][1])
                if (sentenceSegments[i][0] == PLAIN_TEXT) {
                    wordItemComponent.createObject(
                                        sentenceItem.myFlow1, {
                                        "text": sentenceSegments[i][1]
                                        })
                }
                if (sentenceSegments[i][0] == TEXT_TO_ANALYSE) {
                    wordItemComponent.createObject(
                                        sentenceItem.myFlow1, {
                                        "text": sentenceSegments[i][1],
                                        "border.color": "red"
                                        })
                }
                if (sentenceSegments[i][0] == MULTI_CHOICES) {
                    console.log("tttt: " + multipleChoicesElementsArray[0])
                    dropWordAnswerItemComponent.createObject(
                                        sentenceItem.myFlow1, {
                                    "imgHeight": "1",
                                    "imgWidth": "1",
                                    "dropAreaSize": "50",
                                    "imageName": "images/postpoint.svg",
                                    "expectedAnswer": sentenceSegments[i][1]
                                        })
                }

            }

            //create in leftwidget (can be on the top too) the words in the listwidget allowing to fill up the multiple choices questions
            var sentenceItem = sentenceItemComponent.createObject(
                                                items.backgroundImage, {
                                                    "sentenceSegments": sentenceSegments
                                                })


        }

        //Create static background pieces
        else {
            if(levelData.levels[i].type === "SHAPE_BACKGROUND_IMAGE") {
                items.backgroundImage.source = url + levelData.levels[i].pixmapfile
            }
            else {
                items.backgroundPiecesModel.append( {
                    "imgName": levelData.levels[i].pixmapfile,
                    "posX": levelData.levels[i].x,
                    "posY": levelData.levels[i].y,
                    "imgHeight": levelData.levels[i].height == undefined ? 0 : levelData.levels[i].height,
                    "imgWidth": levelData.levels[i].width == undefined ? 0 : levelData.levels[i].width,
                });
            }
        }
    }

    //Initialize displayedGroup variable which is used for showing navigation bars
    for(var i=0;i<items.availablePieces.view.nbDisplayedGroup;++i)
        items.availablePieces.view.displayedGroup[i] = true


   /* textItemComponent.createObject(
                                items.backgroundImage, {
                                    "posX": 100,
                                    "posY": 100,
                                    "textWidth": 100,
                                    "showText" : "test"
                                });*/

}



function nextSubLevel() {
    if(numberOfSubLevel < ++currentSubLevel) {
        currentSubLevel = 0
        numberOfSubLevel = 0
        nextLevel()
    }
    else
        initLevel()
}

function nextLevel() {
    currentSubLevel = 0
    numberOfSubLevel = 0
    if(numberOfLevel < ++currentLevel) {
        currentLevel = 1
    }
    initLevel()
}

function previousLevel() {
    currentSubLevel = 0
    numberOfSubLevel = 0
    if(--currentLevel < 1) {
        currentLevel = numberOfLevel
    }
    initLevel();
}

function win() {
    items.bonus.good("flower")
}

function wrong() {
    items.bonus.bad("flower")
}
