/* GCompris - SentenceItem.qml
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
import GCompris 1.0
import "../../core"
import "multiple_choices_sentences.js" as Activity




Item {
    id: displayText

    property variant sentenceSegments
    property double backGroundWidth
    property double flowXPosition
    property double flowYPosition
    property alias myFlow1: myFlow1

    backGroundWidth: parent.width - x - 100
    flowXPosition: parent.width / 10
    flowYPosition: parent.height / 5


      Flow {
          id: myFlow1
          width: backGroundWidth
          anchors.margins: 4
          spacing: 20

     /*       WordItem { text: "I"}
            WordItem { text: "have"}
            WordItem { text: "seen"}
            WordItem { text: "a"}
            WordItem { text: "cat"}

            DropWordAnswerItem {

                id: mydrop2

                posX: 0.5
                posY: 0.5
                imgHeight: 1
                imgWidth: 1
                dropAreaSize: 50
                imageName: "images/postpoint.svg"


            }


            WordItem { text: "in"}
            WordItem { text: "front"}
            WordItem { text: "of"}
            WordItem { text: "the"}
            WordItem { text: "house"}*/

        }

}



