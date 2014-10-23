//
//  AddMemberViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AddMemberViewController.h"
#import "Contact.h"

#define NO_CONTACTS_TAG @"No contacts"
#define CONTACT_TAG @"Contact Cell"

@interface AddMemberViewController ()

@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
@property (strong, nonatomic) Contact *selectedContact;

@end

@implementation AddMemberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contactTableView.delegate = self;
    self.contactTableView.dataSource = self;
    self.contactTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}


// ----------------------------------------------------------
// Navigation
// ----------------------------------------------------------
- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedContact = (Contact *)self.contacts[indexPath.row];
    
    NSString *message = [NSString stringWithFormat:@"Do you want to add %@ to the group %@?",self.selectedContact.firstName,self.selectedGroup.groupName];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"NO"
                                          otherButtonTitles:@"YES",nil];
    [alert show];
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


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        self.selectedContact = nil;
    } else if (buttonIndex == 1) {
        [self.delegate addMember:self.selectedContact.identifier toGroup:self.selectedGroup];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
