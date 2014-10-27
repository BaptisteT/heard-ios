//
//  Group.h
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Group : NSObject

@property (nonatomic) NSUInteger identifier;
@property (strong, nonatomic) NSString *groupName;
@property (strong, nonatomic) NSMutableArray *memberIds;
@property (strong, nonatomic) NSMutableArray *memberFirstName;
@property (strong, nonatomic) NSMutableArray *memberLastName;
@property (nonatomic) NSInteger lastMessageDate;
@property (nonatomic) BOOL isHidden;

+ (Group *)createGroupWithId:(NSUInteger)identifier groupName:(NSString *)groupName memberIds:(NSMutableArray *)memberIds memberFirstNames:(NSMutableArray *)memberFirstNames memberLastNames:(NSMutableArray *)memberLastNames;
+ (Group *)rawGroupToInstance:(NSDictionary *)rawGroup;
+ (NSArray *)rawGroupsToInstances:(NSArray *)rawGroups;
@end
