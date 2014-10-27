//
//  GroupUtils.h
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Group.h"

@interface GroupUtils : NSObject

+ (NSMutableArray *)retrieveGroupsInMemory;

+ (void)saveGroupsInMemory:(NSArray *)groupIds;

+ (Group *)findGroupFromId:(NSInteger)groupId inGroupsArray:(NSArray *)groups;

@end
