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
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    if (isSigningUp) {
        [mixpanel createAlias:[NSString stringWithFormat:@"%lu", (unsigned long)contact.identifier] forDistinctID:mixpanel.distinctId];
    }
        
    [mixpanel identify:[NSString stringWithFormat:@"%lu", (unsigned long)contact.identifier]];
    
    [mixpanel.people set:@{@"First name": contact.firstName, @"Last name": contact.lastName}];
}

+ (void)trackRecord
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Records" by:[NSNumber numberWithInt:1]];
}

+ (void)trackPlay
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Plays" by:[NSNumber numberWithInt:1]];
}

+ (void)trackReplay
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Replays" by:[NSNumber numberWithInt:1]];
}

+ (void)trackShare
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Share" by:[NSNumber numberWithInt:1]];
}

+ (void)trackAddContact
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel.people increment:@"Add contact" by:[NSNumber numberWithInt:1]];
}

+ (void)trackOpenApp
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    [mixpanel track:@"Open app"];
    
    [mixpanel.people increment:@"Open app count" by:[NSNumber numberWithInt:1]];
}

@end
