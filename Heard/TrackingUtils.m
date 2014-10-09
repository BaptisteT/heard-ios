//
//  TrackingUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/25/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "TrackingUtils.h"
#import "Mixpanel.h"


@implementation TrackingUtils

+ (void)identifyWithMixpanel:(Contact *)contact signup:(BOOL)isSigningUp
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (isSigningUp || !PRODUCTION) {
        [mixpanel createAlias:[NSString stringWithFormat:@"%lu", (unsigned long)contact.identifier] forDistinctID:mixpanel.distinctId];
        
        [mixpanel track:@"Signup"];
    }
        
    [mixpanel identify:[NSString stringWithFormat:@"%lu", (unsigned long)contact.identifier]];
    
    [mixpanel.people set:@{@"First name": contact.firstName, @"Last name": contact.lastName}];
}

+ (void)trackRecord:(BOOL)isEmoji
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (isEmoji) {
        [mixpanel track:@"Record" properties:@{@"Emoji": @"True"}];
    } else {
        [mixpanel track:@"Record" properties:@{@"Emoji": @"False"}];
    }
    
    [mixpanel.people increment:@"Records" by:[NSNumber numberWithInt:1]];
}

+ (void)trackFutureRecord:(BOOL)isEmoji
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (isEmoji) {
        [mixpanel track:@"Future record" properties:@{@"Emoji": @"True"}];
    } else {
        [mixpanel track:@"Future record" properties:@{@"Emoji": @"False"}];
    }
    
    [mixpanel.people increment:@"Future records" by:[NSNumber numberWithInt:1]];
}

+ (void)trackPlayWithDuration:(NSTimeInterval)duration
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Play" properties:@{@"Duration": [NSNumber numberWithInt:duration]}];
    
    [mixpanel.people increment:@"Plays" by:[NSNumber numberWithInt:1]];
}

+ (void)trackReplay
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Replays" by:[NSNumber numberWithInt:1]];
}

+ (void)trackShareSuccessful:(BOOL)success
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (success) {
        [mixpanel track:@"Share" properties:@{@"Success": @"True"}];
        
        [mixpanel.people increment:@"Share" by:[NSNumber numberWithInt:1]];
    } else {
        [mixpanel track:@"Share" properties:@{@"Success": @"False"}];
    }
}

+ (void)trackAddContactSuccessful:(BOOL)success Present:(BOOL)present Pending:(BOOL)pending
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *presentStr = present ? @"True" : @"False";
    
    if (pending) {
        [mixpanel.people increment:@"Add contact" by:[NSNumber numberWithInt:1]];
        
        [mixpanel track:@"Add contact" properties:@{@"Pending": @"True"}];
    } else if (success) {
        [mixpanel.people increment:@"Add contact" by:[NSNumber numberWithInt:1]];
        
        [mixpanel track:@"Add contact" properties:@{@"Success": @"True", @"Present": presentStr, @"Pending": @"False"}];
    } else {
        [mixpanel track:@"Add contact" properties:@{@"Success": @"False", @"Pending": @"False"}];
    }
}

+ (void)trackOpenApp
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    [mixpanel track:@"Open app"];
    
    [mixpanel.people increment:@"Open app count" by:[NSNumber numberWithInt:1]];
}

+ (void)trackNumberOfContacts:(NSInteger)nbrOfContacts
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people set:@{@"Contacts": [NSNumber numberWithInt:nbrOfContacts]}];
}

+ (void)trackInviteContacts:(NSInteger)nbrOfInvites successful:(BOOL)success justAdded:(BOOL)justAdded
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *justAddedStr = justAdded ? @"True" : @"False";
    if (success) {
        [mixpanel.people increment:@"Invite contacts" by:[NSNumber numberWithInt:1]];
        
        [mixpanel track:@"Invite contacts" properties:@{@"Success": @"True", @"Number": [NSNumber numberWithLong:nbrOfInvites] , @"Just added": justAddedStr}];
        
        [mixpanel.people increment:@"Invites" by:[NSNumber numberWithInt:nbrOfInvites]];
    } else {
        [mixpanel track:@"Invite contacts" properties:@{@"Success": @"False", @"Just added": justAddedStr}];
    }
}

+ (void)trackFailedToOpenContact:(NSString *)formattedNumber
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Failed Open Contact" properties:@{@"Phone number":formattedNumber}];
}

+ (void)trackFirstOpenApp
{
    if (!PRODUCTION || DEBUG)return;
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people increment:@"First Open App" by:[NSNumber numberWithInt:1]];
}

@end
