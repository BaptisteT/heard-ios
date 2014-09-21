//
//  InviteContactsViewController.h
//  Heard
//
//  Created by Bastien Beurier on 7/16/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InviteContactsTVC.h"
#import <MessageUI/MessageUI.h>
#import "Message.h"
#import <AVFoundation/AVFoundation.h>

@interface InviteContactsViewController : UIViewController <InviteContactsTVCDelegate, UIGestureRecognizerDelegate, MFMessageComposeViewControllerDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) Message *message;
@property (strong, nonatomic) NSMutableDictionary *indexedContacts;

@end
