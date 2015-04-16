//
//  KandyPlugin.m
//  KandyPlugin
//
//  Created by Srinivasan Baskaran on 2/6/15.
//
//

#import "KandyPlugin.h"
#import <KandySDK/KandySDK.h>
#import "CallViewController.h"

// Kandy PhoneGap Plugin String

static NSString *kandy_error_message = @"Response code: %d - %@";
static NSString *kandy_login_login_success = @"Login succeed";
static NSString *kandy_login_logout_success = @"Logout succeed";
static NSString *kandy_login_empty_username_text = @"Invalid username (userID@domain.com)";
static NSString *kandy_login_empty_password_text = @"Enter password";

static NSString *kandy_calls_local_video_label = @"Local video";
static NSString *kandy_calls_checkbox_label = @"Start with video";
static NSString *kandy_calls_state_video_label = @"Video state";
static NSString *kandy_calls_state_audio_label = @"Audio state";
static NSString *kandy_calls_state_calls_label = @"Calls state";
static NSString *kandy_calls_hold_label = @"hold";
static NSString *kandy_calls_unhold_label = @"unhold";
static NSString *kandy_calls_mute_label = @"mute";
static NSString *kandy_calls_unmute_label = @"unmute";
static NSString *kandy_calls_video_label = @"video";
static NSString *kandy_calls_novideo_label = @"no video";
static NSString *kandy_calls_call_button_label = @"Call";
static NSString *kandy_calls_hangup_button_label = @"Hangup";
static NSString *kandy_calls_receiving_video_state = @"Receiving video:";
static NSString *kandy_calls_sending_video_state = @"Sending video:";
static NSString *kandy_calls_audio_state = @"Audio isMute:";
static NSString *kandy_calls_phone_number_hint = @"userID@domain.com";
static NSString *kandy_calls_invalid_phone_text_msg = @"Invalid recipient (recipientID@domain.com)";
static NSString *kandy_calls_invalid_domain_text_msg = @"Wrong domain";
static NSString *kandy_calls_invalid_hangup_text_msg = @"No active calls";
static NSString *kandy_calls_invalid_hold_text_msg = @"Can not hold - No Active Call";
static NSString *kandy_calls_invalid_mute_call_text_msg = @"Can not mute - No active calls";
static NSString *kandy_calls_invalid_video_call_text_msg = @"Can not enable/disable video - No active calls";
static NSString *kandy_calls_attention_title_text = @"!!! ATTENTION !!!";
static NSString *kandy_calls_full_user_id_message_text = @"Enter full destination user id (userID@domain.com)";
static NSString *kandy_calls_answer_button_label = @"Answer";
static NSString *kandy_calls_ignore_incoming_call_button_label = @"Ignore";
static NSString *kandy_calls_reject_incoming_call_button_label = @"Reject";
static NSString *kandy_calls_incoming_call_popup_message_label = @"Incoming call from:";
static NSString *kandy_calls_remote_video_label = @"Remote video";
static NSString *kandy_chat_phone_number_verification_text = @"Invalid recipient\'s number (recipientID@domain.com)";

@interface KandyPlugin() <KandyCallServiceNotificationDelegate, KandyChatServiceNotificationDelegate, KandyContactsServiceNotificationDelegate, KandyAccessNotificationDelegate,  UIActionSheetDelegate>
@property (nonatomic) NSString *callbackID;

// The current call
@property (assign) id <KandyOutgoingCallProtocol> kandyOutgoingCall;
@property (nonatomic, strong) id <KandyIncomingCallProtocol> kandyIncomingCall;

/** Callback **/

// CallbackContext for current execute
@property (nonatomic) NSString *_callbackContext;

//Incoming call
@property (nonatomic) UIActionSheet * incomingCallOPtions;


/**
 * The {@link CallbackContext} for Kandy listeners *
*/
@property (nonatomic) NSString * kandyConnectServiceNotificationCallback;
@property (nonatomic) NSString * kandyCallServiceNotificationCallback;
@property (nonatomic) NSString * kandyAddressBookServiceNotificationCallback;
@property (nonatomic) NSString * kandyChatServiceNotificationCallback;
@property (nonatomic) NSString * kandyGroupServiceNotificationCallback;

@property (nonatomic) NSString * kandyChatServiceNotificationPluginCallback;

// Kandy listeners for call, chat, presence
@property (nonatomic) NSString * incomingCallListener;
@property (nonatomic) NSString * videoStateChangedListener;
@property (nonatomic) NSString * audioStateChangedListener;
@property (nonatomic) NSString * callStateChangedListener;
@property (nonatomic) NSString * GSMCallIncomingListener;
@property (nonatomic) NSString * GSMCallConnectedListener;
@property (nonatomic) NSString * GSMCallDisconnectedListener;

