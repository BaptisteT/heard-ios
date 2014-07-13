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

#define ACTION_SHEET_1_OPTION_0 @"Replay"
#define ACTION_SHEET_1_OPTION_1 @"Invite contact"
#define ACTION_SHEET_1_OPTION_2 @"Share"
#define ACTION_SHEET_1_OPTION_3 @"Feedback"
#define ACTION_SHEET_2_OPTION_1 @"Add contact"
#define ACTION_SHEET_2_OPTION_2 @"Block user"
#define ACTION_SHEET_CANCEL @"Cancel"

#define RECORDER_LINE_HEIGHT 0.4
#define RECORDER_HEIGHT 50
#define RECORDER_MESSAGE_HEIGHT 20

#define PLAYER_LINE_WEIGHT 6

#define INVITE_CONTACT_BUTTON_HEIGHT 50
#define TUTORIAL_VIEW_HEIGHT 60

@interface DashboardViewController ()

@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactBubbleViews;
@property (weak, nonatomic) UIScrollView *contactScrollView;
@property (strong, nonatomic) UIActionSheet *menuActionSheet;
@property (strong, nonatomic) UIView *recorderContainer;
@property (strong, nonatomic) UIView *playerContainer;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, strong) UILabel *recorderMessage;
@property (weak, nonatomic) UIButton *menuButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) NSString *currentUserPhoneNumber;
@property (nonatomic, strong) Contact *contactToAdd;
@property (strong, nonatomic) NSMutableArray *nonAttributedUnreadMessages;
@property (nonatomic, strong) ContactView *lastContactPlayed;
@property (nonatomic) BOOL isUsingHeadSet;
@property (nonatomic, strong) NSData *resendAudioData;
@property (nonatomic, strong) Contact *resendContact;
@property (nonatomic, strong) UITapGestureRecognizer *oneTapResendRecognizer;
@property (nonatomic) ABAddressBookRef addressBook;
@property (nonatomic, strong) UIButton *inviteContactButton;
@property (nonatomic, strong) UITextView *noAddressBookAccessLabel;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic, strong) UIView *tutorialView;
@property (nonatomic) BOOL retrieveNewContact;
@property (nonatomic) SystemSoundID recordSound;

@property (nonatomic,strong) EZAudioPlotGL *audioPlot;
@property (nonatomic,strong) EZMicrophone *microphone;
@property (nonatomic,strong) UIView *recorderLine;


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
    
    self.contactScrollView.hidden = YES;
    self.retrieveNewContact = YES;
    
    //For custom sound
    //Init recording sound
//    CFURLRef soundFileURLRef  = CFBundleCopyResourceURL (CFBundleGetMainBundle (), CFSTR ("record-sound"), CFSTR ("aif"), NULL);
//    AudioServicesCreateSystemSoundID(soundFileURLRef, &_recordSound);
    
    // Init address book
    self.addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(self.addressBook, MyAddressBookExternalChangeCallback, (__bridge void *)(self));
    
    // Init recorder container
    self.recorderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - RECORDER_HEIGHT, self.view.bounds.size.width, RECORDER_HEIGHT)];
    self.recorderContainer.backgroundColor = [ImageUtils red];
    [self.view addSubview:self.recorderContainer];
    self.recorderContainer.hidden = YES;
    
    // Init player container
    self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - PLAYER_LINE_WEIGHT, self.view.bounds.size.width, PLAYER_LINE_WEIGHT)];
    [self.view addSubview:self.playerContainer];
    self.playerContainer.hidden = YES;
    
    // Init resend gesture
    self.oneTapResendRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleResendTapGesture)];
    self.oneTapResendRecognizer.delegate = self;
    self.oneTapResendRecognizer.numberOfTapsRequired = 1;
    
    self.currentUserPhoneNumber = [SessionUtils getCurrentUserPhoneNumber];
    
    // Init no adress book access label
    [self initNoAddressBookAccessLabel]; // we do it here to avoid to resize text in a parrallel thread
    
    // Create bubble with contacts
    self.contacts = ((HeardAppDelegate *)[[UIApplication sharedApplication] delegate]).contacts;
    // We remove contact if we do not have access to address book
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        [self.contacts removeAllObjects];
    }
    
    [self displayContacts];
    
    if (!self.contacts || [self.contacts count] == 0) {
        [self showLoadingIndicator];
    }

    // Retrieve messages & contacts
    [self retrieveUnreadMessagesAndNewContacts];
    
    // Create audio session
    AVAudioSession* session = [AVAudioSession sharedInstance];
    BOOL success; NSError* error;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (!success)
        NSLog(@"AVAudioSession error setting category:%@",error);
    
    // Add headset observer
    [session addObserver:self forKeyPath:@"inputDataSources" options:NSKeyValueObservingOptionNew context:nil];
    
    // Add proximity state observer
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceProximityStateDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification) {
                                                                 [self updateOutputAudioPort];
                                                             }];
    
    // Headset observer
    self.isUsingHeadSet = [AudioUtils usingHeadsetInAudioSession:session];
    
    // AudioPlot
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    self.audioPlot = [self allocAndInitAudioPlot];
    
    // Recoder line
    self.recorderLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.audioPlot.bounds.size.height/2, 0, RECORDER_LINE_HEIGHT)];
    self.recorderLine.backgroundColor = [UIColor whiteColor];
    [self.audioPlot addSubview:self.recorderLine];
}

