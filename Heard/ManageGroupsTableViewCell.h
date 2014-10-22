//
//  ManageGroupsTableViewCell.h
//  Heard
//
//  Created by Baptiste Truchot on 10/22/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Group.h"

@protocol ManageGroupsCellProtocol;

@interface ManageGroupsTableViewCell : UITableViewCell

@property (strong, nonatomic) Group *group;
@property (weak, nonatomic) id<ManageGroupsCellProtocol> delegate;

@end

@protocol ManageGroupsCellProtocol

- (void)optionButtonClicked:(Group *)group;

@end
