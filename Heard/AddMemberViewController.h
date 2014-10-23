//
//  AddMemberViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Group.h"

@protocol AddMemberVCDelegateProtocol;

@interface AddMemberViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) Group *selectedGroup;
@property (nonatomic) id<AddMemberVCDelegateProtocol> delegate;

@end

@protocol AddMemberVCDelegateProtocol

- (void)addMember:(NSInteger)userId toGroup:(Group *)group;

@end