// Make sure scroll view has been resized (necessary because layout constraints change scroll view size)
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setScrollViewSizeForContactCount:(int)[self.contacts count]];
}

// ------------------------------
#pragma mark UI Modes
// ------------------------------

- (void)noAddressBookAccessMode
{
    self.contactScrollView.hidden = YES;
    
    [self.view addSubview:self.noAddressBookAccessLabel];
}

- (void)initNoAddressBookAccessLabel
{
    NSUInteger labelHeight = 100;
    self.noAddressBookAccessLabel = [[UITextView alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - labelHeight)/2, self.view.bounds.size.width, labelHeight)];
    self.noAddressBookAccessLabel.userInteractionEnabled = NO;
    self.noAddressBookAccessLabel.text = @"Waved uses your address book to find your contacts. Please allow access in Settings > Privacy > Contacts.";
    self.noAddressBookAccessLabel.font = [UIFont fontWithName:@"Avenir-Light" size:17.0];
    self.noAddressBookAccessLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)initTutorialView
{
    self.tutorialView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, TUTORIAL_VIEW_HEIGHT)];
    self.tutorialView.backgroundColor = [ImageUtils blue];
    
    UILabel *tutorialMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, TUTORIAL_VIEW_HEIGHT)];
    tutorialMessage.text = @"Hold contact to record.";
    tutorialMessage.font = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    tutorialMessage.textAlignment = NSTextAlignmentCenter;
    tutorialMessage.textColor = [UIColor whiteColor];
    tutorialMessage.backgroundColor = [UIColor clearColor];
    
    [self.tutorialView addSubview:tutorialMessage];
}

- (void)tutorialModeWithDuration:(NSTimeInterval)duration
{
    [self endTutorialMode];
    
    if (!self.tutorialView) {
        [self initTutorialView];
    }
    
    self.tutorialView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, TUTORIAL_VIEW_HEIGHT);
    [self.view addSubview:self.tutorialView];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.tutorialView.frame = CGRectMake(self.tutorialView.frame.origin.x,
                                             self.tutorialView.frame.origin.y - self.tutorialView.frame.size.height,
                                             self.tutorialView.frame.size.width,
                                             self.tutorialView.frame.size.height);
    } completion:^(BOOL finished) {
        if (finished && self.tutorialView) {
            [UIView animateWithDuration:0.5 delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.tutorialView.frame = CGRectMake(self.tutorialView.frame.origin.x,
                                                     self.tutorialView.frame.origin.y + self.tutorialView.frame.size.height,
                                                     self.tutorialView.frame.size.width,
                                                     self.tutorialView.frame.size.height);
            } completion:^(BOOL finished) {
                if (finished) {
                    [self endTutorialMode];
                }
            }];
        }
    }];
}

- (void)endTutorialMode
{
    if (!self.tutorialView) {
        return;
    }
    
    [self.tutorialView.layer removeAllAnimations];
    [self.tutorialView removeFromSuperview];
}


// ------------------------------
#pragma mark Get Contact
// ------------------------------

