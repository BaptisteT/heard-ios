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

+ (void)trackRecord
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Record"];
    
    [mixpanel.people increment:@"Records" by:[NSNumber numberWithInt:1]];
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

+ (void)trackShare
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Share" by:[NSNumber numberWithInt:1]];
}

+ (void)trackAddContact
{
    if (!PRODUCTION || DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Add contact" by:[NSNumber numberWithInt:1]];
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

@end
