//
//  KandyPlugin.m
//  KandyPlugin
//
//  Created by Srinivasan Baskaran on 2/6/15.
//
//

#import "KandyPlugin.h"
#import "CallViewController.h"
#import "KandyUtil.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "OpenChatAttachment.h"

@interface KandyPlugin() <KandyCallServiceNotificationDelegate, KandyChatServiceNotificationDelegate, KandyContactsServiceNotificationDelegate, KandyAccessNotificationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, CLLocationManagerDelegate, MPMediaPickerControllerDelegate>

/**
 * Kandy response listeners *
 */
@property (nonatomic) NSString *callbackID;
@property (nonatomic) UIView *viewRemoteVideo;
@property (nonatomic) UIView *viewLocalVideo;

/**
 * Kandy Plugin configuration properties *
 */

@property (nonatomic) NSString *startWithVideo;
@property (nonatomic) NSString *downloadPath;
@property (assign) int mediaSizePicker;
@property (nonatomic) NSString *downloadPolicy;
@property (assign) int downloadThumbnailSize;
@property (nonatomic) NSString *kandyHostUrl;
@property (nonatomic) NSString *showNativeVideoPage;

/**
 * Kandy incoming and out going delegate to set
 */
@property (assign) id <KandyOutgoingCallProtocol> kandyOutgoingCall;
@property (nonatomic, strong) id <KandyIncomingCallProtocol> kandyIncomingCall;
@property (nonatomic) UIImagePickerController *pickerView;

//UIStoryboard or UIfile
@property (nonatomic) UIStoryboard * kandyStoryboard;

/**
 * The Incoming options action sheet for Kandy *
 */
@property (nonatomic) UIActionSheet * incomingCallOPtions;


/**
 * The {@link CallbackContext} for Kandy listeners *
*/
@property (nonatomic) NSString * kandyConnectServiceNotificationCallback;
@property (nonatomic) NSString * kandyCallServiceNotificationCallback;
@property (nonatomic) NSString * kandyCallServiceNotificationPluginCallback;
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
@property (assign) BOOL hasNativeCallView;
@property (assign) BOOL hasNativeAcknowledgement;

//NSTimer object for schedule pull events
@property (nonatomic) NSTimer *schedulePullEvent;

@property (nonatomic) NSArray *connectionState;
@property (nonatomic) NSArray *callState;

//Kandy Group
@property (nonatomic) KandyGroup *kandyGroup;
@end


@implementation KandyPlugin

#pragma mark - pluginInitialize

- (void)pluginInitialize {
    [self InitializeObjects];
}

- (void) InitializeObjects {
    
    self.startVideoCall = YES;
    self.hasNativeAcknowledgement = YES;
    
    self.connectionState = @[@"DISCONNECTING", @"DISCONNECTED", @"CONNECTING", @"CONNECTED"];
    self.callState = @[@"INITIAL", @"RINGING", @"DIALING", @"TALKING", @"TERMINATED", @"ON_DOUBLE_HOLD", @"REMOTELY_HELD", @"ON_HOLD"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotificationsWithDeviceToken:) name:CDVRemoteNotification object:nil];
}

/**
 * Register listeners to receive events from Kandy background service.
 */
- (void) registerNotifications {
    //Connect service
    [[Kandy sharedInstance].access registerNotifications:self];
    [[Kandy sharedInstance].services.call registerNotifications:self];
    [[Kandy sharedInstance].services.chat registerNotifications:self];
    [[Kandy sharedInstance].services.contacts registerNotifications:self];
}

/**
 * Unregister listeners out of Kandy background service.
 */
- (void) unRegisterNotifications {
    [[Kandy sharedInstance].access unregisterNotifications:self];
    [[Kandy sharedInstance].services.call unregisterNotifications:self];
    [[Kandy sharedInstance].services.chat unregisterNotifications:self];
    [[Kandy sharedInstance].services.contacts unregisterNotifications:self];
}

#pragma mark - Public Plugin Methods

-(void) configurations:(CDVInvokedUrlCommand *)command {
    NSArray *config = command.arguments;
    NSLog(@"configurations Variables %@", config);
    if (config && [config count] > 0) {
        NSDictionary *configvariables = [config objectAtIndex:0];
        self.hasNativeCallView = [[configvariables objectForKey:@"hasNativeCallView"] boolValue];
        self.hasNativeAcknowledgement = [[configvariables objectForKey:@"acknowledgeOnMsgRecieved"] boolValue];
    }
}

- (void) makeToast:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    //[self.commandDelegate runInBackground:^{
        __block NSString * message = [params objectAtIndex:0];
        [self showNativeAlert:message];
    //}];
}
- (void) setKey:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * apikey = [params objectAtIndex:0];
        __block NSString *apisecret = [params objectAtIndex:1];
        [KandyUtil saveAPIKey:apikey secret:apisecret];
        [Kandy initializeSDKWithDomainKey:apikey domainSecret:apisecret];
    }];
}

- (void) connectServiceNotificationCallback:(CDVInvokedUrlCommand *)command {
    self.kandyConnectServiceNotificationCallback = command.callbackId;
}
- (void) callServiceNotificationCallback:(CDVInvokedUrlCommand *)command {
    self.kandyCallServiceNotificationCallback = command.callbackId;
}
- (void) callServiceNotificationPluginCallback:(CDVInvokedUrlCommand *)command {
    self.kandyCallServiceNotificationPluginCallback = command.callbackId;
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
    [self notifySuccessResponse:[self.connectionState objectAtIndex:[Kandy sharedInstance].access.connectionState] withCallbackID:command.callbackId];
}

/**
 * Load previous session.
 *
 */

