//
//  PushNoAnimationSegue.m
//  Heard
//
//  Created by Bastien Beurier on 9/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "PushNoAnimationSegue.h"

@implementation PushNoAnimationSegue

-(void) perform{
    [[[self sourceViewController] navigationController] pushViewController:[self destinationViewController] animated:NO];
}

@end
