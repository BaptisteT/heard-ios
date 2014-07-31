//
//  EditContactsTableViewCell.h
//  Heard
//
//  Created by Baptiste Truchot on 7/30/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"

@protocol EditContactsTableViewCellDelegate;

@interface EditContactsTableViewCell : UITableViewCell

@property (weak, nonatomic) Contact *contact;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumber;
@property (weak, nonatomic) IBOutlet UISwitch *switchButton;
@property (weak, nonatomic) id <EditContactsTableViewCellDelegate> delegate;

@end

@protocol EditContactsTableViewCellDelegate

- (void)hideContact:(Contact *)contact;
- (void)showContact:(Contact *)contact;

@end