//Session Service
- (void) getSession:(CDVInvokedUrlCommand *)command {

    NSArray *userinfo = [Kandy sharedInstance].sessionManagement.provisionedUsers;
    if ([userinfo count] > 0) {
        KandyUserInfo * kandyUserInfo = [userinfo objectAtIndex:0];
        NSDictionary *jsonObj = @{
                                 @"id": kandyUserInfo.userId,
                                 @"name": kandyUserInfo.record.userName,
                                 @"domain": kandyUserInfo.record.domain,
                                 };
        [self notifySuccessResponse:jsonObj withCallbackID:command.callbackId];
    }
}

//** Call Service **/

/**
 * Create a voip call.
 *
 * @param username The username of the callee.
 */
- (void) createVoipCall:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString *phone = [params objectAtIndex:0];
        __block BOOL isVideo = NO;
        isVideo = [[params objectAtIndex:1] boolValue];
        if (phone) {
            [self establishVoipCall:phone andWithStartVideo:isVideo];
        }
    }];
}


- (void) showLocalVideo:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        int xpos = [[params objectAtIndex:0] intValue];
        int ypos = [[params objectAtIndex:1] intValue];
        float width = [[params objectAtIndex:2] floatValue];
        float height = [[params objectAtIndex:3] floatValue];
        [self setLocalVideoFrame:CGRectMake(xpos, ypos, width, height)];
    }];
}
- (void) hideLocalVideo:(CDVInvokedUrlCommand *)command {
    [self removeLocalVideoView];
}
- (void) showRemoteVideo:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        int xpos = [[params objectAtIndex:0] intValue];
        int ypos = [[params objectAtIndex:1] intValue];
        float width = [[params objectAtIndex:2] floatValue];
        float height = [[params objectAtIndex:3] floatValue];
        [self setRemoteVideoFrame:CGRectMake(xpos, ypos, width, height)];
    }];
}

- (void) hideRemoteVideo:(CDVInvokedUrlCommand *)command {
    [self removeRemoteVideoView];
}

/**
 * Create a PSTN call.
 *
 * @param number The number phone of the callee.
 */
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
- (void) hangup:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self hangupCall];
}
- (void) mute:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doMute:YES];
}
- (void) UnMute:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doMute:NO];
}
- (void) hold:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doHold:YES];
}
- (void) unHold:(CDVInvokedUrlCommand *)command {
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
- (void) accept:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doAcceptCallWithVideo:self.startVideoCall];
}
- (void) reject:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self doRejectCall];
}
- (void) ignore:(CDVInvokedUrlCommand *)command {
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

- (void) openAttachment:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString *uri = [params objectAtIndex:0];
        __block NSString *mimetype = [params objectAtIndex:1];
        [self openAttachmentWithURI:uri mimeType:mimetype];
    }];
}

- (void) sendAttachment:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:3];
    [self.commandDelegate runInBackground:^{
        [[KandyUtil sharedInstance] setChatInputData:params];
        [self showAttachementTypes];
    }];
}

- (void) pickAudio:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self pickVideo];
}
- (void) sendAudio:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        [[KandyUtil sharedInstance] setChatInputData:params];
        [self sendAudio];
    }];
}
- (void) pickVideo:(CDVInvokedUrlCommand *)command; {
    self.callbackID = command.callbackId;
    [self pickVideo];
}
- (void) sendVideo:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        [[KandyUtil sharedInstance] setChatInputData:params];
        [self sendVideo];
    }];
}
- (void) pickImage:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self pickImage];
}
- (void) sendImage:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        [[KandyUtil sharedInstance] setChatInputData:params];
        [self sendImage];
    }];
}
- (void) pickContact:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self pickContact];
}
- (void) sendContact:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        [[KandyUtil sharedInstance] setChatInputData:params];
        [self sendContact];
    }];
}
- (void) sendCurrentLocation:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        [[KandyUtil sharedInstance] setChatInputData:params];
        [self sendCurrentLocation];
    }];
}
- (void) sendLocation:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:4];
    [self.commandDelegate runInBackground:^{
        [[KandyUtil sharedInstance] setChatInputData:params];
        [self sendLocationObject:nil];
    }];
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
    [self.commandDelegate runInBackground:^{
        [self pullEvents];
    }];
}

- (void) startSchedulePullEvents:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block float seconds = [[params objectAtIndex:0] floatValue];
        [self stopSchedulePullEvents:nil];
        [self getPullEventsBySeconds:seconds];
    }];
}

- (void) stopSchedulePullEvents:(CDVInvokedUrlCommand *)command {
    if ([self.schedulePullEvent isValid]) {
        [self.schedulePullEvent invalidate];
        self.schedulePullEvent = nil;
    }
}

- (void) downloadMedia:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString *uuid = [params objectAtIndex:0];
        [self downloadMediaFromChat:uuid];
    }];
}

- (void) downloadMediaThumbnail:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * uuid = [params objectAtIndex:0];
        __block NSString * size = [params objectAtIndex:1];
        [self downloadMediaThumbnailFromChat:uuid size:size];
    }];
}
- (void) cancelMediaTransfer:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString *uuid = [params objectAtIndex:0];
        [self cancelMedia:uuid];
    }];
}

