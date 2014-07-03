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
#import "TrackingUtils.h"
#import "AudioUtils.h"
#import "HeardAppDelegate.h"
#import "ContactUtils.h"
#import <MediaPlayer/MPMusicPlayerController.h>

#define ACTION_SHEET_1_OPTION_0 @"Replay last message"
#define ACTION_SHEET_1_OPTION_1 @"Invite contact"
#define ACTION_SHEET_1_OPTION_2 @"Share this app"
#define ACTION_SHEET_1_OPTION_3 @"Feedback"
#define ACTION_SHEET_2_OPTION_1 @"Add contact"
#define ACTION_SHEET_2_OPTION_2 @"Block user"
#define ACTION_SHEET_CANCEL @"Cancel"

#define MAX_METERS 0
#define MIN_METERS -45
#define METERS_FREQUENCY (30/0.05)

#define RECORDER_LINE_MAX_HEIGHT 20
#define RECORDER_LINE_WEIGHT 2
#define RECORDER_HEIGHT 50

#define PLAYER_LINE_WEIGHT 6

@interface DashboardViewController ()

@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactBubbleViews;
@property (weak, nonatomic) IBOutlet UIScrollView *contactScrollView;
@property (strong, nonatomic) UIActionSheet *menuActionSheet;
@property (strong, nonatomic) UIView *recorderContainer;
@property (strong, nonatomic) UIView *recorderView;
@property (strong, nonatomic) UIView *playerContainer;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic) float recordingLineX;
@property (nonatomic) float recordingLineY;
@property (nonatomic, strong)UILabel *recorderMessage;
@property (nonatomic) float recordLineLength;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) NSString *currentUserPhoneNumber;
@property (nonatomic, strong) Contact *contactToAdd;
@property (strong, nonatomic) NSMutableArray *nonAttributedUnreadMessages;
@property (nonatomic, strong) ContactView *lastContactPlayed;
@property (nonatomic) BOOL isUsingHeadSet;


@end

@implementation DashboardViewController {
    CGPoint pts[5];
    int ctr;
}

// ------------------------------
#pragma mark Life cycle
// ------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.menuButton.hidden = YES;
    
    self.recorderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - RECORDER_HEIGHT, self.view.bounds.size.width, RECORDER_HEIGHT)];
    [self.view addSubview:self.recorderContainer];
    self.recorderContainer.hidden = YES;
    
    self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - PLAYER_LINE_WEIGHT, self.view.bounds.size.width, PLAYER_LINE_WEIGHT)];
    [self.view addSubview:self.playerContainer];
    self.playerContainer.hidden = YES;
    
    self.currentUserPhoneNumber = [SessionUtils getCurrentUserPhoneNumber];
    
    // Create bubble with contacts
    self.contacts = ((HeardAppDelegate *)[[UIApplication sharedApplication] delegate]).contacts;
    [self displayContacts];

    // Retrieve messages & contacts
    [self retrieveUnreadMessagesAndNewContacts:YES];
    
    // Create audio session
    AVAudioSession* session = [AVAudioSession sharedInstance];
    BOOL success; NSError* error;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (!success)
        NSLog(@"AVAudioSession error setting category:%@",error);
    
    // Add headset observer
    [session addObserver:self forKeyPath:@"inputDataSources" options:NSKeyValueObservingOptionNew context:nil];
    
    // Add proximity state observer
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceProximityStateDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification) {
                                                                 [self updateOutputAudioPort];
                                                             }];
    
    // Headset observer
    self.isUsingHeadSet = [AudioUtils usingHeadsetInAudioSession:session];
}

- (void)viewDidLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self setScrollViewSizeForContactCount:(int)[self.contacts count]];
}


// ------------------------------
#pragma mark Get Contact
// ------------------------------

