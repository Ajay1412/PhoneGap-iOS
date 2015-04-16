var app = {
    // Application Constructor
    initialize: function() {
        this.bindEvents();
    },
    // Bind Event Listeners
    //
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        app.receivedEvent('deviceready');
    },
    // Update DOM on a Received Event
    receivedEvent: function(id) {

        Kandy.initialize({
            startWithVideo: true,
            downloadPath: "",
            mediaSizePicker: "",
            downloadPolicy: "",
            autoDownloadThumbnailSize: ""
        });
    }
};

function refreshUI(){
    $(".ui-mobile").trigger('create');
}

function pushEnable(){
    Kandy.push.enable(function(){
        $("#pushState").html("enabled");
    }, function(e){
        alert(e);
    });
}

function pushDisable(){
    Kandy.push.disable(function(){
        $("#pushState").html("disabled");
    }, function(e){
        alert(e);
    });
}

function startWatch() {
    var recipients = $("#usersIdWatched").val();

    $("#usersOnline").html("");
    $("#usersOffline").html("");

    Kandy.presence.startWatch(function(s){
        $("#usersWatched").html(recipients);

        var onlines = "", offlines = "";

        for(var i = 0; i < s.onlines.length; ++i)
            onlines += '[' + s.onlines[i].user + ']'

        for(var i = 0; i < s.offlines.length; ++i)
            offlines += '[' + s.offlines[i] + ']'

        $("#usersOnline").html(onlines);
        $("#usersOffline").html(offlines);
    }, function(e){
        alert(e);
    }, recipients.split(','));
}

function getCountryInfo() {
    Kandy.location.getCountryInfo(function(s){
        $("#countryCode").html(s.code);
        $("#countryNameLong").html(s.long);
        $("#countryNameShort").html(s.short);
    }, function(e){
        alert(e);
    });
}

function getCurrentLocation(){
    $("#currentLocationInfo").html("");

    Kandy.location.getCurrentLocation(function(s){
        $("#currentLocationInfo").html(JSON.stringify(s));
    }, function(e) {
        alert(e);
    });
}

function getDeviceContacts(){
    $("#addressBooks").html("");

    Kandy.addressBook.getDeviceContacts(function(s){
        $("#addressBooks").html(JSON.stringify(s));
    }, function(e){
        alert(e);
    });
}

function getDomainContacts(){
    $("#addressBooks").html("");

    Kandy.addressBook.getDomainContacts(function(s){
        $("#addressBooks").html(JSON.stringify(s));
    }, function(e){
        alert(e);
    });
}