//Group Service
- (void) createGroup:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupname = [params objectAtIndex:0];
        [self createGroupName:groupname];
    }];
}
- (void) getMyGroups:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self.commandDelegate runInBackground:^{
        [self getMyGroups];
    }];
}
- (void) getGroupById:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        [self groupDetailsById:groupid];
    }];
}
- (void) updateGroupName:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        __block NSString * newname = [params objectAtIndex:1];
        [self updateGroupName:newname byGroupID:groupid];
    }];
}
- (void) updateGroupImage:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        __block NSString * uri = [params objectAtIndex:1];
        [self updateGroupImagePath:uri byGroupID:groupid];
    }];
}
- (void) removeGroupImage:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        [self removeGroupImageByID:groupid];
    }];
}
- (void) downloadGroupImage:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        [self downloadGroupImageByGroupID:groupid];
    }];
}
- (void) downloadGroupImageThumbnail:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        __block NSString * size = [params objectAtIndex:1];
        [self downloadGroupImageThumbnailByGroupID:groupid size:size];
    }];
}

- (void) muteGroup:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        [self muteGroupByID:groupid];
    }];
}
- (void) unmuteGroup:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        [self unmuteGroupByID:groupid];
    }];
}
- (void) destroyGroup:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        [self destroyGroupByID:groupid];
    }];
}
- (void) leaveGroup:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:1];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        [self leaveGroupByID:groupid];
    }];
}
- (void) removeParticipants:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        __block NSArray * participant = [params objectAtIndex:1];
        [self removeParticipants:participant ByID:groupid];
    }];
}
- (void) muteParticipants:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        __block NSArray * participant = [params objectAtIndex:1];
        [self muteParticipants:participant ByID:groupid];
    }];
}
- (void) unmuteParticipants:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        __block NSArray * participant = [params objectAtIndex:1];
        [self unmuteParticipants:participant ByID:groupid];
    }];
}
- (void) addParticipants:(CDVInvokedUrlCommand *)command {
    NSArray *params = command.arguments;
    [self validateInvokedUrlCommand:command withRequiredInputs:2];
    [self.commandDelegate runInBackground:^{
        __block NSString * groupid = [params objectAtIndex:0];
        __block NSArray * participant = [params objectAtIndex:1];
        [self addParticipants:participant ByID:groupid];
    }];
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
- (void) enable:(CDVInvokedUrlCommand *)command {
    self.callbackID = command.callbackId;
    [self.commandDelegate runInBackground:^{
        [self enableKandyPushNotification];
    }];

}
- (void) disable:(CDVInvokedUrlCommand *)command {
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
    KandyAreaCode * kandyAreaCode = [[KandyAreaCode alloc] initWithISOCode:isocode andCountryName:@"" andPhonePrefix:@""];
    [[Kandy sharedInstance].provisioning requestCode:kandyAreaCode phoneNumber:phoneno responseCallback:^(NSError *error, NSString *destinationToValidate) {
        [self didHandleResponse:error];
    }];
}

- (void) validateWithOTP:(NSString *)otp andPhone:(NSString *)phoneno andISOCountryCode:(NSString *)isocode  {
    KandyAreaCode * kandyAreaCode = [[KandyAreaCode alloc] initWithISOCode:isocode andCountryName:@"" andPhonePrefix:@""];
    [[Kandy sharedInstance].provisioning validate:otp areaCode:kandyAreaCode destination:phoneno responseCallback:^(NSError *error, KandyUserInfo *userInfo) {
        if (error) {
            [self didHandleResponse:error];
        } else {
            NSDictionary *jsonObj = @{
                                     @"id": userInfo.userId,
                                     @"domain": userInfo.record.domain,
                                     @"username": userInfo.record.userName,
                                     @"password": userInfo.password,
                                     };
            
            [self notifySuccessResponse:jsonObj];
        }
    }];
}

- (void) deactivate {
    KandyUserInfo *userInfo = [Kandy sharedInstance].sessionManagement.provisionedUsers.lastObject;
    if(userInfo)
    {
        [[Kandy sharedInstance].provisioning deactivate:userInfo responseCallback:^(NSError *error) {
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

/**
 * Register/login the user on the server with credentials received from admin.
 *
 * @param username The username to use.
 * @param password The password to use.
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
    [[Kandy sharedInstance].access login:kandyUserInfo responseCallback:^(NSError *error) {
        if (error) {
            [self notifyFailureResponse:kandy_error_message];
        } else {
            [self registerNotifications];
            [self notifySuccessResponse:kandy_login_login_success];
        }
    }];
}

/**
 * This method unregisters user from the Kandy server.
 */
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
            NSDictionary *jsonObj = @{
                                     @"long": areaCode.countryName,
                                     @"code": areaCode.isoCode,
                                     @"short": areaCode.phonePrefix,
                                     };
            
            [self notifySuccessResponse:jsonObj];
        }
    }];
}

/*
 *  Call
 */

/**
 * Show local call video view.
 *
 * @param frame     Set localvideo position using Frame.
 */
- (void) setLocalVideoFrame:(CGRect)frame {
    // Local Video
    [self.viewLocalVideo setHidden:NO];
    [self.viewLocalVideo setFrame:frame];
    self.kandyOutgoingCall.localVideoView = self.viewLocalVideo;
    
}

/**
 * Show local call video view.
 *
 * @param frame     Set remote video position using Frame.
 */

- (void) setRemoteVideoFrame:(CGRect)frame {
    // Remote Video
    [self.viewRemoteVideo setHidden:NO];
    [self.viewRemoteVideo setFrame:frame];
    self.kandyOutgoingCall.remoteVideoView = self.viewRemoteVideo;
}

/**
 * Remote local call video view.
 */

- (void) removeLocalVideoView {
    [self.viewLocalVideo setHidden:YES];
    [self.viewLocalVideo removeFromSuperview];
}

/**
 * Remote Remote call video view.
 */

- (void) removeRemoteVideoView {
    [self.viewRemoteVideo setHidden:YES];
    [self.viewRemoteVideo removeFromSuperview];
}

-(void)establishVoipCall:(NSString *)voip andWithStartVideo:(BOOL)videoOn {
    if (voip && [voip isEqual:[NSNull null]]) {
        [self notifyFailureResponse:kandy_calls_invalid_phone_text_msg];
        return;
    }
    KandyRecord * kandyRecord = [[KandyRecord alloc] initWithURI:voip];
    self.kandyOutgoingCall = [[Kandy sharedInstance].services.call createVoipCall:kandyRecord isStartVideo:videoOn];
    [self initOutgoingCallWithDialog];
}

/**
 * Create a PSTN call.
 *
 * @param number The number phone of the callee.
 */

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


//*** CHAT SERVICE ***/

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
    [self sendChatMessage:chatMessage];
}

