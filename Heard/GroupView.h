//
//  GroupView.h
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactView.h"
#import "Group.h"

@interface GroupView : ContactView

@property (strong, nonatomic) Group *group;

- (id)initWithGroup:(Group *)group;
- (NSInteger)getLastMessageExchangedDate;

@end
