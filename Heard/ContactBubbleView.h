//
//  FriendBubbleView.h
//  Heard
//
//  Created by Baptiste Truchot on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Contact.h"


@interface ContactBubbleView : UIImageView <UIGestureRecognizerDelegate, AVAudioRecorderDelegate>

- (id)initWithContactBubble:(Contact *)contact andFrame:(CGRect)frame;

@property (strong, nonatomic) Contact *contact;

@end