- (void)requestAddressBookAccessAndRetrieveFriends
{
    ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [self retrieveFriendsFromAddressBook:addressBook];
            } else {
                // User denied access
                [GeneralUtils showMessage:@"To activate it, go to Settings > Privacy > Contacts" withTitle:@"Waved does not have access to your contacts"];
                [self distributeNonAttributedMessages];
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [self retrieveFriendsFromAddressBook:addressBook];
    }
    else {
        // The user has previously denied access
        [self distributeNonAttributedMessages];
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
//                    [self.addressBookFormattedContacts setObject:contact forKey:contact.phoneNumber];
                    // We need unformatted numbers for the keys
                    [self.addressBookFormattedContacts setObject:contact forKey:phoneNumber];
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
//                            [self.addressBookFormattedContacts setObject:contact forKey:contact.phoneNumber];
                            [self.addressBookFormattedContacts setObject:contact forKey:phoneNumber];
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
    NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
    NSMutableDictionary * adressBookWithFormattedKey = [NSMutableDictionary new];
    
    for (NSString* phoneNumber in self.addressBookFormattedContacts) {
//        [phoneNumbers addObject:phoneNumber];
        Contact *object = [self.addressBookFormattedContacts objectForKey:phoneNumber];
        NSString * formattedPhoneNumber = object.phoneNumber;
        [phoneNumbers addObject:formattedPhoneNumber];
        [adressBookWithFormattedKey setObject:object forKey:formattedPhoneNumber];
    }
    // The keys are now formatted numbers (to use local names for retrieved contacts)
    self.addressBookFormattedContacts = adressBookWithFormattedKey;
    
    // Get contacts and compare with contact in memory
    [ApiUtils getMyContacts:phoneNumbers success:^(NSArray *contacts) {
        for (Contact *contact in contacts) {
            Contact *existingContact = [ContactUtils findContact:contact.identifier inContactsArray:self.contacts];
            if (! existingContact) {
                [self.contacts addObject:contact];
                contact.firstName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
                contact.lastName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
                contact.lastMessageDate = 0;
                [self displayAdditionnalContact:contact];
            } else if (existingContact.isPending) {
                // Mark as non pending
                existingContact.firstName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
                existingContact.lastName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
                existingContact.phoneNumber = contact.phoneNumber;
                existingContact.isPending = NO;
            }
        }
        self.addressBookFormattedContacts = nil;
        
        // Distribute non attributed messages
        [self distributeNonAttributedMessages];
        
    } failure: ^void(NSURLSessionDataTask *task){
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtils invalidTokenResponse:task]) {
            [SessionUtils redirectToSignIn];
        }
    }];
}



// ----------------------------------
#pragma mark Create Contact Bubble
// ----------------------------------

- (void)removeDisplayedContacts
{
    self.menuButton.hidden = YES;
    
    // Erase existing views
    for (ContactView *contactView in self.contactBubbleViews) {
        [contactView removeFromSuperview];
        [contactView.nameLabel removeFromSuperview];
    }
    
    self.contactBubbleViews = [[NSMutableArray alloc] init];
}

- (void)displayContacts
{
    [self removeDisplayedContacts];
    self.menuButton.hidden = NO;
    
    NSUInteger contactCount = [self.contacts count];
    if (contactCount == 0)
        return;
    self.contactBubbleViews = [[NSMutableArray alloc] initWithCapacity:contactCount];
    
    // Sort contact
    [self.contacts sortUsingComparator:^(Contact *contact1, Contact * contact2) {
        if (contact1.lastMessageDate < contact2.lastMessageDate) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedAscending;
        }
    }];
    
    // Create bubbles
    int position = 1;
    for (Contact *contact in self.contacts) {
        [self createContactViewWithContact:contact andPosition:position];
        position ++;
    }
}

- (void)redisplayContact
{
    // Sort contact
    [self.contactBubbleViews sortUsingComparator:^(ContactView *contactView1, ContactView * contactView2) {
        if (contactView1.contact.lastMessageDate < contactView2.contact.lastMessageDate) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedAscending;
        }
    }];
    
    // Create bubbles
    int position = 1;
    for (ContactView *contactView in self.contactBubbleViews) {
        [contactView setOrderPosition:position];
        position ++;
    }
    
    // Pending contact UI
    [self showContactViewAsPending];
}

