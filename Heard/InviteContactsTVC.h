//
//  InviteContactsTVC.h
//  Heard
//
//  Created by Bastien Beurier on 7/16/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InviteContactsTVCDelegate;

@interface InviteContactsTVC : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (weak, nonatomic) id <InviteContactsTVCDelegate> delegate;
- (void)deselectAll;
- (void)dismissSearch;

@end

@protocol InviteContactsTVCDelegate

- (void)selectContactWithPhoneNumber:(NSString *)phoneNumber;
- (void)deselectContactWithPhoneNumber:(NSString *)phoneNumber;
@property (strong, nonatomic) NSMutableDictionary *indexedContacts;

@end