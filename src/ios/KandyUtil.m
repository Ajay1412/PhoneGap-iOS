//
//  KandyUtil.m
//  Kandy
//
//  Created by Srinivasan Baskaran on 5/11/15.
//
//

#import "KandyUtil.h"


 NSString *kandy_error_message = @"Response code: %d - %@";
 NSString *kandy_login_login_success = @"Login succeed";
 NSString *kandy_login_logout_success = @"Logout succeed";
 NSString *kandy_login_empty_username_text = @"Invalid username (userID@domain.com)";
 NSString *kandy_login_empty_password_text = @"Enter password";

 NSString *kandy_calls_local_video_label = @"Local video";
 NSString *kandy_calls_checkbox_label = @"Start with video";
 NSString *kandy_calls_state_video_label = @"Video state";
 NSString *kandy_calls_state_audio_label = @"Audio state";
 NSString *kandy_calls_state_calls_label = @"Calls state";
 NSString *kandy_calls_hold_label = @"hold";
 NSString *kandy_calls_unhold_label = @"unhold";
 NSString *kandy_calls_mute_label = @"mute";
 NSString *kandy_calls_unmute_label = @"unmute";
 NSString *kandy_calls_video_label = @"video";
 NSString *kandy_calls_novideo_label = @"no video";
 NSString *kandy_calls_call_button_label = @"Call";
 NSString *kandy_calls_hangup_button_label = @"Hangup";
 NSString *kandy_calls_receiving_video_state = @"Receiving video:";
 NSString *kandy_calls_sending_video_state = @"Sending video:";
 NSString *kandy_calls_audio_state = @"Audio isMute:";
 NSString *kandy_calls_phone_number_hint = @"userID@domain.com";
 NSString *kandy_calls_invalid_phone_text_msg = @"Invalid recipient (recipientID@domain.com)";
 NSString *kandy_calls_invalid_domain_text_msg = @"Wrong domain";
 NSString *kandy_calls_invalid_hangup_text_msg = @"No active calls";
 NSString *kandy_calls_invalid_hold_text_msg = @"Can not hold - No Active Call";
 NSString *kandy_calls_invalid_mute_call_text_msg = @"Can not mute - No active calls";
 NSString *kandy_calls_invalid_video_call_text_msg = @"Can not enable/disable video - No active calls";
 NSString *kandy_calls_attention_title_text = @"!!! ATTENTION !!!";
 NSString *kandy_calls_full_user_id_message_text = @"Enter full destination user id (userID@domain.com)";
 NSString *kandy_calls_answer_button_label = @"Answer";
 NSString *kandy_calls_ignore_incoming_call_button_label = @"Ignore";
 NSString *kandy_calls_reject_incoming_call_button_label = @"Reject";
 NSString *kandy_calls_incoming_call_popup_message_label = @"Incoming call from:";
 NSString *kandy_calls_remote_video_label = @"Remote video";
 NSString *kandy_chat_phone_number_verification_text = @"Invalid recipient\'s number (recipientID@domain.com)";


//Kandy Login details
 NSString *kandy_api_key = @"_kandy_api_key";
 NSString *kandy_api_secret = @"_kandy_secret";

@interface KandyUtil()

@end;


static KandyUtil *obj;
@implementation KandyUtil


+ (KandyUtil *) sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (KandyRecord *) getRecipientKandyRecord {
    KandyRecord *kandyRecord = [[KandyRecord alloc] initWithURI:[KandyUtil chatRecipient]];
    return kandyRecord;
}

