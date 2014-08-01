//
//  EditContactsViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 7/30/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditContactsTableViewCell.h"
#import "ContactView.h"

@protocol EditContactsVCDelegate;

@interface EditContactsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,EditContactsTableViewCellDelegate>

@property (nonatomic, weak) id <EditContactsVCDelegate> delegate;
@property (nonatomic, weak) NSArray *contacts;

@end

@protocol EditContactsVCDelegate

- (void)reorderContactViews;
- (void)removeViewOfContact:(Contact *)contact;
- (void)displayViewOfContact:(Contact *)contact;
- (ContactView *)getViewOfContact:(Contact *)contact;

@end