- (void)requestAddressBookAccessAndRetrieveFriends
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [self retrieveFriendsFromAddressBook:self.addressBook];
            } else {
                // User denied access
                [self noAddressBookAccessMode];
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [self retrieveFriendsFromAddressBook:self.addressBook];
        if (self.noAddressBookAccessLabel) {
            [self.noAddressBookAccessLabel removeFromSuperview];
        }
    }
    else {
        // The user has previously denied access
        [self noAddressBookAccessMode];
    }
}

- (void)retrieveFriendsFromAddressBook:(ABAddressBookRef) addressBook
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    
    NSMutableDictionary *countryCodes = [[NSMutableDictionary alloc] init];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    self.addressBookFormattedContacts = [[NSMutableDictionary alloc] init];
    NSNumber *defaultCountryCode = [phoneUtil getCountryCodeForRegion:[phoneUtil countryCodeByCarrier]];
    
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
                    // We need unformatted numbers for the keys
                    [self.addressBookFormattedContacts setObject:contact forKey:phoneNumber];
                }
                
                //Store country codes found in international numbers
                if (nbPhoneNumber.countryCode != defaultCountryCode) {
                    if (![countryCodes objectForKey:nbPhoneNumber.countryCode]) {
                        [countryCodes setObject:[NSNumber numberWithInt:1] forKey:nbPhoneNumber.countryCode];
                    } else {
                        [countryCodes setObject:[NSNumber numberWithInt:1+[[countryCodes objectForKey:nbPhoneNumber.countryCode] intValue]] forKey:nbPhoneNumber.countryCode];
                    }
                }
            }
        }
    }
    
    // Retrieve the most common country code (except from the local one)
    NSNumber *mostCommonCountryCode;
    int maxOccurence = 0;
    for (NSNumber *countryCode in countryCodes) {
        if (maxOccurence < [[countryCodes objectForKey:countryCode] intValue]) {
            maxOccurence = [[countryCodes objectForKey:countryCode] intValue];
            mostCommonCountryCode = countryCode;
        }
    }
    
    // Try to rematch invalid phone numbers by using this country code
    for (CFIndex j = 0 ; j < peopleCount; j++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, j);
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex k = 0; k < ABMultiValueGetCount(phoneNumbers); k++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, k);
            
            if (![self.addressBookFormattedContacts objectForKey:phoneNumber]) {
                NSError *aError = nil;
                
                NBPhoneNumber *nbPhoneNumber = [phoneUtil parse:phoneNumber defaultRegion:[[phoneUtil regionCodeFromCountryCode:mostCommonCountryCode] firstObject] error:&aError];
                
                if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                    Contact *contact = [Contact createContactWithId:0 phoneNumber:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]
                                       firstName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty)
                                        lastName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty)];
                    
                    if (contact.firstName != nil || contact.lastName != nil) {
                        [self.addressBookFormattedContacts setObject:contact forKey:phoneNumber];
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
        Contact *object = [self.addressBookFormattedContacts objectForKey:phoneNumber];
        [adressBookWithFormattedKey setObject:object forKey:object.phoneNumber];
    }
    // The keys are now formatted numbers (to use local names for retrieved contacts)
    self.addressBookFormattedContacts = adressBookWithFormattedKey;
    
    for (NSString* phoneNumber in self.addressBookFormattedContacts) {
        [phoneNumbers addObject:phoneNumber];
    }
    
    // Get contacts and compare with contact in memory
    [ApiUtils getMyContacts:phoneNumbers atSignUp:self.isSignUp success:^(NSArray *contacts) {
        [self hideLoadingIndicator];
        
        for (Contact *contact in contacts) {
            Contact *existingContact = [ContactUtils findContact:contact.identifier inContactsArray:self.contacts];
            if (!existingContact) {
                [self.contacts addObject:contact];
                
                //Use server name if blank in address book
                NSString *firstName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
                
                if (firstName && [firstName length] > 0) {
                    contact.firstName = firstName;
                }
                
                contact.lastName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
                
                contact.lastMessageDate = 0;
                [self displayAdditionnalContact:contact];
            } else if (existingContact.isPending) {
                // Mark as non pending
                
                //Use server name if blank in address book
                NSString *firstName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
                
                if (firstName && [firstName length] > 0) {
                    contact.firstName = firstName;
                }
                
                contact.lastName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
                
                existingContact.phoneNumber = contact.phoneNumber;
                existingContact.isPending = NO;
            }
        }
        self.addressBookFormattedContacts = nil;
        
        // Distribute non attributed messages
        [self distributeNonAttributedMessages];
        
    } failure: ^void(NSURLSessionDataTask *task){
        [self hideLoadingIndicator];
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtils invalidTokenResponse:task]) {
            [SessionUtils redirectToSignIn];
        }
    }];
    self.isSignUp = NO;
}

