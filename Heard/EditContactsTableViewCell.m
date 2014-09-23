//
//  EditContactsTableViewCell.m
//  Heard
//
//  Created by Baptiste Truchot on 7/30/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "EditContactsTableViewCell.h"

@implementation EditContactsTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    return; // to avoid the cell to stay selected
}

- (IBAction)hideButtonSwitched:(id)sender {
    if (self.switchButton.on) {
        [self.delegate hideContact:self.contact];
    } else {
        [self.delegate showContact:self.contact];
    }
}

@end
