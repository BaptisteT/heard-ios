//
//  InviteContactsTVC.m
//  Heard
//
//  Created by Bastien Beurier on 7/16/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "InviteContactsTVC.h"
#import <AddressBook/AddressBook.h>
#import "NBPhoneNumberUtil.h"

@interface InviteContactsTVC ()

@property (strong, nonatomic) NSArray *sectionTitles;

@property (nonatomic) BOOL allSelected;

@end

@implementation InviteContactsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.allSelected = NO;
    
    self.sectionTitles = [[self.delegate.indexedContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.sectionTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSString *sectionTitle = [self.sectionTitles objectAtIndex:section];
    NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
    return [sectionContacts count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sectionTitles objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Invite Contact Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
    NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
    NSMutableArray *contact = [sectionContacts objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", contact[0], contact[1]];
    
    cell.detailTextLabel.text = contact[2];
    
    if ([contact[3] isEqualToString:@"selected"]) {
        cell.imageView.image = [UIImage imageNamed:@"checkbox-selected.png"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"checkbox.png"];
    }
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    //  return animalSectionTitles;
    return self.sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.sectionTitles indexOfObject:title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
    NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
    NSMutableArray *contact = [sectionContacts objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([contact[3] isEqualToString:@"selected"]) {
        contact[3] = @"not selected";
        cell.imageView.image = [UIImage imageNamed:@"checkbox.png"];
        [self.delegate deselectContactWithPhoneNumber:contact[2]];
        
        self.allSelected = NO;
    } else {
        contact[3] = @"selected";
        cell.imageView.image = [UIImage imageNamed:@"checkbox-selected.png"];
        [self.delegate selectContactWithPhoneNumber:contact[2]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)selectAll {
    if (self.allSelected) {
        [self deselectAll];
    } else {
        self.allSelected = YES;
        
        for (int i = 0; i < [self.tableView numberOfSections]; i++) {
            for (int j = 0; j < [self.tableView numberOfRowsInSection:i]; j++) {
                NSUInteger ints[2] = {i,j};
                NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
                NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
                NSMutableArray *contact = [sectionContacts objectAtIndex:indexPath.row];
                
                contact[3] = @"selected";
                cell.imageView.image = [UIImage imageNamed:@"checkbox-selected.png"];
                [self.delegate selectContactWithPhoneNumber:contact[2]];
            }
        }
    }
}

- (void)deselectAll {
    self.allSelected = NO;
        
    for (int i = 0; i < [self.tableView numberOfSections]; i++) {
        for (int j = 0; j < [self.tableView numberOfRowsInSection:i]; j++) {
            NSUInteger ints[2] = {i,j};
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
            NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
            NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
            NSMutableArray *contact = [sectionContacts objectAtIndex:indexPath.row];
                
            contact[3] = @"not selected";
            cell.imageView.image = [UIImage imageNamed:@"checkbox.png"];
            [self.delegate deselectContactWithPhoneNumber:contact[2]];
        }
    }
}



@end
