//
//  DashboardViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "DashboardViewController.h"
#import "FriendBubbleView.h"
#import "ApiUtils.h"

@interface DashboardViewController ()

// test (to delete)
@property (strong, nonatomic) IBOutlet FriendBubbleView *exampleBubble;

@end

@implementation DashboardViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // todo
    // 1 -> retrive all contacts + order (last message exchanged)
    // 2 -> Create corresponding bubbles
    
    // 3 -> Query all unread message
    // 4 -> Add messages to friend buble or create other bubles 
    [ApiUtils getUnreadMessagesAndExecuteSuccess:nil failure:nil];
    
    // test (to delete)
    self.exampleBubble = [self.exampleBubble initBubbleViewWithFriendId:6];
}


@end
