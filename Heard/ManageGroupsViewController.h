//
//  ManageGroupsViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 10/22/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ManageGroupsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *groups;

@end