// Address book changes callback
void MyAddressBookExternalChangeCallback (ABAddressBookRef ntificationaddressbook,CFDictionaryRef info,void *context)
{
    ((__bridge DashboardViewController *)context).retrieveNewContact = YES;
}

// ----------------------------------
#pragma mark Create Contact Bubble
// ----------------------------------

- (void)removeDisplayedContacts
{
    self.contactScrollView.hidden = YES;
    
    // Erase existing views
    for (ContactView *contactView in self.contactBubbleViews) {
        [contactView removeFromSuperview];
        [contactView.nameLabel removeFromSuperview];
    }
    
    self.contactBubbleViews = [[NSMutableArray alloc] init];
}

- (void)displayContacts
{
    [TrackingUtils trackNumberOfContacts:[self.contactBubbleViews count]];
    
    //Because of bug when user quits app while playing a message
    [self endPlayerUI];
    
    [self removeDisplayedContacts];
    
    self.contactScrollView.hidden = NO;
    
    NSUInteger contactCount = [self.contacts count];
    
    if (contactCount == 0) {
        return;
    }
    
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
    
    // Resize view
    [self setScrollViewSizeForContactCount:(int)[self.contacts count]];
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
    
    // Resize view
    [self setScrollViewSizeForContactCount:(int)[self.contacts count]];
    
    if ([GeneralUtils isFirstOpening]) {
        [self tutorialModeWithDuration:10];
    }
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
    self.contactScrollView.contentSize = CGSizeMake(screenWidth, MAX(screenHeight - 20, rows * rowHeight + 3 * kContactMargin));
    
    [self addInviteContactButton];
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
    
    if (contact.identifier == 1) {
        nameLabel.text = @"Waved";
        nameLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:14.0];
    } else if ([self.currentUserPhoneNumber isEqualToString:contact.phoneNumber]) {
        nameLabel.text = @"Me";
        nameLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:14.0];
    } else {
        if (contact.firstName) {
            nameLabel.text = [NSString stringWithFormat:@"%@", contact.firstName ? contact.firstName : @""];
        } else {
            nameLabel.text = [NSString stringWithFormat:@"%@", contact.lastName ? contact.lastName : @""];
        }
        
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
        if (contactView.contact.isPending && contactView.contact.identifier != kAdminId) {
            [contactView setPendingContact:YES];
        }
    }
}

- (void)addInviteContactButton
{
    NSUInteger buttonHeight = 50;
    
    if (self.inviteContactButton) {
        [self.inviteContactButton removeFromSuperview];
        self.inviteContactButton = nil;
    }
    
    self.inviteContactButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.contactScrollView.contentSize.height - INVITE_CONTACT_BUTTON_HEIGHT, self.contactScrollView.contentSize.width, buttonHeight)];
    [self.inviteContactButton setTitle:@"Invite new contacts" forState:UIControlStateNormal];
    [self.inviteContactButton setTitle:@"Invite new contacts" forState:UIControlStateSelected];
    self.inviteContactButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:17.0];
    self.inviteContactButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteContactButton.titleLabel.textColor = [ImageUtils blue];
    
    [self.inviteContactButton addTarget:self action:@selector(inviteContacts) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contactScrollView addSubview:self.inviteContactButton];
}

// ----------------------------------
#pragma mark Display Messages
// ----------------------------------

