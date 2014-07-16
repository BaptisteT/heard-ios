//
//  CountryCodeViewController.m
//  Heard
//
//  Created by Bastien Beurier on 7/15/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "CountryCodeTVC.h"

@interface CountryCodeTVC ()

@property (strong, nonatomic) NSMutableDictionary *indexedCountries;
@property (strong, nonatomic) NSMutableDictionary *countryToCodes;
@property (strong, nonatomic) NSArray *sectionTitles;

@end

@implementation CountryCodeTVC


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.indexedCountries = [[NSMutableDictionary alloc] init];
    self.countryToCodes = [[NSMutableDictionary alloc] init];
    
    [self setCountriesAndCodes];
    
    self.sectionTitles = [[self.indexedCountries allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
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
    NSArray *sectionCountries = [self.indexedCountries objectForKey:sectionTitle];
    return [sectionCountries count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sectionTitles objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Country Code Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *sectionTitle = [self.sectionTitles objectAtIndex:indexPath.section];
    NSArray *sectionCountries = [self.indexedCountries objectForKey:sectionTitle];
    NSString *country = [sectionCountries objectAtIndex:indexPath.row];
    
    cell.textLabel.text = country;
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@", [self.countryToCodes objectForKey:country][0]];
    
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
    NSArray *sectionCountries = [self.indexedCountries objectForKey:sectionTitle];
    NSString *country = [sectionCountries objectAtIndex:indexPath.row];
    
    [self.delegate updateCountryName:country code:[self.countryToCodes objectForKey:country][0] letterCode:[self.countryToCodes objectForKey:country][1]];
    
}

- (void)setCountriesAndCodes
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PhoneCountries" ofType:@"txt"];
    NSData *stringData = [NSData dataWithContentsOfFile:filePath];
    NSString *data = nil;
    if (stringData != nil)
        data = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    
    if (data == nil)
        return;
    
    NSString *delimiter = @";";
    NSString *endOfLine = @"\n";
    
    NSInteger currentLocation = 0;
    while (true)
    {
        NSRange codeRange = [data rangeOfString:delimiter options:0 range:NSMakeRange(currentLocation, data.length - currentLocation)];
        if (codeRange.location == NSNotFound)
            break;
        
        int countryCode = [[data substringWithRange:NSMakeRange(currentLocation, codeRange.location - currentLocation)] intValue];
        
        NSRange idRange = [data rangeOfString:delimiter options:0 range:NSMakeRange(codeRange.location + 1, data.length - (codeRange.location + 1))];
        if (idRange.location == NSNotFound)
            break;
        
        NSString *countryId = [[data substringWithRange:NSMakeRange(codeRange.location + 1, idRange.location - (codeRange.location + 1))] lowercaseString];
        
        NSRange nameRange = [data rangeOfString:endOfLine options:0 range:NSMakeRange(idRange.location + 1, data.length - (idRange.location + 1))];
        if (nameRange.location == NSNotFound)
            nameRange = NSMakeRange(data.length, INT_MAX);
        
        NSString *countryName = [data substringWithRange:NSMakeRange(idRange.location + 1, nameRange.location - (idRange.location + 1))];
        if ([countryName hasSuffix:@"\r"])
            countryName = [countryName substringToIndex:countryName.length - 1];
        
        if ([self.indexedCountries valueForKey:[countryName substringToIndex:1]]) {
            [(NSMutableArray *)[self.indexedCountries valueForKey:[countryName substringToIndex:1]] addObject:countryName];
        } else {
            [self.indexedCountries setValue:[[NSMutableArray alloc] initWithObjects:countryName, nil] forKey:[countryName substringToIndex:1]];
        }
        
        [self.countryToCodes setValue:@[[[NSNumber alloc] initWithInt:countryCode], countryId] forKey:countryName];
        
        currentLocation = nameRange.location + nameRange.length;
        if (nameRange.length > 1)
            break;
    }
    
    //Order country names alphabetically for each section
    for (NSString *key in [self.indexedCountries allKeys]) {
        [self.indexedCountries setObject:[(NSMutableArray *)[self.indexedCountries objectForKey:key] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] forKey:key];
    }
}

@end
