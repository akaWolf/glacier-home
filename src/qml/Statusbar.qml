/****************************************************************************************
**
** Copyright (C) 2014 Aleksi Suomalainen <suomalainen.aleksi@gmail.com>
** All rights reserved.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in the
**       documentation and/or other materials provided with the distribution.
**     * Neither the name of the author nor the
**       names of its contributors may be used to endorse or promote products
**       derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
** ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
** LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
** ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
** SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/
import QtQuick 2.1
import QtQuick.Controls.Nemo 1.0
import QtQuick.Controls.Styles.Nemo 1.0
import org.freedesktop.contextkit 1.0
import MeeGo.Connman 0.2

Item {
    id: root
    z: 201
    height: 48
    width: parent.width
    anchors.bottom: parent.bottom

    Rectangle {
        id: statusbar
        color: "black"
        anchors.fill: parent
        opacity: 0.5
        z: 200
    }

    ContextProperty {
        id: batteryChargePercentage
        key: "Battery.ChargePercentage"
        value: "100"
    }

    ContextProperty {
        id: cellularSignalBars
        key: "Cellular.SignalBars"
    }

    ContextProperty {
        id: cellularRegistrationStatus
        key: "Cellular.RegistrationStatus"
    }

    NetworkManager {
        id: networkManager
        function updateTechnologies() {
            if (available && technologiesEnabled) {
                wlan.path = networkManager.technologyPathForType("wifi")
            }
        }

        onAvailableChanged: updateTechnologies()
        onTechnologiesEnabledChanged: updateTechnologies()
        onTechnologiesChanged: updateTechnologies()

    }

    NetworkTechnology {
        id: wlan
    }

    Row {
        spacing: 16
        StatusbarItem {
            source: "image://theme/icon_cell" + cellularSignalBars.value
        }
        StatusbarItem {
            source: {
                if (wlan.connected) {
                    if (networkManager.defaultRoute.type !== "wifi")
                        return "image://theme/icon_wifi_0"
                    if (networkManager.defaultRoute.strength >= 59) {
                        return "image://theme/icon_wifi_normal4"
                    } else if (networkManager.defaultRoute.strength >= 55) {
                        return "image://theme/icon_wifi_normal3"
                    } else if (networkManager.defaultRoute.strength >= 50) {
                        return "image://theme/icon_wifi_normal2"
                    } else if (networkManager.defaultRoute.strength >= 40) {
                        return "image://theme/icon_wifi_normal1"
                    } else {
                        return "image://theme/icon_wifi_0"
                    }
                } else {
                    return "image://theme/icon_wifi_0"
                }
            }
        }
        StatusbarItem {
            source: "image://theme/icon_bt_normal"
        }
        StatusbarItem {
            source: "image://theme/icon_nfc_normal"
        }
        StatusbarItem {
            source: "image://theme/icon_gps_normal"
        }
        StatusbarItem {
            source: "image://theme/icon_play_pause"
        }
        StatusbarItem {
            Label {
                id: hours
                width: 16
                height: 16
                font.pointSize: 6
                text: Qt.formatDateTime(wallClock.time, "hh")
            }
            Label {
                id: minutes
                anchors.top: hours.bottom
                anchors.topMargin: 4
                width: 16
                height: 16
                font.pointSize: 6
                text: Qt.formatDateTime(wallClock.time, "mm")
            }
        }

        StatusbarItem {
            source: {
                if(batteryChargePercentage.value > 85) {
                    return "images/battery6.png"
                } else if (batteryChargePercentage.value <= 5) {
                    return "images/battery0.png"
                } else if (batteryChargePercentage.value <= 10) {
                    return "images/battery1.png"
                } else if (batteryChargePercentage.value <= 25) {
                    return "images/battery2.png"
                } else if (batteryChargePercentage.value <= 40) {
                    return "images/battery3.png"
                } else if (batteryChargePercentage.value <= 65) {
                    return "images/battery4.png"
                } else if (batteryChargePercentage.value <= 80) {
                    return "images/battery5.png"
                }
            }
        }
    }
}