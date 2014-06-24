//
//  DashboardViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "DashboardViewController.h"
#import "ApiUtils.h"
#import <AddressBook/AddressBook.h>
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "Contact.h"
#import "ApiUtils.h"
#import "GeneralUtils.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "ImageUtils.h"
#import "SessionUtils.h"

#define ACTION_SHEET_OPTION_0 @"Replay last message"
#define ACTION_SHEET_OPTION_1 @"Invite contact"
#define ACTION_SHEET_OPTION_2 @"Share this app"
#define ACTION_SHEET_OPTION_3 @"Feedback"
#define ACTION_SHEET_CANCEL @"Cancel"

#define MAX_METERS 0
#define MIN_METERS -45
#define METERS_FREQUENCY (30/0.05)

#define RECORDING_LINE_MAX_HEIGHT 20
#define RECORDING_LINE_WEIGHT 2
#define PLAYER_HEIGHT 50


@interface DashboardViewController ()

@property (strong, nonatomic) UIAlertView *failedToRetrieveFriendsAlertView;
@property (strong, nonatomic) UIAlertView *failedToRetrieveNewFriendAlertView;
@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactBubbleViews;
@property (weak, nonatomic) IBOutlet UIScrollView *contactScrollView;
@property (strong, nonatomic) UIActionSheet *menuActionSheet;
@property (strong, nonatomic) UIView *recordingView;
@property (nonatomic) float recordingLineX;
@property (nonatomic) float recordingLineY;
@property (nonatomic, strong)UILabel *recordingMessage;
@property (nonatomic) float recordLineLength;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UIView *playerAudioLine;
@property (nonatomic, strong) NSString *currentUserPhoneNumber;
@property (nonatomic, strong) ContactBubbleView *lastMessagePlayedContact;

@end

@implementation DashboardViewController {
    CGPoint pts[5];
    int ctr;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.menuButton.hidden = YES;
    
    // Some init
    self.contactBubbleViews = [[NSMutableArray alloc] init];
    
    [self requestAddressBookAccess];
    
    //Use speakers (TODO: kill warning)
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    
    self.currentUserPhoneNumber = [SessionUtils getCurrentUserPhoneNumber];
}

- (void)requestAddressBookAccess
{
    ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [self retrieveFriendsFromAddressBook:addressBook];
            } else {
                // User denied access
                // Todo Display an alert telling user the contact could not be added
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [self retrieveFriendsFromAddressBook:addressBook];
    }
    else {
        // The user has previously denied access
        // Todo Send an alert telling user to change privacy setting in settings app
    }

}

- (void)retrieveFriendsFromAddressBook:(ABAddressBookRef) addressBook
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    
    NSMutableArray *countryCodes = [[NSMutableArray alloc] init];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    self.addressBookFormattedContacts = [[NSMutableDictionary alloc] init];
    
    for (CFIndex i = 0 ; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            
            NSError *aError = nil;
            NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:phoneNumber error:&aError];
            
            if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                Contact *contact = [Contact createContactWithId:0 phoneNumber:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]
                                   firstName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty)
                                    lastName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty)];
                
                if (contact.firstName != nil || contact.lastName != nil) {
                    [self.addressBookFormattedContacts setObject:contact forKey:contact.phoneNumber];
                }
                
                //Store country codes found in international numbers
                if (![countryCodes containsObject:nbPhoneNumber.countryCode]) {
                    [countryCodes addObject:nbPhoneNumber.countryCode];
                }
            }
        }
    }
    
    NSUInteger count = [countryCodes count];
    
    //Try to rematch invalid phone numbers by using previously stores country codes
    for (NSUInteger i = 0; i < count; i++) {
        
        for (CFIndex j = 0 ; j < peopleCount; j++) {
            ABRecordRef person = CFArrayGetValueAtIndex(people, j);
            
            ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
            for (CFIndex k = 0; k < ABMultiValueGetCount(phoneNumbers); k++) {
                NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, k);
                
                if (![self.addressBookFormattedContacts objectForKey:phoneNumber]) {
                    NSError *aError = nil;
                    
                    NBPhoneNumber *nbPhoneNumber = [phoneUtil parse:phoneNumber defaultRegion:[[phoneUtil regionCodeFromCountryCode:[countryCodes objectAtIndex:i]] firstObject] error:&aError];
                    
                    if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                        Contact *contact = [Contact createContactWithId:0 phoneNumber:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]
                                           firstName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty)
                                            lastName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty)];
                        
                        if (contact.firstName != nil || contact.lastName != nil) {
                            [self.addressBookFormattedContacts setObject:contact forKey:contact.phoneNumber];
                        }
                    }
                }
            }
        }
    }
    
    [self getHeardContacts];
    
    CFRelease(people);
}

