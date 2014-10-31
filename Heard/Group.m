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
            memberFirstNames:(NSMutableArray *)memberFirstNames
             memberLastNames:(NSMutableArray *)memberLastNames
{
    Group *group = [[Group alloc] init];
    
    group.identifier = identifier;
    group.groupName = groupName;
    group.memberIds = memberIds;
    group.memberFirstName = memberFirstNames;
    group.memberLastName = memberLastNames;
    group.lastMessageDate = 1; // so that by default, they appear before contact
    group.isHidden = NO;
    return group;
}

+ (NSArray *)rawGroupsToInstances:(NSArray *)rawGroups
{
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawGroup in rawGroups) {
        [groups addObject:[Group rawGroupToInstance:rawGroup]];
    }
    
    return groups;
}

+ (Group *)rawGroupToInstance:(NSDictionary *)rawGroup
{
    return [Group createGroupWithId:[[rawGroup objectForKey:@"id"] integerValue]
                          groupName:[rawGroup objectForKey:@"group_name"]
                          memberIds:[rawGroup objectForKey:@"member_ids"]
                   memberFirstNames:[rawGroup objectForKey:@"member_first_names"]
                    memberLastNames:[rawGroup objectForKey:@"member_last_names"]];
}


@end