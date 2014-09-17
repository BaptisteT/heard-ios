//
//  AudioUtils.m
//  Heard
//
//  Created by Baptiste Truchot on 6/26/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AudioUtils.h"


@implementation AudioUtils

+ (BOOL)usingHeadsetInAudioSession:(AVAudioSession *)session
{
    AVAudioSessionPortDescription *output = [[session.currentRoute.outputs count]?session.currentRoute.outputs:nil objectAtIndex:0];
    if ([output.portType isEqualToString:AVAudioSessionPortHeadphones]) {
        NSLog(@"yes %@", output.portType);
        return YES;
    } else {
        NSLog(@"no %@", output.portType);
        return NO;
    }
}

@end
