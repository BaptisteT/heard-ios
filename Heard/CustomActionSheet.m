//
//  CustomActionSheet.m
//  Heard
//
//  Created by Baptiste Truchot on 7/31/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "CustomActionSheet.h"
#import "GeneralUtils.h"
#import "UIImageView+AFNetworking.h"

#define USER_PROFILE_VIEW_SIZE 60
#define USER_PROFILE_PICTURE_SIZE 50
#define USER_PROFILE_PICTURE_MARGIN 5

@interface CustomActionSheet()

@property (nonatomic, strong) UIView *titleContainer;
@property (strong, nonatomic) UIImageView *profilePicture;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, copy) void (^titleOneTapAction)();

@end

@implementation CustomActionSheet

- (id)init  
{
    // Add observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hide) name:@"UIApplicationWillResignActiveNotification" object:nil];
    return [super init];
}

- (void)addTitleViewWithUsername:(NSString *)username image:(UIImage *)image andOneTapBlock:(void(^)())oneTapBlock
{
    self.titleContainer = [[UIView alloc] initWithFrame:CGRectMake(8, -8 - USER_PROFILE_VIEW_SIZE, 304, USER_PROFILE_VIEW_SIZE)];
    self.titleContainer.layer.cornerRadius = 3;
    self.titleContainer.backgroundColor = [UIColor colorWithRed:240/256.0 green:240/256.0 blue:240/256.0 alpha:0.98];
    
    //Menu profile picture
    self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(USER_PROFILE_PICTURE_MARGIN,USER_PROFILE_PICTURE_MARGIN,USER_PROFILE_PICTURE_SIZE,USER_PROFILE_PICTURE_SIZE)];
    self.profilePicture.layer.cornerRadius = USER_PROFILE_PICTURE_SIZE/2;
    self.profilePicture.clipsToBounds = YES;
    self.profilePicture.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.profilePicture.layer.borderWidth = 0.5;
    self.profilePicture.image = image;
    [self.titleContainer addSubview:self.profilePicture];
    
    //Action sheet menu name label
    float usernameOffset = self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width + USER_PROFILE_PICTURE_MARGIN;
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(usernameOffset, 0,
                                                                   self.titleContainer.bounds.size.width - 2 * usernameOffset, self.titleContainer.bounds.size.height)];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.font = [UIFont systemFontOfSize:15.0];
    self.usernameLabel.textColor = [UIColor grayColor];
    self.usernameLabel.text = username;
    [self.titleContainer addSubview:self.usernameLabel];
    
    // Add block and action mark
    self.titleOneTapAction = oneTapBlock;
    if (oneTapBlock) {
        UILabel *actionMark = [[UILabel alloc] initWithFrame:CGRectMake(self.titleContainer.frame.size.width - 30, 0, 30, USER_PROFILE_VIEW_SIZE)];
        actionMark.text = @"\u3009";
        actionMark.textAlignment = NSTextAlignmentRight;
        actionMark.font = [UIFont fontWithName:@"Futura-CondensedExtraBold"
                                          size:22];
        actionMark.textColor = [UIColor lightGrayColor];
        [self.titleContainer addSubview:actionMark];
    }
    
    // Add title to actionsheet
    [self addSubview:self.titleContainer];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.titleContainer.frame, point)) {
        [self dismissWithClickedButtonIndex:self.numberOfButtons -1 animated:NO];
        // execute block
        if (self.titleOneTapAction)
            self.titleOneTapAction();
        return nil;
    } else {
        return [super hitTest:point withEvent:event];
    }
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    if (self.titleContainer)
        [self.titleContainer removeFromSuperview];
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

- (void) hide {
    [self dismissWithClickedButtonIndex:0 animated:NO];
}

@end
