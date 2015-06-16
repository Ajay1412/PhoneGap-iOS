//
//  OpenChatAttachment.m
//  Kandy
//
//  Created by Srinivasan Baskaran on 6/11/15.
//
//

#import "OpenChatAttachment.h"
#import "KandyUtil.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MapKit/MapKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface OpenChatAttachment () <ABNewPersonViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *ivImage;
@property (nonatomic, strong) MPMoviePlayerController * moviePlayer;
@property (nonatomic, strong) AVAudioPlayer * audioPlayer;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) ABNewPersonViewController * vcAddrUi;
@end

@implementation OpenChatAttachment

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Image Attachment";
    UIBarButtonItem * btnClose = [[UIBarButtonItem alloc]
                                  initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(didTapClose:)];
    self.navigationItem.leftBarButtonItem = btnClose;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) openAttachementByType:(ChatAttachementType)type {
    
    switch (type) {
        case image: {
            self.ivImage.image = self.image;
        }
            break;
        case video: {

            self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.urlMovie];
            [self.view addSubview:self.moviePlayer.view];
            [self.moviePlayer.view setFrame:self.view.frame];
            [self.moviePlayer prepareToPlay];
            [self.moviePlayer play];
        }
            break;
        case audio: {
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.urlAudio error:nil];
            self.audioPlayer.numberOfLoops = -1;
            [self.audioPlayer play];
        }
            break;
        case location: {
            float  zoomLevel = 0.5;
            MKCoordinateRegion region = MKCoordinateRegionMake (self.location.coordinate, MKCoordinateSpanMake (zoomLevel, zoomLevel));
            [self.mapView setRegion: [self.mapView regionThatFits: region] animated: YES];
            
            MKPointAnnotation * point = [[MKPointAnnotation alloc]init];
            point.coordinate = self.location.coordinate;
            [self.mapView addAnnotation:point];
        }
            break;
        case contact: {
            NSString *vCardString = [NSString stringWithContentsOfFile:self.vcfFilePath encoding:NSUTF8StringEncoding error:nil ];
            
            CFDataRef vCardData = (__bridge CFDataRef)[vCardString dataUsingEncoding:NSUTF8StringEncoding];
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(addressBook);
            
            CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
            ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, 0);
            self.vcAddrUi = [[ABNewPersonViewController alloc] init];
            self.vcAddrUi.newPersonViewDelegate = self;
            self.vcAddrUi.displayedPerson = person;
            CFRelease(person);
            CFRelease(vCardPeople);
            CFRelease(defaultSource);
            CFRelease(addressBook);
            [self.vcAddrUi willMoveToParentViewController:self];
            [self.view addSubview:self.vcAddrUi.view];
            self.vcAddrUi.view.frame = self.view.frame;
            [self addChildViewController:self.vcAddrUi];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - IBActions

-(void)didTapClose:(id)sender{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - ABNewPersonViewControllerDelegate

-(void) newPersonViewController:(ABNewPersonViewController *)newPersonView
       didCompleteWithNewPerson:(ABRecordRef)person
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