- (void)getHeardContacts
{
    [self showLoadingIndicator];
    
    NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
    
    for (NSString* phoneNumber in self.addressBookFormattedContacts) {
        [phoneNumbers addObject:phoneNumber];
    }

    [ApiUtils getMyContacts:phoneNumbers success:^(NSArray *contacts) {
        [self hideLoadingIndicator];
        
        self.contacts = contacts;
        
        for (Contact *contact in self.contacts) {
            contact.firstName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
            contact.lastName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
        }
        
        self.addressBookFormattedContacts = nil;
        
        [self displayContacts];
    } failure:^{
        [self hideLoadingIndicator];
        
        self.failedToRetrieveFriendsAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                           message:@"We failed to retrieve your contacts, please try again."
                                                                          delegate:self
                                                                 cancelButtonTitle:@"OK!"
                                                                 otherButtonTitles:nil];
        
        [self.failedToRetrieveFriendsAlertView show];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.failedToRetrieveFriendsAlertView) {
        [self getHeardContacts];
    }
}

- (void)displayContacts
{
    //TODO erase existing views
    
    self.menuButton.hidden = NO;
    
    NSUInteger contactCount = [self.contacts count];
    NSUInteger rows = [self.contacts count] / 3 + 1;
    float rowHeight = kContactMargin + kContactSize + kContactNameHeight;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    self.contactScrollView.contentSize = CGSizeMake(screenWidth, MIN(screenHeight - 20, rows * rowHeight + 2 * kContactMargin));
    
    if ([self.contacts count] > 0) {
        Contact* contact = [self.contacts firstObject];
        
        ContactBubbleView *contactView = [[ContactBubbleView alloc] initWithContactBubble:contact andFrame:CGRectMake(2 * kContactMargin + kContactSize, kContactMargin, kContactSize, kContactSize)];
        
        contactView.delegate = self;
        
        [self addNameLabelForView:contactView andContact:contact];
        [self.contactBubbleViews addObject:contactView];
        [contactView setImage:[UIImage imageNamed:@"contact-placeholder.png"]];
        
        [self.contactScrollView addSubview:contactView];
    }
    
    if ([self.contacts count] > 1) {
        Contact* contact = [self.contacts objectAtIndex:1];
        
        ContactBubbleView *contactView = [[ContactBubbleView alloc] initWithContactBubble:contact andFrame:CGRectMake(3 * kContactMargin + 2 * kContactSize, kContactMargin, kContactSize, kContactSize)];
        
        contactView.delegate = self;
        
        [self addNameLabelForView:contactView andContact:contact];
        [self.contactBubbleViews addObject:contactView];
        [contactView setImage:[UIImage imageNamed:@"contact-placeholder.png"]];
        
        [self.contactScrollView addSubview:contactView];
    }
    
    for (NSUInteger i = 1; i < rows; i++) {
        if (contactCount > i * 3 - 1) {
            [self addContactViewForContactIndex:i horizontalPosition:0];
        }
        
        if (contactCount > i * 3) {
            [self addContactViewForContactIndex:i horizontalPosition:1];

        }
        
        if (contactCount > i * 3 + 1) {
            [self addContactViewForContactIndex:i horizontalPosition:2];
        }
    }
    
    // Retrieve unread messages
    [self retrieveAndDisplayUnreadMessages];
}

- (void)addContactViewForContactIndex:(NSUInteger)index horizontalPosition:(NSUInteger)position
{
    Contact* contact = [self.contacts objectAtIndex:(index*3 - 1 + position)];
    
    ContactBubbleView *contactView = [[ContactBubbleView alloc] initWithContactBubble:contact andFrame:CGRectMake((position + 1) *kContactMargin + position * kContactSize, index * (kContactMargin + kContactSize + kContactNameHeight) + kContactMargin, kContactSize, kContactSize)];
    
    contactView.delegate = self;
    
    [self addNameLabelForView:contactView andContact:contact];
    [self.contactBubbleViews addObject:contactView];
    [contactView setImage:[UIImage imageNamed:@"contact-placeholder.png"]];
    
    [self.contactScrollView addSubview:contactView];
}

