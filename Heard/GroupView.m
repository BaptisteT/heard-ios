//
//  GroupView.m
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "GroupView.h"
#import "Constants.h"
#import "GeneralUtils.h"
#import "UIImageView+AFNetworking.h"
#import "ImageUtils.h"
#import "SessionUtils.h"
#import "Group.h"
#import "TrackingUtils.h"

#define CONTACT_BORDER 0.5

@interface GroupView()

@property (strong, nonatomic) NSMutableArray *imageViews;

@end

@implementation GroupView

- (id)initWithGroup:(Group *)group
{
    self = [super initWithContact:nil andFrame:CGRectMake(0, 0, kContactSize, kContactSize)];
    self.group = group;
    return self;
}

- (void)sendRecording
{
    BOOL isEmoji = self.delegate.emojiData ? true : false;
    self.sendingMessageCount ++;
    [self resetDiscussionStateAnimated:NO];
        
    // Send
    [self.delegate sendMessageToContact:self];
    for (int i=0;i<self.group.memberIds.count -1;i++) {
        [TrackingUtils trackRecord:isEmoji];
    }
}

- (void)setContactPicture
{
    if (!self.group || !self.group.memberIds) {
        return;
    } else {
        self.imageView.image = nil;
        for (UIView *subview in self.imageView.subviews) {
            [subview removeFromSuperview];
        }
        NSInteger membersCount = self.group.memberIds.count -1;
        self.imageViews = [[NSMutableArray alloc] initWithCapacity:membersCount];
        int kkk = 0;
        self.pictureIsLoaded = YES;
        for (NSNumber *memberId in self.group.memberIds) {
            if ([SessionUtils getCurrentUserId] == [memberId integerValue]) {
                continue;
            }
            CGRect frame = CGRectNull; CAShapeLayer * shapeLayer = nil; UIBezierPath *path = nil;
            if (membersCount == 1) {
                frame = self.frame;
            } else if (membersCount == 2) {
                frame = CGRectMake(kkk * kContactSize/2, 0, kContactSize/2, kContactSize);
            } else if (membersCount == 3) {
                shapeLayer = [CAShapeLayer layer]; path = [UIBezierPath bezierPath];
                if (kkk == 0) {
                    frame = CGRectMake(0, 0, kContactSize/2, kContactSize/2 * 3/sqrt(3));
                    [path moveToPoint:CGPointMake(0, 0)];
                    [path addLineToPoint:CGPointMake(kContactSize/2, 0)];
                    [path addLineToPoint:CGPointMake(kContactSize/2, kContactSize/2)];
                    [path addLineToPoint:CGPointMake(0, kContactSize/2 * 3/sqrt(3))];
                } else if (kkk == 1) {
                    frame = CGRectMake(kContactSize/2, 0, kContactSize/2, kContactSize/2 * 3/sqrt(3));
                    [path moveToPoint:CGPointMake(0, 0)];
                    [path addLineToPoint:CGPointMake(kContactSize/2,0)];
                    [path addLineToPoint:CGPointMake(kContactSize/2, kContactSize/2 * 3/sqrt(3))];
                    [path addLineToPoint:CGPointMake(0, kContactSize/2)];
                } else {
                    frame = CGRectMake(0, kContactSize/2, kContactSize, kContactSize/2);
                    [path moveToPoint:CGPointMake(0,kContactSize/2 * (3/sqrt(3) -1))];
                    [path addLineToPoint:CGPointMake(0,kContactSize/2)];
                    [path addLineToPoint:CGPointMake(kContactSize, kContactSize/2)];
                    [path addLineToPoint:CGPointMake(kContactSize, kContactSize/2 * (3/sqrt(3) -1))];
                    [path addLineToPoint:CGPointMake(kContactSize/2, 0)];
                    
                }
                shapeLayer.path = path.CGPath;
            } else if (membersCount == 4) {
                frame = CGRectMake(kkk % 2 ? kContactSize/2 : 0, kkk < 2 ? 0 : kContactSize/2, kContactSize/2, kContactSize/2);
            } else if (membersCount > 4) {
                if (kkk < 3) {
                   frame = CGRectMake(kkk % 2 ? kContactSize/2 : 0, kkk < 2 ? 0 : kContactSize/2, kContactSize/2, kContactSize/2);
                } else if (kkk == 3) {
                    // label
                    UILabel *moreMembersLabel = [[UILabel alloc] initWithFrame:CGRectMake(kContactSize/2+kContactSize/8,kContactSize/2, kContactSize/2, kContactSize/2)];
                    moreMembersLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0];
                    moreMembersLabel.text = [NSString stringWithFormat:@"+%lu",membersCount-3];
                    [self.imageView addSubview:moreMembersLabel];
                }
            }
            kkk ++;
            if (!CGRectIsNull(frame)) {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
                if (shapeLayer) {
                    imageView.layer.masksToBounds = YES;
                    imageView.layer.mask = shapeLayer;
                } else {
                    imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
                    imageView.layer.borderWidth = CONTACT_BORDER;
                }
                imageView.clipsToBounds = YES;
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                [self.imageViews addObject:imageView];
                [self.imageView addSubview:imageView];
                NSURL *url = [GeneralUtils getUserProfilePictureURLFromUserId:[memberId integerValue]];
                NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
                __weak __typeof(imageView)weakImageView = imageView;
                __weak __typeof(self)weakSelf = self;
                
                //Fade in profile picture
                [imageView setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    [UIView transitionWithView:weakImageView
                                      duration:1.0f
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{[weakImageView setImage:image];}
                                    completion:nil];
                    weakSelf.pictureIsLoaded &= YES;
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    weakSelf.pictureIsLoaded &= NO;
                }];
            }
        }
    }
}

- (void)playNextMessage {
    NSInteger senderId = ((Message *)self.unreadMessages[0]).senderId;
    int i = 0;
    for (NSNumber *ids in self.group.memberIds) {
        if ([ids integerValue] == senderId) {
            self.nameLabel.text = self.group.memberFirstName[i];
            break;
        }
        i++;
    }
    [super playNextMessage];
}

- (void)messageFinishPlaying:(BOOL)completed {
    self.nameLabel.text = self.group.groupName;
    [super messageFinishPlaying:completed];
}

// No state symbol for groups
- (BOOL)lastMessageSentReadByContact {
    return NO;
}

- (BOOL)currentUserDidNotAnswerLastMessage {
    return NO;
}

- (BOOL)messageNotReadByContact {
    return NO;
}

- (BOOL)isGroupContactView {
    return YES;
}

- (NSInteger)contactIdentifier {
    return self.group.identifier;
}

- (void)updateLastMessageDate:(NSInteger)date
{
    self.group.lastMessageDate = date;
}

- (NSInteger)getLastMessageExchangedDate
{
    return self.group.lastMessageDate;
}

@end
