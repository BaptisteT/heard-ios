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
    AVAudioSessionDataSourceDescription *ds = session.inputDataSource;
    
    for(AVAudioSessionPortDescription *port in session.availableInputs)  //looks at all of the available inputs
    {
        if([port.portType isEqual: @"MicrophoneWired"]) //if input port type is "MicrophoneWired" - it's a headset
        {if(([ds.dataSourceName isEqual:port.selectedDataSource.dataSourceName])||(ds==port.selectedDataSource))
                //confirm that input source is the same as the microphone port.  It may seem repetitive but I've found values to be null for this input so I check to make sure they're equal or that the string it returns is equal in case a future iOS represents it with a string
            {
                return YES;    //if source input is the same as the microphone input then YES the user is using a headset
            }
        }
    }
    return NO;    //otherwise the user is not using a headset
}

@end
