//
//  CreateGroupsViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactView.h"
#import "Group.h"

@protocol CreateGroupsVCDelegate;

@interface CreateGroupsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) id <CreateGroupsVCDelegate> delegate;
@property (nonatomic, strong) NSArray *contacts;

@end

@protocol CreateGroupsVCDelegate

- (void)addNewGroup:(Group *)group;

@end