- (void)displayAdditionnalContact:(Contact *)contact
{
    if (!self.contactBubbleViews) {
        self.contactBubbleViews = [[NSMutableArray alloc] initWithCapacity:[self.contacts count]];
    }
    [self createContactViewWithContact:contact andPosition:(int)[self.contactBubbleViews count]+1];
}

// Set Scroll View size from the number of contacts
- (void)setScrollViewSizeForContactCount:(int)count
{
    NSUInteger rows = count / 3 + 1;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    float rowHeight = kContactMargin + kContactSize + kContactNameHeight;
    self.contactScrollView.contentSize = CGSizeMake(screenWidth, MAX(screenHeight - 20, rows * rowHeight + 2 * kContactMargin));
}

// Create contact view
- (void)createContactViewWithContact:(Contact *)contact andPosition:(int)position
{
    ContactView *contactView = [[ContactView alloc] initWithContact:contact];
    
    // if pending, and missing name, request info
    if (contact.isPending && contact.phoneNumber.length == 0) {
        void(^successBlock)(Contact *) = ^void(Contact *serverContact) {
            contact.phoneNumber = serverContact.phoneNumber;
            contact.firstName = serverContact.firstName;
            contact.lastName = serverContact.lastName;
            [self addNameLabelForView:contactView];
        };
        [ApiUtils getNewContactInfo:contact.identifier AndExecuteSuccess:successBlock failure:nil];
    } else {
        [self addNameLabelForView:contactView];
    }
    
    contactView.delegate = self;
    contactView.orderPosition = position;
    [self.contactBubbleViews addObject:contactView];
    [self.contactScrollView addSubview:contactView];
}

// Add name below contact
- (void)addNameLabelForView:(ContactView *)contactView
{
    Contact *contact = contactView.contact;
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
    contactView.nameLabel = nameLabel;
    [self.contactScrollView addSubview:nameLabel];
}

- (void)showContactViewAsPending
{
    for (ContactView *contactView in self.contactBubbleViews) {
        if (contactView.contact.isPending) {
            [contactView setPendingContact:YES];
        }
    }
}

// ----------------------------------
#pragma mark Display Messages
// ----------------------------------

// Retrieve unread messages and display alert
- (void) retrieveUnreadMessagesAndNewContacts:(BOOL)retrieveNewContacts
{
    void (^successBlock)(NSArray *messages) = ^void(NSArray *messages) {
        //Reset unread messages
        [self resetUnreadMessages];
        BOOL areAttributed = YES;
        for (Message *message in messages) {
            areAttributed &= [self addUnreadMessageToExistingContacts:message];
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:messages.count];
        // Check if we have new contacts
        if (retrieveNewContacts || !areAttributed || self.contacts.count == 0) {
            [self requestAddressBookAccessAndRetrieveFriends];
        } else {
            [self redisplayContact];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *) = ^void(NSURLSessionDataTask *task){
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtils invalidTokenResponse:task]) {
            [SessionUtils redirectToSignIn];
        }
    };
    
    [ApiUtils getUnreadMessagesAndExecuteSuccess:successBlock failure:failureBlock];
}

- (void)resetUnreadMessages
{
    for (ContactView *contactBubble in self.contactBubbleViews) {
        [contactBubble resetUnreadMessages];
    }
    self.nonAttributedUnreadMessages = nil;
}

// Add a message we just received
- (BOOL)addUnreadMessageToExistingContacts:(Message *)message
{
    for (ContactView *contactBubble in self.contactBubbleViews) {
        if (message.senderId == contactBubble.contact.identifier) {
            [contactBubble addUnreadMessage:message];
            
            // Update last message date to sort contacts even if no push
            contactBubble.contact.lastMessageDate = MAX(contactBubble.contact.lastMessageDate,message.createdAt);
            return YES;
        }
    }

    // unread message pool
    if (!self.nonAttributedUnreadMessages) {
            self.nonAttributedUnreadMessages = [[NSMutableArray alloc] init];
        }
    [self.nonAttributedUnreadMessages addObject:message];
    return NO;
}

