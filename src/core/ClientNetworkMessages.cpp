/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include <QtWidgets>
#include <QString>
#include <QQmlComponent>
#include <QQmlEngine>


#include "ClientNetworkMessages.h"



ClientNetworkMessages* ClientNetworkMessages::_instance = 0;

ClientNetworkMessages::ClientNetworkMessages(): QObject()
{

    connect(&client, SIGNAL(newMessage(QString,QString)),
            this, SLOT(appendMessage(QString,QString)));

    m_currentUsername = "Mathilda";

}

ClientNetworkMessages::~ClientNetworkMessages()
{
    _instance = 0;
}


// It is not recommended to create a singleton of Qml Singleton registered
// object but we could not found a better way to let us access ClientNetworkMessages
// on the C++ side. All our test shows that it works.
// Using the singleton after the QmlEngine has been destroyed is forbidden!
ClientNetworkMessages* ClientNetworkMessages::getInstance()
{
    if (!_instance)
        _instance = new ClientNetworkMessages;
    return _instance;
}

QObject *ClientNetworkMessages::systeminfoProvider(QQmlEngine *engine,
        QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return getInstance();
}

void ClientNetworkMessages::init()
{
    qmlRegisterSingletonType<ClientNetworkMessages>("GCompris", 1, 0,
            "ClientNetworkMessages",
            systeminfoProvider);




    //here I create the engine then the component like explained here
    //http://doc.qt.io/qt-5/qtqml-cppintegration-interactqmlfromcpp.html#invoking-qml-methods


    QQmlEngine engine;
    //QQmlComponent component(&engine, "qrc:/gcompris/src/activities/networkclient/Networkclient.qml");
    QQmlComponent component(&engine, "/home/charruau/Development/GComprisNetwork/GCompris-qt/src/activities/networkclient/Networkclient.qml");


    //then I create the tree node as form of object
    QObject *object = component.create();

    //I create the pointer which will sort the position of textEdit objectName (described in Networkclient.qml line 104.
    QObject *s_qml_text_edit;
    //I find a child called textEdit within the tree representing the qml content, I do that recursively because textEdit is not under root
    s_qml_text_edit = object->findChild<QObject*>("textEdit",Qt::FindChildrenRecursively);



    QVariant msg = "Hello from C++";

    //I call the method append() part of textEdit
    QMetaObject::invokeMethod(s_qml_text_edit, "append", Q_ARG(QVariant, msg));
   // s_qml_text_edit->x = 10;

    delete object;
}


void ClientNetworkMessages::appendMessage(const QString &from, const QString &message)
{
    if (from.isEmpty() || message.isEmpty())
        return;

    if (message.indexOf("controle::") == 0)
       qDebug() << "Control::" << message;
    else if (message.indexOf("client_data::") == 0)
       qDebug() << "client_data::" << message;
    else
        qDebug() << "invalid data::" << message;




}

void ClientNetworkMessages::sendMessage(QString message)
{


   qDebug() << "Message:" << message;
   client.sendMessage(message);

}

void ClientNetworkMessages::setCurrentUsername(QString &currentUsername)
{
    m_currentUsername = currentUsername;
    emit currentUsernameChanged();
}

QString ClientNetworkMessages::getCurrentUsername() const
{
    return m_currentUsername;
}



void appendMsgToTextEdit()
{

}







