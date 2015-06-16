//
//  OpenChatAttachment.h
//  Kandy
//
//  Created by Srinivasan Baskaran on 6/11/15.
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface OpenChatAttachment : UIViewController
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, strong) NSURL * urlMovie;
@property (nonatomic, strong) NSURL * urlAudio;
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, strong) NSString * vcfFilePath;
@end