- (void)distributeNonAttributedMessages
{
    BOOL isAttributed;
    for (Message *message in self.nonAttributedUnreadMessages) {
        isAttributed = NO;
        for (ContactView *contactBubble in self.contactBubbleViews) {
            if (message.senderId == contactBubble.contact.identifier) {
                [contactBubble addUnreadMessage:message];
                isAttributed = YES;
                // Update last message date to sort contacts even if no push
                contactBubble.contact.lastMessageDate = MAX(contactBubble.contact.lastMessageDate,message.createdAt);
                break;
            }
        }
        
        if (!isAttributed) {
            // create contact if does not exists
            Contact *contact = [ContactUtils findContact:message.senderId inContactsArray:self.contacts];
            if (!contact) {
                contact = [Contact createContactWithId:message.senderId phoneNumber:nil firstName:nil lastName:nil];
                contact.lastMessageDate = message.createdAt;
                contact.isPending = YES;
                [self.contacts addObject:contact];
            }
            // create bubble
            [self displayAdditionnalContact:contact];
            [[self.contactBubbleViews lastObject] addUnreadMessage:message];
        }
    }
    
    // Redisplay correctly
    self.nonAttributedUnreadMessages = nil;
    [self redisplayContact];
    [self setScrollViewSizeForContactCount:(int)[self.contacts count]];
}


// ------------------------------
#pragma mark Click & navigate
// ------------------------------
- (IBAction)menuButtonClicked:(id)sender {
    self.menuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:ACTION_SHEET_1_OPTION_0, ACTION_SHEET_2_OPTION_1, ACTION_SHEET_1_OPTION_2, ACTION_SHEET_1_OPTION_3, nil];
    
    for (UIView* view in [self.menuActionSheet subviews])
    {
        if ([view respondsToSelector:@selector(title)])
        {
            NSString* title = [view performSelector:@selector(title)];
            if ([title isEqualToString:@"Replay last message"] && [view respondsToSelector:@selector(setEnabled:)])
            {
                if (self.mainPlayer) {
                    [view performSelector:@selector(setEnabled:) withObject:@YES];
                } else {
                    [view performSelector:@selector(setEnabled:) withObject:NO];
                }
            }
        }
    }
    
    [self.menuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}


// ----------------------------------------------------------
#pragma mark Recording Mode
// ----------------------------------------------------------

- (void)recordingUIForContactView:(ContactView *)contactView
{
    [contactView recordingUI];
}

- (void)endRecordingUIForAllContactViews
{
    for (ContactView *contactView in self.contactBubbleViews) {
        [contactView endRecordingUI];
    }
}

- (void)disableAllContactViews
{
    for (UIView *view in [self.contactScrollView subviews]) {
        if ([view isKindOfClass:[ContactView class]]) {
            view.userInteractionEnabled = NO;
        }
    }
}

- (void)enableAllContactViews
{
    for (UIView *view in [self.contactScrollView subviews]) {
        if ([view isKindOfClass:[ContactView class]]) {
            view.userInteractionEnabled = YES;
        }
    }
}

- (void)addRecorderMessage:(NSString *)message color:(UIColor *)color {
    if (self.recorderMessage) {
        [self.recorderMessage removeFromSuperview];
        self.recorderMessage = nil;
    }
    
    self.recorderMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, self.recorderView.bounds.size.height/2, self.recorderView.bounds.size.width, self.recorderView.bounds.size.height/2)];
    
    self.recorderMessage.text = message;
    self.recorderMessage.font = [UIFont fontWithName:@"Avenir-Light" size:14.0];
    self.recorderMessage.textAlignment = NSTextAlignmentCenter;
    self.recorderMessage.textColor = color;
    
    [self.recorderView addSubview:self.recorderMessage];
}


// ----------------------------------------------------------
#pragma mark ContactBubbleViewDelegate Protocole
// ----------------------------------------------------------

- (void)updateFrameOfContactView:(ContactView *)view
{
    NSInteger row = view.orderPosition / 3 + 1;
    NSInteger horizontalPosition = 3 - (3*(view.orderPosition/3) + 2 - view.orderPosition);
    float rowHeight = kContactMargin + kContactSize + kContactNameHeight;
    view.frame = CGRectMake(kContactMargin + (horizontalPosition - 1) * (kContactSize + kContactMargin), kContactMargin + (row - 1)* rowHeight, kContactSize, kContactSize);
    
    // Update frame of Name Label too
    view.nameLabel.frame = CGRectMake(view.frame.origin.x - kContactMargin/4, view.frame.origin.y + kContactSize, view.frame.size.width + kContactMargin/2, kContactNameHeight);
}