- (void)addNameLabelForView:(UIView *)contactView andContact:(Contact *)contact
{
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(contactView.frame.origin.x - kContactMargin/4, contactView.frame.origin.y + kContactSize, contactView.frame.size.width + kContactMargin/2, kContactNameHeight)];
    
    if ([self.currentUserPhoneNumber isEqualToString:contact.phoneNumber]) {
        nameLabel.text = @"Me";
        nameLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:14.0];
    } else {
        nameLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstName ? contact.firstName : @"", contact.lastName ? contact.lastName : @""];
        nameLabel.font = [UIFont fontWithName:@"Avenir-Light" size:14.0];
    }
    
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.adjustsFontSizeToFitWidth = YES;
    nameLabel.minimumScaleFactor = 0.7;
    
    [self.contactScrollView addSubview:nameLabel];
}

- (IBAction)menuButtonClicked:(id)sender {
    self.menuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                            destructiveButtonTitle:nil
                                              otherButtonTitles:ACTION_SHEET_OPTION_0, ACTION_SHEET_OPTION_1, ACTION_SHEET_OPTION_2, ACTION_SHEET_OPTION_3, nil];
    
    for (UIView* view in [self.menuActionSheet subviews])
    {
        if ([view respondsToSelector:@selector(title)])
        {
            NSString* title = [view performSelector:@selector(title)];
            if ([title isEqualToString:@"Replay last message"] && [view respondsToSelector:@selector(setEnabled:)])
            {
                if (self.replayPlayer) {
                    [view performSelector:@selector(setEnabled:) withObject:@YES];
                } else {
                    [view performSelector:@selector(setEnabled:) withObject:NO];
                }
            }
        }
    }
    
    [self.menuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    
    //Add Friend
    if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_0]) {
        [self quitPlayerMode];
        
        [self startPlayerMode:([self.replayPlayer duration])];
        
        [self.replayPlayer play];
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_1]) {
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    //Share (in the future, it'd be cool to share a vocal message!)
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_2]) {
        NSString *shareString = @"Download Waved, the new voice messaging app.";
        
        NSURL *shareUrl = [NSURL URLWithString:kProdAFHeardWebsite];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [activityViewController setValue:@"You should download Waved." forKey:@"subject"];
        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
        
        [self presentViewController:activityViewController animated:YES completion:nil];
    //Feedback
    } else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=Feedback for Waved on iOS (v%@)", kFeedbackEmail,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self dismissViewControllerAnimated:YES completion:^{
        //Check if phone is a contact and phone validity
        
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        firstName = firstName ? firstName : @"";
        lastName = lastName ? lastName : @"";
        
        if (!firstName && !lastName) {
            [GeneralUtils showMessage:@"Contact should have a first name or a last name." withTitle:nil];
            return;
        }
        
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        NSMutableArray *selectedContactFormattedPhoneNumbers = [[NSMutableArray alloc] init];
        NSMutableArray *selectedContactPhoneNumbers = [[NSMutableArray alloc] init];
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            
            [selectedContactPhoneNumbers addObject:phoneNumber];
            
            NSError *aError = nil;
            NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:phoneNumber error:&aError];
            
            if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                Contact *contact = [Contact createContactWithId:0 phoneNumber:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]
                                                      firstName:firstName
                                                       lastName:lastName];
                
                [selectedContactFormattedPhoneNumbers addObject:contact.phoneNumber];
            }
        }
        
        //No phone number for selected contact
        if ([selectedContactPhoneNumbers count] == 0) {
            [GeneralUtils showMessage:[NSString stringWithFormat:@"We couldn't find any phone number for %@ %@.", firstName, lastName]  withTitle:nil];
            return;
        }
        
        //Check if not already in Waved contacts
        for (NSString *phoneNumber in selectedContactFormattedPhoneNumbers) {
            for (Contact *contact in self.contacts) {
                if ([contact.phoneNumber isEqualToString:phoneNumber]) {
                    [GeneralUtils showMessage:[NSString stringWithFormat:@"%@ %@ is already your contact on Waved!", firstName, lastName]  withTitle:nil];
                    return;
                }
            }
        }
        
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"Download Waved, the new voice messaging app, at %@", kProdAFHeardWebsite];
        viewController.recipients = selectedContactPhoneNumbers;
        viewController.messageComposeDelegate = self;
        
        
        [self presentViewController:viewController animated:YES completion:nil];
    }];
    
	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Retrieve unread messages and display alert
