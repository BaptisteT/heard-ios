//
//  Constants.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Constants : NSObject

@end

static NSString * const kApiVersion = @"1";

static NSString * const kProdAFHeardAPIBaseURLString = @"http://heard.herokuapp.com/";
static NSString * const kProdAFHeardWebsite = @"www.waved.io/beta";

static NSString * const kStagingAFHeardAPIBaseURLString = @"http://heard-staging.herokuapp.com/";
    
static NSString * const kFeedbackEmail = @"info@waved.io";

static NSString * const kProdHeardRecordBaseURL = @"https://s3.amazonaws.com/heard_messages/";
static NSString * const kProdHeardProfilePictureBaseURL = @"https://s3.amazonaws.com/heard_profile_pictures/original/";

static NSString * const kStagingHeardRecordBaseURL = @"https://s3.amazonaws.com/heard_messages_staging/";
static NSString * const kStagingHeardProfilePictureBaseURL = @"https://s3.amazonaws.com/heard_profile_pictures_staging/original/";

static const NSUInteger kMaxNameLength = 20;

// Audio parameter
static const NSUInteger kAVSampleRateKey = 32000;
static const NSUInteger kAVNumberOfChannelsKey = 2;
static const CGFloat kMaxAudioDuration = 30.; // in sec
static const CGFloat kMinAudioDuration = 0.5; // in sec
static const CGFloat kLongPressMinDuration = 0.05;
static const CGFloat kAudioPlayerVolume = 1;

// Admin
static const NSUInteger kAdminId = 1;

// UI size
static const NSUInteger kUnreadMessageSize = 30;
static const NSUInteger kContactMargin = 20;
static const NSUInteger kContactSize = 80;
static const NSUInteger kContactNameHeight = 30;
static const NSUInteger kProfilePictureSize = 200;

//Mixpanel token
static NSString * const kProdMixPanelToken = @"898ed29f5309c83be61a27a41d55c879";