// Retrieve unread messages and display alert
- (void) retrieveUnreadMessagesAndNewContacts
{
    void (^successBlock)(NSArray*,BOOL) = ^void(NSArray *messages, BOOL newContactOnServer) {
        //Reset unread messages
        [self resetUnreadMessages];
        BOOL areAttributed = YES;
        for (Message *message in messages) {
            areAttributed &= [self addUnreadMessageToExistingContacts:message];
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:messages.count];
        
        // Check if we have new contacts
        // App launch - Change in address book - Message from unknown - New user added current user - 0 contact
        if (self.retrieveNewContact || !areAttributed || newContactOnServer || self.contacts.count == 0) {
            [self requestAddressBookAccessAndRetrieveFriends];
            self.retrieveNewContact = NO;
        } else {
            [self redisplayContact];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *) = ^void(NSURLSessionDataTask *task){
        [self hideLoadingIndicator];
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
}


// ------------------------------
#pragma mark Click & navigate
// ------------------------------
- (IBAction)menuButtonClicked:(id)sender {
    self.menuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:ACTION_SHEET_1_OPTION_0, ACTION_SHEET_1_OPTION_2, ACTION_SHEET_1_OPTION_3, nil];
    
    for (UIView* view in [self.menuActionSheet subviews])
    {
        if ([view respondsToSelector:@selector(title)])
        {
            NSString* title = [view performSelector:@selector(title)];
            if ([title isEqualToString:ACTION_SHEET_1_OPTION_0] && [view respondsToSelector:@selector(setEnabled:)])
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
    
    self.recorderMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, self.recorderContainer.bounds.size.height - RECORDER_MESSAGE_HEIGHT, self.recorderContainer.bounds.size.width, RECORDER_MESSAGE_HEIGHT)];
    
    self.recorderMessage.text = message;
    self.recorderMessage.font = [UIFont fontWithName:@"Avenir-Light" size:14.0];
    self.recorderMessage.textAlignment = NSTextAlignmentCenter;
    self.recorderMessage.textColor = color;
    [self.audioPlot addSubview:self.recorderMessage];
}

- (void)startRecordSound
{
    AudioServicesPlaySystemSound(1113);
    //For custom sound
    //AudioServicesPlaySystemSound (self.recordSound);
}

- (void)endRecordSound
{
    AudioServicesPlaySystemSound(1114);
    //For custom sound
    //AudioServicesPlaySystemSound (self.recordSound);
}

// ----------------------------------
#pragma mark Sending Messages
// ----------------------------------

- (void)handleResendTapGesture
{
    if (self.resendContact && self.resendAudioData) {
        [self addRecorderMessage:@"Sending..." color:[UIColor whiteColor]];
        [self sendMessage:self.resendAudioData toContact:self.resendContact];
    } else {
        [self quitRecordingModeAnimated:NO];
    }
}

- (void)sendMessage:(NSData *)audioData toContact:(Contact *)contact
{
    self.audioPlot.userInteractionEnabled = NO;
    [ApiUtils sendMessage:audioData toUser:contact.identifier success:^{
        // Update last message date
        contact.lastMessageDate = [[NSDate date] timeIntervalSince1970];
        self.resendAudioData = nil;
        self.resendContact = nil;
        [self messageSentWithError:NO];
    } failure:^{
        self.resendAudioData = audioData;
        self.resendContact = contact;
        [self messageSentWithError:YES];
    }];
}

- (void)messageSentWithError:(BOOL)error
{
    if (error) {
        [self addRecorderMessage:@"Sending failed. Tap to resend." color:[UIColor whiteColor]];
        self.audioPlot.userInteractionEnabled = YES;
        [self enableAllContactViews];
        [self.audioPlot addGestureRecognizer:self.oneTapResendRecognizer];
    } else {
        [self addRecorderMessage:@"Sent!" color:[UIColor whiteColor]];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self setRecorderLineWidth:self.audioPlot.bounds.size.width];
        } completion:^(BOOL dummy){
            [self quitRecordingModeAnimated:YES];
        }];
    }
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
    
    // Case where we had a pending message
    if (!self.recorderContainer.isHidden) {
        [self.audioPlot clear];
        [self setRecorderLineWidth:0];
        self.resendContact = nil;
        self.resendAudioData = nil;
    }

    [self.recorderContainer addSubview:self.audioPlot];
    
    self.recorderContainer.hidden = NO;
    [self.microphone startFetchingAudio];
    
    float finalWidth = self.audioPlot.bounds.size.width;
    
    [UIView animateWithDuration:30
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self setRecorderLineWidth:finalWidth];
                     } completion:^(BOOL finished){
                         if (finished) {
                         }
                     }];
    [self addRecorderMessage:@"Release to send..." color:[UIColor whiteColor]];
}