@property (nonatomic) NSString * chatReceivedListener;
@property (nonatomic) NSString * chatDeliveredListener;
@property (nonatomic) NSString * chatMediaDownloadProgressListener;
@property (nonatomic) NSString * chatMediaDownloadFailedListener;
@property (nonatomic) NSString * chatMediaDownloadSuccededListener;

@property (nonatomic) NSString * deviceAddressBookChangedListener;

// Whether or not the call start with sharing video enabled
@property (assign) BOOL startVideoCall;

// The call dialog (native)
@property (assign) BOOL isUsingNativeDialog;

@end


@implementation KandyPlugin

#pragma mark - pluginInitialize

- (void)pluginInitialize {
    [self InitializeObjects];
}

- (void) InitializeObjects {
    
    NSString *apikey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"PROJECT_API_KEY"];
    NSString *apisecret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"PROJECT_API_SECRET"];
    [Kandy initializeWithDomainKey:apikey domainSecret:apisecret];

    self.startVideoCall = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRemoteNotification:) name:CDVRemoteNotification object:nil];
}

- (void) registerNotifications {
    //Connect service
    [[Kandy sharedInstance].access registerNotifications:self];
    [[Kandy sharedInstance].services.call registerNotifications:self];
    [[Kandy sharedInstance].services.chat registerNotifications:self];
    [[Kandy sharedInstance].services.contacts registerNotifications:self];
}

- (void) unRegisterNotifications {
    [[Kandy sharedInstance].access unregisterNotifications:self];
    [[Kandy sharedInstance].services.call unregisterNotifications:self];
    [[Kandy sharedInstance].services.chat unregisterNotifications:self];
    [[Kandy sharedInstance].services.contacts unregisterNotifications:self];
}

#pragma mark - Delegate

/**
 * The listeners for callback
 */

#pragma mark - KandyConnectServiceNotificationDelegate

-(void) connectionStatusChanged:(EKandyConnectionState)connectionStatus{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onConnectionStateChanged",@"action",
                             @(connectionStatus), @"state",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyConnectServiceNotificationCallback];
}

-(void) gotInvalidUser:(NSError*)error{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onInvalidUser",@"action",
                             error, @"error",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyConnectServiceNotificationCallback];
}
#pragma mark - KandyCallServiceNotificationDelegate

/**
 *
 * @param call
 */
-(void) gotIncomingCall:(id<KandyIncomingCallProtocol>)call{
    self.kandyIncomingCall = call;
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onIncomingCall",@"action",
                             call.callId,@"id",
                             call.callee.uri, @"callee",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
    
    //TODO: Need to check whether need thread
    [self answerIncomingCall];
}

/**
 *
 * @param state
 * @param call
 */
-(void) stateChanged:(EKandyCallState)callState forCall:(id<KandyCallProtocol>)call{
    
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onCallStateChanged",@"action",
                             call.callId,@"id",
                             call.callee.uri, @"callee",
                             @(callState), @"state",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];

    [self.incomingCallOPtions dismissWithClickedButtonIndex:3 animated:YES];
}

/**
 *
 * @param iKandyCall
 * @param isReceivingVideo
 * @param isSendingVideo
 */
-(void) videoStateChangedForCall:(id<KandyCallProtocol>)call{
        NSDictionary *jsonObj = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"onVideoStateChanged",@"action",
                                 call.callId,@"id",
                                 call.callee.uri, @"callee",
                                 @(call.isReceivingVideo),@"isReceivingVideo",
                                 @(call.isSendingVideo), @"isSendingVideo",
                                 nil
                                 ];
        [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}

/**
 *
 * @param call
 * @param onMute
 */
-(void) audioRouteChanged:(EKandyCallAudioRoute)audioRoute forCall:(id<KandyCallProtocol>)call{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onVideoStateChanged",@"action",
                             call.callId,@"id",
                             call.callee.uri, @"callee",
                             @(call.isMute), @"isMute",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}
-(void) gotMissedCall:(id<KandyCallProtocol>)call{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onMissedCall",@"action",
                             call.callId,@"id",
                             call.callee.uri, @"callee",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}
-(void) participantsChanged:(NSArray*)participants forCall:(id<KandyCallProtocol>)call{
}
-(void) videoCallImageOrientationChanged:(EKandyVideoCallImageOrientation)newImageOrientation forCall:(id<KandyCallProtocol>)call{
}
/**
 *
 * @param call
 */
