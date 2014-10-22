//
//  ManageGroupsViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 10/22/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ManageGroupsViewController.h"
#import "CreateGroupsViewController.h"
#import "ManageGroupsTableViewCell.h"
#import "Constants.h"

#define NO_GROUPS_TAG @"No Groups"
#define GROUP_TAG @"Group Cell"
#define SELECTED_TAG @"ManageGroupsTableViewCell"
#define ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable(@"leave_group_button_title",kStringFile,@"comment")
#define ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable(@"add_person_button_title",kStringFile,@"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")

@interface ManageGroupsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *groupTableView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation ManageGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.groupTableView.delegate = self;
    self.groupTableView.dataSource = self;
    self.groupTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}


// ----------------------------------------------------------
// Manage groups
// ----------------------------------------------------------

- (void)optionButtonClicked:(Group *)group {
    // todo BT
    // show alert view
    // Title = name
    // Leave group
    // if less than 5, add people
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:group.groupName
                                                             delegate:self
                                                    cancelButtonTitle:ACTION_SHEET_CANCEL
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:ACTION_SHEET_OPTION_1, nil];
    if (group.memberIds.count < 5) {
        [actionSheet addButtonWithTitle:ACTION_SHEET_OPTION_2];
    }
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_1]) {
        // todo BT
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_2]) {
        // todo BT
    }
}

// ----------------------------------------------------------
// Navigation
// ----------------------------------------------------------

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Create Group From Manage Groups" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString:@"Create Group From Manage Groups"]) {
        ((CreateGroupsViewController *) [segue destinationViewController]).contacts = self.contacts;
    }
}

// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(1,[self.groups count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier;
    if (self.groups.count == 0) {
         cellIdentifier = NO_GROUPS_TAG;
         UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else if([indexPath isEqual:self.selectedIndexPath] && ![[tableView cellForRowAtIndexPath:indexPath].reuseIdentifier  isEqualToString: SELECTED_TAG]) {
        NSLog([tableView cellForRowAtIndexPath:indexPath].reuseIdentifier);
        cellIdentifier = SELECTED_TAG;
        ManageGroupsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        cell.group = (Group *)self.groups[indexPath.row];
        cell.delegate = self;
        return cell;
    } else {
        cellIdentifier = GROUP_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        Group *group = (Group *)self.groups[indexPath.row];
        cell.textLabel.text = group.groupName;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld members",(long)group.memberIds.count];
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    Group *group = (Group *)self.groups[indexPath.row];
//    
//    if ([tableView cellForRowAtIndexPath:indexPath].frame.size.height == 100) {
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//        
//        EditContactsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:"EditContactsTableViewCell"];
//        [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    } else {
//        cell.accessoryType = UITableViewCellAccessoryNone;
//    }
//    [tableView beginUpdates];
//    [tableView endUpdates];
    self.selectedIndexPath = indexPath;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation: UITableViewRowAnimationNone];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath isEqual:[tableView indexPathForSelectedRow]]) {
        return 60.0;
    } else {
        return 60;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}



@end
