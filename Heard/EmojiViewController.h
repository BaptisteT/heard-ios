//
//  EmojiViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 11/4/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmojiViewControllerProtocol;

@interface EmojiViewController : UIViewController

@property (strong, nonatomic) id<EmojiViewControllerProtocol> delegate;
@property (weak, nonatomic) NSArray *emojiViews;

@end

@protocol EmojiViewControllerProtocol

@end