-(void) GSMCallIncoming{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onGSMCallIncoming",@"action",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}

-(void) GSMCallDialing{
}
-(void) GSMCallConnected{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onGSMCallConnected",@"action",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}
-(void) GSMCallDisconnected{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onGSMCallDisconnected",@"action",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}

#pragma mark - KandyChatServiceNotificationDelegate


-(void)onMessageReceived:(id<KandyMessageProtocol>)kandyMessage
{
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onChatReceived",@"action",
                             kandyMessage.uuid,@"UUID",
                             kandyMessage.sender.uri, @"sender",
                             kandyMessage.mediaItem.text , @"message",
                             kandyMessage.timestamp , @"timestamp",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
    
}
-(void)onMessageDelivered:(KandyDeliveryAck *)ackData {
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onChatDelivered",@"action",
                             ackData.uuid,@"UUID",
                             ackData.timestamp , @"timestamp",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
}

-(void) onAutoDownloadProgress:(KandyTransferProgress*)transferProgress kandyMessage:(id<KandyMessageProtocol>)kandyMessage {
    NSDictionary *jsonObj = [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"onChatMediaAutoDownloadProgress",@"action",
                             kandyMessage.uuid,@"UUID",
                             kandyMessage.timestamp , @"timestamp",
                             transferProgress.transferProgressPercentage, @"process",
                             transferProgress.transferState, @"state",
                             transferProgress.transferredSize, @"byteTransfer",
                             transferProgress.expectedSize, @"byteExpected",
                             nil
                             ];
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
}

-(void) onAutoDownloadFinished:(NSError*)error fileAbsolutePath:(NSString*)path kandyMessage:(id<KandyMessageProtocol>)kandyMessage {
    NSDictionary *jsonObj;
    if(error)
    {
        jsonObj = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"onChatMediaAutoDownloadFailed",@"action",
                                 error.description,@"error",
                                 error.code,@"code",
                                 nil
                                 ];
    } else {
        jsonObj = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"onChatMediaAutoDownloadSucceded",@"action",
                                 kandyMessage.recipient.uri,@"uri",
                                 nil
                                 ];
    }
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
}

#pragma mark - KandyContactsServiceNotificationDelegate

-(void)onDeviceContactsChanged {
    [self notifySuccessResponse:nil withCallbackID:self.kandyAddressBookServiceNotificationCallback];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self doAcceptCallWithVideo:YES];
            break;
        case 1:
            [self doAcceptCallWithVideo:NO];
            break;
        case 2:
            [self doRejectCall];
            break;
        case 3:
            [self doIgnoreCall];
            break;
        default:
            break;
        }
}

#pragma mark - Helper methods

- (void) didReceiveRemoteNotification:(NSData *)deviceToken {
    [[NSUserDefaults standardUserDefaults]setObject:deviceToken forKey:@"deviceToken"];
}

- (void) notifySuccessResponse:(id)response {
    [self notifySuccessResponse:response withCallbackID:self.callbackID];
}

- (void) notifySuccessResponse:(id)response withCallbackID:(NSString *)callbackId {
    // Create an instance of CDVPluginResult, with an OK status code.
    CDVPluginResult *pluginResult;
    if ([response isKindOfClass:[NSDictionary class]]) {
        pluginResult = [ CDVPluginResult
                                         resultWithStatus    : CDVCommandStatus_OK
                                         messageAsDictionary : response
                                         ];
    } else {
        pluginResult = [ CDVPluginResult
                                        resultWithStatus    : CDVCommandStatus_OK
                                        messageAsString:response
                                         ];
    }
    // Execute sendPluginResult on this plugin's commandDelegate, passing in the ...
    // ... instance of CDVPluginResult
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) notifyFailureResponse:(NSString *)errString {
    [self notifyFailureResponse:errString withCallbackID:self.callbackID];
}

- (void) notifyFailureResponse:(NSString *)errString withCallbackID:(NSString *)callbackId {
    // Create an instance of CDVPluginResult, with an OK status code.
    // Set the return message as the String object (errString)...
    CDVPluginResult *pluginResult = [ CDVPluginResult
                                     resultWithStatus    : CDVCommandStatus_ERROR
                                     messageAsString:errString
                                     ];
    
    // Execute sendPluginResult on this plugin's commandDelegate, passing in the ...
    // ... instance of CDVPluginResult
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) handleRequiredInputError {
    [self notifyFailureResponse:@"Missing required input parameter" withCallbackID:self.callbackID];
}