+ (ChatAttachementType) indexOfChatAttachementType {
    NSArray *attachementType = @[@"image",@"video",@"audio",@"location",@"contact"];
    int typeIndex = (int) [attachementType indexOfObject:[[KandyUtil sharedInstance].chatInputData objectAtIndex:2]];
    return typeIndex;
}
+ (NSString *) chatMediaURI {
    return [[KandyUtil sharedInstance].chatInputData objectAtIndex:2];
}
+ (NSString *) chatRecipient {
    return [[KandyUtil sharedInstance].chatInputData objectAtIndex:0];
}
+ (NSString *) chatMessage {
    return [[KandyUtil sharedInstance].chatInputData objectAtIndex:1];
}
+ (NSString *) chatAttachmentFileType {
    return [[KandyUtil sharedInstance].chatInputData objectAtIndex:3];
}
+ (NSString *) saveImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5f);
    [imageData writeToFile:[[KandyUtil sharedInstance] getSavePath:@"imageItem.jpeg"]  atomically:YES];
    return [[KandyUtil sharedInstance] getSavePath:@"imageItem.jpeg"];
}
+ (void) saveAudioVideo:(NSData *)data {
    [data writeToFile:[[KandyUtil sharedInstance] getSavePath:@"videoItem.MOV"]  atomically:YES];
}
- (NSString *) getSavePath:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fullPathToFile = [documentsDirectory stringByAppendingPathComponent:filename];
    return fullPathToFile;
}

+ (void) saveAPIKey:(NSString *)key secret:(NSString *)secret {
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:kandy_api_key];
    [[NSUserDefaults standardUserDefaults] setObject:secret forKey:kandy_api_secret];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary *) dictionaryWithKandyGroup:(KandyGroup *)group {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm aaa"];
    NSString *dateString = [dateFormat stringFromDate:group.creationDate];
    NSDictionary *jsonObj = @{
                                 @"id": [KandyUtil dictionaryWithKandyRecord:group.groupId],
                                 @"name": group.name,
                                 @"creationDate": dateString,
                                 @"maxParticipantsNumber": @(group.maxParticipants),
                                 @"isGroupMuted": @(group.isMuted),
                                 @"selfParticipant": [KandyUtil parseParticipants:group.participants],
                                 @"participants": [KandyUtil parseParticipants:group.participants]
                             };

    return jsonObj;
}
+ (NSDictionary *) dictionaryWithKandyRecord:(KandyRecord *)record {
    NSDictionary *jsonObj = @{
                                @"uri" : record.uri,
                                @"type" : @(record.type),
                                @"domain": record.domain,
                                @"username": record.userName
                             };
    return jsonObj;
}

+ (KandyRecord *) recordWithGroupID:(NSString *)groupid {
    return [[KandyRecord alloc] initWithURI:groupid];
}

+ (NSArray *)parseParticipants:(NSArray *)participants {
    
    NSMutableArray * participantList = [[NSMutableArray alloc] init];
    for (KandyGroupParticipant *participant in participants) {
        NSMutableDictionary *jsonObj = [NSMutableDictionary dictionaryWithDictionary:[KandyUtil dictionaryWithKandyRecord:participant.kandyRecord]];
        [jsonObj setObject:@(participant.isAdmin) forKey:@"isAdmin" ];
        [jsonObj setObject:@(participant.isMuted) forKey:@"isMuted" ];
        [participantList addObject:jsonObj];
    }
    return participantList;
}

/**
 * Get {@link KandyChatMessage} from {@link UUID}.
 *
 * @param uuid The {@link UUID}.
 * @return The {@link KandyChatMessage}.
 */

+ (KandyChatMessage *) KandyMessageFromUUID:(NSString *)uuid {
    KandyRecord *record = [[KandyRecord alloc] initWithUsername:@"dummy@dummy.com" withDomain:@"dummy"];
    KandyChatMessage *message = [[KandyChatMessage alloc] initWithText:@"" recipient:record];
    [message updateUUID:uuid];
    return message;
}

+ (NSDictionary *) dictionaryWithTransferProgress:(KandyTransferProgress *)progress {
    NSDictionary *jsonObj = @{
                                 @"process": @(progress.transferProgressPercentage),
                                 @"state": @(progress.transferState),
                                 @"byteTransfer": @(progress.transferredSize),
                                 @"byteExpected": @(progress.expectedSize)
                             };
    return jsonObj;
}

+ (void) presentModalViewContriller:(id)viewcontroller {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [window.rootViewController presentViewController:viewcontroller animated:YES completion:nil];
}

@end
