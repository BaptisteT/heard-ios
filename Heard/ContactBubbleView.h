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
#import "Message.h"

@protocol ContactBubbleViewDelegate;

@interface ContactBubbleView : UIView <UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

- (id)initWithContactBubble:(Contact *)contact andFrame:(CGRect)frame;

@property (strong, nonatomic) Contact *contact;
@property (weak, nonatomic) id <ContactBubbleViewDelegate> delegate;

- (void)addUnreadMessage:(Message *)message;
- (void)setImage:(UIImage *)image;

@end

@protocol ContactBubbleViewDelegate

- (void)longPressOnContactBubbleViewStarted:(NSUInteger)contactId;

- (void)longPressOnContactBubbleViewEnded:(NSUInteger)contactId longEnough:(BOOL)longEnough;

- (void)notifiedNewMeters:(float)meters;

- (void)messageSentWithError:(BOOL)error;

@end
