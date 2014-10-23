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
@property (weak, nonatomic) IBOutlet UILabel *member1Name;
@property (weak, nonatomic) IBOutlet UILabel *member2Name;
@property (weak, nonatomic) IBOutlet UILabel *member3Name;
@property (weak, nonatomic) IBOutlet UILabel *member4Name;
@property (weak, nonatomic) IBOutlet UILabel *member5Name;

@end

@implementation ManageGroupsTableViewCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroup:(Group *)group {
    _group = group;
    self.groupName.text = group.groupName;
    
    // horrible code
    if (group.memberIds.count > 2) {
        self.member1Name.text = [NSString stringWithFormat:@"%@ %@",group.memberFirstName[0],group.memberLastName[0]];
        self.member1Name.hidden = NO;
        self.member2Name.text = [NSString stringWithFormat:@"%@ %@",group.memberFirstName[1],group.memberLastName[1]];
        self.member2Name.hidden = NO;
        self.member3Name.text = [NSString stringWithFormat:@"%@ %@",group.memberFirstName[2],group.memberLastName[2]];
        self.member3Name.hidden = NO;
        self.member4Name.hidden = YES;
        self.member5Name.hidden = YES;
    }
    if (group.memberIds.count > 3) {
        self.member4Name.text = [NSString stringWithFormat:@"%@ %@",group.memberFirstName[3],group.memberLastName[3]];
        self.member4Name.hidden = NO;
        self.member5Name.hidden = YES;
    }
    if (group.memberIds.count > 4) {
        self.member5Name.text = [NSString stringWithFormat:@"%@ %@",group.memberFirstName[4],group.memberLastName[4]];
        self.member5Name.hidden = NO;
    }
}

- (IBAction)optionButtonClicked:(id)sender {
    [self.delegate optionButtonClicked:self.group];
}

@end