/**
 * Send a message to the recipient.
 *
 * @param KandyChatMessage The recipient.
 */
- (void) sendChatMessage:(KandyChatMessage *)chatMessage {
    [[Kandy sharedInstance].services.chat sendChat:chatMessage
      progressCallback:^(KandyTransferProgress *transferProgress) {
          NSLog(@"Uploading message. Recipient - %@, UUID - %@, upload percentage - %ld", chatMessage.recipient.uri, chatMessage.uuid, (long)transferProgress.transferProgressPercentage);
      }
      responseCallback:^(NSError *error) {
          [self didHandleResponse:error];
      }];
}

/**
 * Send text SMS message.
 *
 * @param recipient The recipient user.
 * @param text        The message to send.
 */
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

- (void) openAttachmentWithURI:(NSString *)uri mimeType:(NSString *)type {
    
    OpenChatAttachment * attachmentVC = nil;
    
    switch ([type intValue]) {
        case EKandyFileType_image:
        {
            attachmentVC = [self.kandyStoryboard instantiateViewControllerWithIdentifier:@"imageview"];
            attachmentVC.image = [UIImage imageWithContentsOfFile:uri];
            break;
        }
        case EKandyFileType_video:{
            attachmentVC = [self.kandyStoryboard instantiateViewControllerWithIdentifier:@"emptyview"];
            attachmentVC.urlMovie = [NSURL fileURLWithPath:uri isDirectory:NO];
            break;
        }
        case EKandyFileType_audio:{
            attachmentVC = [self.kandyStoryboard instantiateViewControllerWithIdentifier:@"emptyview"];
            attachmentVC.urlAudio = [NSURL fileURLWithPath:uri isDirectory:NO];
            break;
        }
        case EKandyFileType_location:{
            attachmentVC = [self.kandyStoryboard instantiateViewControllerWithIdentifier:@"locationview"];
            //attachmentVC.location = mediaItem.location;
            break;
        }
        case EKandyFileType_contact:{
            attachmentVC = [self.kandyStoryboard instantiateViewControllerWithIdentifier:@"emptyview"];
            attachmentVC.vcfFilePath = uri;
            break;
        }
        default:
            break;
    }
    if (attachmentVC) {
        UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:attachmentVC];
        [KandyUtil presentModalViewContriller:navigationController];
    }
}

/**
 * Pick audio by iOS default audio picker
 */

- (void) pickAudio {
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = NO;
    [KandyUtil presentModalViewContriller:mediaPicker];
}

/**
 * Send a audio message.
 */
- (void) sendAudio {
    id<KandyMediaItemProtocol> mediaItem = [[Kandy sharedInstance].services.chat.messageBuilder createVideoItem:[KandyUtil chatMediaURI] text:[KandyUtil chatMessage]];
    [self sendMediaItem:mediaItem];
}

/**
 * Pick video by iOS default video picker
 */
- (void) pickVideo {
    self.pickerView = [[UIImagePickerController alloc] init];
    self.pickerView.delegate = self;
    self.pickerView.allowsEditing = YES;
    self.pickerView.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.pickerView.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    [KandyUtil presentModalViewContriller:self.pickerView];
}

/**
 * Send a video message.
 */
- (void) sendVideo {
    id<KandyMediaItemProtocol> mediaItem = [[Kandy sharedInstance].services.chat.messageBuilder createVideoItem:[KandyUtil chatMediaURI] text:[KandyUtil chatMessage]];
    [self sendMediaItem:mediaItem];
}

/**
 * Pick image by android default gallery picker
 */
- (void) pickImage {
    self.pickerView = [[UIImagePickerController alloc] init];
    self.pickerView.delegate = self;
    self.pickerView.allowsEditing = YES;
    self.pickerView.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    self.pickerView.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    [KandyUtil presentModalViewContriller:self.pickerView];
}


/**
 * Send a image message.
 *
 */

- (void) sendImage {
    id<KandyMediaItemProtocol> mediaItem = [[Kandy sharedInstance].services.chat.messageBuilder createImageItem:[KandyUtil chatMediaURI] text:[KandyUtil chatMessage]];
    [self sendMediaItem:mediaItem];
}

- (void) pickContact {
    NSString *vcardPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"vcard.vcf"];
    [[Kandy sharedInstance].services.contacts getDeviceContactsWithResponseCallback:^(NSError *error, NSArray *kandyContacts) {
        if(kandyContacts.count > 0)
        {
            id<KandyContactProtocol> contact = [kandyContacts objectAtIndex:0];
            [[Kandy sharedInstance].services.contacts createVCardDataByContact:contact completionBlock:^(NSError *error, NSData *vCardData) {
                if(!error)
                {
                    [vCardData writeToFile:vcardPath atomically:YES];
                    NSDictionary * jsonObj = [NSDictionary dictionaryWithObjectsAndKeys:
                                              @(CONTACT_PICKER_RESULT),@"code", vcardPath, @"uri",nil];
                    [self notifySuccessResponse:jsonObj];

                } else {
                    NSDictionary * jsonObj = [NSDictionary dictionaryWithObjectsAndKeys:
                                              @(CONTACT_PICKER_RESULT),@"code", vcardPath, @"uri",nil];
                    [self notifySuccessResponse:jsonObj];
                }
            }];
        }
    }];
}

