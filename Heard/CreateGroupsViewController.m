//
//  CreateGroupsViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 10/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "CreateGroupsViewController.h"
#import "GeneralUtils.h"
#import "Constants.h"
#import "ApiUtils.h"
#import "SessionUtils.h"
#import "MBProgressHUD.h"
#import "Group.h"

#define NO_CONTACTS_TAG @"No contacts"
#define CONTACT_TAG @"Contact Cell"

@interface CreateGroupsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UILabel *membersLabel;
@property (strong, nonatomic) IBOutlet UITextField *groupNameTextField;
@property (nonatomic) NSMutableArray *selectedContacts;

@end

@implementation CreateGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedContacts = [NSMutableArray new];
    self.contactsTableView.delegate = self;
    self.contactsTableView.dataSource = self;
    self.groupNameTextField.delegate = self;
    self.contactsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}


// ----------------------------------------------------------
// Navigation
// ----------------------------------------------------------
- (IBAction)backButtonClicked:(id)sender {
    // todo BT
    // CHange if we come directly from dashboard
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createButtonClicked:(id)sender {
    if (self.groupNameTextField.text.length == 0) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"empty_group_name_message", kStringFile, nil) withTitle:nil];
    } else if (self.selectedContacts.count <= 1) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"insufficient_members_number_message", kStringFile, nil) withTitle:nil];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSMutableArray *contactIds = [NSMutableArray new];
        [contactIds addObject:[NSNumber numberWithInteger:[SessionUtils getCurrentUserId]]];
        for (Contact *contact in self.selectedContacts) {
            [contactIds addObject:[NSNumber numberWithInteger:contact.identifier]];
        }
        [ApiUtils createGroupWithName:self.groupNameTextField.text
                              members:contactIds
                              success:^void(NSInteger groupId) {
                                  Group *group = [Group createGroupWithId:groupId groupName:self.groupNameTextField.text memberIds:contactIds];
                                  group.lastMessageDate = [[NSDate date] timeIntervalSince1970];
                                  [self.delegate addNewGroup:group];
                                  [GeneralUtils showMessage:NSLocalizedStringFromTable(@"group_successfully_created_message", kStringFile, nil) withTitle:nil];
                                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                                  [self dismissViewControllerAnimated:YES completion:nil];
                              }
                              failure:^void() {
                                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                                  [GeneralUtils showMessage:NSLocalizedStringFromTable(@"group_creation_failed_message", kStringFile, nil) withTitle:nil];
                              }];
    }
}

// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.contacts count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.contacts.count == 0) {
        static NSString *cellIdentifier = NO_CONTACTS_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else {
        static NSString *cellIdentifier = CONTACT_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
 
        Contact *contact = (Contact *)self.contacts[indexPath.row];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstName ? contact.firstName : @"", contact.lastName ? contact.lastName : @""];

        if ([self.selectedContacts containsObject:contact]) {
            cell.imageView.image = [UIImage imageNamed:@"checkbox-selected"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"checkbox"];
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Contact *contact = (Contact *)self.contacts[indexPath.row];

    if ([GeneralUtils isCurrentUser:contact] || contact.isFutureContact) {
        // should not happen
    } else if ([self.selectedContacts containsObject:contact]) {
        [self.selectedContacts removeObject:contact];
        cell.imageView.image = [UIImage imageNamed:@"checkbox"];
        self.membersLabel.text = [NSString stringWithFormat:@"Selected Members (%lu)",self.selectedContacts.count];
    } else {
        if ([self.selectedContacts count] > kMaxGroupMembers - 2) {
            [GeneralUtils showMessage:nil withTitle:NSLocalizedStringFromTable(@"max_group_members_title", kStringFile, nil)];
        } else {
            [self.selectedContacts addObject:contact];
            cell.imageView.image = [UIImage imageNamed:@"checkbox-selected"];
            self.membersLabel.text = [NSString stringWithFormat:@"Selected Members (%lu)",self.selectedContacts.count];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [self.groupNameTextField resignFirstResponder];
    return YES;
}


@end
