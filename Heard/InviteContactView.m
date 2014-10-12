//
//  InviteContactView.m
//  Heard
//
//  Created by Bastien Beurier on 9/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "InviteContactView.h"
#import "Constants.h"
#import "Contact.h"

@implementation InviteContactView

- (id)initWithContactMargin:(CGFloat)contactMargin
{
    self = [super initWithFrame:CGRectMake(contactMargin, contactMargin, kContactSize, kContactSize)];
    self.clipsToBounds = NO;
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.pictureIsLoaded = NO;
    
    // Init variables
    self.failedMessages = [NSMutableArray new];
    self.unreadMessages = [NSMutableArray new];
    self.isRecording = NO; self.isPlaying = NO; self.messageNotReadByContact = NO;
    self.sendingMessageCount = 0; self.loadingMessageCount = 0;
    
    // Image view
    [self initImageView];
    
    // Gesture recognisers
    [self initTapAndLongPressGestureRecognisers];
    
    // Init Discussion UI elements
    [self initRecordOverlay];
    
    self.contact = [Contact createContactWithId:0 phoneNumber:@"" firstName:NSLocalizedStringFromTable(@"invite_contact_name",kStringFile, @"comment") lastName:@""];
    
    return self;
}

- (void)setContactPicture
{
    self.imageView.image = [UIImage imageNamed:@"invite-button"];
}

- (void) initImageView {
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self setContactPicture];
    [self addSubview:self.imageView];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.bounds.size.height/2;
}

- (void)sendRecording
{
    Message *message = [Message new];
    message.senderId = self.contact.identifier;
    message.audioData = [self.delegate getLastRecordedData];
    
    [self.delegate inviteContactsWithMessage:message];
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        [self.delegate displayContactAuthView];
    } else {
        [super handleLongPressGesture:recognizer];
    }
}

@end
