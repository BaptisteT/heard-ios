//
//  Group.m
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "Group.h"

@implementation Group

+ (Group *)createGroupWithId:(NSUInteger)identifier
                     groupName:(NSString *)groupName
                     memberIds:(NSMutableArray *)memberIds
{
    Group *group = [[Group alloc] init];
    
    group.identifier = identifier;
    group.groupName = groupName;
    group.memberIds= memberIds;
    group.lastMessageDate = 0;
    return group;
}

+ (Group *)rawGroupToInstance:(NSDictionary *)rawGroup
{
    return [Group createGroupWithId:[[rawGroup objectForKey:@"id"] integerValue]
                          groupName:[rawGroup objectForKey:@"group_name"]
                          memberIds:[rawGroup objectForKey:@"member_ids"]];
}


@end
