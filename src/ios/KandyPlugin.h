//
//  KandyPlugin.h
//  KandyPlugin
//
//  Created by Srinivasan Baskaran on 2/6/15.
//
//

#import <UIKit/UIKit.h>
#import <Cordova/CDV.h>

@interface KandyPlugin : CDVPlugin

//configurations
- (void) configurations:(CDVInvokedUrlCommand *)command;
- (void) makeToast:(CDVInvokedUrlCommand *)command;
- (void) setKey:(CDVInvokedUrlCommand *)command;

//Callback set-up
- (void) connectServiceNotificationCallback:(CDVInvokedUrlCommand *)command;
- (void) callServiceNotificationCallback:(CDVInvokedUrlCommand *)command;
- (void) callServiceNotificationPluginCallback:(CDVInvokedUrlCommand *)command;
- (void) addressBookServiceNotificationCallback:(CDVInvokedUrlCommand *)command;
- (void) chatServiceNotificationCallback:(CDVInvokedUrlCommand *)command;
- (void) groupServiceNotificationCallback:(CDVInvokedUrlCommand *)command;
- (void) chatServiceNotificationPluginCallback:(CDVInvokedUrlCommand *)command;

//Plugin methods

//Provisioning
- (void) request:(CDVInvokedUrlCommand *)command;
- (void) validate:(CDVInvokedUrlCommand *)command;
- (void) deactivate:(CDVInvokedUrlCommand *)command;

//Login
- (void) login:(CDVInvokedUrlCommand *)command;
- (void) logout:(CDVInvokedUrlCommand *)command;
- (void) getConnectionState:(CDVInvokedUrlCommand *)command;
- (void) getSession:(CDVInvokedUrlCommand *)command;

//Call
- (void) createVoipCall:(CDVInvokedUrlCommand *)command;
- (void) showLocalVideo:(CDVInvokedUrlCommand *)command;
- (void) hideLocalVideo:(CDVInvokedUrlCommand *)command;
- (void) showRemoteVideo:(CDVInvokedUrlCommand *)command;
- (void) hideRemoteVideo:(CDVInvokedUrlCommand *)command;
- (void) createPSTNCall:(CDVInvokedUrlCommand *)command;
- (void) hangup:(CDVInvokedUrlCommand *)command;
- (void) mute:(CDVInvokedUrlCommand *)command;
- (void) UnMute:(CDVInvokedUrlCommand *)command;
- (void) hold:(CDVInvokedUrlCommand *)command;
- (void) unHold:(CDVInvokedUrlCommand *)command;
- (void) enableVideo:(CDVInvokedUrlCommand *)command;
- (void) disableVideo:(CDVInvokedUrlCommand *)command;
- (void) accept:(CDVInvokedUrlCommand *)command;
- (void) reject:(CDVInvokedUrlCommand *)command;
- (void) ignore:(CDVInvokedUrlCommand *)command;

//Chat
- (void) sendChat:(CDVInvokedUrlCommand *)command;
- (void) sendSMS:(CDVInvokedUrlCommand *)command;
- (void) openAttachment:(CDVInvokedUrlCommand *)command;
- (void) sendAttachment:(CDVInvokedUrlCommand *)command;
- (void) pickAudio:(CDVInvokedUrlCommand *)command;
- (void) sendAudio:(CDVInvokedUrlCommand *)command;
- (void) pickVideo:(CDVInvokedUrlCommand *)command;
- (void) sendVideo:(CDVInvokedUrlCommand *)command;
- (void) pickImage:(CDVInvokedUrlCommand *)command;
- (void) sendImage:(CDVInvokedUrlCommand *)command;
- (void) pickContact:(CDVInvokedUrlCommand *)command;
- (void) sendContact:(CDVInvokedUrlCommand *)command;
- (void) sendCurrentLocation:(CDVInvokedUrlCommand *)command;
- (void) sendLocation:(CDVInvokedUrlCommand *)command;
- (void) downloadMedia:(CDVInvokedUrlCommand *)command;
//- (void) cancelMediaTransfer:(CDVInvokedUrlCommand *)command;
//- (void) downloadMediaThumbnail:(CDVInvokedUrlCommand *)command;
- (void) markAsReceived:(CDVInvokedUrlCommand *)command;
- (void) pullEvents:(CDVInvokedUrlCommand *)command;
- (void) startSchedulePullEvents:(CDVInvokedUrlCommand *)command;
- (void) stopSchedulePullEvents:(CDVInvokedUrlCommand *)command;

//Group
- (void) createGroup:(CDVInvokedUrlCommand *)command;
- (void) getMyGroups:(CDVInvokedUrlCommand *)command;
- (void) getGroupById:(CDVInvokedUrlCommand *)command;
- (void) updateGroupName:(CDVInvokedUrlCommand *)command;
- (void) updateGroupImage:(CDVInvokedUrlCommand *)command;
- (void) removeGroupImage:(CDVInvokedUrlCommand *)command;
- (void) downloadGroupImage:(CDVInvokedUrlCommand *)command;
- (void) downloadGroupImageThumbnail:(CDVInvokedUrlCommand *)command;
- (void) muteGroup:(CDVInvokedUrlCommand *)command;
- (void) unmuteGroup:(CDVInvokedUrlCommand *)command;
- (void) destroyGroup:(CDVInvokedUrlCommand *)command;
- (void) leaveGroup:(CDVInvokedUrlCommand *)command;
- (void) removeParticipants:(CDVInvokedUrlCommand *)command;
- (void) muteParticipants:(CDVInvokedUrlCommand *)command;
- (void) unmuteParticipants:(CDVInvokedUrlCommand *)command;
- (void) addParticipants:(CDVInvokedUrlCommand *)command;

//Presence
- (void) presence:(CDVInvokedUrlCommand *)command;

//Location
- (void) getCountryInfo:(CDVInvokedUrlCommand *)command;
- (void) getCurrentLocation:(CDVInvokedUrlCommand *)command;

//Push
- (void) enable:(CDVInvokedUrlCommand *)command;
- (void) disable:(CDVInvokedUrlCommand *)command;

//AddressBook
- (void) getDeviceContacts:(CDVInvokedUrlCommand *)command;
- (void) getDomainContacts:(CDVInvokedUrlCommand *)command;
- (void) getFilteredDomainDirectoryContacts:(CDVInvokedUrlCommand *)command;

@end