- (void) validateInvokedUrlCommand:(CDVInvokedUrlCommand *)command withRequiredInputs:(int)inputs {
    self.callbackID = command.callbackId;
    NSArray *params = command.arguments;
    if (params && [params count] < 1) {
        [self handleRequiredInputError];
        return;
    }
}

- (void) answerIncomingCall {
    self.incomingCallOPtions = [[UIActionSheet alloc] initWithTitle:@"Incoming Call" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Accept With Video", @"Accept Without Video", @"Reject", @"Ignore", nil];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [self.incomingCallOPtions showInView:window.rootViewController.view];
}

- (void) initOutgoingCallWithDialog {
    [self.kandyOutgoingCall establishWithResponseBlock:^(NSError *error) {
        if (error) {
            [self didHandleResponse:error];
        } else {
            CallViewController *callVC = [[CallViewController alloc] initWithNibName:@"CallView" bundle:nil];
            callVC.kandyCall = self.kandyOutgoingCall;
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            [window.rootViewController presentViewController:callVC animated:YES completion:nil];
        }
    }];
}

- (NSDictionary *) enumerateContactDetails:(NSArray *)kandyContacts {
    NSMutableDictionary *contacts = [[NSMutableDictionary alloc] init];
    for (id <KandyContactProtocol> kandyContact in kandyContacts) {
        NSMutableDictionary *deviceContacts = [[NSMutableDictionary alloc] init];
        [deviceContacts setValue:kandyContact.displayName forKey:@"displayName"];
        NSMutableDictionary *deviceEmailContacts = [[NSMutableDictionary alloc] init];
        for (id <KandyEmailContactRecordProtocol> kandyEmailContactRecord in kandyContact.emails) {
            [deviceEmailContacts setValue:kandyEmailContactRecord.email forKey:@"address"];
            [deviceEmailContacts setValue:@(kandyEmailContactRecord.valueType) forKey:@"type"];
        }
        [deviceContacts setValue:deviceEmailContacts forKey:@"emails"];
        NSMutableDictionary *devicePhoneContacts = [[NSMutableDictionary alloc] init];
        for (id <KandyPhoneContactRecordProtocol> kandyPhoneContactRecord in kandyContact.phones) {
            [devicePhoneContacts setValue:kandyPhoneContactRecord.phone forKey:@"number"];
            [devicePhoneContacts setValue:@(kandyPhoneContactRecord.valueType) forKey:@"type"];
        }
        [deviceContacts setValue:devicePhoneContacts forKey:@"phones"];
        [contacts setValue:deviceContacts forKey:@"contacts"];
    }
    return contacts;
}

#pragma mark - Public Plugin Methods

- (void) connectServiceNotificationCallback:(CDVInvokedUrlCommand *)command {
    self.kandyConnectServiceNotificationCallback = command.callbackId;
}
- (void) callServiceNotificationCallback:(CDVInvokedUrlCommand *)command {
    self.kandyCallServiceNotificationCallback = command.callbackId;
}
- (void) addressBookServiceNotificationCallback:(CDVInvokedUrlCommand *)command {
    self.kandyAddressBookServiceNotificationCallback = command.callbackId;
}
- (void) chatServiceNotificationCallback:(CDVInvokedUrlCommand *)command {
    self.kandyChatServiceNotificationCallback = command.callbackId;
}
- (void) groupServiceNotificationCallback:(CDVInvokedUrlCommand *)command {
    self.kandyGroupServiceNotificationCallback = command.callbackId;
}
- (void) chatServiceNotificationPluginCallback:(CDVInvokedUrlCommand *)command {
    self.kandyChatServiceNotificationPluginCallback = command.callbackId;
}

// Provisioning
- (void) request:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * phone = [params objectAtIndex:0];
        __block NSString *countryCode = [params objectAtIndex:1];
        [self requestCodeWithPhone:phone andISOCountryCode:countryCode];

    }];
}
- (void) validate:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:3];
    [self.commandDelegate runInBackground:^{
        __block NSString *phone = [params objectAtIndex:0];
        __block NSString *otp = [params objectAtIndex:1];
        __block NSString *countryCode = [params objectAtIndex:2];
        [self validateWithOTP:otp andPhone:phone andISOCountryCode:countryCode];
    }];
}
- (void) deactivate:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self deactivate];
}

// Access Service
- (void) login:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString *username = [params objectAtIndex:0];
        __block NSString *password = [params objectAtIndex:1];
        [self connectWithUserName:username andPassword:password];
    }];
}
- (void) logout:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self disconnect];
}

