/* GCompris - DropAnswerItem.qml
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
    
    property double posX
    property double posY
    property string showText
    property double backGroundWidth
    
    x: posX * parent.width
    y: posY * parent.height

    backGroundWidth: parent.width - x - 100

  /*  Flow {
        id: myFlow1
        width: backGroundWidth
        anchors.margins: 4
        spacing: 20

          WordItem { text: "Le"}
          WordItem { text: "chat"}
          WordItem { text: "ne"}

          DropWordAnswerItem {

              id: mydrop1

              posX: 0.5
              posY: 0.5
              imgHeight: 1
              imgWidth: 1
              dropAreaSize: 500
              imageName: "images/postpoint.svg"

          }
          WordItem { text: "pas"}
          WordItem { text: "avec"}
          WordItem { text: "la"}

          DropWordAnswerItem {

              id: mydrop2

              posX: 0.5
              posY: 0.5
              imgHeight: 1
              imgWidth: 1
              dropAreaSize: 500
              imageName: "images/postpoint.svg"


          }
      }*/

    WordItem { text: showText
    x: 100
    y: 100
    }

}
