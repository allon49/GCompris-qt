/* GCompris - lang.qml
*
* Copyright (C) Siddhesh suthar <siddhesh.it@gmail.com> (Qt Quick port)
*
* Authors:
*   Pascal Georges (pascal.georges1@free.fr) (GTK+ version)
*   Holger Kaelberer <holger.k@elberer.de> (Qt Quick port of imageid)
*   Siddhesh suthar <siddhesh.it@gmail.com> (Qt Quick port)
*   Bruno Coudoin <bruno.coudoin@gcompris.net> (Integration Lang dataset)
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
import QtGraphicalEffects 1.0

import "../../core"
import "lang.js" as Activity
import "spell_it.js" as SpellActivity
import "qrc:/gcompris/src/core/core.js" as Core

ActivityBase {
    id: activity

    onStart: focus = true
    onStop: {}

    pageComponent: Image {
        id: background
        source: "qrc:/gcompris/src/activities/lang/resource/imageid-bg.svg"
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: parent.width

        readonly property string wordsResource: "data2/words/words.rcc"
        property bool englishFallback: false
        property bool downloadWordsNeeded: false

        signal start
        signal stop
        signal voiceError
        signal voiceDone

        Component.onCompleted: {
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        // Add here the QML items you need to access in javascript
        QtObject {
            id: items
            property Item main: activity.main
            property GCAudio audioVoices: activity.audioVoices
            property alias background: background
            property alias bar: bar
            property alias imageReview: imageReview
            property alias parser: parser
            property alias menuModel: menuScreen.menuModel
            property var wordList
            property alias menuScreen: menuScreen
            property alias englishFallbackDialog: englishFallbackDialog
            property string locale: 'system'
            property alias dialogActivityConfig: dialogActivityConfig
        }

        function handleResourceRegistered(resource)
        {
            if (resource == wordsResource)
                Activity.start();
        }

        onStart: {
            Activity.init(items)
            dialogActivityConfig.getInitialConfiguration()

            activity.audioVoices.error.connect(voiceError)
            activity.audioVoices.done.connect(voiceDone)

            // check for words.rcc:
            if (DownloadManager.isDataRegistered("words")) {
                // words.rcc is already registered -> start right away
                Activity.start();
            } else if(DownloadManager.haveLocalResource(wordsResource)) {
                // words.rcc is there -> register old file first
                if (DownloadManager.registerResource(wordsResource))
                    Activity.start(items);
                else // could not register the old data -> react to a possible update
                    DownloadManager.resourceRegistered.connect(handleResourceRegistered);
                // then try to update in the background
                DownloadManager.updateResource(wordsResource);
            } else {
                // words.rcc has not been downloaded yet -> ask for download
                downloadWordsNeeded = true
            }
        }

        onStop: {
            DownloadManager.resourceRegistered.disconnect(handleResourceRegistered);
            dialogActivityConfig.saveDatainConfiguration()
            Activity.stop()
        }

        JsonParser {
            id: parser
            onError: console.error("lang: Error parsing json: " + msg);
        }

        MenuScreen {
            id: menuScreen
        }

        ImageReview {
            id: imageReview
        }

        DialogHelp {
            id: dialogHelp
            onClose: home()
        }

        Bar {
            id: bar
            content: BarEnumContent { value:
                    menuScreen.visible ? help | home |config
                                       : help | home }
            onHelpClicked: {
                displayDialog(dialogHelp)
            }
            onHomeClicked: {
                if(!items.menuScreen.started && !items.imageReview.started)
                    // We're in a mini game, start imageReview
                    items.imageReview.start()
                else if(items.imageReview.started)
                    // Leave imageReview
                    Activity.launchMenuScreen()
                else
                    home()
            }
            onConfigClicked: {
                dialogActivityConfig.active = true
                dialogActivityConfig.setDefaultValues()
                displayDialog(dialogActivityConfig)
            }
        }

        Loader {
            id: englishFallbackDialog
            sourceComponent: GCDialog {
                parent: activity.main
                message: qsTr("We are sorry, we don't have yet a translation for your language.") + " " +
                         qsTr("GCompris is developed by the KDE community, you can translate GCompris by joining a translation team on <a href=\"%2\">%2</a>").arg("http://l10n.kde.org/") +
                         "<br /> <br />" +
                         qsTr("We switched to English for this activity but you can select another language in the configuration dialog.")
                onClose: background.englishFallback = false
            }
            anchors.fill: parent
            focus: true
            active: background.englishFallback
            onStatusChanged: if (status == Loader.Ready) item.start()
        }

        Loader {
            id: downloadWordsDialog
            sourceComponent: GCDialog {
                parent: activity.main
                message: qsTr("The images for this activity are not yet installed.")
                button1Text: qsTr("Download the images")
                onClose: background.downloadWordsNeeded = false
                onButton1Hit: {
                    DownloadManager.resourceRegistered.connect(handleResourceRegistered);
                    DownloadManager.downloadResource(wordsResource)
                    var downloadDialog = Core.showDownloadDialog(activity, {});
                }
            }
            anchors.fill: parent
            focus: true
            active: background.downloadWordsNeeded
            onStatusChanged: if (status == Loader.Ready) item.start()
        }

        DialogActivityConfig {
            id: dialogActivityConfig
            currentActivity: activity
            content: Component {
                Item {
                    property alias localeBox: localeBox
                    height: column.height

                    property alias availableLangs: langs.languages
                    LanguageList {
                        id: langs
                    }

                    Column {
                        id: column
                        spacing: 10
                        width: parent.width

                        Flow {
                            spacing: 5
                            width: dialogActivityConfig.width
                            GCComboBox {
                                id: localeBox
                                model: langs.languages
                                background: dialogActivityConfig
                                width: dialogActivityConfig.width
                                label: qsTr("Select your locale")
                            }
                        }
                    }
                }
            }

            onLoadData: {
                if(!dataToSave)
                    return

                if(dataToSave['locale']) {
                    items.locale = dataToSave["locale"];
                }
            }
            onSaveData: {
                // Save the lessons status on the current locale
                var oldLocale = items.locale
                dataToSave[ApplicationInfo.getVoicesLocale(items.locale)] =
                        Activity.lessonsToSavedProperties(dataToSave)

                if(!dialogActivityConfig.loader.item)
                    return

                var newLocale =
                        dialogActivityConfig.configItem.availableLangs[
                            dialogActivityConfig.loader.item.localeBox.currentIndex].locale;
                // Remove .UTF-8
                if(newLocale.indexOf('.') != -1) {
                    newLocale = newLocale.substring(0, newLocale.indexOf('.'))
                }
                dataToSave['locale'] = newLocale
                items.locale = newLocale;

                // Restart the activity with new information
                if(oldLocale !== newLocale) {
                    Activity.stop()
                    Activity.start();
                }
            }


            function setDefaultValues() {
                var localeUtf8 = items.locale;
                if(items.locale != "system") {
                    localeUtf8 += ".UTF-8";
                }

                for(var i = 0 ; i < dialogActivityConfig.configItem.availableLangs.length ; i ++) {
                    if(dialogActivityConfig.configItem.availableLangs[i].locale === localeUtf8) {
                        dialogActivityConfig.loader.item.localeBox.currentIndex = i;
                        break;
                    }
                }
            }
            onClose: home()
        }
    }

}