- (void) retrieveAndDisplayUnreadMessages
{
    void (^successBlock)(NSArray *messages) = ^void(NSArray *messages) {
        //Reset unread messages
        [self resetUnreadMessages];
        
        for (Message *message in messages) {
            [self addUnreadMessage:message];
        }
    };
    
    [ApiUtils getUnreadMessagesAndExecuteSuccess:successBlock failure:nil];
}

- (void)resetUnreadMessages
{
    for (ContactBubbleView *contactBubble in self.contactBubbleViews) {
        [contactBubble resetUnreadMessages];
    }

}

// Add a message we just received
- (void)addUnreadMessage:(Message *)message
{
    for (ContactBubbleView *contactBubble in self.contactBubbleViews) {
        BOOL isAttributed = NO;
        if (message.senderId == contactBubble.contact.identifier) {
            [contactBubble addUnreadMessage:message];
            isAttributed = YES;
            break;
        }
        if (!isAttributed) {
            // todo BT
            // case where we receive a message from someone not in our contacts
        }
    }
}

// ----------------------------------------------------------
// Recording Mode
// ----------------------------------------------------------

- (void)addOverlayOverContactView:(ContactBubbleView *)view
{
    [view addActiveOverlay];
}

- (void)removeOverlayFromContactView
{
    for (ContactBubbleView *contactView in self.contactBubbleViews) {
        [contactView removeActiveOverlay];
    }
}

- (void)disableAllContactViews
{
    for (UIView *view in [self.contactScrollView subviews]) {
        if ([view isKindOfClass:[ContactBubbleView class]]) {
            view.userInteractionEnabled = NO;
        }
    }
}

- (void)enableAllContactViews
{
    for (UIView *view in [self.contactScrollView subviews]) {
        if ([view isKindOfClass:[ContactBubbleView class]]) {
            view.userInteractionEnabled = YES;
           
        }
    }
}

//Create recording mode screen
- (void)longPressOnContactBubbleViewStarted:(NSUInteger)contactId FromView:(ContactBubbleView *)view
{
    [self disableAllContactViews];
    
    [self addOverlayOverContactView:view];
    
    //Recording view is same size as screen
    self.recordingView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - PLAYER_HEIGHT, self.view.bounds.size.width, PLAYER_HEIGHT)];
    self.recordingView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0];
    [self.view addSubview:self.recordingView];
    
    //Recording line starting point
    ctr = 0;
    self.recordingLineX = 0;
    self.recordingLineY = self.recordingView.bounds.size.height/2;
    ctr = 0;
    pts[ctr] = CGPointMake(self.recordingLineX, self.recordingLineY);
    
    [self addRecordingMessage:@"Release to send..." color:[UIColor blackColor]];
}

//User stop pressing screen
- (void)longPressOnContactBubbleViewEnded:(NSUInteger)contactId
{
    //Bring the recording line to zero, to prepare sending animation
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:pts[0]];
    self.recordingLineX = self.recordingLineX + self.recordLineLength/METERS_FREQUENCY;
    self.recordingLineY = self.recordingView.bounds.size.height/2;
    [path addLineToPoint:CGPointMake(self.recordingLineX, self.recordingLineY)];
    [self.recordingView.layer addSublayer:[self shapeLayerWithPath:path]];
    
    [self addRecordingMessage:@"Sending..." color:[UIColor blackColor]];
}

//Recorder notifies a change in volume intensity (every 0.05 seconds)
- (void)notifiedNewMeters:(float)power
{
    ctr ++;
    
    if (self.recordLineLength == 0) {
        self.recordLineLength = self.recordingView.bounds.size.width;
    }
    
    self.recordingLineX = self.recordingLineX + self.recordingView.bounds.size.width/METERS_FREQUENCY;
    
    if (power + (-MIN_METERS) < 0) {
        power = 0;
    } else {
        power = power + (-MIN_METERS);
    }
    
    self.recordingLineY = self.recordingView.bounds.size.height/2 - RECORDING_LINE_MAX_HEIGHT * (power/(MAX_METERS + (-MIN_METERS)));
    pts[ctr] = CGPointMake(self.recordingLineX, self.recordingLineY);
    
    if (ctr == 4)
    {
        pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0);
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:pts[0]];
        [path addCurveToPoint:pts[3] controlPoint1:pts[1] controlPoint2:pts[2]];
        pts[0] = pts[3];
        pts[1] = pts[4];
        ctr = 1;
        
        [self.recordingView.layer addSublayer:[self shapeLayerWithPath:path]];
    }
}