//User stop pressing screen
- (void)longPressOnContactBubbleViewEnded:(NSUInteger)contactId
{
    self.recorderLine.frame = [[self.recorderLine.layer presentationLayer] frame];
    [self.recorderLine.layer removeAllAnimations];
    
    [self.microphone stopFetchingAudio];
    [self addRecorderMessage:@"Sending..." color:[UIColor whiteColor]];
}

- (void)startedPlayingAudioFileByView:(ContactView *)contactView
{
    self.lastContactPlayed = contactView;
    
    //TODO restart player
    [self playerUI:self.mainPlayer.duration ByContactView:contactView];
}

- (void)quitRecordingModeAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            self.recorderContainer.alpha = 0;
        } completion:^(BOOL dummy){
            [self enableAllContactViews];
            [self setRecorderLineWidth:0];
            [self.audioPlot clear];
            [self.audioPlot removeFromSuperview];
            self.recorderContainer.hidden = YES;
            self.recorderContainer.alpha = 1;
        }];
    } else {
        [self setRecorderLineWidth:0];
        [self.audioPlot clear];
        [self.audioPlot removeFromSuperview];
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
    if (appPlayer.volume < 0.25) {
        [appPlayer setVolume:0.25];
    }
    
    // Set loud speaker and proximity check
    self.disableProximityObserver = NO;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
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
                             [self endPlayerUI];
                         }
                     }];
}

- (void)endPlayerUI
{
    if ([UIDevice currentDevice].proximityState) {
        self.disableProximityObserver = YES;
    } else {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    }
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
    self.contactScrollView.hidden = YES;
    
    if (!self.activityView) {
        self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityView.center = self.view.center;
    }
    
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
}

- (void)hideLoadingIndicator
{
    self.contactScrollView.hidden = NO;
    
    if (self.activityView) {
        [self.activityView stopAnimating];
        [self.activityView removeFromSuperview];
    }
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
        NSMutableArray* mobileNumbers = [NSMutableArray new];
        for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
            [mobileNumbers addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, i))];
        }
        
        BOOL isAttributed = NO;
        for (NSString *mobile in mobileNumbers) {
            for (ContactView *contactBubble in self.contactBubbleViews) {
                if ([mobile isEqualToString:contactBubble.contact.phoneNumber]) {
                    if (contactBubble.pendingContact) {
                        [contactBubble setPendingContact:NO];
                        contactBubble.contact.isPending = NO;
                        self.contactToAdd = nil;
                    }
                    isAttributed = YES;
                    break;
                }
            }
            if (isAttributed) {
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
            self.contactToAdd = nil;
        };
        [ApiUtils blockUser:self.contactToAdd.identifier AndExecuteSuccess:successBlock failure:nil];
    }
}

// ----------------------------------------------------------
#pragma mark MFMessageComposeViewControllerDelegate
// ----------------------------------------------------------

- (void)inviteContacts
{
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
    picker.body = @"Join Waved to chat with me! Download at http://www.waved.io.";
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
        if (self.disableProximityObserver) {
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        }
    }
    if (!success)
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
}


// ----------------------------------------------------------
#pragma mark EZ audio
// ----------------------------------------------------------

- (EZAudioPlotGL *)allocAndInitAudioPlot {
    EZAudioPlotGL *audioPlot = [[EZAudioPlotGL alloc] initWithFrame:CGRectMake(0, 0, self.recorderContainer.bounds.size.width, self.recorderContainer.bounds.size.height - RECORDER_MESSAGE_HEIGHT / 2)];
    audioPlot.backgroundColor = [ImageUtils red];
    audioPlot.color           = [UIColor whiteColor];
    audioPlot.plotType        = EZPlotTypeRolling;
    audioPlot.shouldFill      = YES;
    audioPlot.shouldMirror    = YES;
    [audioPlot setRollingHistoryLength:1290]; // todo BT make this precise & robust
    audioPlot.gain = 4;
    return audioPlot;
}

- (void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.

    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

- (void)setRecorderLineWidth:(float)width {
    CGRect frame = self.recorderLine.frame;
    frame.size.width = width;
    self.recorderLine.frame = frame;
}

@end
