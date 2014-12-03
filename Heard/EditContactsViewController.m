//
//  EditContactsViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 7/30/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "EditContactsViewController.h"
#import "Contact.h"
#import "UIImageView+AFNetworking.h"
#import "GeneralUtils.h"

#define NO_CONTACTS_TAG @"No contacts"
#define CONTACT_TAG @"EditContactsTableViewCell"
#define PROFILE_PIC_SIZE 50
#define BORDER_WIDTH 0.5

@interface EditContactsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UIView *navBar;

@end

@implementation EditContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [GeneralUtils addBottomBorder:self.navBar borderSize:BORDER_WIDTH];
    
    self.contactsTableView.delegate = self;
    self.contactsTableView.dataSource = self;
    
    self.contactsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
}

// ----------------------------------------------------------
// EditContactsTVC protocol
// ----------------------------------------------------------
- (void)hideContact:(Contact *)contact
{
    [self.delegate removeViewOfContact:contact];
}

- (void)showContact:(Contact *)contact
{
    [self.delegate displayViewOfContact:contact];
}


// ----------------------------------------------------------
// Navigation
// ----------------------------------------------------------
- (IBAction)doneButtonClicked:(id)sender {
    [self.delegate reorderContactViews];
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
        
        EditContactsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        Contact *contact = (Contact *)self.contacts[indexPath.row];
        
        cell.contact = contact;
        cell.phoneNumber.text = [NSString stringWithFormat:@"%@ %@", contact.firstName ? contact.firstName : @"", contact.lastName ? contact.lastName : @""];
        cell.switchButton.on = contact.isHidden;
        if (contact.isHidden) {
            [GeneralUtils setProfilePicture:cell.profilePicture fromContact:contact andAddressBook:[self.delegate addressBook]];
        } else {
            cell.profilePicture.image = [self.delegate getViewOfContact:contact].imageView.image;
        }
        cell.profilePicture.clipsToBounds = YES;
        cell.profilePicture.layer.cornerRadius = PROFILE_PIC_SIZE/2;
        
        cell.delegate = self;
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
