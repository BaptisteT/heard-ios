//
//  ShareInvitationViewControllerViewController.h
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import "Message.h"

@interface ShareInvitationViewControllerViewController : UIViewController <MFMessageComposeViewControllerDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) NSString *invitationLink;
@property (nonatomic, strong) NSData *message;

@end
