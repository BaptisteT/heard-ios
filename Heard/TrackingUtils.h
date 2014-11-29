//
//  TrackingUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/25/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface TrackingUtils : NSObject

+ (void)identifyWithMixpanel:(Contact *)contact signup:(BOOL)isSigningUp;

+ (void)trackRecord:(NSString *)messageType isGroup:(BOOL)isGroup emoji:(NSString *)emoji;

//+ (void)trackFutureRecord:(BOOL)isEmoji;

+ (void)trackPlayWithDuration:(NSTimeInterval)duration andSpeakerMode:(NSString *)speakerMode;

+ (void)trackReplay;

+ (void)trackAddContact;

+ (void)trackAddPendingContact;

+ (void)trackSearchUser:(NSString *)result;

+ (void)trackOpenApp;

+ (void)trackNumberOfContacts:(NSInteger)nbrOfContacts;

+ (void)trackInvite:(NSString *)option Success:(NSString *)success;

+ (void)trackFailedToOpenContact:(NSString *)formattedNumber;

+ (void)trackFirstOpenApp;

+ (void)trackSendingFailed;

+ (void)trackCreateGroup:(NSInteger)memberCount;

@end
