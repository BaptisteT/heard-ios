//
//  ManageGroupsViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 10/22/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ManageGroupsViewController.h"
#import "CreateGroupsViewController.h"

#define NO_GROUPS_TAG @"No Groups"
#define GROUP_TAG @"Group Cell"

@interface ManageGroupsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *groupTableView;

@end

@implementation ManageGroupsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.groupTableView.delegate = self;
    self.groupTableView.dataSource = self;
    self.groupTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
    if (self.groups.count == 0) {
        static NSString *cellIdentifier = NO_GROUPS_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else {
        static NSString *cellIdentifier = GROUP_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        Group *group = (Group *)self.groups[indexPath.row];
        cell.textLabel.text = group.groupName;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld members",(long)group.memberIds.count];
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Group *group = (Group *)self.groups[indexPath.row];
    
    if ([tableView cellForRowAtIndexPath:indexPath].frame.size.height == 100) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    } else {
        [
    }
    [tableView beginUpdates];
    [tableView endUpdates];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath isEqual:[tableView indexPathForSelectedRow]]) {
        return 100.0;
    }
    return 60;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
