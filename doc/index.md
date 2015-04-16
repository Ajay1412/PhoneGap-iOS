<!---
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
-->

# com.kandy.phonegap
[**Kandy**](http://www.kandy.io/) is a full-service cloud platform that enables real-time communications for business applications. **KandyPhonegap** is a [Cordova](http://cordova.apache.org/) plugin that makes it easy to use Kandy API with Cordova/PhoneGap.

**Kandy** homepage: [kandy.io](http://www.kandy.io/)
## Supported Platforms
- Android
- IOS (coming soon)

## Installation
Check out PhoneGap CLI [docs](http://docs.phonegap.com/en/3.0.0/guide_cli_index.md.html#The%20Command-line%20Interface)
before starting out.

    cordova plugin add "path/to/plugin/directory" --variable API_KEY=<api-key> --variable API_SECRET=<api-secret>
or

    cordova plugin add https://github.com/kodeplusdev/kandyphonegap.git --variable API_KEY=<api-key> --variable API_SECRET=<api-secret>
## Getting Started
This plugin defines a global `Kandy` object, which provide an easy way to interact with KANDY.
Although the object is in the global scope, it is not available until after the `deviceready` event.
    
```js
    document.addEventListener("deviceready", onDeviceReady, false);
    function onDeviceReady() {
        console.log(Kandy);
    }
```
After the `deviceready` event, you can config and register listeners to receive events from KANDY background service
```js
    function onDeviceReady(){
        ...
        Kandy.initialize({
            widgets: {
                chat: "kandy-chat-widget", // id chat element
                call: "kandy-call-widget", // id call element
                // ...
            },
            listeners: {
                onChatReceived: function(message){
                    // your code here
                }
                // ...
            }
        });
    }
```
After you initialize the `KandyPlugin`, you can use `Kandy` with following syntax:
```js
    Kandy.access.login(function(s){ // successCallback function
        // your code here
    }, function(e){ // errorCallback function
        // your code here
    }, username, password);
```
or as a widget:
```html
    <div id="kandy-call-widget" action-call-error="onCallError"></div>
```
See [API Reference](#api-reference) for more details.
## How to use example codes
**Create the App**

Go to the directory where you maintain your source code, and run a command such as the following:
```shell
    phonegap create hello com.example.hello HelloWorld
```
Then, copy example source codes from [`demo`](/demo) directory of this plugin to your app directory

**Add android platform**

Run a command such as the following:
```shell
    phonegap platform add android
```
**Add plugin**

Go to your app directory and run a command such as the following:
```shell
    phonegap local plugin add directory/to/this/plugin --variable API_KEY=<your_api_key> --variable API_SECRET=<your_api_secret>
```
**Build the App**

Run a command such as the following:
```shell
    phonegap build android
```
## Widgets
The plugin provides several widgets that you can easily use Kandy. You can config id of widgets in the `initialize` function.
### Provisioning widget
Default id of the provisioning widget is `kandy-provisioning-widget`. Some callback actions you can use: `request`, `validate`, `deactivate`

Example:
```html
    <div id="kandy-provisioning-widget" action-request-success="onRequestSuccess" action-request-error="onRequestError"></div>
```
### Access widget
Default id of the access widget is `kandy-access-widget`. Some callback actions you can use: `login`, `logout`

Example:
```html
    <div id="kandy-access-widget" action-login-success="onLoginSuccess"></div>
```
### Call widget
Default id of the call widget is `kandy-call-widget`. The callback action you can use: `call`.
Default call widget type is `voip`. If you want to widget type to `PSTN`, you can use attribute `call-type="PSTN"`.

Example:
```html
    <div id="kandy-call-widget" call-type="PSTN"></div>
```
### Chat widget
Default id of the chat widget is `kandy-chat-widget`. Some callback actions you can use: `send`, `pull`

Example
```html
    <div id="kandy-chat-widget" action-send-success="onSendSuccess"></div>
```
## API Reference
### Configurations
**initialize**(*config*)

Initialize the `KandyPlugin` based on `config` parameters. The `config` parameter is an object with the following properties:
- `widgets` (object) - The id of the widgets (widgets: `provisioning`, `access`, `call`, `chat`).
- `listeners` (object) - Registers listeners to receive events from the KandyPlugin background service. There are a number of events for which you can register:  `onIncomingCall`, `onVideoStateChanged`, `onAudioStateChanged`, `onCallStateChanged`, `onGSMCallIncoming`, `onGSMCallConnected`, `onGSMCallDisconnected`, `onChatReceived`, `onChatDelivered`, `onChatMediaDownloadProgress`, `onChatMediaDownloadFailed`, `onChatMediaDownloadSucceded`, `onDeviceAddressBookChanged` and `onPresenceChanged`.

**onIncomingCall**(*callee*)

Called when a call is coming. The `callee` parameter is an object with the following properties:
- `id` (string) - The ID of the call.
- `callee` (string) - The uri of caller (*callee@domain.com*).
- `via` (string) - Where the call make from.

**onVideoStateChanged**(*state*)

Called when the video of the call change states. The `state` parameter is an object with the following properties:
- `isReceivingVideo` (boolean) - Determines whether or it is receiving video.
- `isSendingVideo` (boolean) - Determines whether or not it is sending video.

**onAudioStateChanged**(*state*)

Called when the audio of the call change states. The `state` parameter is an object with the following properties:
- `id` (string) - The ID of the call.
- `isMute` (boolean) - Determines whether or not the audio is muted.
 
**onCallStateChanged**(*state*)

Called when the call change states. The `state` parameter is an object with the following properties:
- `id` (string) - The ID of the call.
- `state` (string) - The name of current call state (holding, terminated, ...).

**onGSMCallIncoming**(*callee*)

Called when a GSM call is in coming.
- `id` (string) - The ID of the call.
- `callee` (string) - The uri of caller (*callee@domain.com*).
- `via` (string) - Where the call make from.

**onGSMCallConnected**(*callee*)
Called when a GSM call is in connected.
- `id` (string) - The ID of the call.
- `callee` (string) - The uri of caller (*callee@domain.com*).
- `via` (string) - Where the call make from.

**onGSMCallDisconnected**(*callee*)
Called when a GSM call is in disconnected.
- `id` (string) - The ID of the call.
- `callee` (string) - The uri of caller (*callee@domain.com*).
- `via` (string) - Where the call make from.

**onChatReceived**(*message*)

Called when there is a comming message. The `message` parameter is an object message with `chat` type, sent to the user by another user. Here's an example:
```json
    {
        "message": [
        {
            "UUID":"46242C4A-D47A-4098-8DE1-19A5482D1F0F",
            "messageType":"chat",
            "timestamp":1419979765811,
            "sender": "user2@joecool.com",
            "contentType":"text",
            "message":{
                "mimeType":"text/plain",
                "text":"hello world"
            }
        }
        ]
    }
```
**onChatDelivered**(*message*)

Called when a message the user sent was received by the recipient's application. The `message` parameter is an object message with `chatRemoteAck` type. Here's an example of a message:
```json
    {
        "message": [
            {
                "UUID": "4D9D8213-AD6A-4F6D-B0D2-AE02BB95C06B",
                "timestamp": 1412201946514
            }
        ]
    }
```
**onChatMediaDownloadProgress**(*message*, *progress*)

Called when a chat media is in download process.
- `message` (object)
- `process` (integer)

**onChatMediaDownloadFailed**(*message*, *error*)

Called when a chat media download failed.
- `message` (object)
- `error` (string)

**onChatMediaDownloadSucceded**(*message*, *uri*)

Called when a chat media download successed.
- `message` (object)
- `uri` (string)

**onPresenceChanged**(*presence*)

Called when the users change the presence. The `presence` parameter is an object with the following properties:
- `user` (string) - The contact name.
- `state` (string) - the contact state.

**onDeviceAddressBookChanged**()

In order to receive local address book related events.

### Provisioning (namespace `provisioning`)
**requestCode**(*sucessCallback*, *errorCallback*, *userId*, *twoLetterCountryCode*)

Request code for verification and registration process.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `userId` (string) - The user's phone number.
- `twoLetterCountryCode` (string) - The two letter the country code. To retrieve the two letter country code, you can use location service `location.getCountryInfo()`.

**validate**(*successCallback*, *errorCallback*, *userId*, *otpCode*, *twoLetterCountryCode*)

Validation of the signed up phone number send received code to the server.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `userId` (string) - The user's phone number.
- `twoLetterCountryCode` (string) - The two letter the country code. To retrieve the two letter country code, you can use location service `location.getCountryInfo()`.
- `otpCode` (string) - The OTP code received.

**deactivate**(*successCallback*, *errorCallback*)

Signing off the registered account(phone number) from a Kandy.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

### Access (namespace `access`)
**login**(*successCallback*, *errorCallback*, *username*, *password*)

Register/login the user on the server with credentials received from admin.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `username` (string) - The user's username.
- `password` (string) - The user's password

**logout**(*successCallback*, *errorCallback*)

This method unregisters user from the Kandy server.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**getSession**(*successCallback*, *errorCallback*)

Get the current session.
- `sucessCallback` (function) - Called when the request was successed. Parameter is an object with the properties: `userId`, `user`, `domain` and `deviceId`.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

### Call (namespace `call`)
**createVoipCall**(*successCallback*, *errorCallback*, *user*, *startWithVideo*)

Create a voip call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `user` (string) - The callee username.
- `startWithVideo` (boolean) - Create a call with video enabled.

**createPSTNCall**(*successCallback*, *errorCallback*, *phoneNumber*)

Create a PSTN call
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `phonNumber` (string) - The callee number.

**hangup**(*successCallback*, *errorCallback*)

Hangup current call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**mute**(*successCallback*, *errorCallback*)

Mute current call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**unmute**(*successCallback*, *errorCallback*)

Unmute current call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**hold**(*successCallback*, *errorCallback*)

Hold currnet call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**unhold**(*successCallback*, *errorCallback*)

Unhold current call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**enableVideo**(*successCallback*, *errorCallback*)

Enable sharing video for current call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**disableVideo**(*successCallback*, *errorCallback*)

Disable sharing video for current call.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

### Chat (namespace `chat`)
**send**(*successCallback*, *errorCallback*, *recipient*, *message*)

Send the message to recipient.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `recipient` (string) - The recipient to receive the message.
- `message` (string) - The message to send.

**markAsReceived**(*successCallback*, *errorCallback*, *UUID*)

Send ack to sever for UUID of received/handled message(s).
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `UUID` (string/string array) - The uuid(s) of the message(s) to mark.

**pullEvents**(*successCallback*, *errorCallback*)

Pull pending events from Kandy service.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

### Presence (namespace `presence`)
**startWatch**(*successCallback*, *errorCallback*, *userList*)

Register listener for presence's callbacks/notifications
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).
- `userList` (string array) - The list users needed to watched.

### Location (namespace `location`)
**getCountryInfo**(*successCallback*, *errorCallback*)

Get the country info.
- `sucessCallback` (function) - Called when the request was successed. The parameters is an object with the properties: `code`, `nameLong` and `nameShort`.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

### Push (namespace `push`)
**enable**(*successCallback*, *errorCallback*)

Enable the push service.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

**disable**(*successCallback*, *errorCallback*)

Disable the push service.
- `sucessCallback` (function) - Called when the request was successed. The function has no parameter.
- `errorCallback` (function) - Called when the request was failed. Parameters: `errorMessage` (string).

### Address book (namespace `addressBook`)
**getDeviceContacts**(*successCallback*, *errorCallback*, *filters*)

## Troubleshooting

## License