- (void) getConnectionState:(CDVInvokedUrlCommand *)command {
    [self notifySuccessResponse:@([Kandy sharedInstance].access.connectionState) withCallbackID:command.callbackId];
}

//Session Service
- (void) getSession:(CDVInvokedUrlCommand *)command {
    NSArray *userinfo = [Kandy sharedInstance].sessionManagement.provisionedUsers;
    if ([userinfo count] > 0) {
        KandyUserInfo * kandyUserInfo = [userinfo objectAtIndex:0];
        NSDictionary *jsonObj = [ [NSDictionary alloc]
                                 initWithObjectsAndKeys :
                                 kandyUserInfo.userId, @"userId",
                                 kandyUserInfo.record.userName, @"user",
                                 kandyUserInfo.record.domain, @"domain",
                                 nil
                                 ];
        [self notifySuccessResponse:jsonObj withCallbackID:command.callbackId];
    }
}

//Call Service
- (void) createVoipCall:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString *phone = [params objectAtIndex:0];
        __block NSString *isVideo = [params objectAtIndex:1];
        if (phone && isVideo) {
            [self establishVoipCall:phone andWithStartVideo:isVideo];
        }
    }];
}
- (void) createPSTNCall:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString *phone = [params objectAtIndex:0];
        if (phone) {
            [self establishPSTNCall:phone];
        }
    }];
}
- (void) hangupCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self hangupCall];
}
- (void) muteCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doMute:YES];
}
- (void) unMuteCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doMute:NO];
}
- (void) holdCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doHold:YES];
}
- (void) unHoldCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doHold:NO];
}
- (void) enableVideo:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doEnableVideo:YES];
}
- (void) disableVideo:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doEnableVideo:NO];
}
- (void) acceptCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doAcceptCallWithVideo:self.startVideoCall];
}
- (void) rejectCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doRejectCall];
}
- (void) ignoreCall:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doIgnoreCall];
}

// Chat Service
- (void) sendChat:(CDVInvokedUrlCommand *)command{
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString *recipient = [params objectAtIndex:0];
        __block NSString *msg = [params objectAtIndex:1];
        if (recipient && msg) {
            [self sendChatWithMessage:msg toUser:recipient];
        }
    }];
}
- (void) sendSMS:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString *recipient = [params objectAtIndex:0];
        __block NSString *msg = [params objectAtIndex:1];
        if (recipient && msg) {
            [self sendSMSWithMessage:msg toUser:recipient];
        }
    }];
}
- (void) downloadMedia:(CDVInvokedUrlCommand *)command {
    //TODO:
}
- (void) downloadMediaThumbnail:(CDVInvokedUrlCommand *)command {
    //TODO:
}
- (void) cancelMediaTransfer:(CDVInvokedUrlCommand *)command {
    //TODO:
}
- (void) sendAudio:(CDVInvokedUrlCommand *)command {
    //TODO:
}
- (void) sendVideo:(CDVInvokedUrlCommand *)command {
     //TODO:
}
- (void) sendImage:(CDVInvokedUrlCommand *)command {
     //TODO:
}
- (void) sendFile:(CDVInvokedUrlCommand *)command {
     //TODO:
}
- (void) sendContact:(CDVInvokedUrlCommand *)command {
     //TODO:
}
- (void) sendCurrentLocation:(CDVInvokedUrlCommand *)command {
    //TODO:
}
- (void) sendLocation:(CDVInvokedUrlCommand *)command {
     //TODO:
}

- (void) markAsReceived:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block id uuids = [params objectAtIndex:0];
        if (![uuids isEqual:[NSNull null]] && [uuids isKindOfClass:[NSArray class]]) {
            [self ackEvents:uuids];
        } else {
            [self ackEvents:[NSArray arrayWithObject:uuids]];
        }
        
    }];
}
- (void) pullEvents:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self pullEvents];
}

//Group Service
- (void) createGroup:(CDVInvokedUrlCommand *)command {
//TODO:
}
- (void) getMyGroups:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) getGroupById:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) updateGroupName:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) updateGroupImage:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) removeGroupImage:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) downloadGroupImage:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) downloadGroupImageThumbnail:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) muteGroup:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) unmuteGroup:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) destroyGroup:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) leaveGroup:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) removeParticipants:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) muteParticipants:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) unmuteParticipants:(CDVInvokedUrlCommand *)command {
 //TODO:
}
- (void) addParticipants:(CDVInvokedUrlCommand *)command {
 //TODO:
}