- (void)addRecordingMessage:(NSString *)message color:(UIColor *)color {
    if (self.recordingMessage) {
        [self.recordingMessage removeFromSuperview];
        self.recordingMessage = nil;
    }
    
    self.recordingMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, self.recordingView.bounds.size.height/2, self.recordingView.bounds.size.width, self.recordingView.bounds.size.height/2)];
    
    self.recordingMessage.text = message;
    self.recordingMessage.font = [UIFont fontWithName:@"Avenir-Light" size:14.0];
    self.recordingMessage.textAlignment = NSTextAlignmentCenter;
    self.recordingMessage.textColor = color;
    
    [self.recordingView addSubview:self.recordingMessage];
}

- (void)messageSentWithError:(BOOL)error
{
    [self enableAllContactViews];
    
    if (error) {
        [self addRecordingMessage:@"Sending failed." color:[UIColor redColor]];
        
        sleep(1);
        
        [self quitRecodingModeAnimated:YES];
    } else {
        [self addRecordingMessage:@"Sent!" color:[UIColor blackColor]];
        
        float initialWidth = 0;
        float finalWidth = self.recordingView.bounds.size.width - self.recordingLineX;
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.recordingLineX, self.recordingView.bounds.size.height/2 - RECORDING_LINE_WEIGHT, initialWidth, RECORDING_LINE_WEIGHT)];
        
        line.backgroundColor = [ImageUtils blue];
        
        [self.recordingView addSubview:line];
        
        [UIView animateWithDuration:0.5 animations:^{
            CGRect frame = line.frame;
            frame.size.width = finalWidth;
            line.frame = frame;
        } completion:^(BOOL dummy){
            [self quitRecodingModeAnimated:YES];
        }];
    }
}

- (void)quitRecodingModeAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:1.0 animations:^{
            self.recordingView.alpha = 0;
        } completion:^(BOOL dummy){
            [self.recordingView removeFromSuperview];
            self.recordingView = nil;
        }];
    } else {
        [self.recordingView removeFromSuperview];
        self.recordingView = nil;
    }
}

// ----------------------------------------------------------
// Player Mode
// ----------------------------------------------------------

- (void)startedPlayingAudioFileWithDuration:(NSTimeInterval)duration data:(NSData *)data andView:(ContactBubbleView *)view
{
    //In case of a replay
    self.lastMessagePlayedContact = view;
    self.replayPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
    [self.replayPlayer setVolume:2];
    
    [self startPlayerMode:duration];
}

//Only UI
- (void)startPlayerMode:(NSTimeInterval)duration
{
    float initialWidth = 0;
    float finalWidth = self.view.bounds.size.width;
    float lineWeight = 6;
    
    self.playerAudioLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - lineWeight, initialWidth, lineWeight)];
    
    self.playerAudioLine.backgroundColor = [ImageUtils blue];
    
    [self.view addSubview:self.playerAudioLine];
    
    [UIView setAnimationCurve: UIViewAnimationCurveLinear];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         CGRect frame = self.playerAudioLine.frame;
                         frame.size.width = finalWidth;
                         self.playerAudioLine.frame = frame;
                     } completion:^(BOOL finished){
                         if (finished) {
                             [self quitPlayerMode];
                         }
                     }];
}

- (void)quitPlayerMode
{
    if ([self.mainPlayer isPlaying]) {
        [self.mainPlayer stop];
    }
    
    if ([self.replayPlayer isPlaying]) {
        [self.replayPlayer stop];
        self.replayPlayer.currentTime = 0;
    }
    
    [self.playerAudioLine.layer removeAllAnimations];
    [self.playerAudioLine removeFromSuperview];
    self.playerAudioLine = nil;
}

- (void)showLoadingIndicator
{
    if (!self.activityView) {
        self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityView.center = self.view.center;
    }
    
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
}

- (void)hideLoadingIndicator
{
    [self.activityView stopAnimating];
    [self.activityView removeFromSuperview];
}

- (CAShapeLayer *)shapeLayerWithPath:(UIBezierPath *)path
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [path CGPath];
    shapeLayer.strokeColor = [[ImageUtils blue] CGColor];
    shapeLayer.lineWidth = RECORDING_LINE_WEIGHT;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    return shapeLayer;
}

@end
