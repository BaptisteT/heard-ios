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
#import "NoCancelSearchBar.h"

@interface InviteContactsTVC ()

@property (strong, nonatomic) NSArray *sectionTitles;
@property (strong, nonatomic) NSMutableArray *filteredContacts;

@property (weak, nonatomic) IBOutlet UISearchBar *tableSearchBar;

@end

@implementation InviteContactsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.sectionTitles = [[self.delegate.indexedContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    //change button in table search bar
    for(UIView *subView in [self.tableSearchBar subviews]) {
        if([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
            [(UITextField *)subView setReturnKeyType: UIReturnKeyDone];
        } else {
            for(UIView *subSubView in [subView subviews]) {
                if([subSubView conformsToProtocol:@protocol(UITextInputTraits)]) {
                    [(UITextField *)subSubView setReturnKeyType: UIReturnKeyDone];
                }
            }      
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    } else {
        // Return the number of sections.
        return [self.sectionTitles count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredContacts.count;
    } else {
        // Return the number of rows in the section.
        NSString *sectionTitle = [self.sectionTitles objectAtIndex:section];
        NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
        return [sectionContacts count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return [self.sectionTitles objectAtIndex:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    NSMutableArray *contact;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"Invite Contact Cell"];
        NSString *key = self.filteredContacts[indexPath.row][0];
        NSInteger i = [self.filteredContacts[indexPath.row][1] integerValue];
        contact = [self.delegate.indexedContacts objectForKey:key][i];
    } else {
        // Configure the cell...
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"Invite Contact Cell" forIndexPath:indexPath];
        NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
        NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
        contact = [sectionContacts objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", contact[0], contact[1]];
    cell.detailTextLabel.text = contact[2];
    
    if ([contact[3] isEqualToString:@"selected"]) {
        cell.imageView.image = [UIImage imageNamed:@"checkbox-selected"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"checkbox"];
    }
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return self.sectionTitles;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 0;
    } else {
        return [self.sectionTitles indexOfObject:title];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *contact;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        NSString *key = self.filteredContacts[indexPath.row][0];
        NSInteger i = [self.filteredContacts[indexPath.row][1] integerValue];
        contact = [self.delegate.indexedContacts objectForKey:key][i];
    } else {
        NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
        NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
        contact = [sectionContacts objectAtIndex:indexPath.row];
    }
    
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([contact[3] isEqualToString:@"selected"]) {
        contact[3] = @"not selected";
        cell.imageView.image = [UIImage imageNamed:@"checkbox"];
        [self.delegate deselectContactWithPhoneNumber:contact[2]];
        
    } else {
        contact[3] = @"selected";
        cell.imageView.image = [UIImage imageNamed:@"checkbox-selected"];
        [self.delegate selectContactWithPhoneNumber:contact[2]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

}

- (void)deselectAll {
    if (self.tableView == self.searchDisplayController.searchResultsTableView) {
        NSInteger count = [self.filteredContacts count];
        
        for (int i = 0; i < count; i++) {
            NSUInteger ints[2] = {0,i};
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            NSString *key = self.filteredContacts[i][0];
            NSInteger j = [self.filteredContacts[i][1] integerValue];
            NSMutableArray *contact = [self.delegate.indexedContacts objectForKey:key][j];
            
            contact[3] = @"not selected";
            cell.imageView.image = [UIImage imageNamed:@"checkbox"];
            [self.delegate deselectContactWithPhoneNumber:contact[2]];
        }
    } else {
        for (int i = 0; i < [self.tableView numberOfSections]; i++) {
            for (int j = 0; j < [self.tableView numberOfRowsInSection:i]; j++) {
                NSUInteger ints[2] = {i,j};
                NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
                NSArray *sectionContacts = [self.delegate.indexedContacts objectForKey:sectionTitle];
                NSMutableArray *contact = [sectionContacts objectAtIndex:indexPath.row];
                
                contact[3] = @"not selected";
                cell.imageView.image = [UIImage imageNamed:@"checkbox"];
                [self.delegate deselectContactWithPhoneNumber:contact[2]];
            }
        }
    }
}

//UI Search bar

- (NSMutableArray *)filterContentForSearchText:(NSString *)searchText {
    self.filteredContacts = [NSMutableArray new];

    for (NSString *sectionTitle in self.sectionTitles) {
        
        long length = [[self.delegate.indexedContacts objectForKey:sectionTitle] count];
        
        for (NSInteger i = 0; i < length; i++) {
            NSMutableArray *contact = [self.delegate.indexedContacts objectForKey:sectionTitle][i];
            
            if ([[[contact[0] stringByAppendingString:contact[1]] lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound ||
                [[[contact[1] stringByAppendingString:contact[2]] lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound) {
                [self.filteredContacts addObject:[[NSArray alloc] initWithObjects:sectionTitle,[NSNumber numberWithLong:i], nil]];
            }
        }
    }
    
    return self.filteredContacts;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    return true;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
    return true;
}

- (void)dismissSearch
{
    [self.searchDisplayController setActive:NO];
}

@end
