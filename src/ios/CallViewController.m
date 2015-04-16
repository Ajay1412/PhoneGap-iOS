//
//  CallViewController.m
//
//  Created by Genband Ltd on 04/13/15.
//  Copyright (c) 2014 Genband Ltd. All rights reserved.
//

#import "CallViewController.h"

@interface CallViewController () <KandyCallServiceNotificationDelegate>
@property (weak, nonatomic) IBOutlet UILabel *lblCallee;
@property (weak, nonatomic) IBOutlet UIView *viewRemoteVideo;
@property (weak, nonatomic) IBOutlet UIView *viewLocalVideo;
@property (weak, nonatomic) IBOutlet UILabel *lblCallState;
@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title =  @"Call";
    [[Kandy sharedInstance].services.call registerNotifications:self];
}
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupGui];
}
-(void)viewDidDisappear:(BOOL)animated{
    [[Kandy sharedInstance].services.call unregisterNotifications:self];
    [super viewDidDisappear:animated];
}

#pragma mark - Public

-(void)refresh{
    [self setupGui];
}

#pragma mark - Using Kandy SDK

-(void)setupGui{
    NSString * strCalleeTitle;
    if (self.kandyCall.isIncomingCall) {
        strCalleeTitle = @"Caller :";
    } else {
        strCalleeTitle = @"Destination :";
    }
    self.lblCallee.text = [NSString stringWithFormat:@"%@ %@", strCalleeTitle, self.kandyCall.callee.uri];
    self.kandyCall.remoteVideoView = self.viewRemoteVideo;
    self.kandyCall.localVideoView = self.viewLocalVideo;
    [self updateCallStateLabel:self.kandyCall.callState];
}

-(void)updateCallStateLabel:(EKandyCallState)kandyCallState{
    switch (kandyCallState) {
        case EKandyCallState_initialized:
            self.lblCallState.text = @"Initialized";
            break;
        case EKandyCallState_ringing:
            self.lblCallState.text = @"Ringing";
            break;
        case EKandyCallState_dialing:
            self.lblCallState.text = @"Dialing";
            break;
        case EKandyCallState_talking:
            self.lblCallState.text = @"Talking";
            break;
        case EKandyCallState_terminated:
            self.lblCallState.text = @"Terminating";
            break;
        case EKandyCallState_notificationWaiting:
            self.lblCallState.text = @"Notification Waiting";
            break;
        case EKandyCallState_switchingCall:
            self.lblCallState.text = @"Switching Call";
            break;
        case EKandyCallState_unknown:
            self.lblCallState.text = @"Unknown";
            break;
        default:
            break;
    }
}

-(void)hangupCall{
    [self.kandyCall hangupWithResponseCallback:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:error.localizedDescription
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - IBActions
- (IBAction)callVCDidClose:(id)sender {
    if (self.kandyCall)
    {
        [self hangupCall];
    }
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)didTapHangup:(id)sender {
    [self hangupCall];
}

- (IBAction)didTapOptions:(id)sender {

}

#pragma mark - KandyCallServiceNotificationDelegate

-(void) gotIncomingCall:(id<KandyIncomingCallProtocol>)call{
}

-(void) gotMissedCall:(id<KandyCallProtocol>)call{
}

-(void) stateChanged:(EKandyCallState)callState forCall:(id<KandyCallProtocol>)call{
    [self updateCallStateLabel:callState];
    if (callState == EKandyCallState_terminated) {
        KandyCallActivityRecord * kandyCallActivityRecord = [call createActivityRecord];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Call Information"
                                                        message:kandyCallActivityRecord.description
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
         [alert show];
    }
}

-(void) participantsChanged:(NSArray*)participants forCall:(id<KandyCallProtocol>)call{
}
-(void) videoStateChangedForCall:(id<KandyCallProtocol>)call{
}
-(void) audioRouteChanged:(EKandyCallAudioRoute)audioRoute forCall:(id<KandyCallProtocol>)call{
}
-(void) videoCallImageOrientationChanged:(EKandyVideoCallImageOrientation)newImageOrientation forCall:(id<KandyCallProtocol>)call{
}
-(void) GSMCallIncoming{
    NSLog(@"************************* Incoming GSM *************************");
}

-(void) GSMCallDialing{
}
-(void) GSMCallConnected{
    NSLog(@"************************* Connected GSM *************************");
}
-(void) GSMCallDisconnected{
}

#pragma mark - GUI

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /*if (self.vcCallOptions) {
        UITouch * touch = [touches anyObject];
        if (!CGRectContainsPoint(self.vcCallOptions.view.frame, [touch locationInView:self.view])) {
            [self callOptionsDidClose];
        }
    }*/
}

#pragma mark - CallOptionsViewControllerDelegate

-(void)callOptionsDidClose{
    /*
    [self.vcCallOptions willMoveToParentViewController:nil];
    [self.vcCallOptions removeFromParentViewController];
    [self.vcCallOptions.view removeFromSuperview];
    self.vcCallOptions = nil;
     */
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"Call Information"]) {
        [self.navigationController popViewControllerAnimated:YES];   
    }
}


@end
