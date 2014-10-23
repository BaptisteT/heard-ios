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
#import "ApiUtils.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"
#import "AddMemberViewController.h"

#define NO_GROUPS_TAG @"No Groups"
#define GROUP_TAG @"Group Cell"
#define SELECTED_TAG @"ManageGroupsTableViewCell"
#define ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable(@"leave_group_button_title",kStringFile,@"comment")
#define ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable(@"add_person_button_title",kStringFile,@"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")

@interface ManageGroupsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *groupTableView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) Group *selectedGroup;

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
    self.selectedGroup = group;
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
    if (!self.selectedGroup) {
        return;
    }
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_1]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [ApiUtils leaveGroup:self.selectedGroup.identifier
           AndExecuteSuccess:^void() {
               // Delete group, group view, group cell
               [self.groups removeObject:self.selectedGroup];
               [self.delegate deleteGroupAndAssociatedView:self.selectedGroup];
               self.selectedIndexPath = nil;
               [self.groupTableView reloadData];
               [MBProgressHUD hideHUDForView:self.view animated:YES];
           }
                     failure:^void() {
                         [GeneralUtils showMessage:NSLocalizedStringFromTable(@"unexpected_error_message", kStringFile, nil) withTitle:NSLocalizedStringFromTable(@"unexpected_error_title", kStringFile, nil)];
                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                     }
         ];
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_2]) {
        [self performSegueWithIdentifier:@"Add Member From Create Group" sender:nil];
    }
}

// ----------------------------------------------------------
// Create protocol
// ----------------------------------------------------------
- (void)addNewGroup:(Group *)group
{
    [self.delegate addNewGroup:group];
    self.selectedIndexPath = nil;
    [self.groupTableView reloadData];
}

// ----------------------------------------------------------
// Add Member protocol
// ----------------------------------------------------------
- (void)addMember:(NSInteger)userId toGroup:(Group *)group
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiUtils addUser:userId
              toGroup:group.identifier
    AndExecuteSuccess:^void(BOOL isFull, Group *group) {
        self.selectedGroup.memberIds = group.memberIds;
        self.selectedIndexPath = nil;
        [self.groupTableView reloadData];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (isFull) {
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"group_full_message", kStringFile, nil) withTitle:NSLocalizedStringFromTable(@"group_full_title", kStringFile, nil)];
        } else {
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"add_member_success_message", kStringFile, nil) withTitle:nil];
        }
    }
              failure:^void() {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"unexpected_error_message", kStringFile, nil) withTitle:NSLocalizedStringFromTable(@"unexpected_error_title", kStringFile, nil)];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
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
        ((CreateGroupsViewController *) [segue destinationViewController]).delegate = self;
    } else if ([segueName isEqualToString:@"Add Member From Create Group"]) {
        ((AddMemberViewController *) [segue destinationViewController]).contacts = [self contactsNotBelongingToGroup:self.selectedGroup];
        ((AddMemberViewController *) [segue destinationViewController]).selectedGroup = self.selectedGroup;
        ((AddMemberViewController *) [segue destinationViewController]).delegate = self;
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
    } else if(self.selectedIndexPath && [indexPath isEqual:self.selectedIndexPath] && ![[tableView cellForRowAtIndexPath:indexPath].reuseIdentifier  isEqualToString: SELECTED_TAG]) {
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
        if ([indexPath isEqual:self.selectedIndexPath])
            self.selectedIndexPath = nil;
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
    NSIndexPath *previousIndexPath = self.selectedIndexPath;
    self.selectedIndexPath = indexPath;
    NSArray *reloadPaths = previousIndexPath && previousIndexPath != indexPath ? @[previousIndexPath,indexPath] : @[indexPath];
    [tableView reloadRowsAtIndexPaths:reloadPaths withRowAnimation: UITableViewRowAnimationNone];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.selectedIndexPath && [indexPath isEqual:self.selectedIndexPath]) {
        return 100.0;
    } else {
        return 60;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSArray *)contactsNotBelongingToGroup:(Group *)group
{
    NSMutableArray *contactArray = [NSMutableArray new];
    for (Contact *contact in self.contacts) {
        BOOL isInGroup = NO;
        for (NSNumber *memberId in group.memberIds) {
            if ([memberId integerValue] == contact.identifier) {
                isInGroup = YES;
                break;
            }
        }
        if (!isInGroup) {
            [contactArray addObject:contact];
        }
    }
    return contactArray;
}


@end