//Create recording mode screen
- (void)longPressOnContactBubbleViewStarted:(NSUInteger)contactId FromView:(ContactView *)view
{
    [self disableAllContactViews];
    
    [self recordingUIForContactView:view];
    
    self.recorderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.recorderContainer.bounds.size.width, self.recorderContainer.bounds.size.height)];
    self.recorderView.backgroundColor = [ImageUtils red];
    [self.recorderContainer addSubview:self.recorderView];
    
    self.recorderContainer.hidden = NO;
    
    //Recording line starting point
    ctr = 0;
    self.recordingLineX = 0;
    self.recordingLineY = self.recorderView.bounds.size.height/2;
    ctr = 0;
    pts[ctr] = CGPointMake(self.recordingLineX, self.recordingLineY);
    
    [self addRecorderMessage:@"Release to send..." color:[UIColor whiteColor]];
}

//User stop pressing screen
- (void)longPressOnContactBubbleViewEnded:(NSUInteger)contactId
{
    //Bring the recording line to zero, to prepare sending animation
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:pts[0]];
    self.recordingLineX = self.recordingLineX + self.recordLineLength/METERS_FREQUENCY;
    self.recordingLineY = self.recorderView.bounds.size.height/2;
    [path addLineToPoint:CGPointMake(self.recordingLineX, self.recordingLineY)];
    [self.recorderView.layer addSublayer:[self shapeLayerWithPath:path]];
    
    [self addRecorderMessage:@"Sending..." color:[UIColor whiteColor]];
}

//Recorder notifies a change in volume intensity (every 0.05 seconds)
- (void)notifiedNewMeters:(float)power
{
    ctr ++;
    
    if (self.recordLineLength == 0) {
        self.recordLineLength = self.recorderView.bounds.size.width;
    }
    
    self.recordingLineX = self.recordingLineX + self.recorderView.bounds.size.width/METERS_FREQUENCY;
    
    if (power + (-MIN_METERS) < 0) {
        power = 0;
    } else {
        power = power + (-MIN_METERS);
    }
    
    self.recordingLineY = self.recorderView.bounds.size.height/2 - RECORDER_LINE_MAX_HEIGHT * (power/(MAX_METERS + (-MIN_METERS)));
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
        
        [self.recorderView.layer addSublayer:[self shapeLayerWithPath:path]];
    }
}

- (void)messageSentWithError:(BOOL)error
{
    if (error) {
        [self addRecorderMessage:@"Sending failed." color:[UIColor whiteColor]];
        
        sleep(1);
        
        [self quitRecordingModeAnimated:YES];
    } else {
        [self addRecorderMessage:@"Sent!" color:[UIColor whiteColor]];
        
        float initialWidth = 0;
        float finalWidth = self.recorderView.bounds.size.width - self.recordingLineX;
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.recordingLineX, self.recorderView.bounds.size.height/2 - RECORDER_LINE_WEIGHT, initialWidth, RECORDER_LINE_WEIGHT)];
        
        line.backgroundColor = [UIColor whiteColor];
        
        [self.recorderView addSubview:line];
        
        [UIView animateWithDuration:0.5 animations:^{
            CGRect frame = line.frame;
            frame.size.width = finalWidth;
            line.frame = frame;
        } completion:^(BOOL dummy){
            [self quitRecordingModeAnimated:YES];
        }];
    }
}

- (void)startedPlayingAudioFileByView:(ContactView *)contactView
{
    self.lastContactPlayed = contactView;
    
    //TODO restart player
    [self playerUI:self.mainPlayer.duration ByContactView:contactView];
}

