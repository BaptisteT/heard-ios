//
//  ManageGroupsTableViewCell.m
//  Heard
//
//  Created by Baptiste Truchot on 10/22/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ManageGroupsTableViewCell.h"

@interface ManageGroupsTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *groupName;
@property (strong, nonatomic) NSMutableArray *membersLabelArray;

@end

@implementation ManageGroupsTableViewCell


- (void)setGroup:(Group *)group {
    _group = group;
    if (self.membersLabelArray) {
        for (UILabel *label in self.membersLabelArray) {
            [label removeFromSuperview];
        }
    }
    self.membersLabelArray = [NSMutableArray new];
    self.groupName.text = group.groupName;
    for (int k=0; k<group.memberIds.count; k++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(45, 35 + k*20, 200, 20)];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
        label.text = [NSString stringWithFormat:@"%@ %@",group.memberFirstName[k],group.memberLastName[k]];
        [self.membersLabelArray addObject:label];
        [self addSubview:label];
    }
}

- (IBAction)optionButtonClicked:(id)sender {
    [self.delegate optionButtonClicked:self.group];
}

@end
