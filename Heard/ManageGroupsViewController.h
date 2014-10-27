//
//  ManageGroupsViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 10/22/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ManageGroupsTableViewCell.h"
#import "Group.h"
#import "AddMemberViewController.h"
#import "CreateGroupsViewController.h"
#import "GroupView.h"

@protocol ManageGroupsVCDelegateProtocol;

@interface ManageGroupsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ManageGroupsCellProtocol, UIActionSheetDelegate, AddMemberVCDelegateProtocol, CreateGroupsVCDelegate>

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic) id<ManageGroupsVCDelegateProtocol> delegate;

@end

@protocol ManageGroupsVCDelegateProtocol

- (void)deleteGroupAndAssociatedView:(Group *)group;
- (void)updateGroupAndAssociatedView:(Group *)group;
- (void)addNewGroup:(Group *)group;
- (void)reorderContactViews;
- (GroupView *)getViewOfGroup:(Group *)group;

@end
