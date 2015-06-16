
"use strict";

var exec = cordova.require('cordova/exec');

/**
 * Kandy PhoneGap Plugin interface.
 * See [README](https://github.com/Kandy-IO/kandy-phonegap/blob/master/doc/index.md) for more details.
 *
 * @author kodeplusdev
 * @version 1.2.0
 */
var Kandy = {

    //***** CONSTANT *****//

    ELEMENT_TAG: "kandy",

    Widget: {
        PROVISIONING: "provisioning",
        ACCESS: "access",
        CALL: "call",
        CHAT: "chat",
        GROUP: "group"
    },

    DeviceContactsFilter: {
        ALL: "ALL",
        IS_FAVORITE: "IS_FAVORITE",
        HAS_PHONE_NUMBER: "HAS_PHONE_NUMBER",
        HAS_EMAIL_ADDRESS: "HAS_EMAIL_ADDRESS"
    },

    DomainContactFilter: {
        ALL: "ALL",
        FIRST_AND_LAST_NAME: "FIRST_AND_LAST_NAME",
        USER_ID: "USER_ID",
        PHONE: "PHONE"
    },

    ThumbnailSize: {
        LARGE: "LARGE",
        MEDIUM: "MEDIUM",
        SMALL: "SMALL"
    },

    ConnectionState: {
        UNKNOWN: "UNKNOWN",
        DISCONNECTED: "DISCONNECTED",
        CONNECTED: "CONNECTED",
        DISCONNECTING: "DISCONNECTING",
        CONNECTING: "CONNECTING",
        FAILED: "FAILED"
    },

    CallState: {
        INITIAL: "INITIAL",
        RINGING: "RINGING",
        DIALING: "DIALING",
        TALKING: "TALKING",
        TERMINATED: "TERMINATED",
        ON_DOUBLE_HOLD: "ON_DOUBLE_HOLD",
        REMOTELY_HELD: "REMOTELY_HELD",
        ON_HOLD: "ON_HOLD"
    },

    ConnectionType: {
        NONE: "NONE",
        MOBILE: "MOBILE",
        WIFI: "WIFI",
        ALL: "ALL"
    },

    RecordType: {
        CONTACT: "CONTACT",
        GROUP: "GROUP"
    },

    CameraInfo: {
        FACING_FRONT: "FACING_FRONT",
        FACING_BACK: "FACING_BACK",
        UNKNOWN: "UNKNOWN"
    },

    PickerResult: {
        CONTACT_PICKER_RESULT: 1001,
        IMAGE_PICKER_RESULT: 1002,
        VIDEO_PICKER_RESULT: 1003,
        AUDIO_PICKER_RESULT: 1004,
        FILE_PICKER_RESULT: 1005
    },

    //*** LISTENERS ***//

    // Access listeners
    onConnectionStateChanged: function (args) {
    },
    onSocketConnected: function () {
    },
    onSocketConnecting: function () {
    },
    onSocketDisconnected: function () {
    },
    onSocketFailedWithError: function (args) {
    },
    onInvalidUser: function (args) {
    },
    onSessionExpired: function (args) {
    },
    onSDKNotSupported: function (args) {
    },

    // Call listeners
    onIncomingCall: function (args) {
    },
    onMissedCall: function (args) {
    },
    onCallStateChanged: function (args) {
    },
    onVideoStateChanged: function (args) {
    },
    onAudioStateChanged: function (args) {
    },
    onGSMCallIncoming: function (args) {
    },
    onGSMCallConnected: function (args) {
    },
    onGSMCallDisconnected: function (args) {
    },

    // Chat listeners
    onChatReceived: function (args) {
    },
    onChatDelivered: function (args) {
    },
    onChatMediaAutoDownloadProgress: function (args) {
    },
    onChatMediaAutoDownloadSucceded: function (args) {
    },
    onChatMediaAutoDownloadFailed: function (args) {
    },

    // Group listeners
    onGroupDestroyed: function (args) {
    },
    onGroupUpdated: function (args) {
    },
    onParticipantJoined: function (args) {
    },
    onParticipantKicked: function (args) {
    },
    onParticipantLeft: function (args) {
    },

    // Addressbook listeners
    onDeviceAddressBookChanged: function () {
    },

    //*** LOGIC ***//

    _messageContainers: [],

    videoView: {
        top: 400,
        left: 86,
        width: 596,
        height: 596
    },

    /**
     * Initialize Kandy SDK.
     *
     * @param config The Kandy plugin configurations.
     */
    initialize: function (config) {
        this._setupKandyPluginWithConfig(config);
        this._registerNotificationListeners();
        this._renderKandyWidgets();
    },

    /**
     * Setup kandy plugin
     *
     * @param config The configurations
     * @private
     */
    _setupKandyPluginWithConfig: function (config) {
        if (config == undefined) return;

        if (config.apiKey != undefined && config.apiSecret != undefined)
            this.setKey(config.apiKey, config.apiSecret);

        if (config.hostUrl != undefined)
            this.setHostUrl(config.hostUrl);

        if (config.videoView != undefined)
            Kandy.videoView = config.videoView;


        var callback = function (args) {
            console.log(args);
        };

        exec(callback, callback, "KandyPlugin", "configurations", [config]);
    },

    /**
     * Default chat service notification callback.
     *
     * @param args The callback parameter.
     * @private
     */
    _chatServiceNotificationPluginCallback: function (args) {
        switch (args.action) {
            case "onChatReceived":
                Kandy._addMessagetoContainers(args.data);
                break;
            case "onChatDelivered":
                // TODO: not complete yet
                Kandy._makeToast("Message delivered");
                break;
            case "onChatMediaAutoDownloadProgress":
                if (args.data.process == 0) {
                    Kandy._makeToast("Downloading a attachment...");
                }
                break;
            case "onChatMediaAutoDownloadSucceded":
                Kandy._addMessagetoContainers(args.data);
                Kandy._makeToast(args.data.message.message.content_name + " saved at " + args.data.uri);
                break;
            default :
        }
    },

    /**
     * Default call service notification callback.
     *
     * @param args The callback parameter.
     * @private
     */
    _callServiceNotificationPluginCallback: function (args) {
        switch (args.action) {
            case "onIncomingCall":
                Kandy._incomingCallWidget(args.data.callee.uri);
                break;
            case "onCallStateChanged":
            {
                var state = args.data.state;
                if (state == Kandy.CallState.TERMINATED) {
                    var modal = document.getElementById(args.data.callee.uri + '-talking-modal');
                    modal.remove();
                }
                break;
            }
            default:
                break;
        }
    },

    /**
     * Execute callback function by name `args["action"]`
     *
     * @param args The args of the callback function.
     * @private
     */
    _notificationCallback: function (args) {
        return Kandy._executeFunctionByName(args.action, Kandy, args.data);
    },

    /**
     * Register notification listeners.
     *
     * @private
     */
    _registerNotificationListeners: function () {
        exec(this._notificationCallback, null, "KandyPlugin", "connectServiceNotificationCallback", []);
        exec(this._notificationCallback, null, "KandyPlugin", "callServiceNotificationCallback", []);
        exec(this._notificationCallback, null, "KandyPlugin", "addressBookServiceNotificationCallback", []);
        exec(this._notificationCallback, null, "KandyPlugin", "chatServiceNotificationCallback", []);
        exec(this._notificationCallback, null, "KandyPlugin", "groupServiceNotificationCallback", []);

        exec(this._chatServiceNotificationPluginCallback, null, "KandyPlugin", "chatServiceNotificationPluginCallback", []);
        exec(this._callServiceNotificationPluginCallback, null, "KandyPlugin", "callServiceNotificationPluginCallback", []);
    },

    /**
     * Load plugin stylesheets and javascripts.
     * @private
     */
    _loadPluginResources: function () {
        this._loadStylesheets(["kandy.min.css"]);
        this._loadJavascript([]);
    },

    /**
     * Get the file path of the plugin.
     *
     * @param filename The file name.
     * @param type The type of the file.
     * @returns {string}
     * @private
     */
    _link: function (filename) {
        return "plugins/com.kandy.phonegap/www/" + filename;
    },

    /**
     * Load plugin stylesheets.
     *
     * @param files The file list.
     * @private
     */
    _loadStylesheets: function (files) {
        for (var i = 0; i < files.length; ++i) {
            var link = document.createElement("link");
            link.setAttribute("rel", "stylesheet");
            link.setAttribute("type", "text/css");
            link.setAttribute("href", this._link(files[i]));
            if (typeof link != "undefined")
                document.getElementsByTagName("head")[0].appendChild(link);
        }
    },

    /**
     * Load plugin javascript.
     *
     * @param files The file list.
     * @private
     */
    _loadJavascript: function (files) {
        for (var i = 0; i < files.length; ++i) {
            var link = document.createElement("script");
            link.setAttribute("type", "text/javascript");
            link.setIdAttribute("src", this._link(files[i]));
            if (typeof link != "undefined")
                document.getElementsByTagName("head")[0].appendChild(link);
        }
    },

    /**
     * Render Kandy widgets.
     *
     * @private
     */
    _renderKandyWidgets: function () {

        var widgets = document.getElementsByTagName(Kandy.ELEMENT_TAG);

        if (widgets.length > 0)
            this._loadPluginResources();

        for (var i = 0; i < widgets.length; ++i) {
            var name = widgets[i].getAttribute("widget");

            if (name != undefined)
                name = name.toLowerCase();

            switch (name) {
                case this.Widget.PROVISIONING:
                    this._renderKandyProvisioningWidget(widgets[i]);
                    break;
                case this.Widget.ACCESS:
                    this._renderKandyAccessWidget(widgets[i]);
                    break;
                case this.Widget.CALL:
                    this._renderKandyCallWidget(widgets[i]);
                    break;
                case this.Widget.CHAT:
                    this._renderKandyChatWidget(widgets[i]);
                    break;
                case this.Widget.GROUP:
                    this._renderKandyGroupWidget(widgets[i]);
                    break;
                default:
                    break;
            }
        }
    },

    /**
     * Default success action callback.
     *
     * @param success The success parameter.
     * @private
     */
    _defaultSuccessAction: function (success) {
        console.log(success);
    },

    /**
     * Default error action callback.
     *
     * @param error The error parameter.
     * @private
     */
    _defaultErrorAction: function (error) {
        console.log(error), alert(error); // default action
    },

    /**
     * Create a Toast message.
     * @param message The message to show.
     */
    _makeToast: function (message) {
        exec(null, null, "KandyPlugin", "makeToast", [message]);
    },

    /**
     * Find or Validate an Email Address
     *
     * @param email The email address
     * @returns {boolean}
     * @private
     */
    _validateEmail: function (email) {
        var re = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
        return re.test(email);
    },

    /**
     * Execute a function by name in a context scope.
     *
     * @param functionName The function name to execute.
     * @param context The context scope.
     * @private
     */
    _executeFunctionByName: function (functionName, context /*, args */) {
        var args = [].slice.call(arguments).splice(2);
        var namespaces = functionName.split(".");
        var fn = namespaces.pop();
        for (var i = 0; i < namespaces.length; i++) {
            context = context[namespaces[i]];
        }
        return context[fn].apply(this, args);
    },

    /**
     * Check and execute a function by name.
     *
     * @param fn The function name.
     * @param args The args of the function.
     * @param callback The callback function if fn do not exist.
     * @private
     */
    _checkAndCallFunction: function (fn, args, callback) {
        if (fn != undefined && fn != "" && fn != '') {
            return this._executeFunctionByName(fn, window, args);
        } else if (callback != undefined) {
            return callback(args);
        }
    },

    /**
     * Get function from element and trigger it.
     *
     * @param element The element widget.
     * @param action The action name.
     * @param val The value of the parameter which is passed to function.
     * @param callback The default action would be used if the function was not found.
     * @private
     */
    _callFunctionByAction: function (element, action, val, callback) {
        var fn = element.getAttribute(action);

        this._checkAndCallFunction(fn, val, callback);
    },

    /**
     * Call success action from element.
     *
     * @param element The element widget.
     * @param val The value of the parameter which is passed to function.
     * @param callback The default action would be used if the function was not found.
     * @private
     */
    _callSuccessFunction: function (element, fn, val, callback) {
        this._callFunctionByAction(element, fn + "-success", val, callback);
    },

    /**
     * Call error function from element.
     *
     * @param element The element widget.
     * @param val The value of the parameter which is passed to function.
     * @param callback The default action would be used if the function was not found.
     * @private
     */
    _callErrorFunction: function (element, fn, val, callback) {
        this._callFunctionByAction(element, fn + "-error", val, callback);
    },

    /**
     * Get next id of the element.
     *
     * @param element The element of the widget.
     * @private
     */
    _getIdOrGenerateNextId: function (element) {
        var id = element.getAttribute("id");
        if (id == undefined || id == "") {
            var idx = -1;
            var prefix = "kandy";
            var name = element.getAttribute("widget");

            do {
                ++idx;
                id = prefix + "-" + name + "-" + idx;
            } while (document.getElementById(id) != undefined);
        }

        element.setAttribute("id", id);

        return id;
    },

    /**
     * Render provisioning widget.
     *
     * @param element The element of the provisioning widget.
     * @private
     */
    _renderKandyProvisioningWidget: function (element) {
        if (element == undefined) return;

        var id = this._getIdOrGenerateNextId(element);

        var code = element.getAttribute("country-code");

        element.innerHTML += '<div class="container center">'
            + '<div class="row">'
            + '<input type="tel" id="' + id + '-phone-number" placeholder="Enter number phone..."/>'
            + '<input type="text" id="' + id + '-region-code" maxlength="2" placeholder="Country code" value="' + code + '"/>'
            + '<button class="btn" id="' + id + '-btn-request">Request</button>'
            + '</div>'
            + '<div class="row">'
            + '<input type="text" id="' + id + '-otp-code" placeholder="Enter OTP code..."/>'
            + '<button class="btn blue" id="' + id + '-btn-validate">Validate</button>'
            + '</div>'
            + '<div class="row">'
            + '<button class="btn red" id="' + id + '-btn-deactivate">Deactivate</button>'
            + '</div>'
            + '</div>';

        document.getElementById(id + '-btn-request').onclick = function (event) {
            var number = document.getElementById(id + '-phone-number').value,
                code = document.getElementById(id + '-region-code').value;

            Kandy.provisioning.requestCode(function (s) {
                Kandy._callSuccessFunction(element, "request", s, function (s) {
                    alert("Your request has been sent successfully.");
                });
            }, function (e) {
                Kandy._callErrorFunction(element, "request", e, Kandy._defaultErrorAction);
            }, number, code);
        }

        document.getElementById(id + '-btn-validate').onclick = function (event) {
            var number = document.getElementById(id + '-phone-number').value,
                code = document.getElementById(id + '-region-code').value,
                otp = document.getElementById(id + '-otp-code').value;

            Kandy.provisioning.validate(function (s) {
                Kandy._callSuccessFunction(element, "validate", s, function (account) {
                    alert("ACCOUNT INFORMATION\nId: " + account.id + "\nDomain: " + account.domain + "\nUsername: " + account.username + "\nPassword: " + account.password);
                });
            }, function (e) {
                Kandy._callErrorFunction(element, "validate", e, Kandy._defaultErrorAction);
            }, number, otp, code);
        }

        document.getElementById(id + '-btn-deactivate').onclick = function (event) {
            Kandy.provisioning.deactivate(function (s) {
                Kandy._callSuccessFunction(element, "deactivate", s, function (s) {
                    alert("Your account has been deactivated.");
                });
            }, function (e) {
                Kandy._callErrorFunction(element, "deactivate", e, Kandy._defaultErrorAction);
            })
        }
    },

    /**
     * Render access widget.
     *
     * @param element The element of the access widget.
     * @private
     */
    _renderKandyAccessWidget: function (element) {
        if (element == undefined) return;

        var id = this._getIdOrGenerateNextId(element);

        var loginForm = '<div class="container center">'
            + '<input type="text" id="' + id + '-username" value="jerome@google.gmail.com" placeholder="Username"/>'
            + '<input type="password" id="' + id + '-password" value="test@123" placeholder="Password"/>'
            + '<button class="btn" id="' + id + '-btn-login">Login</button>'
            + '</div>';

        var logoutForm = function (user) {
            return '<div class="container center">'
                + '<h5>' + user + '</h5>'
                + '<button class="btn red" id="' + id + '-btn-logout">Logout</button>'
                + '</div>';
        }

        var addLogoutAction = function () {
            document.getElementById(id + '-btn-logout').onclick = function (event) {
                Kandy.access.logout(function (s) {
                    element.innerHTML = loginForm;
                    addLoginAction();
                    Kandy._callSuccessFunction(element, "logout", s, Kandy._defaultSuccessAction);
                }, function (e) {
                    Kandy._callErrorFunction(element, "logout", e, Kandy._defaultErrorAction);
                })
            }
        }

        var addLoginAction = function () {
            document.getElementById(id + '-btn-login').onclick = function (event) {
                var username = document.getElementById(id + '-username').value,
                    password = document.getElementById(id + '-password').value;

                Kandy.access.login(function (s) {
                        element.innerHTML = logoutForm(username);
                        addLogoutAction();
                        Kandy._callSuccessFunction(element, "login", s, Kandy._defaultSuccessAction);
                    }, function (e) {
                        Kandy._callErrorFunction(element, "login", e, Kandy._defaultErrorAction);
                    }, username, password
                )
            }
        }

        Kandy.access.getConnectionState(function (state) {
            if (state != Kandy.ConnectionState.CONNECTED) {
                element.innerHTML = loginForm;
                addLoginAction();
            } else {
                Kandy.getSession(function (data) {
                    element.innerHTML = logoutForm(data.user.id);
                    addLogoutAction();
                })
            }
        })
    },

    _incomingCallWidget: function (calleeId) {
        var modal = document.createElement(Kandy.ELEMENT_TAG);
        modal.id = calleeId + '-incoming-modal';
        modal.innerHTML = '<div class="modal">'
            + '<div class="modal-content center">'
            + '<h5>' + calleeId + ' calling...</h5>'
            + '<div class="row">'
            + '<button class="btn" id="' + calleeId + '-btn-call-accept">Accept</button>'
            + '<button class="btn red" id="' + calleeId + '-btn-call-reject">Reject</button>'
            + '<button class="btn orange" id="' + calleeId + '-btn-call-ignore">Ignore</button>'
            + '</div>'
            + '</div>'
            + '</div>'
            + '<div id="' + calleeId + '-overlay" class="modal-overlay"></div>'

        var body = document.getElementsByTagName("body")[0];
        body.appendChild(modal);

        document.getElementById(calleeId + '-btn-call-accept').onclick = function () {
            Kandy.call.accept(function () {
                Kandy._talkingCallWidget(calleeId);
            }, function (e) {
                Kandy._defaultErrorAction(e);
            }, calleeId, true);

            modal.remove();
        }

        document.getElementById(calleeId + '-btn-call-reject').onclick = function () {
            Kandy.call.reject(null, function (e) {
                Kandy._defaultErrorAction(e);
            }, calleeId);

            modal.remove();
        }

        document.getElementById(calleeId + '-btn-call-ignore').onclick = function () {
            Kandy.call.ignore(null, function (e) {
                Kandy._defaultErrorAction(e);
            }, calleeId);

            modal.remove();
        }
    },

    _talkingCallWidget: function (calleeId, video) {

        if (video == undefined || video == true)
            video = 'checked';
        else video = '';

        var modal = document.createElement(Kandy.ELEMENT_TAG);
        modal.id = calleeId + '-talking-modal';
        modal.innerHTML = '<div class="modal">'
            + '<div class="modal-content center">'
            + '<div class="row">'
            + '<h6><b>' + calleeId + '</b></h6>'
            + '</div>'
            + '<div class="row">'
            + '<div class="switch">'
            + '<label>Hold'
            + '<input id="' + calleeId + '-btn-call-hold" type="checkbox"/>'
            + '<span class="lever"></span>'
            + '</label>'
            + '<label>Mute'
            + '<input id="' + calleeId + '-btn-call-mute" type="checkbox"/>'
            + '<span class="lever"></span>'
            + '</label>'
            + '<label>Video'
            + '<input id="' + calleeId + '-btn-call-video" type="checkbox" ' + video + '/>'
            + '<span class="lever"></span>'
            + '</label>'
            + '</div>'
            + '</div>'
            + '<div class="row">'
            + '<div class="switch">'
            + '<label>Camera'
            + '<input id="' + calleeId + '-btn-call-camera" type="checkbox" checked/>'
            + '<span class="lever"></span>'
            + '</label>'
            + '<label>Speaker'
            + '<input id="' + calleeId + '-btn-call-speaker" type="checkbox"/>'
            + '<span class="lever"></span>'
            + '</label>'
            + '</div>'
            + '</div>'
            + '<div class="row">'
            + '<button class="btn red btn-large btn-block" id="' + calleeId + '-btn-call-hangup">Hangup</button>'
            + '</div>'
            + '<div class="row">'
            + '<img id="' + calleeId + '-video-view-placeholder" src="" width="298" height="298" />'
            + '</div>'
            + '</div>'
            + '</div>'
            + '<div id="' + calleeId + '-overlay" class="modal-overlay"></div>'

        var body = document.getElementsByTagName("body")[0];
        body.appendChild(modal);

        if (Kandy.videoView != undefined) {
            Kandy.call.showRemoteVideo(null, function (e) {
                Kandy._defaultErrorAction(e);
            }, calleeId, Kandy.videoView.left, Kandy.videoView.top, Kandy.videoView.width, Kandy.videoView.height);

            var delta = {
                width: Kandy.videoView.width * 0.3,
                height: Kandy.videoView.height * 0.3
            };

            Kandy.call.showLocalVideo(null, function (e) {
                Kandy._defaultErrorAction(e);
            }, calleeId, Kandy.videoView.left + Kandy.videoView.width - delta.width, Kandy.videoView.top + Kandy.videoView.height - delta.height, delta.width, delta.height);
        }

        document.getElementById(calleeId + '-btn-call-camera').onchange = function () {
            var checked = document.getElementById(calleeId + '-btn-call-camera').checked;
            if (checked) {
                Kandy.call.switchFrontCamera(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-camera').checked = false;
                }, calleeId);
            } else {
                Kandy.call.switchBackCamera(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-camera').checked = true;
                }, calleeId);
            }
        };

        document.getElementById(calleeId + '-btn-call-speaker').onchange = function () {
            var checked = document.getElementById(calleeId + '-btn-call-speaker').checked;
            if (checked) {
                Kandy.call.switchSpeakerOn();
            } else {
                Kandy.call.switchSpeakerOff();
            }
        };

        document.getElementById(calleeId + '-btn-call-hold').onchange = function () {
            var checked = document.getElementById(calleeId + '-btn-call-hold').checked;
            if (checked) {
                Kandy.call.hold(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-hold').checked = false;
                }, calleeId);
            } else {
                Kandy.call.unhold(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-hold').checked = true;
                }, calleeId);
            }
        };

        document.getElementById(calleeId + '-btn-call-mute').onchange = function () {
            var checked = document.getElementById(calleeId + '-btn-call-mute').checked;
            if (checked) {
                Kandy.call.mute(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-mute').checked = false;
                }, calleeId);
            } else {
                Kandy.call.unmute(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-mute').checked = true;
                }, calleeId);
            }
        };

        document.getElementById(calleeId + '-btn-call-video').onchange = function () {
            var checked = document.getElementById(calleeId + '-btn-call-video').checked;
            if (checked) {
                Kandy.call.enableVideo(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-video').checked = false;
                }, calleeId);
            } else {
                Kandy.call.disableVideo(null, function (e) {
                    Kandy._defaultErrorAction(e);
                    document.getElementById(calleeId + '-btn-call-video').checked = true;
                }, calleeId);
            }
        };

        document.getElementById(calleeId + '-btn-call-hangup').onclick = function () {
            Kandy.call.hangup(null, function (e) {
                Kandy._defaultErrorAction(e);
            }, calleeId);

            modal.remove();
        }
    },

    /**
     * Render call widget.
     *
     * @param element The element of the call widget.
     * @private
     */
    _renderKandyCallWidget: function (element) {
        if (element == undefined) return;

        var id = this._getIdOrGenerateNextId(element);

        var type = element.getAttribute("type");
        var callee = element.getAttribute("call-to");
        var label = element.getAttribute("label");
        var startWithVideo = element.getAttribute("start-with-video");

        if (label == undefined || label == "") label = "Call";

        if (type == undefined) type = 'VOIP';
        else type = type.toUpperCase();


        var callPanel = '<div id="' + id + '-dial-panel">';

        if (type == 'PSTN') {
            if (callee != undefined && callee != "" && !this._validateEmail(callee)) {
                callPanel += '<input type="hidden" id="' + id +
                    '-callee" value="' + callee + '"/>';
            } else {
                callPanel += '<input type="text" id="' + id + '-callee" placeholder="Enter number phone..."/>';
            }

            callPanel += '<button id="' + id + '-btn-call" class="btn">' + label + '</button>'
                + '</div>';
        } else {

            if (callee != undefined && callee != "" && this._validateEmail(callee)) {
                callPanel += '<input type="hidden" id="' + id + '-callee" value="' + callee + '"/>';
            } else {
                callPanel += '<input type="text" id="' + id + '-callee" placeholder="userID@domain.com"/>';
            }

            if (startWithVideo != undefined && startWithVideo != "") {
                var checked = (startWithVideo == 1 || startWithVideo == "true") ? "checked" : "";
                callPanel += '<input type="hidden" id="' + id + '-start-with-video"' + checked + '/>';
            } else
                callPanel += '<p><input type="checkbox" id="' + id + '-start-with-video"/><label for="' + id + '-start-with-video">Start with video</label></p>';

            callPanel += '<button id="' + id + '-btn-call" class="btn">' + label + '</button>'
                + '</div>';
        }

        element.innerHTML = '<div class="container center">' + callPanel + '</div>';

        if (type == 'PSTN') {
            document.getElementById(id + '-btn-call').onclick = function (event) {
                var username = document.getElementById(id + '-callee').value;

                Kandy.call.createPSTNCall(function (s) {
                        Kandy._talkingCallWidget(s.callee.uri, false);
                        Kandy._callSuccessFunction(element, "call", s, Kandy._defaultSuccessAction);
                    }, function (e) {
                        Kandy._callErrorFunction(element, "call", e, Kandy._defaultErrorAction);
                    }, username
                );
            }
        } else {
            document.getElementById(id + '-btn-call').onclick = function (event) {
                var username = document.getElementById(id + '-callee').value,
                    startWithVideo = document.getElementById(id + '-start-with-video').checked == true ? 1 : 0;

                Kandy.call.createVoipCall(function (s) {
                        Kandy._talkingCallWidget(s.callee.uri, startWithVideo)
                        Kandy._callSuccessFunction(element, "call", s, Kandy._defaultSuccessAction);
                    }, function (e) {
                        Kandy._callErrorFunction(element, "call", e, Kandy._defaultErrorAction);
                    }, username, startWithVideo
                );
            }
        }
    },

    /**
     * Render message item.
     *
     * @param data The message to render.
     * @returns {string} The message item.
     * @private
     */
    _renderMessageItem: function (data) {
        var msg = data.message;

        if ($("#" + msg.UUID).length) return "";

        var extras = "";
        switch (msg.contentType) {
            case "text":
                break;
            case "location":
                extras = "lat: " + msg.message.location_latitude
                    + " lng: " + msg.message.location_longitude
                    + " acc: " + msg.message.media_accuracy
                    + " zoom: " + msg.message.media_map_zoom;
                extras = '<div id="' + msg.UUID + '-extras">' + extras + '</div>'
                break;
            default: // audio, video, contact, file
                if (data.uri == undefined) return "";
                extras = "<div id=\"" + msg.UUID + "-extras\" onclick=\"js:Kandy.chat.openAttachment(null, null,\'" + data.uri + "\',\'" + msg.message.mimeType + "\')\">" + msg.message.content_name + "</div>";
                break;
        }

        var item = '<li class="collection-item" onClick="js:Kandy._markMessageAsReceived(\'' + msg.UUID + '\')">'
            + '<h5><b>' + msg.sender + '</b></h5>'
            + '<div class="row"><small>' + new Date(msg.timestamp).toUTCString() + '</small></div>'
            + '<div class="row" id="' + msg.UUID + '">'
            + '<div id="' + msg.UUID + '-text"><strong>' + msg.message.text + '</strong></div>'
            + extras
            + '</div>'
            + '</li>';

        return item;
    },

    /**
     * Add the message to the message containers.
     *
     * @param data The message to add.
     * @private
     */
    _addMessagetoContainers: function (data) {

        var item = data.message == undefined ? data.item : Kandy._renderMessageItem(data);
        var type = data.message == undefined ? data.type : data.message.messageType;

        if (item == "") return;

        for (var i = 0; i < this._messageContainers.length; ++i) {
            var container = document.getElementById(this._messageContainers[i]);
            if (container != undefined) {
                if (type == container.getAttribute("type"))
                    container.innerHTML = item + container.innerHTML;
            }
        }
    },

    /**
     * Render chat widget.
     *
     * @param element The element of the chat widget.
     * @private
     */
    _renderKandyChatWidget: function (element) {
        if (element == undefined) return;

        var id = this._getIdOrGenerateNextId(element);

        var type = element.getAttribute("type");
        var recipientValue = element.getAttribute("send-to");

        if (type == undefined) type = "CHAT";
        else type = type.toUpperCase();

        this._messageContainers.push(id + '-messages');

        if (type == "SMS") {

            if (recipientValue != undefined && recipientValue != "" && !this._validateEmail(recipientValue)) {
                recipientValue = 'value="' + recipientValue + '" disabled';
            } else {
                recipientValue = "";
            }

            element.innerHTML = '<div class="container">'
                + '<div class="center">'
                + '<input type="text" placeholder="Enter number phone..." id="' + id + '-recipient" ' + recipientValue + '/>'
                + '<div class="row">'
                + '<div class="col s10">'
                + '<input type="text" placeholder="Message..." id="' + id + '-message"/>'
                + '</div>'
                + '<div class="col s2">'
                + '<button class="btn btn-small" id="' + id + '-btn-send">Send</button>'
                + '</div>'
                + '</div>'
                + '<div class="row">'
                + '<button class="btn orange" id="' + id + '-btn-pull">Pull</button>'
                + '</div>'
                + '</div>'
                + '<h5><b>Messages</b></h5>'
                + '<ul id="' + id + '-messages" type="' + type + '" class="collection">'
                + '</ul>'
                + '</div>';

            document.getElementById(id + '-btn-send').onclick = function (event) {
                var recipient = document.getElementById(id + '-recipient').value,
                    message = document.getElementById(id + '-message').value;

                Kandy.chat.sendSMS(function (s) {
                    Kandy._callSuccessFunction(element, "send", s, function () {
                        var item = '<li class="collection-item"><h5><b>You: </b></h5><p>' + message + '</p><p class="right"><small>' + new Date().toUTCString() + '</small></p></li>';
                        Kandy._addMessagetoContainers({item: item, type: type});
                        Kandy._makeToast("Message has been sent");
                    });
                }, function (e) {
                    Kandy._callErrorFunction(element, "send", e, Kandy._defaultErrorAction);
                }, recipient, message)
            }
        } else {
            if (recipientValue != undefined && recipientValue != "" && this._validateEmail(recipientValue)) {
                recipientValue = 'value="' + recipientValue + '" disabled';
            } else {
                recipientValue = "";
            }

            element.innerHTML = '<div class="container">'
                + '<div class="center">'
                + '<input type="text" placeholder="recipientID@domain" id="' + id + '-recipient" ' + recipientValue + '/>'
                + '<div class="row">'
                + '<div class="col s10">'
                + '<input type="text" placeholder="Message..." id="' + id + '-message"/>'
                + '</div>'
                + '<div class="col s2">'
                + '<button class="btn btn-small" id="' + id + '-btn-send">Send</button>'
                + '</div>'
                + '</div>'
                + '<div class="row">'
                + '<button class="btn" id="' + id + '-btn-attach">Attactment</button>'
                + '<button class="btn orange" id="' + id + '-btn-pull">Pull</button>'
                + '</div>'
                + '</div>'
                + '<h5><b>Messages</b></h5>'
                + '<ul id="' + id + '-messages" type="' + type + '" class="collection">'
                + '</ul>'
                + '</div>';

            document.getElementById(id + '-btn-send').onclick = function (event) {
                var recipient = document.getElementById(id + '-recipient').value,
                    message = document.getElementById(id + '-message').value;

                Kandy.chat.sendChat(function (s) {
                    Kandy._callSuccessFunction(element, "send", s, function () {
                        var item = '<li class="collection-item"><h5><b>You: </b></h5><p>' + message + '</p><p class="right"><small>' + new Date().toUTCString() + '</small></p></li>';
                        Kandy._addMessagetoContainers({item: item, type: type});
                        Kandy._makeToast("Message has been sent");
                    });
                }, function (e) {
                    Kandy._callErrorFunction(element, "send", e, Kandy._defaultErrorAction);
                }, recipient, message)

            }

            document.getElementById(id + '-btn-attach').onclick = function (event) {
                var recipient = document.getElementById(id + '-recipient').value,
                    caption = document.getElementById(id + '-message').value;

                Kandy.chat.sendAttachment(function (s) {
                    Kandy._callSuccessFunction(element, "attach", s, function () {
                        Kandy._makeToast("Attachment has been sent");
                    });
                }, function (e) {
                    Kandy._callErrorFunction(element, "attach", e, Kandy._defaultErrorAction);
                }, recipient, caption)
            }
        }

        document.getElementById(id + '-btn-pull').onclick = function (event) {
            Kandy.chat.pullEvents(function (s) {
                Kandy._callSuccessFunction(element, "pull", s, Kandy._defaultSuccessAction);
            }, function (e) {
                Kandy._callErrorFunction(element, "pull", e, Kandy._defaultErrorAction);
            });
        }
    },

    /**
     * Notify message read.
     *
     * @param uuid The UUID of the message.
     * @private
     */
    _markMessageAsReceived: function (uuid) {
        Kandy.chat.markAsReceived(function () {
            var e = document.getElementById(uuid + "-text");
            e.innerHTML = e.textContent;
        }, function (e) {
            Kandy._defaultErrorAction(e);
        }, uuid);
    },

    _renderKandyGroupWidget: function (element) {
        if (element == undefined) return;

        var id = this._getIdOrGenerateNextId(element);

        element.innerHTML = '<div class="container">'
            + '<div id="' + id + '-groups">'
            + '<div class="center">'
            + '<div class="row">'
            + '<button id="' + id + '-btn-refresh-groups" class="btn">Refresh</button>'
            + '<button id="' + id + '-btn-create-group" class="btn cyan">New</button>'
            + '</div>'
            + '</div>'
            + '<h5><b>Groups list</b></h5>'
            + '<ul id="' + id + '-groups-list" class="collection">'
            + '</ul>'
            + '</div>'
            + '</div>';

        document.getElementById(id + '-btn-refresh-groups').onclick = function () {
            Kandy._refreshGroups(id + '-groups-list');
        };

        document.getElementById(id + '-btn-create-group').onclick = function () {
            var name = prompt("Enter group name");
            if (name != null) {
                Kandy.group.createGroup(function () {
                    Kandy._refreshGroups(id + '-groups-list');
                    alert("Created successfully!");
                }, function (e) {
                    Kandy._defaultErrorAction(e);
                }, name);
            }
        };

        Kandy._refreshGroups(id + '-groups-list');
    },

    _refreshGroups: function (id) {
        Kandy.group.getMyGroups(function (groups) {

            var list = document.getElementById(id);
            list.innerHTML = "";

            for (var i = 0; i < groups.length; ++i) {
                var group = groups[i];

                var item = document.createElement('li');
                item.setAttribute('class', 'collection-item');

                item.innerHTML = '<select class="browser-default" id="' + id + '-group-' + group.id.uri + '" uri="' + group.id.uri + '">'
                    + '<option disabled selected>' + group.name + '</option>'
                    + '<option>Chat room</option>'
                    + '<option>View detail</option>'
                    + '<option value="' + group.isGroupMuted + '">' + (group.isGroupMuted ? 'Unmute' : 'Mute') + '</option>'
                    + '<option>Leave</option>'
                    + (group.selfParticipant.isAdmin ? '<option>Rename</option><option>Delete</option>' : '')
                    + '</select>';

                list.appendChild(item);

                var selector = document.getElementById(id + '-group-' + group.id.uri);
                selector.onchange = function (e) {
                    var selector = e.target;
                    var uri = selector.getAttribute('uri');
                    var idx = selector.selectedIndex;
                    selector.selectedIndex = 0;
                    switch (idx) {
                        case 0: // disabled
                            break;
                        case 1: // Chat room
                            // TODO
                            break;
                        case 2: // View detail
                            Kandy._detailGroupWidget(uri);
                            break;
                        case 3: // Mute/Unmute
                            var state = selector.options[idx].value;
                            if (state == 'true') {
                                Kandy.group.unmuteGroup(function () {
                                    selector.options[idx].value = 'false';
                                    selector.options[idx].text = 'Mute';
                                    Kandy._makeToast('Unmuted');
                                }, function (e) {
                                    Kandy._defaultErrorAction(e);
                                }, uri);
                            } else {
                                Kandy.group.muteGroup(function () {
                                    selector.options[idx].value = 'true';
                                    selector.options[idx].text = 'Unmute';
                                    Kandy._makeToast('Muted');
                                }, function (e) {
                                    Kandy._defaultErrorAction(e);
                                }, uri);
                            }
                            break;
                        case 4:
                        { // Leave
                            var ok = confirm("Are you sure?");
                            if (ok == true) {
                                Kandy.group.leaveGroup(function () {
                                    Kandy._refreshGroups(id + '-groups-list');
                                    alert("Leaved successfully!");
                                }, function (e) {
                                    Kandy._defaultErrorAction(e);
                                }, uri);
                            }
                            break;
                        }
                        case 5: // Rename
                            var name = prompt("Enter new group name");
                            if (name != null) {
                                Kandy.group.updateGroupName(function (group) {
                                    selector.options[0].text = group.name;
                                    alert("Renamed successfully!");
                                }, function (e) {
                                    Kandy._defaultErrorAction(e);
                                }, uri, name);
                            }
                            break;
                        case 6:
                        {// Delete
                            var ok = confirm("Are you sure?");
                            if (ok == true) {
                                Kandy.group.destroyGroup(function () {
                                    Kandy._refreshGroups(id + '-groups-list');
                                    alert("Deleted successfully!");
                                }, function (e) {
                                    Kandy._defaultErrorAction(e);
                                }, uri);
                            }
                            break;
                        }
                        default:
                            break;
                    }
                }
            }
        }, function (e) {
            Kandy._defaultErrorAction(e);
        });
    },

    _detailGroupWidget: function (groupId) {
        Kandy.group.getGroupById(function (group) {
            var modal = document.createElement('kandy');
            modal.id = groupId + '-modal';
            modal.innerHTML = '<div class = "modal">'
                + '<div class="modal-content">'
                + '<div class="center">'
                + '<h5><b>' + group.name + '</b></h5>'
                + '<img id="' + group.id.uri + '-group-image" src="" alt="group-thumbnail" width="100%" height="100%">'
                + '<div class="row">'
                + '<div class="btn-group">'
                + '<button id="' + group.id.uri + '-btn-chat" class="btn btn-large">Chat room</button>'
                + '<div class="btn-append">'
                + '<select class="browser-default btn btn-large white-text" id="' + group.id.uri + '-options">'
                + '<option value="" disabled selected>Choose your action</option>'
                + '<option value="' + group.isGroupMuted + '">' + (group.isGroupMuted ? 'Unmute' : 'Mute') + '</option>'
                + '<option>Change image</option>'
                + '<option>Remove image</option>'
                + '<option>Add participant</option>'
                + '</select>'
                + '</div>'
                + '</div>'
                + '</div>'
                + '</div>'
                + '<div class="row">'
                + '<div class="col s8">'
                + '<h5><b>Participants:</b></h5>'
                + '</div>'
                + '<div class="col s4">'
                + '<button id="' + group.id.uri + '-btn-refresh-participants" class="btn btn-small">Refresh</button>'
                + '</div>'
                + '</div>'
                + '<ul id="' + groupId + '-participants-list" class="collection">'
                + '</ul>'
                + '</div>'
                + '</div>'
                + '<div class="modal-overlay"></div>';

            var body = document.getElementsByTagName('body')[0];
            body.appendChild(modal);

            document.getElementById(group.id.uri + '-btn-refresh-participants').onclick = function () {
                Kandy.group.getGroupById(function (updatedGroup) {
                    Kandy._refreshPariticipants(updatedGroup);
                }, function (e) {
                    Kandy._defaultErrorAction(e);
                }, group.id.uri);
            };

            Kandy._refreshPariticipants(group);

            Kandy.group.downloadGroupImageThumbnail(function (uri) {
                document.getElementById(group.id.uri + '-group-image').setAttribute('src', uri);
            }, function (e) {
                Kandy._defaultErrorAction(e);
            }, group.id.uri, Kandy.ThumbnailSize.LARGE);

            modal.onclick = function (e) {
                if (e.target == modal.getElementsByClassName('modal-overlay')[0])
                    modal.remove();
            }

            var selector = document.getElementById(groupId + '-options');
            selector.onchange = function () {
                var idx = selector.selectedIndex;
                selector.selectedIndex = 0;

                switch (idx) {
                    case 0: // disabled
                        break;
                    case 1: // Mute/Unmute
                        var state = selector.options[idx].value;
                        if (state == 'true') {
                            Kandy.group.unmuteGroup(function () {
                                selector.options[idx].value = 'false';
                                selector.options[idx].text = 'Mute';
                                Kandy._makeToast('Unmuted');
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri);
                        } else {
                            Kandy.group.muteGroup(function () {
                                selector.options[idx].value = 'true';
                                selector.options[idx].text = 'Unmute';
                                Kandy._makeToast('Muted');
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri);
                        }
                        break;
                    case 2: // Change group image
                        Kandy.chat.pickImage(function (uri) {
                            Kandy.group.updateGroupImage(function () {
                                document.getElementById(group.id.uri + '-group-image').setAttribute('src', uri);
                                Kandy._makeToast('Updated successfully');
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri, uri);
                        }, function (e) {
                            Kandy._defaultErrorAction(e);
                        });
                        break;
                    case 3: // Delete group image
                        var ok = confirm("Are you sure?");
                        if (ok == true) {
                            Kandy.group.removeGroupImage(function () {
                                document.getElementById(group.id.uri + '-group-image').setAttribute('src', '');
                                Kandy._makeToast('Removed successfully');
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri);
                        }
                        break;
                    case 4: // Add participants
                        var name = prompt("Enter participant name");
                        if (name != null) {
                            Kandy.group.addParticipants(function (updatedGroup) {
                                Kandy._refreshPariticipants(updatedGroup);
                                alert("Added successfully!");
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri, [name]);
                        }
                        break;
                    default:
                        break;
                }
            }
        }, function (e) {
            Kandy._defaultErrorAction(e);
        }, groupId);
    },

    _refreshPariticipants: function (group) {
        var list = document.getElementById(group.id.uri + '-participants-list');
        list.innerHTML = '';
        var participants = group.participants;
        for (var i = 0; i < participants.length; ++i) {
            var participant = participants[i];
            var item = document.createElement('li');
            item.setAttribute('class', 'collection-item');
            item.innerHTML = '<select class="browser-default" id="' + group.id.uri + '-participant-' + participant.uri + '-options" uri="' + participant.uri + '">'
                + '<option disabled selected>' + participant.username + (participant.isAdmin ? ' (admin)' : '') + '</option>'
                + '<option value="' + participant.isMuted + '">' + (participant.isMuted ? 'Unmute' : 'Mute') + '</option>'
                + '<option>Remove</option>'
                + '</select>';
            list.appendChild(item);

            var selector = document.getElementById(group.id.uri + '-participant-' + participant.uri + '-options');
            selector.onchange = function (e) {
                var selector = e.target;
                var uri = selector.getAttribute('uri');
                var idx = selector.selectedIndex;
                selector.selectedIndex = 0;
                switch (idx) {
                    case 0: // disabled
                        break;
                    case 1: // Mute/Unmute
                        var state = selector.options[idx].value;
                        if (state == 'true') {
                            Kandy.group.unmuteParticipants(function () {
                                selector.options[idx].value = 'false';
                                selector.options[idx].text = 'Mute';
                                Kandy._makeToast('Unmuted');
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri, [uri]);
                        } else {
                            Kandy.group.muteParticipants(function () {
                                selector.options[idx].value = 'true';
                                selector.options[idx].text = 'Unmute';
                                Kandy._makeToast('Muted');
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri, [uri]);
                        }
                        break;
                    case 2: // Delete
                        var ok = confirm("Are you sure?");
                        if (ok == true) {
                            Kandy.group.removeParticipants(function (updatedGroup) {
                                Kandy._refreshPariticipants(updatedGroup);
                                alert("Deleted successfully!");
                            }, function (e) {
                                Kandy._defaultErrorAction(e);
                            }, group.id.uri, [uri]);
                        }
                        break;
                    default:
                        break;
                }
            }
        }
    },

    //*** CONFIGURATIONS ***//

    /**
     * Setup API key.
     *
     * @param api The api key.
     * @param secret The api secret key.
     */
    setKey: function (api, secret) {
        exec(null, null, "KandyPlugin", "setKey", [api, secret]);
    },

    /**
     * Set host address.
     *
     * @param url
     */
    setHostUrl: function (url) {
        if (!/^(f|ht)tps?:\/\//i.test(url.toLowerCase())) {
            url = "http://" + url;
        }
        exec(null, null, "KandyPlugin", "setHostUrl", [url]);
    },

    /**
     * Get current host address.
     *
     * @param callback The callback function.
     */
    getHostUrl: function (callback) {
        exec(callback, null, "KandyPlugin", "getHostUrl", []);
    },

    /**
     * Get current plugin configurations report.
     *
     * @param callback The callback function.
     */
    getReport: function (callback) {
        exec(callback, null, "KandyPlugin", "getReport", []);
    },

    /**
     * Get current session.
     *
     * @param success The success callback function.
     */
    getSession: function (success) {
        exec(success, null, "KandyPlugin", "getSession", []);
    },

    //*** PROVISIONING SERVICE ***//
    provisioning: {

        /**
         * Request code for verification and registration process.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param phoneNumber The user phone number.
         * @param countryCode The two letter ISO country code.
         */
        requestCode: function (success, error, phoneNumber, countryCode) {
            exec(success, error, "KandyPlugin", "request", [phoneNumber, countryCode]);
        },

        /**
         * Validation of the signed up phone number send received code to the server.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param phoneNumber The user phone number.
         * @param otp The OTP code.
         * @param countryCode The two letter ISO country code.
         */
        validate: function (success, error, phoneNumber, otp, countryCode) {
            exec(success, error, "KandyPlugin", "validate", [phoneNumber, otp, countryCode]);
        },

        /**
         * Signing off the registered account (phone number) from a Kandy.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        deactivate: function (success, error) {
            exec(success, error, "KandyPlugin", "deactivate", []);
        }
    },

    //*** ACCESS SERVICE ***//
    access: {

        /**
         * Register/login the user on the server with credentials received from admin.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param username The username to login
         * @param password The password to login
         */
        login: function (success, error, username, password) {
            exec(success, error, "KandyPlugin", "login", [username, password]);
        },

        /**
         * This method unregisters user from the Kandy server.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        logout: function (success, error) {
            exec(success, error, "KandyPlugin", "logout", []);
        },

        /**
         * Get the current state.
         *
         * @param success The success callback function.
         */
        getConnectionState: function (success) {
            exec(success, null, "KandyPlugin", "getConnectionState", []);
        }
    },

    //*** CALL SERVICE ***//
    call: {

        /**
         * Create a voip call.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param user The id of callee.
         * @param startWithVideo Start the call with video call enabled.
         */
        createVoipCall: function (success, error, user, startWithVideo) {
            startWithVideo = startWithVideo ? 1 : 0;
            exec(success, error, "KandyPlugin", "createVoipCall", [user, startWithVideo]);
        },

        /**
         * Create a PSTN call
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param phoneNumber The user phone number
         */
        createPSTNCall: function (success, error, phoneNumber) {
            exec(success, error, "KandyPlugin", "createPSTNCall", [phoneNumber]);
        },

        /**
         * Show Local Video in given Dimension.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         * @param left The co-ordinate of X position.
         * @param top The co-ordinate of Y position.
         * @param width The width of of Video that needs to show.
         * @param height The height of of Video that needs to show.
         */
        showLocalVideo: function (success, error, id, left, top, width, height) {
            exec(success, error, "KandyPlugin", "showLocalVideo", [id, left, top, width, height]);
        },

        /**
         * Show Remote Video in given Dimension.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         * @param left The co-ordinate of X position.
         * @param top The co-ordinate of Y position.
         * @param width The width of of Video that needs to show.
         * @param height The height of of Video that needs to show.
         */
        showRemoteVideo: function (success, error, id, left, top, width, height) {
            exec(success, error, "KandyPlugin", "showRemoteVideo", [id, left, top, width, height]);
        },

        /**
         * Hide Local Video.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        hideLocalVideo: function (success, error, id) {
            exec(success, error, "KandyPlugin", "hideLocalVideo", [id]);
        },

        /**
         * Hide Local Video.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        hideRemoteVideo: function (success, error, id) {
            exec(success, error, "KandyPlugin", "hideRemoteVideo", [id]);
        },

        /**
         * Hangup current call.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        hangup: function (success, error, id) {
            exec(success, error, "KandyPlugin", "hangup", [id]);
        },

        /**
         * Mute current call.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        mute: function (success, error, id) {
            exec(success, error, "KandyPlugin", "mute", [id]);
        },

        /**
         * Unmute current call.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        unmute: function (success, error, id) {
            exec(success, error, "KandyPlugin", "unmute", [id]);
        },

        /**
         * Hold current call
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        hold: function (success, error, id) {
            exec(success, error, "KandyPlugin", "hold", [id]);
        },

        /**
         * Unhold current call
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        unhold: function (success, error, id) {
            exec(success, error, "KandyPlugin", "unhold", [id]);
        },

        /**
         * Enable sharing video.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        enableVideo: function (success, error, id) {
            exec(success, error, "KandyPlugin", "enableVideo", [id]);
        },

        /**
         * Disable sharing video.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        disableVideo: function (success, error, id) {
            exec(success, error, "KandyPlugin", "disableVideo", [id]);
        },

        /**
         * Switch to front-camera
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        switchFrontCamera: function (success, error, id) {
            exec(success, error, "KandyPlugin", "switchFrontCamera", [id]);
        },

        /**
         * Switch to back-camera
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        switchBackCamera: function (success, error, id) {
            exec(success, error, "KandyPlugin", "switchBackCamera", [id]);
        },

        /**
         * Switch speaker on.
         */
        switchSpeakerOn: function () {
            exec(null, null, "KandyPlugin", "switchSpeakerOn", [])
        },

        /**
         * Switch speaker off.
         */
        switchSpeakerOff: function () {
            exec(null, null, "KandyPlugin", "switchSpeakerOff", [])
        },

        /**
         * Accept current coming call.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         * @param videoEnabled Enable video call or not.
         */
        accept: function (success, error, id, videoEnabled) {
            if (videoEnabled == undefined) videoEnabled = false;
            videoEnabled = videoEnabled ? 1 : 0;
            exec(success, error, "KandyPlugin", "accept", [id, videoEnabled]);
        },

        /**
         * Reject current coming call.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        reject: function (success, error, id) {
            exec(success, error, "KandyPlugin", "reject", [id]);
        },

        /**
         * Ignore current coming call.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The callee uri.
         */
        ignore: function (success, error, id) {
            exec(success, error, "KandyPlugin", "ignore", [id]);
        }
    },

    //*** CHAT SERVICE ***/
    chat: {

        /**
         * Send the message to recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message/
         * @param message The message to send.
         * @param type The {@link RecordType} to use.
         */
        sendChat: function (success, error, recipient, message, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendChat", [recipient, message, type]);
        },

        /**
         * Send the SMS to recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param message The message to send.
         */
        sendSMS: function (success, error, recipient, message) {
            exec(success, error, "KandyPlugin", "sendSMS", [recipient, message]);
        },

        /**
         * Pick a audio file by android default picker.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         *
         */
        pickAudio: function (success, error) {
            exec(success, error, "KandyPlugin", "pickAudio", []);
        },

        /**
         * Send a audio file to the recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param caption The caption of the file.
         * @param uri The URI of the file.
         * @param type The {@link RecordType} to use.
         */
        sendAudio: function (success, error, recipient, caption, uri, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendAudio", [recipient, caption, uri, type]);
        },

        /**
         * Pick a video file by android default picker.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        pickVideo: function (success, error) {
            exec(success, error, "KandyPlugin", "pickVideo", []);
        },

        /**
         * Send a video file to the recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param caption The caption of the file.
         * @param uri The URI of the file.
         * @param type The {@link RecordType} to use.
         */
        sendVideo: function (success, error, recipient, caption, uri, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendVideo", [recipient, caption, uri, type]);
        },

        /**
         * Pick a image file by android default picker.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        pickImage: function (success, error) {
            exec(success, error, "KandyPlugin", "pickImage", []);
        },

        /**
         * Send a image file to the recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param caption The caption of the file.
         * @param uri The URI of the file.
         * @param type The {@link RecordType} to use.
         */
        sendImage: function (success, error, recipient, caption, uri, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendImage", [recipient, caption, uri, type]);
        },

        /**
         * Pick a file file by android default picker.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        pickFile: function (success, error) {
            exec(success, error, "KandyPlugin", "pickFile", []);
        },

        /**
         * Send a file to the recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param caption The caption of the file.
         * @param uri The URI of the file.
         * @param type The {@link RecordType} to use.
         */
        sendFile: function (success, error, recipient, caption, uri, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendFile", [recipient, caption, uri, type]);
        },

        /**
         * Pick a contact file by android default picker.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        pickContact: function (success, error) {
            exec(success, error, "KandyPlugin", "pickContact", []);
        },

        /**
         * Send a contact to the recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param caption The caption of the file.
         * @param uri The URI of the file.
         * @param type The {@link RecordType} to use.
         */
        sendContact: function (success, error, recipient, caption, uri, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendContact", [recipient, caption, uri, type]);
        },

        /**
         * Send current location info to the recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param caption The caption of the file.
         * @param type The {@link RecordType} to use.
         */
        sendCurrentLocation: function (success, error, recipient, caption, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendCurrentLocation", [recipient, caption, type]);
        },

        /**
         * Send a location info to the recipient.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The destination of the message.
         * @param caption The caption of the file.
         * @param location The location to send.
         * @param type The {@link RecordType} to use.
         */
        sendLocation: function (success, error, recipient, caption, location, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;
            exec(success, error, "KandyPlugin", "sendLocation", [recipient, caption, location, type]);
        },

        /**
         * Open a chooser dialog and send the attachment.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param recipient The recipient user.
         * @param caption The message (caption) of the attachment.
         * @param type The {@link RecordType} to use.
         */
        sendAttachment: function (success, error, recipient, caption, type) {
            if (type == undefined) type = Kandy.RecordType.CONTACT;

            var _success = function (args) {
                switch (args.code) {
                    case Kandy.PickerResult.AUDIO_PICKER_RESULT:
                        Kandy.chat.sendAudio(success, error, recipient, caption, args.uri, type);
                        break;
                    case Kandy.PickerResult.VIDEO_PICKER_RESULT:
                        Kandy.chat.sendVideo(success, error, recipient, caption, args.uri, type);
                        break;
                    case Kandy.PickerResult.IMAGE_PICKER_RESULT:
                        Kandy.chat.sendImage(success, error, recipient, caption, args.uri, type);
                        break;
                    case Kandy.PickerResult.CONTACT_PICKER_RESULT:
                        Kandy.chat.sendContact(success, error, recipient, caption, args.uri, type);
                        break;
                    case Kandy.PickerResult.FILE_PICKER_RESULT:
                        Kandy.chat.sendFile(success, error, recipient, caption, args.uri, type);
                        break;
                    default:
                        break;
                }
            }

            exec(_success, error, "KandyPlugin", "sendAttachment", [recipient, caption, type]);
        },

        /**
         * Open a attachment of the file.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param uri The uri of the attachment.
         * @param mimeType The mimeType of the attachment.
         */
        openAttachment: function (success, error, uri, mimeType) {
            exec(success, error, "KandyPlugin", "openAttachment", [uri, mimeType]);
        },

        /**
         * Cancel the current media transfer of the message.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param uuid The UUID of the message.
         */
        cancelMediaTransfer: function (success, error, uuid) {
            exec(success, error, "KandyPlugin", "cancelMediaTransfer", [uuid]);
        },

        /**
         * Download the media file of the message.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param uuid The UUID of the message.
         */
        downloadMedia: function (success, error, uuid) {
            exec(success, error, "KandyPlugin", "downloadMedia", [uuid]);
        },

        /**
         * Get a thumbnail of the media message.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param uuid The UUID of the message.
         * @param thumbnailSize The {@link ThumbnailSize} of image.
         */
        downloadMediaThumbnail: function (success, error, uuid, thumbnailSize) {
            exec(success, error, "KandyPlugin", "downloadMediaThumbnail", [uuid, thumbnailSize]);
        },

        /**
         * Send ack to sever for UUID of received/handled message(s).
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param uuid The UUID of the message.
         */
        markAsReceived: function (success, error, uuid) {
            exec(success, error, "KandyPlugin", "markAsReceived", [uuid]);
        },

        /**
         * Pull pending events from Kandy service.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        pullEvents: function (success, error) {
            exec(success, error, "KandyPlugin", "pullEvents", []);
        }
    },

    // *** GROUP SERVICE ***//
    group: {

        /**
         * Create a new group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param name The name of the group to create.
         */
        createGroup: function (success, error, name) {
            exec(success, error, "KandyPlugin", "createGroup", [name]);
        },

        /**
         * Get group list of user.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        getMyGroups: function (success, error) {
            exec(success, error, "KandyPlugin", "getMyGroups", []);
        },

        /**
         * Get group detail by group id.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         */
        getGroupById: function (success, error, id) {
            exec(success, error, "KandyPlugin", "getGroupById", [id]);
        },

        /**
         * Update group name.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         * @param newName The new name of the group.
         */
        updateGroupName: function (success, error, id, newName) {
            exec(success, error, "KandyPlugin", "updateGroupName", [id, newName]);
        },

        /**
         * Update group image.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         * @param uri The uri of the image.
         */
        updateGroupImage: function (success, error, id, uri) {
            exec(success, error, "KandyPlugin", "updateGroupImage", [id, uri]);
        },

        /**
         * Remove group image.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         */
        removeGroupImage: function (success, error, id) {
            exec(success, error, "KandyPlugin", "removeGroupImage", [id]);
        },

        /**
         * Get the group image.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         */
        downloadGroupImage: function (success, error, id) {
            exec(success, error, "KandyPlugin", "downloadGroupImage", [id]);
        },

        /**
         * Get thumbnail group image.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         * @param thumbnailSize The {@link ThumbnailSize} of image.
         */
        downloadGroupImageThumbnail: function (success, error, id, thumbnailSize) {
            exec(success, error, "KandyPlugin", "downloadGroupImageThumbnail", [id, thumbnailSize]);
        },

        /**
         * Mute the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         */
        muteGroup: function (success, error, id) {
            exec(success, error, "KandyPlugin", "muteGroup", [id]);
        },

        /**
         * Unmute the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         */
        unmuteGroup: function (success, error, id) {
            exec(success, error, "KandyPlugin", "unmuteGroup", [id]);
        },

        /**
         * Destroy the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         */
        destroyGroup: function (success, error, id) {
            exec(success, error, "KandyPlugin", "destroyGroup", [id]);
        },

        /**
         * Leave the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         */
        leaveGroup: function (success, error, id) {
            exec(success, error, "KandyPlugin", "leaveGroup", [id]);
        },

        /**
         * Remove participants of the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         * @param participants The uri list of the participants.
         */
        removeParticipants: function (success, error, id, participants) {
            exec(success, error, "KandyPlugin", "removeParticipants", [id, participants]);
        },

        /**
         * Mute participants of the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         * @param participants The uri list of the participants.
         */
        muteParticipants: function (success, error, id, participants) {
            exec(success, error, "KandyPlugin", "muteParticipants", [id, participants]);
        },

        /**
         * Unmute participants of the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         * @param participants The uri list of the participants.
         */
        unmuteParticipants: function (success, error, id, participants) {
            exec(success, error, "KandyPlugin", "unmuteParticipants", [id, participants]);
        },

        /**
         * Add participants to the group.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param id The id of the group.
         * @param participants The uri list of the participants.
         */
        addParticipants: function (success, error, id, participants) {
            exec(success, error, "KandyPlugin", "addParticipants", [id, participants]);
        }

    },

    //*** PRESENCE SERVICE ***//
    presence: {

        /**
         * Register listener for presence's callbacks/notifications.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param userList The id list of users.
         */
        startWatch: function (success, error, userList) {
            exec(success, error, "KandyPlugin", "presence", userList);
        }
    },

    //*** LOCATION SERVICE ***//
    location: {

        /**
         * Get the country info.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        getCountryInfo: function (success, error) {
            exec(success, error, "KandyPlugin", "getCountryInfo", []);
        },

        /**
         * Get current location.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        getCurrentLocation: function (success, error) {
            exec(success, error, "KandyPlugin", "getCurrentLocation", []);
        }
    },

    //*** PUSH SERVICE ***//
    push: {

        /**
         * Enable the push service.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        enable: function (success, error) {
            exec(success, error, "KandyPlugin", "enable", []);
        },

        /**
         * Disable the push service.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        disable: function (success, error) {
            exec(success, error, "KandyPlugin", "disable", []);
        }
    },

    //*** ADDRESS BOOK SERVICE ***//
    addressBook: {

        /**
         * Get the contacts list from user device.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param filters The {@link DeviceContactsFilter} array to use.
         */
        getDeviceContacts: function (success, error, filters) {
            exec(success, error, "KandyPlugin", "getDeviceContacts", [filters]);
        },

        /**
         * Get the contacts list from the host domain.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         */
        getDomainContacts: function (success, error) {
            exec(success, error, "KandyPlugin", "getDomainContacts", []);
        },

        /**
         * Get the filterd contacts list from the host domain.
         *
         * @param success The success callback function.
         * @param error The error callback function.
         * @param filter The {@link DomainContactFilter} to search.
         * @param searchString The search string.
         */
        getFilteredDomainDirectoryContacts: function (success, error, filter, searchString) {
            exec(success, error, "KandyPlugin", "getFilteredDomainDirectoryContacts", [filter, searchString]);
        }
    }
};

module.exports = Kandy;
