//
//  ManageGroupsViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 10/22/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ManageGroupsTableViewCell.h"

@interface ManageGroupsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ManageGroupsCellProtocol, UIActionSheetDelegate>

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *groups;

@end
