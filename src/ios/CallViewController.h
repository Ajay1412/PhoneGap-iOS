//
//  CallViewController.h
//
//  Created by Genband Ltd on 04/13/15.
//  Copyright (c) 2014 Genband Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KandySDK/KandySDK.h>

@interface CallViewController : UIViewController
@property (nonatomic, strong) id <KandyCallProtocol> kandyCall;
@end
