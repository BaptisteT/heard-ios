//
//  GroupUtils.m
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "GroupUtils.h"
#import "Group.h"

#define GROUP_ID_PREF @"Group Ids Preference"
#define GROUP_NAME_PREF @"Group Names Preference"
#define GROUP_MEMBERS_ID_PREF @"Group Members Id Preference"
#define GROUP_MEMBERS_FIRST_NAME_PREF @"Group Members First Name Preference"
#define GROUP_MEMBERS_LAST_NAME_PREF @"Group Members Last Name Preference"
#define GROUP_LAST_MESSAGE_DATE_PREF @"Group Last Message Date Preference"

@implementation GroupUtils

+ (NSMutableArray *)retrieveGroupsInMemory
{
    NSArray *idArray = [[NSUserDefaults standardUserDefaults] arrayForKey:GROUP_ID_PREF];
    NSArray *nameArray = [[NSUserDefaults standardUserDefaults] arrayForKey:GROUP_NAME_PREF];
    NSArray *membersIdArray = [[NSUserDefaults standardUserDefaults] arrayForKey:GROUP_MEMBERS_ID_PREF];
    NSArray *membersFirstNameArray = [[NSUserDefaults standardUserDefaults] arrayForKey:GROUP_MEMBERS_FIRST_NAME_PREF];
    NSArray *membersLastNameArray = [[NSUserDefaults standardUserDefaults] arrayForKey:GROUP_MEMBERS_LAST_NAME_PREF];
    NSArray *lastMessageDateArray = [[NSUserDefaults standardUserDefaults] arrayForKey:GROUP_LAST_MESSAGE_DATE_PREF];
    if (!idArray || !nameArray || !membersIdArray || !membersFirstNameArray || !membersLastNameArray) {
        return [NSMutableArray new];
    }
    
    NSInteger groupCount = [idArray count];
    NSMutableArray *groups = [[NSMutableArray alloc] initWithCapacity:groupCount];
    for (int i=0;i<groupCount;i++) {
        Group *group = [Group createGroupWithId:[idArray[i] integerValue]
                                      groupName:nameArray[i]
                                      memberIds:membersIdArray[i]
                               memberFirstNames:membersFirstNameArray[i]
                                memberLastNames:membersLastNameArray[i]];
        group.lastMessageDate = [lastMessageDateArray[i] integerValue];
        [groups addObject:group];
    }
    return groups;
}

+ (void)saveGroupsInMemory:(NSArray *)groups
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger groupCount = [groups count];
    NSMutableArray *idArray = [[NSMutableArray alloc] initWithCapacity:groupCount];
    NSMutableArray *nameArray = [[NSMutableArray alloc] initWithCapacity:groupCount];
    NSMutableArray *membersIdArray = [[NSMutableArray alloc] initWithCapacity:groupCount];
    NSMutableArray *membersFirstNameArray = [[NSMutableArray alloc] initWithCapacity:groupCount];
    NSMutableArray *membersLastNameArray = [[NSMutableArray alloc] initWithCapacity:groupCount];
    NSMutableArray *lastMessageDateArray = [[NSMutableArray alloc] initWithCapacity:groupCount];
    for (Group * group in groups) {
        [idArray addObject:[NSNumber numberWithInteger:group.identifier]];
        [nameArray addObject:group.groupName];
        [membersIdArray addObject:group.memberIds];
        [membersFirstNameArray addObject:group.memberFirstName];
        [membersLastNameArray addObject:group.memberLastName];
        [lastMessageDateArray addObject:[NSNumber numberWithInteger:group.lastMessageDate]];
    }
    
    [prefs setObject:idArray forKey:GROUP_ID_PREF];
    [prefs setObject:nameArray forKey:GROUP_NAME_PREF];
    [prefs setObject:membersIdArray forKey:GROUP_MEMBERS_ID_PREF];
    [prefs setObject:membersFirstNameArray forKey:GROUP_MEMBERS_FIRST_NAME_PREF];
    [prefs setObject:membersLastNameArray forKey:GROUP_LAST_MESSAGE_DATE_PREF];
    [prefs setObject:lastMessageDateArray forKey:GROUP_LAST_MESSAGE_DATE_PREF];
    [prefs synchronize];
}

+ (Group *)findGroupFromId:(NSInteger)groupId inGroupsArray:(NSArray *)groups
{
    if (groupId == 0) {
        return nil;
    }
    for (Group * existingGroup in groups) {
        if (existingGroup.identifier == groupId) {
            return existingGroup;
        }
    }
    return nil;
}

@end