- (void)quitRecordingModeAnimated:(BOOL)animated
{
    [self enableAllContactViews];
    if (animated) {
        [UIView animateWithDuration:1.0 animations:^{
            self.recorderView.alpha = 0;
        } completion:^(BOOL dummy){
            [self.recorderView removeFromSuperview];
            self.recorderView = nil;
            self.recorderContainer.hidden = YES;
        }];
    } else {
        [self.recorderView removeFromSuperview];
        self.recorderView = nil;
        self.recorderContainer.hidden = YES;
    }
}

- (void)pendingContactClicked:(Contact *)contact
{
    // check contact access
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        [GeneralUtils showMessage:@"To activate it, go to Settings > Privacy > Contacts" withTitle:@"Waved does not have access to your contacts"];
        return;
    }
    
    self.contactToAdd = contact;
    UIActionSheet *pendingActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                    delegate:self
                                                           cancelButtonTitle:ACTION_SHEET_CANCEL
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:ACTION_SHEET_2_OPTION_1, ACTION_SHEET_2_OPTION_2, nil];
    [pendingActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}


// ----------------------------------------------------------
#pragma mark Player Mode
// ----------------------------------------------------------

- (void)playerUIForContactView:(ContactView *)contactView
{
    [contactView playingUI];
}

- (void)endPlayerUIForAllContactViews
{
    for (ContactView *contactView in self.contactBubbleViews) {
        [contactView endPlayingUI];
    }
}

// Audio Playing UI + volume setting
- (void)playerUI:(NSTimeInterval)duration ByContactView:(ContactView *)contactView
{
    // Min volume (legal / deprecated ?)
    MPMusicPlayerController *appPlayer = [MPMusicPlayerController applicationMusicPlayer];
    float volumeLevel = appPlayer.volume;
    if (volumeLevel < 0.5) {
        [appPlayer setVolume:0.5];
    }
    
    [self playerUIForContactView:contactView];
    self.playerContainer.hidden = NO;
    
    float initialWidth = 0;
    float finalWidth = self.playerContainer.bounds.size.width;
    
    self.playerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, initialWidth, PLAYER_LINE_WEIGHT)];
    
    self.playerView.backgroundColor = [ImageUtils green];
    
    [self.playerContainer addSubview:self.playerView];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         CGRect frame = self.playerView.frame;
                         frame.size.width = finalWidth;
                         self.playerView.frame = frame;
                     } completion:^(BOOL finished){
                         if (finished) {
                             [appPlayer setVolume:volumeLevel];
                             [self endPlayerUI];
                         }
                     }];
}

- (void)endPlayerUI
{
    [self endPlayerUIForAllContactViews];
    
    if ([self.mainPlayer isPlaying]) {
        [self.mainPlayer stop];
        self.mainPlayer.currentTime = 0;
    }
    
    [self.playerView.layer removeAllAnimations];
    [self.playerView removeFromSuperview];
    self.playerView = nil;
    
    self.playerContainer.hidden = YES;
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
    shapeLayer.strokeColor = [[UIColor whiteColor] CGColor];
    shapeLayer.lineWidth = RECORDER_LINE_WEIGHT;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    return shapeLayer;
}


// ----------------------------------------------------------
#pragma mark ABNewPersonViewControllerDelegate
// ----------------------------------------------------------
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
    if (!person) { // cancel clicked
        self.contactToAdd = nil;
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        ABMultiValueRef phones =ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSString* mobile=@"";
        NSString* mobileLabel;
        for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
            mobileLabel = (__bridge NSString *)(ABMultiValueCopyLabelAtIndex(phones, i));
            if([mobileLabel isEqualToString:(NSString *)kABPersonPhoneMainLabel])
            {
                mobile = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, i));
            }
        }
        
        for (ContactView *contactBubble in self.contactBubbleViews) {
            if ([mobile isEqualToString:contactBubble.contact.phoneNumber]) {
                if (contactBubble.pendingContact) {
                    [contactBubble setPendingContact:NO];
                    contactBubble.contact.isPending = NO;
                    self.contactToAdd = nil;
                }
                break;
            }
        }
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

