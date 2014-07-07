//
//  Constants.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RECORD_TUTO_PREF @"Record message tutorial pref"

@interface Constants : NSObject

@end

static NSString * const kApiVersion = @"1";
static NSString * const kProdAFHeardAPIBaseURLString = @"http://heard.herokuapp.com/";
static NSString * const kProdAFHeardWebsite = @"http://www.waved.io/";
static NSString * const kFeedbackEmail = @"info@waved.io";

static NSString * const kProdHeardRecordBaseURL = @"https://s3.amazonaws.com/heard_messages/";
static NSString * const kProdHeardProfilePictureBaseURL = @"https://s3.amazonaws.com/heard_profile_pictures/original/";

static const NSUInteger kMaxNameLength = 20;

// Audio parameter
static const NSUInteger kAVSampleRateKey = 32000;
static const NSUInteger kAVNumberOfChannelsKey = 2;
static const CGFloat kMaxAudioDuration = 30.; // in sec
static const CGFloat kMinAudioDuration = 0.5; // in sec
static const CGFloat kLongPressMinDurationMessageCase = 0.2;
static const CGFloat kLongPressMinDurationNoMessageCase = 0.05;
static const CGFloat kAudioPlayerVolume = 1;


// UI size
static const NSUInteger kUnreadMessageSize = 30;
static const NSUInteger kContactMargin = 20;
static const NSUInteger kContactSize = 80;
static const NSUInteger kContactNameHeight = 30;

//Mixpanel token
static NSString * const kProdMixPanelToken = @"898ed29f5309c83be61a27a41d55c879";