var app = {
    // Application Constructor
    initialize: function () {
        this.bindEvents();
    },
    // Bind Event Listeners
    //
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function () {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function () {
        app.receivedEvent('deviceready');
    },
    // Update DOM on a Received Event
    receivedEvent: function (id) {
        $(".button-collapse").sideNav();

        Kandy.initialize();

        if (typeof loginRequired === 'undefined' || loginRequired == true) {
            Kandy.access.getConnectionState(function (state) {
                if (state != Kandy.ConnectionState.CONNECTED) {
                    window.open("index.html");
                }
            })
        }
    }
};

/**
 * Enable push notification.
 */
function pushEnable() {
    Kandy.push.enable(function () {
        $("#pushState").html("enabled");
    }, function (e) {
        alert(e);
    });
}

/**
 * Disable push notification.
 */
function pushDisable() {
    Kandy.push.disable(function () {
        $("#pushState").html("disabled");
    }, function (e) {
        alert(e);
    });
}

/**
 * Start watch users.
 */
function startWatch() {
    var recipients = $("#usersIdWatched").val();

    $("#usersOnline").html("");
    $("#usersOffline").html("");

    Kandy.presence.startWatch(function (s) {
        $("#usersWatched").html(recipients);

        var presences = [], absences = [];

        for (var i = 0; i < s.presences.length; ++i)
            presences += '[' + s.presences[i].user + ']'

        for (var i = 0; i < s.absences.length; ++i)
            absences += '[' + s.absences[i] + ']'

        $("#usersOnline").html(presences);
        $("#usersOffline").html(absences);
    }, function (e) {
        alert(e);
    }, recipients.split(','));
}

/**
 * Get the country info.
 */
function getCountryInfo() {
    Kandy.location.getCountryInfo(function (s) {
        $("#countryCode").html(s.code);
        $("#countryNameLong").html(s.long);
        $("#countryNameShort").html(s.short);
    }, function (e) {
        alert(e);
    });
}

/**
 * Get the current location info.
 */
function getCurrentLocation() {
    $("#currentLocationInfo").html("");

    Kandy.location.getCurrentLocation(function (s) {
        $("#currentLocationInfo").html("<br /> Current location info:<br />" + JSON.stringify(s));
    }, function (e) {
        alert(e);
    });
}

/**
 * Get local contacts.
 */
function getDeviceContacts() {
    $("#addressBooks").html("");

    Kandy.addressBook.getDeviceContacts(function (s) {
        $("#addressBooks").html(JSON.stringify(s));
    }, function (e) {
        alert(e);
    }, [Kandy.DeviceContactsFilter.HAS_EMAIL_ADDRESS]);
}

/**
 * Get domain contacts.
 */
function getDomainContacts() {
    $("#addressBooks").html("");

    Kandy.addressBook.getDomainContacts(function (s) {
        $("#addressBooks").html(JSON.stringify(s));
    }, function (e) {
        alert(e);
    });
}

function updateConfigs() {
    var apiKey = $("#apiKey").val();
    var apiSecret = $("#apiSecret").val();
    var hostUrl = $("#hostUrl").val();
    Kandy.setKey(apiKey, apiSecret);
    Kandy.setHostUrl(hostUrl);
    alert("Updated successfully");
}

function refreshConfigs() {
    Kandy.getSession(function (data) {
        $("#apiKey").val(data.domain.apiKey);
        $("#apiSecret").val(data.domain.apiSecret);
    });
    Kandy.getHostUrl(function (url) {
        $("#hostUrl").val(url);
    });
    Kandy.getReport(function (report) {
        $("#configsReport").html('<pre>' + report + '</pre>');
    })
}