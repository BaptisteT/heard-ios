//
//  NoCancelSearchBar.m
//  Heard
//
//  Created by Bastien Beurier on 9/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "NoCancelSearchBar.h"

@implementation NoCancelSearchBar

-(void)layoutSubviews{
    [super layoutSubviews];
    [self setShowsCancelButton:NO animated:NO];
}

@end