// Presence service
- (void) presence:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        NSString *userlist = [params objectAtIndex:0];
        [self getPresenceInfoByUser:userlist];
    }];
}

//Location service
- (void) getCountryInfo:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self.commandDelegate runInBackground:^{
        [self getLocationinfo];
    }];
}

- (void) getCurrentLocation:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self.commandDelegate runInBackground:^{
        [self getLocationinfo];
    }];
}

// Push service
- (void) pushEnable:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self.commandDelegate runInBackground:^{
        [self enableKandyPushNotification];
    }];

}
- (void) pushDisable:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self.commandDelegate runInBackground:^{
        [self disableKandyPushNotification];
    }];
}

//AddressBook
- (void) getDeviceContacts:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self.commandDelegate runInBackground:^{
        [self getUsersFromDeviceContacts];
    }];
}
- (void) getDomainContacts:(CDVInvokedUrlCommand *)command {
    [self getDomainContacts];
}
- (void) getFilteredDomainDirectoryContacts:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        NSString *filter = [params objectAtIndex:0];
        NSString *searchString = [params objectAtIndex:1];
        [self getFilteredDomainDirectoryContacts:searchString fields:[filter intValue] caseSensitive:NO];
    }];
}


#pragma mark - Private Plugin Methods

/*
 *  Provisioning
 */
- (void) requestCodeWithPhone:(NSString *)phoneno andISOCountryCode:(NSString *)isocode {
    isocode = isocode ? isocode : @"US";
    KandyAreaCode * kandyAreaCode = [[KandyAreaCode alloc] initWithISOCode:isocode andCountryName:@"" andPhonePrefix:@""];
    [[Kandy sharedInstance].provisioning requestCode:kandyAreaCode
                 phoneNumber:phoneno
         andResponseCallback:^(NSError *error, NSString *destinationToValidate) {
             [self didHandleResponse:error];
     }];

}

- (void) validateWithOTP:(NSString *)otp andPhone:(NSString *)phoneno andISOCountryCode:(NSString *)isocode  {
    KandyAreaCode * kandyAreaCode = [[KandyAreaCode alloc] initWithISOCode:isocode andCountryName:@"" andPhonePrefix:@""];
    [[Kandy sharedInstance].provisioning validate:otp
                 areaCode:kandyAreaCode
              destination:phoneno
      andResponseCallback:^(NSError *error, KandyUserInfo *signupData) {
          [self didHandleResponse:error];
  }];

}

- (void) deactivate {
    KandyUserInfo *userInfo = [Kandy sharedInstance].sessionManagement.provisionedUsers.lastObject;
    if(userInfo)
    {
        [[Kandy sharedInstance].provisioning deactivate:userInfo withResponseCallback:^(NSError *error) {
            [self didHandleResponse:error];
        }];
    }
    else
    {
        [self notifyFailureResponse:@"No provisioned user"];
    }
}

/*
 *  Access
 */

-(void)connectWithUserName:(NSString *)usrname andPassword:(NSString *)pwd {
    
    if (usrname && [usrname isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_login_empty_username_text];
        return;
    }
    if (pwd && [pwd isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_login_empty_password_text];
        return;
    }
    
    KandyUserInfo * kandyUserInfo = [[KandyUserInfo alloc] initWithUserId:usrname password:pwd];
    [[Kandy sharedInstance].access login:kandyUserInfo andResponseCallback:^(NSError *error) {
        if (error) {
            [self notifyFailureResponse:kandy_error_message];
        } else {
            [self registerNotifications];
            [self notifySuccessResponse:kandy_login_login_success];
        }
    }];
}

-(void)disconnect{
    [[Kandy sharedInstance].access logoutWithResponseCallback:^(NSError *error) {
        if (error) {
            [self notifyFailureResponse:kandy_error_message];
        } else {
            [self notifySuccessResponse:kandy_login_logout_success];
            [self unRegisterNotifications];
        }
    }];
}

/*
 *  Location
 */

- (void) getLocationinfo {
    [[Kandy sharedInstance].services.location getCountryInfoWithResponseCallback:^(NSError *error, KandyAreaCode *areaCode) {
        if (error) {
            [self notifyFailureResponse:kandy_error_message];
        } else {
            NSDictionary *jsonObj = [ [NSDictionary alloc]
                                     initWithObjectsAndKeys :
                                     areaCode.countryName, @"nameLong",
                                     areaCode.isoCode, @"code",
                                     areaCode.phonePrefix, @"nameShort",
                                     nil
                                     ];
            
            [self notifySuccessResponse:jsonObj];
        }
    }];
    
}

