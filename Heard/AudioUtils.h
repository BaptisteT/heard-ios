//
//  AudioUtils.h
//  Heard
//
//  Created by Baptiste Truchot on 6/26/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>

@interface AudioUtils : NSObject

+ (BOOL)usingHeadsetInAudioSession:(AVAudioSession *)session;

@end