// ----------------------------------------------------------
#pragma mark ActionSheetProtocol
// ----------------------------------------------------------
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    
    //Replay message
    if ([buttonTitle isEqualToString:ACTION_SHEET_1_OPTION_0]) {
        [self endPlayerUI];
        
        [self playerUI:([self.mainPlayer duration]) ByContactView:self.lastContactPlayed];
        
        [self.mainPlayer play];
        [TrackingUtils trackReplay];
    //Add contact
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_1_OPTION_1]) {
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        [self presentViewController:picker animated:YES completion:nil];
        [TrackingUtils trackAddContact];
        //Share (in the future, it'd be cool to share a vocal message!)
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_1_OPTION_2]) {
        NSString *shareString = @"Download Waved, the fastest messaging app.";
        
        NSURL *shareUrl = [NSURL URLWithString:kProdAFHeardWebsite];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [activityViewController setValue:@"You should download Waved." forKey:@"subject"];
        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop, UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard];
        
        [self presentViewController:activityViewController animated:YES completion:nil];
        
        [TrackingUtils trackShare];
        //Send feedback
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_1_OPTION_3]) {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=Feedback for Waved on iOS (v%@)", kFeedbackEmail,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
    //BB: Add contact a contact not in address book: should be merged with add contact
    else if ([buttonTitle isEqualToString:ACTION_SHEET_2_OPTION_1]) {
        // create person record
        ABRecordRef person = ABPersonCreate();
        
        // Fill contact info if any
        if (self.contactToAdd) {
            ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFStringRef) self.contactToAdd.firstName, NULL);
            ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFStringRef) self.contactToAdd.lastName, NULL);
            ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)self.contactToAdd.phoneNumber, kABPersonPhoneMainLabel, NULL);
            ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumbers, nil);
        }
        
        // let's show view controller
        ABNewPersonViewController *controller = [[ABNewPersonViewController alloc] init];
        controller.displayedPerson = person;
        controller.newPersonViewDelegate = self;
        UINavigationController *newNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [self.navigationController presentViewController:newNavigationController animated:YES completion:nil];
        CFRelease(person);
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_2_OPTION_2]) {
        // block user + delete bubble / contact
        void(^successBlock)() = ^void() {
            NSInteger holePosition = 0;
            for (ContactView * bubbleView in self.contactBubbleViews) {
                if (bubbleView.contact.identifier == self.contactToAdd.identifier) {
                    [bubbleView removeFromSuperview];
                    holePosition = bubbleView.orderPosition;
                    [self.contacts removeObject:bubbleView.contact];
                    [bubbleView.nameLabel removeFromSuperview];
                    // update Badge
                    if (bubbleView.unreadMessages) {
                        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - bubbleView.unreadMessages.count];
                    }
                    [self.contactBubbleViews removeObject:bubbleView];
                    break;
                }
            }
            // Change position of other bubbles
            [self redisplayContact];
            
            // Update badge & scroll view frame
            [self setScrollViewSizeForContactCount:(int)[self.contactBubbleViews count]];
            self.contactToAdd = nil;
        };
        [ApiUtils blockUser:self.contactToAdd.identifier AndExecuteSuccess:successBlock failure:nil];
    }
}



// ----------------------------------------------------------
#pragma mark ABPeoplePickerNavigationControllerDelegate
// ----------------------------------------------------------
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
        viewController.body = [NSString stringWithFormat:@"Download Waved, the fastest messaging app, at %@", kProdAFHeardWebsite];
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


// ----------------------------------------------------------
#pragma mark MFMessageComposeViewControllerDelegate
// ----------------------------------------------------------
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


// ----------------------------------------------------------
#pragma mark OutPut Port
// ----------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"inputDataSources"]) {
        self.isUsingHeadSet = [AudioUtils usingHeadsetInAudioSession:[AVAudioSession sharedInstance]];
    }
}

- (void)setIsUsingHeadSet:(BOOL)isUsingHeadSet {
    _isUsingHeadSet = isUsingHeadSet;
    [self updateOutputAudioPort];
}

- (void)updateOutputAudioPort {
    BOOL success; NSError* error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (self.isUsingHeadSet || [UIDevice currentDevice].proximityState ) {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    } else {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    }
    if (!success)
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
}

@end
