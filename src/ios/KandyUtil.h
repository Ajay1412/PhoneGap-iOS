//
//  KandyUtil.h
//  Kandy
//
//  Created by Srinivasan Baskaran on 5/11/15.
//
//

#import <Foundation/Foundation.h>
#import <KandySDK/KandySDK.h>


// Kandy PhoneGap Plugin String

extern NSString *kandy_error_message;
extern NSString *kandy_login_login_success;
extern NSString *kandy_login_logout_success;
extern NSString *kandy_login_empty_username_text;
extern NSString *kandy_login_empty_password_text;

extern NSString *kandy_calls_local_video_label;
extern NSString *kandy_calls_checkbox_label;
extern NSString *kandy_calls_state_video_label;
extern NSString *kandy_calls_state_audio_label;
extern NSString *kandy_calls_state_calls_label;
extern NSString *kandy_calls_hold_label;
extern NSString *kandy_calls_unhold_label;
extern NSString *kandy_calls_mute_label;
extern NSString *kandy_calls_unmute_label;
extern NSString *kandy_calls_video_label;
extern NSString *kandy_calls_novideo_label;
extern NSString *kandy_calls_call_button_label;
extern NSString *kandy_calls_hangup_button_label;
extern NSString *kandy_calls_receiving_video_state;
extern NSString *kandy_calls_sending_video_state;
extern NSString *kandy_calls_audio_state;
extern NSString *kandy_calls_phone_number_hint;
extern NSString *kandy_calls_invalid_phone_text_msg;
extern NSString *kandy_calls_invalid_domain_text_msg;
extern NSString *kandy_calls_invalid_hangup_text_msg;
extern NSString *kandy_calls_invalid_hold_text_msg;
extern NSString *kandy_calls_invalid_mute_call_text_msg;
extern NSString *kandy_calls_invalid_video_call_text_msg;
extern NSString *kandy_calls_attention_title_text;
extern NSString *kandy_calls_full_user_id_message_text;
extern NSString *kandy_calls_answer_button_label;
extern NSString *kandy_calls_ignore_incoming_call_button_label;
extern NSString *kandy_calls_reject_incoming_call_button_label;
extern NSString *kandy_calls_incoming_call_popup_message_label;
extern NSString *kandy_calls_remote_video_label;
extern NSString *kandy_chat_phone_number_verification_text;

//NSArray *attachementType = @[@"image",@"video",@"audio",@"location",@"contact"];
//Chat - Attachment
typedef enum {
    image = 0,
    video,
    audio,
    location,
    contact
}ChatAttachementType;

typedef enum {
    CONTACT_PICKER_RESULT = 1001,
    IMAGE_PICKER_RESULT = 1002,
    VIDEO_PICKER_RESULT = 1003,
    AUDIO_PICKER_RESULT = 1004,
    FILE_PICKER_RESULT = 1005
}ChatAttachementResult;

@interface KandyUtil : NSObject

@property (nonatomic) NSArray *chatInputData;

+ (KandyUtil *) sharedInstance;
+ (KandyRecord *) getRecipientKandyRecord;
+ (ChatAttachementType) indexOfChatAttachementType;
+ (NSString *) chatMediaURI;
+ (NSString *) chatRecipient;
+ (NSString *) chatMessage;
+ (NSString *) chatAttachmentFileType;
+ (NSString *) saveImage:(UIImage *)image;
+ (void) saveAudioVideo:(NSData *)data;
+ (void) saveAPIKey:(NSString *)key secret:(NSString *)secret;
+ (NSDictionary *) dictionaryWithKandyGroup:(KandyGroup *)group;
+ (NSDictionary *) dictionaryWithKandyRecord:(KandyRecord *)record;
+ (KandyRecord *) recordWithGroupID:(NSString *)groupid;
+ (KandyChatMessage *) KandyMessageFromUUID:(NSString *)uuid;
+ (NSDictionary *) dictionaryWithTransferProgress:(KandyTransferProgress *)progress;
+ (void) presentModalViewContriller:(id)viewcontroller;
+ (NSArray *)parseParticipants:(NSArray *)participants;
@end