/*
 *  Call
 */
//Callback
- (void) didHandleResponse:(NSError *)error {
    if (error) {
        [self notifyFailureResponse:[NSString stringWithFormat:kandy_error_message,error.code,error.description]];
    } else {
        [self notifySuccessResponse:nil];
    }
}

-(void)establishVoipCall:(NSString *)voip andWithStartVideo:(BOOL)videoOn {
    if (voip && [voip isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_calls_invalid_phone_text_msg];
        return;
    }
    KandyRecord * kandyRecord = [[KandyRecord alloc] initWithURI:voip andWithType:EKandyRecordType_contact andAssociationType:EKandyRecordAssociationType_community];
    self.kandyOutgoingCall = [[Kandy sharedInstance].services.call createVoipCall:kandyRecord isStartVideo:videoOn];
    [self initOutgoingCallWithDialog];
}

-(void)establishPSTNCall:(NSString *)pstn {
    if (pstn && [pstn isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_calls_invalid_phone_text_msg];
        return;
    }
    self.kandyOutgoingCall = [[Kandy sharedInstance].services.call createPSTNCall:pstn];
    [self initOutgoingCallWithDialog];
}

/**
 * Hangup current call.
 */
-(void)hangupCall {
    
    if (self.kandyOutgoingCall == nil) {
        [self notifyFailureResponse:kandy_calls_invalid_hangup_text_msg];
        return;
    }
    [self.kandyOutgoingCall hangupWithResponseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

/**
 * Mute/Unmute current call.
 *
 * @param mute The state of current audio call.
 */

- (void) doMute:(BOOL)mute {
    
    if (self.kandyOutgoingCall == nil) {
        [self notifyFailureResponse:kandy_calls_invalid_hangup_text_msg];
        return;
    }
    
    if (mute && !self.kandyOutgoingCall.isMute) {
        [self.kandyOutgoingCall unmuteWithResponseCallback:^(NSError *error) {
            [self didHandleResponse:error];
        }];
    }
    else {
        [self.kandyOutgoingCall muteWithResponseCallback:^(NSError *error) {
            [self didHandleResponse:error];
        }];
    }
}

/**
 * Hold/unhold current call.
 *
 * @param hold The state of current call.
 */
- (void) doHold:(BOOL)hold {
    
    if (self.kandyOutgoingCall == nil) {
        [self notifyFailureResponse:kandy_calls_invalid_hangup_text_msg];
        return;
    }

    if (hold && !self.kandyOutgoingCall.isOnHold) {
        [self.kandyOutgoingCall unHoldWithResponseCallback:^(NSError *error) {
            [self didHandleResponse:error];
        }];
    }
    else {
        [self.kandyOutgoingCall holdWithResponseCallback:^(NSError *error) {
            [self didHandleResponse:error];
        }];
    }
    
}

/**
 * Whether or not The sharing video is enabled.
 *
 * @param video The state of current video call.
 */

- (void) doEnableVideo:(BOOL)isVideoOn {
    
    if (self.kandyOutgoingCall == nil) {
        [self notifyFailureResponse:kandy_calls_invalid_hangup_text_msg];
        return;
    }

    if (isVideoOn && !self.kandyOutgoingCall.isSendingVideo) {
        [self.kandyOutgoingCall stopVideoSharingWithResponseCallback:^(NSError *error) {
            [self didHandleResponse:error];
        }];
    }
    else {
        [self.kandyOutgoingCall startVideoSharingWithResponseCallback:^(NSError *error) {
            [self didHandleResponse:error];
        }];
    }
}

/**
 * Accept a coming call.
 */

- (void) doAcceptCallWithVideo:(BOOL)isWithVideo {
    if (self.kandyIncomingCall == nil) {
        [self notifyFailureResponse:kandy_calls_invalid_hangup_text_msg];
        return;
    }
 
    [self.kandyIncomingCall accept:isWithVideo withResponseBlock:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

/**
 * Reject a coming call.
 */
-(void) doRejectCall {
    
    if (self.kandyIncomingCall == nil) {
        [self notifyFailureResponse:kandy_calls_invalid_hangup_text_msg];
        return;
    }
    
    [self.kandyIncomingCall rejectWithResponseBlock:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

/**
 * Ignore a coming call.
 */
-(void) doIgnoreCall {
    
    if (self.kandyIncomingCall == nil) {
        [self notifyFailureResponse:kandy_calls_invalid_hangup_text_msg];
        return;
    }
    
    [self.kandyIncomingCall ignoreWithResponseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

/**
 * Send a message to the recipient.
 *
 * @param user The recipient.
 * @param text The message text
 */

-(void)sendChatWithMessage:(NSString *)textMessage toUser:(NSString *)recipient {
    
    if (textMessage && [textMessage isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_error_message];
    }
    
    if (recipient && [recipient isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_error_message];
    }
    
    KandyRecord * kandyRecord = [[KandyRecord alloc] initWithURI:recipient];
    KandyChatMessage *chatMessage = [[KandyChatMessage alloc] initWithText:textMessage recipient:kandyRecord];
    
    [[Kandy sharedInstance].services.chat sendChat:chatMessage
          progressCallback:^(KandyTransferProgress *transferProgress) {
              NSLog(@"Uploading message. Recipient - %@, UUID - %@, upload percentage - %ld", chatMessage.recipient.uri, chatMessage.uuid, (long)transferProgress.transferProgressPercentage);
          }
          responseCallback:^(NSError *error) {
              [self didHandleResponse:error];
    }];
}

-(void)sendSMSWithMessage:(NSString *)textMessage toUser:(NSString *)recipient {
    
    if (textMessage && [textMessage isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_error_message];
    }
    
    if (recipient && [recipient isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_error_message];
    }
    
    KandySMSMessage *smsMessage = [[KandySMSMessage alloc] initWithText:textMessage recipient:recipient displayName:recipient];
    [[Kandy sharedInstance].services.chat sendSMS:smsMessage responseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

-(void)pullEvents {
    [[Kandy sharedInstance].services.chat pullEventsWithResponseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

/**
 * Mark message as read.
 *
 * @param arrKandyEvents The uuid of the message.
 */

-(void)ackEvents:(NSArray*)arrKandyEvents {
    [[Kandy sharedInstance].services.chat markAsReceived:arrKandyEvents withResponseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

/*
 * Presence service
 */

- (void) getPresenceInfoByUser:(NSString *)userlist
{
    if (userlist && [userlist isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_error_message];
    }

    KandyRecord* kandyRecord = [[KandyRecord alloc]initWithURI:userlist andWithType:EKandyRecordType_contact andAssociationType:EKandyRecordAssociationType_community];
    
    [[Kandy sharedInstance].services.presence getPresenceForRecords:[NSArray arrayWithObject:kandyRecord] withResponseCallback:^(NSError *error, NSArray *presenceObjects, NSArray * missingPresenceKandyRecords) {
        [self didHandleResponse:error];
    }];
}

//Contact service
-(void)getUsersFromDeviceContacts {
    [[Kandy sharedInstance].services.contacts getDeviceContactsWithResponseCallback:^(NSError *error, NSArray *kandyContacts) {
        if (error) {
            [self notifyFailureResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[self enumerateContactDetails:kandyContacts] withCallbackID:self.callbackID];
        }
    }];
}

- (void) getDomainContacts {
    [[Kandy sharedInstance].services.contacts getDomainDirectoryContactsWithResponseCallback:^(NSError *error, NSArray *kandyContacts) {
        if (error) {
            [self didHandleResponse:error];
        } else {
            [self notifySuccessResponse:[self enumerateContactDetails:kandyContacts] withCallbackID:self.callbackID];
        }
    }];
}
- (void) getFilteredDomainDirectoryContacts:(NSString*)strSearch fields:(EKandyDomainContactFilter)fields caseSensitive:(BOOL)caseSensitive {
    
    [[Kandy sharedInstance].services.contacts getFilteredDomainDirectoryContactsWithTextSearch:strSearch filterType:fields caseSensitive:caseSensitive responseCallback:^(NSError *error, NSArray *kandyContacts) {
        if (error) {
            [self didHandleResponse:error];
        } else {
            [self notifySuccessResponse:[self enumerateContactDetails:kandyContacts] withCallbackID:self.callbackID];
        }
    }];
}

/*
 * Push Notification
 */

-(void)enableKandyPushNotification
{
    NSData* deviceToken = [[NSUserDefaults standardUserDefaults]objectForKey:@"deviceToken"];
    NSString* bundleId = [[NSBundle mainBundle]bundleIdentifier];
    [[Kandy sharedInstance].services.push enableRemoteNotificationsWithToken:deviceToken bundleId:bundleId responseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

- (void) disableKandyPushNotification {
    NSString* bundleId = [[NSBundle mainBundle]bundleIdentifier];
    [[Kandy sharedInstance].services.push disableRemoteNotificationsWithBundleId:bundleId responseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}
@end
