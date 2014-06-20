//
//  MessageBubbleView.h
//  Heard
//
//  Created by Baptiste Truchot on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Message.h"

@interface MessageBubbleView : UIImageView <UIGestureRecognizerDelegate, AVAudioPlayerDelegate>

- (id)initWithMessage:(Message *)message;

@end