- (void) sendContact {
    id<KandyMediaItemProtocol> contactMediaItem = [[Kandy sharedInstance].services.chat.messageBuilder createContactItem:[KandyUtil chatMediaURI] text:[KandyUtil chatMessage]];
    [self sendMediaItem:contactMediaItem];
}

/**
 * Send current location.
 *
*/
- (void) sendCurrentLocation {
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.pausesLocationUpdatesAutomatically = NO;
    [locationManager startUpdatingLocation];
}

/**
 * addParticipants
 * Send a location message.
 *
*/

- (void) sendLocationObject:(CLLocation*)location {
    id<KandyMediaItemProtocol> mediaItem = [[Kandy sharedInstance].services.chat.messageBuilder createLocationItem:location text:[KandyUtil chatMessage]];
    [self sendMediaItem:mediaItem];
}

-(void)pullEvents {
    [[Kandy sharedInstance].services.chat pullEventsWithResponseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

- (void) getPullEventsBySeconds:(float)seconds {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.schedulePullEvent = [NSTimer scheduledTimerWithTimeInterval:seconds
                                             target:self
                                           selector:@selector(pullEvents)
                                           userInfo:nil
                                            repeats:YES];
        });
    });
}

- (void) downloadMediaFromChat:(NSString *)uuid {
    KandyChatMessage *kandyMessage = [KandyUtil KandyMessageFromUUID:uuid];
    [[Kandy sharedInstance].services.chat downloadMedia:kandyMessage progressCallback:^(KandyTransferProgress *transferProgress) {
            [self notifySuccessResponse:[KandyUtil dictionaryWithTransferProgress:transferProgress]];
    } responseCallback:^(NSError *error, NSString *fileAbsolutePath) {
        if (error) {
            [self notifyFailureResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:fileAbsolutePath];
        }
    }];
}
- (void) downloadMediaThumbnailFromChat:(NSString *)uuid size:(NSString *)size {
    EKandyThumbnailSize thumbsize;
    if ([size isEqual:[NSNull null]] && [size isEqualToString:@"null"]) {
        thumbsize = EKandyThumbnailSize_medium;
    }else {
        thumbsize = [size intValue];
    }
    
    [[Kandy sharedInstance].services.chat downloadMediaThumbnail:[KandyUtil KandyMessageFromUUID:uuid] thumbnailSize:thumbsize progressCallback:^(KandyTransferProgress *transferProgress) {
        [self notifySuccessResponse:[KandyUtil dictionaryWithTransferProgress:transferProgress]];
    } responseCallback:^(NSError *error, NSString *fileAbsolutePath) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:fileAbsolutePath];
        }
    }];
}
- (void) cancelMedia:(NSString *)uuid {
    [[Kandy sharedInstance].services.chat cancel:[KandyUtil KandyMessageFromUUID:uuid] responseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

// *** GROUP SERVICE **//

/**
 * Create a new group.
 *
 * @param groupName The new group name.
 */

- (void) createGroupName:(NSString *)name {
    KandyGroupParams * kandyGroupParams = [[KandyGroupParams alloc] init];
    kandyGroupParams.groupName = name;
    kandyGroupParams.groupAbsoluteImagePath = [[NSBundle mainBundle] pathForResource:@"group" ofType:@"jpeg"];
    [[Kandy sharedInstance].services.group createGroup:kandyGroupParams progressCallback:^(KandyTransferProgress *transferProgress) {
        NSLog(@"Group Image upload progress : %ld", (long)transferProgress.transferProgressPercentage);
    } responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            //Success
            self.kandyGroup = group;
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}

/**
 * Try to get the state presence of users.
 *
 */
- (void) getMyGroups {
    [[Kandy sharedInstance].services.group getMyGroupsWithResponseCallback:^(NSError *error, NSArray *groups) {
        if (error) {
            [self notifyFailureResponse:error.localizedDescription];
        } else {
            NSMutableArray *groupList = [[NSMutableArray alloc] init];
            for (KandyGroup *group in groups) {
                [groupList addObject:[KandyUtil dictionaryWithKandyGroup:group]];
            }
            [self notifySuccessResponse:groupList];
        }
    }];

}

- (void) groupDetailsById:(NSString *)groupid {

    [[Kandy sharedInstance].services.group getGroupDetails:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) updateGroupName:(NSString *)newgroupname byGroupID:(NSString *)groupid{
    [[Kandy sharedInstance].services.group updateGroupName:newgroupname groupId:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) updateGroupImagePath:(NSString *)imagepath byGroupID:(NSString *)groupid {
    [[Kandy sharedInstance].services.group updateGroupImage:imagepath groupId:[KandyUtil recordWithGroupID:groupid] progressCallback:^(KandyTransferProgress *transferProgress) {
        NSLog(@"Update group image progress : %ld", (long)transferProgress.transferProgressPercentage);
    } responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) removeGroupImageByID:(NSString *)groupid {
    [[Kandy sharedInstance].services.group removeGroupImage:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) downloadGroupImageByGroupID:(NSString *)groupid {
    [[Kandy sharedInstance].services.group downloadGroupImage:[[KandyGroup alloc] initWithGroupID:[KandyUtil recordWithGroupID:groupid]] progressCallback:^(KandyTransferProgress *transferProgress) {
        [self notifySuccessResponse:[KandyUtil dictionaryWithTransferProgress:transferProgress]];
    } responseCallback:^(NSError *error, NSString *fileAbsolutePath) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:fileAbsolutePath];
        }
    }];
}
- (void) downloadGroupImageThumbnailByGroupID:(NSString *)groupid size:(NSString *)size {
    
    EKandyThumbnailSize thumbsize;
    if ([size isEqual:[NSNull null]] && [size isEqualToString:@"null"]) {
        thumbsize = EKandyThumbnailSize_medium;
    }else {
        thumbsize = [size intValue];
    }
        
    [[Kandy sharedInstance].services.group downloadGroupThumbnail:self.kandyGroup thumbnailSize:thumbsize progressCallback:^(KandyTransferProgress *transferProgress) {
        [self notifySuccessResponse:[KandyUtil dictionaryWithTransferProgress:transferProgress]];
    } responseCallback:^(NSError *error, NSString *fileAbsolutePath) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:fileAbsolutePath];
        }
    }];
}
- (void) muteGroupByID:(NSString *)groupid {
    [[Kandy sharedInstance].services.group muteGroup:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];

}
- (void) unmuteGroupByID:(NSString *)groupid {
    
    [[Kandy sharedInstance].services.group unMuteGroup:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) destroyGroupByID:(NSString *)groupid {
    [[Kandy sharedInstance].services.group destroyGroup:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:nil];
        }
    }];
}
- (void) leaveGroupByID:(NSString *)groupid {
    [[Kandy sharedInstance].services.group leaveGroup:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:nil];
        }
    }];
}
- (void) removeParticipants:(NSArray *)participants ByID:(NSString *)groupid  {
    
    NSMutableArray * arrParticipants = [[NSMutableArray alloc] init];
    for (NSString *participantid in participants) {
        [arrParticipants addObject:[KandyUtil recordWithGroupID:participantid]];
    }
    
    [[Kandy sharedInstance].services.group removeGroupParticipants:arrParticipants groupId:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) muteParticipants:(NSArray *)participants ByID:(NSString *)groupid {
    NSMutableArray * arrParticipants = [[NSMutableArray alloc] init];
    for (NSString *participantid in participants) {
        [arrParticipants addObject:[KandyUtil recordWithGroupID:participantid]];
    }
    
    [[Kandy sharedInstance].services.group muteGroupParticipants:arrParticipants groupId:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) unmuteParticipants:(NSArray *)participants ByID:(NSString *)groupid {
    NSMutableArray * arrParticipants = [[NSMutableArray alloc] init];
    for (NSString *participantid in participants) {
        [arrParticipants addObject:[KandyUtil recordWithGroupID:participantid]];
    }

    [[Kandy sharedInstance].services.group unMuteGroupParticipants:arrParticipants groupId:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
}
- (void) addParticipants:(NSArray *)participants ByID:(NSString *)groupid {
    NSMutableArray * arrParticipants = [[NSMutableArray alloc] init];
    for (NSString *participantid in participants) {
        [arrParticipants addObject:[KandyUtil recordWithGroupID:participantid]];
    }
    
    [[Kandy sharedInstance].services.group addGroupParticipants:arrParticipants groupId:[KandyUtil recordWithGroupID:groupid] responseCallback:^(NSError *error, KandyGroup *group) {
        if (error) {
            [self notifySuccessResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[KandyUtil dictionaryWithKandyGroup:group]];
        }
    }];
  
}

/**
 * Mark message as read.
 *
 * @param arrKandyEvents The uuid of the message.
 */

-(void)ackEvents:(NSArray*)arrKandyEvents {
    [[Kandy sharedInstance].services.chat markAsReceived:arrKandyEvents responseCallback:^(NSError *error) {
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

    KandyRecord* kandyRecord = [[KandyRecord alloc]initWithURI:userlist];
    [[Kandy sharedInstance].services.presence getPresenceForRecords:[NSArray arrayWithObject:kandyRecord] responseCallback:^(NSError *error, NSArray *presenceObjects, NSArray * missingPresenceKandyRecords) {
        [self didHandleResponse:error];
    }];
}

// ** CONTACT SERVICE **/

/**
 * Try to get the phones list from the contact.
 *
 */
-(void)getUsersFromDeviceContacts {
    [[Kandy sharedInstance].services.contacts getDeviceContactsWithResponseCallback:^(NSError *error, NSArray *kandyContacts) {
        if (error) {
            [self notifyFailureResponse:error.localizedDescription];
        } else {
            [self notifySuccessResponse:[self enumerateContactDetails:kandyContacts] withCallbackID:self.callbackID];
        }
    }];
}

/**
 * Try to get contact details.
 *
 */

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

/** Push Notification **/

/**
 * Enable Push Notification service.
 */

-(void)enableKandyPushNotification
{
    NSData* deviceToken = [[NSUserDefaults standardUserDefaults]objectForKey:@"deviceToken"];
    NSString* bundleId = [[NSBundle mainBundle]bundleIdentifier];
    [[Kandy sharedInstance].services.push enableRemoteNotificationsWithToken:deviceToken bundleId:bundleId responseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

/**
 * Disable Push Notification service.
 */

- (void) disableKandyPushNotification {
    NSString* bundleId = [[NSBundle mainBundle]bundleIdentifier];
    [[Kandy sharedInstance].services.push disableRemoteNotificationsWithBundleId:bundleId responseCallback:^(NSError *error) {
        [self didHandleResponse:error];
    }];
}

#pragma mark - Helper methods

- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[NSUserDefaults standardUserDefaults]setObject:deviceToken forKey:@"deviceToken"];
}
- (void) didHandleResponse:(NSError *)error {
    if (error) {
        [self notifyFailureResponse:[NSString stringWithFormat:kandy_error_message,error.code,error.description]];
    } else {
        [self notifySuccessResponse:nil];
    }
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
    }else if ([response isKindOfClass:[NSArray class]]) {
            pluginResult = [ CDVPluginResult
                            resultWithStatus: CDVCommandStatus_OK
                            messageAsArray: response
                            ];
    } else {
        pluginResult = [ CDVPluginResult
                        resultWithStatus: CDVCommandStatus_OK
                        messageAsString:response
                        ];
    }
    // Execute sendPluginResult on this plugin's commandDelegate, passing in the ...
    // ... instance of CDVPluginResult
    [pluginResult setKeepCallbackAsBool:YES];
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
    self.incomingCallOPtions.tag = 200;
    [self.incomingCallOPtions showInView:[UIApplication sharedApplication].keyWindow];
}

- (void) initOutgoingCallWithDialog {
    [self.kandyOutgoingCall establishWithResponseBlock:^(NSError *error) {
        if (error) {
            [self didHandleResponse:error];
        } else if(self.showNativeVideoPage) {
            CallViewController *callVC = [[CallViewController alloc] initWithNibName:@"CallView" bundle:nil];
            callVC.kandyCall = self.kandyOutgoingCall;
            [KandyUtil presentModalViewContriller:callVC];
        } else {
            
            // Local Video
            self.viewLocalVideo = [[UIView alloc] initWithFrame:CGRectZero];
            self.viewLocalVideo.backgroundColor = [UIColor blackColor];
            [self.webView.superview addSubview:self.viewLocalVideo];
            
            // Remote Video
            self.viewRemoteVideo = [[UIView alloc] initWithFrame:CGRectZero];
            self.viewRemoteVideo.backgroundColor = [UIColor blackColor];
            [self.webView.superview addSubview:self.viewRemoteVideo];
        }
        [self notifySuccessResponse:@"Call Init"];
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

- (void) showNativeAlert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void) sendMediaItem:(id<KandyMediaItemProtocol>)mediaItem
{
    if(mediaItem)
    {
        KandyRecord * kandyRecord = [KandyUtil getRecipientKandyRecord];
        KandyChatMessage *chatMessage = [[KandyChatMessage alloc] initWithMediaItem:mediaItem recipient:kandyRecord];
        [self sendChatMessage:chatMessage];
    }
}

- (void) showAttachementTypes {
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Send attachment:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                            @"Send image",
                            @"Send video",
                            @"Send audio",
                            @"Send Current location",
                            @"Send contact",
                            nil];
    popup.tag = 100;
    dispatch_async(dispatch_get_main_queue(), ^{
        [popup showInView:[UIApplication sharedApplication].keyWindow];
    });

}

- (void) didSelectAttachementTypeByID:(int)buttonIndex {
    
    switch (buttonIndex) {
        case image:
        {
            [self pickImage];
        }
            break;
        case video:
        {
            [self pickVideo];
        }
            break;
        case audio:
        {
            [self pickAudio];
        }
            break;
        case location:
        {
            [self sendCurrentLocation];
        }
            break;
        case contact:
        {
            [self pickContact];
        }
            break;
        default:
            break;
    }
}

- (UIStoryboard *) kandyStoryboard {
    return [UIStoryboard storyboardWithName:@"KandyPlugin" bundle:nil];
}

#pragma mark - Delegate

/**
 * The listeners for callback
 */

#pragma mark - KandyConnectServiceNotificationDelegate

-(void) connectionStatusChanged:(EKandyConnectionState)connectionStatus {
    NSDictionary *jsonObj = @{
                             @"action": @"onConnectionStateChanged",
                             @"data": [self.connectionState objectAtIndex:connectionStatus],
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyConnectServiceNotificationCallback];
}

-(void) gotInvalidUser:(NSError*)error{
    NSDictionary *jsonObj = @{
                             @"action": @"onInvalidUser",
                             @"data": error,
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyConnectServiceNotificationCallback];
}
// Handled by appDelegate
-(void) sessionExpired:(NSError*)error{
    NSDictionary *jsonObj = @{
                             @"action": @"onSessionExpired",
                             @"data": error,
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyConnectServiceNotificationCallback];
}
// Handled by appDelegate
-(void) SDKNotSupported:(NSError*)error{
    NSDictionary *jsonObj = @{
                             @"action": @"onSDKNotSupported",
                             @"data": error,
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyConnectServiceNotificationCallback];
}

#pragma mark - KandyCallServiceNotificationDelegate

/**
 *
 * @param call
 */
-(void) gotIncomingCall:(id<KandyIncomingCallProtocol>)call{
    self.kandyIncomingCall = call;
    NSDictionary *jsonObj = @{
                             @"action": @"onIncomingCall",
                             @"data": @{
                                        @"id": call.callId,
                                        @"callee":call.callee.uri
                                        }
                             };
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
    
    NSDictionary *jsonObj = @{
                             @"action": @"onCallStateChanged",
                             @"data": @{
                                     @"state": [self.callState objectAtIndex:callState],
                                     @"id": (call.callId ? call.callId : @"0"),
                                     @"callee": (call.callee.uri ? call.callee.uri : @"")
                                     }
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
    
    //TODO: Add condition for native config
    //[self.incomingCallOPtions dismissWithClickedButtonIndex:3 animated:YES];
}

/**
 *
 * @param iKandyCall
 * @param isReceivingVideo
 * @param isSendingVideo
 */
-(void) videoStateChangedForCall:(id<KandyCallProtocol>)call{
    NSDictionary *jsonObj = @{
                             @"action": @"onVideoStateChanged",
                             @"data": @{
                                     @"id": call.callId,
                                     @"callee": call.callee.uri,
                                     @"isReceivingVideo": @(call.isReceivingVideo),
                                     @"isSendingVideo": @(call.isSendingVideo)
                                     }
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}

/**
 *
 * @param call
 * @param onMute
 */
-(void) audioRouteChanged:(EKandyCallAudioRoute)audioRoute forCall:(id<KandyCallProtocol>)call{
    NSDictionary *jsonObj = @{
                             @"action": @"onAudioStateChanged",
                             @"data": @{
                                         @"id": call.callId,
                                         @"callee": call.callee.uri,
                                         @"isMute": @(call.isMute)
                                        }
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}
-(void) gotMissedCall:(id<KandyCallProtocol>)call{
    NSDictionary *jsonObj = @{
                             @"action": @"onMissedCall",
                             @"data": @{
                                     @"id": call.callId,
                                     @"callee": call.callee.uri
                                     }
                             };
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
-(void) GSMCallIncoming {
    NSDictionary *jsonObj = @{
                             @"action": @"onGSMCallIncoming"
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}

-(void) GSMCallDialing{
}
-(void) GSMCallConnected {
    NSDictionary *jsonObj = @{
                             @"action": @"onGSMCallConnected"
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}
-(void) GSMCallDisconnected {
    NSDictionary *jsonObj = @{
                             @"action": @"onGSMCallDisconnected"
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyCallServiceNotificationCallback];
}

#pragma mark - KandyChatServiceNotificationDelegate


-(void)onMessageReceived:(id<KandyMessageProtocol>)kandyMessage recipientType:(EKandyRecordType)recipientType {
    double epochTime = [@(floor([kandyMessage.timestamp timeIntervalSince1970])) longLongValue];
    
    NSDictionary *jsonObj = @{
                             @"action": @"onChatReceived",
                             @"data": @{
                                     @"UUID": kandyMessage.uuid,
                                     @"sender": kandyMessage.sender.uri,
                                     @"message": kandyMessage.mediaItem.text,
                                     @"timestamp": [NSNumber numberWithDouble:epochTime],
                                     @"type": @(recipientType)
                                     }
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
    
    if (self.hasNativeAcknowledgement) {
        [kandyMessage markAsReceivedWithResponseCallback:^(NSError *error) {
        }];
    }
}
-(void)onMessageDelivered:(KandyDeliveryAck *)ackData {

    double epochTime = [@(floor([ackData.timestamp timeIntervalSince1970])) longLongValue];

    NSDictionary *jsonObj = @{
                             @"action": @"onChatDelivered",
                             @"data" : @{
                                            @"UUID": ackData.uuid,
                                            @"timestamp": [NSNumber numberWithDouble:epochTime],
                                        }
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
}

-(void) onAutoDownloadProgress:(KandyTransferProgress*)transferProgress kandyMessage:(id<KandyMessageProtocol>)kandyMessage {
    NSDictionary *jsonObj = @{
                             @"action": @"onChatMediaAutoDownloadProgress",
                             @"data": @{
                                     @"UUID": kandyMessage.uuid,
                                     @"timestamp": kandyMessage.timestamp,
                                     @"process": @(transferProgress.transferProgressPercentage),
                                     @"state": @(transferProgress.transferState),
                                     @"byteTransfer": @(transferProgress.transferredSize),
                                     @"byteExpected": @(transferProgress.expectedSize)
                                     }
                             };
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
}

-(void) onAutoDownloadFinished:(NSError*)error fileAbsolutePath:(NSString*)path kandyMessage:(id<KandyMessageProtocol>)kandyMessage {
    NSDictionary *jsonObj;
    if(error)
    {
        jsonObj = @{
                   @"action": @"onChatMediaAutoDownloadFailed",
                   @"data": @{
                           @"error": error.description,
                           @"code": @(error.code)
                           }
                   };
    } else {
        jsonObj = @{
                   @"action": @"onChatMediaAutoDownloadSucceded",
                   @"data": @{ @"uri": kandyMessage.recipient.uri }
                   };
    }
    [self notifySuccessResponse:jsonObj withCallbackID:self.kandyChatServiceNotificationCallback];
}

#pragma mark - KandyContactsServiceNotificationDelegate

-(void)onDeviceContactsChanged {
    [self notifySuccessResponse:nil withCallbackID:self.kandyAddressBookServiceNotificationCallback];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
   
    if (popup.tag == 100)
    { // open attachment
        [self didSelectAttachementTypeByID:(int)buttonIndex];
    } else
    {
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
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *path;
    NSDictionary * jsonObj;

    if ([picker sourceType] == UIImagePickerControllerSourceTypeSavedPhotosAlbum) {
        UIImage *chosenImage = [info objectForKey:UIImagePickerControllerEditedImage];
        path = [KandyUtil saveImage:chosenImage];
        jsonObj = @{
                    @"code": @(IMAGE_PICKER_RESULT),
                    @"uri": path
                    };
    }
    
    if ([picker sourceType] == UIImagePickerControllerSourceTypePhotoLibrary) {
        NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        path = [videoUrl path];
        jsonObj = @{
                    @"code": @(VIDEO_PICKER_RESULT),
                    @"uri": path
                    };
    }

    [self notifySuccessResponse:jsonObj];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Localtion Manager Failed Error :  %@", error.description);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *location = [[CLLocation alloc] initWithLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
    [self sendLocationObject:location];
    [manager stopUpdatingLocation];
    manager.delegate = nil;
}

#pragma mark - MPMediaPickerDelegate

- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    MPMediaItem *item = [[mediaItemCollection items] objectAtIndex:0];
    NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];

    NSDictionary * jsonObj = @{
                               @"code": @(AUDIO_PICKER_RESULT),
                               @"uri": url
                               };

    [self notifySuccessResponse:jsonObj];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

@end
