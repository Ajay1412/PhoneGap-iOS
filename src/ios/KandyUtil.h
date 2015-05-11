//
//  KandyUtil.h
//  Kandy
//
//  Created by Srinivasan Baskaran on 5/11/15.
//
//

#import <Foundation/Foundation.h>


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

@interface KandyUtil : NSObject

@end
