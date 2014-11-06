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
    
    [mixpanel.people set:@{@"First name": contact.firstName, @"Last name": contact.lastName, @"FB Connected": @"Yes"}];
}

+ (void)trackRecord:(BOOL)isEmoji
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (isEmoji) {
        [mixpanel track:@"Record" properties:@{@"Emoji": @"True", @"Group": @"False"}];
    } else {
        [mixpanel track:@"Record" properties:@{@"Emoji": @"False", @"Group": @"False"}];
    }
    
    [mixpanel.people increment:@"Records" by:[NSNumber numberWithInt:1]];
}

+ (void)trackGroupRecord:(BOOL)isEmoji
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (isEmoji) {
        [mixpanel track:@"Record" properties:@{@"Emoji": @"True", @"Group": @"True"}];
    } else {
        [mixpanel track:@"Record" properties:@{@"Emoji": @"False", @"Group": @"True"}];
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
    
    [mixpanel track:@"Replay"];
}

+ (void)trackAddContact
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Add contact"];
    
    [mixpanel.people increment:@"Add contact after search" by:[NSNumber numberWithInt:1]];
}

+ (void)trackAddPendingContact
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Add pending contact"];
    
    [mixpanel.people increment:@"Add contact after pending" by:[NSNumber numberWithInt:1]];
}

+ (void)trackSearchUser:(NSString *)result
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Search contact" properties:@{@"Result": result}];
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
    
    [mixpanel.people set:@{@"Contacts": [NSNumber numberWithLong:nbrOfContacts]}];
}

+ (void)trackInvite:(NSString *)option Success:(NSString *)success;
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Invite contacts" by:[NSNumber numberWithInt:1]];
    
    [mixpanel track:@"Invite contacts" properties:@{@"Option": option, @"Success": success}];
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

    [mixpanel track:@"First Open App"];
}

+ (void)trackSendingFailed
{
    if (!PRODUCTION || DEBUG) return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Sending Failed"];
}

@end
