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

@end

@implementation ManageGroupsTableViewCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroup:(Group *)group {
    _group = group;
    self.groupName.text = group.groupName;
}

- (IBAction)optionButtonClicked:(id)sender {
    [self.delegate optionButtonClicked:self.group];
}

@end
