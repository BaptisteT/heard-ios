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
#import "FDWaveformView.h"
#import "AddContactViewController.h"

#define ACTION_SHEET_1_OPTION_1 @"Invite Contacts"
#define ACTION_SHEET_1_OPTION_2 @"Add Contact"
#define ACTION_SHEET_1_OPTION_3 @"Other"
#define ACTION_SHEET_2_OPTION_1 @"Profile"
#define ACTION_SHEET_2_OPTION_2 @"Share"
#define ACTION_SHEET_2_OPTION_3 @"Feedback"
#define ACTION_SHEET_PENDING_OPTION_1 @"Add contact"
#define ACTION_SHEET_PENDING_OPTION_2 @"Block user"
#define ACTION_SHEET_PROFILE_OPTION_1 @"Picture"
#define ACTION_SHEET_PROFILE_OPTION_2 @"First Name"
#define ACTION_SHEET_PROFILE_OPTION_3 @"Last Name"
#define ACTION_SHEET_PICTURE_OPTION_1 @"Camera"
#define ACTION_SHEET_PICTURE_OPTION_2 @"Library"
#define ACTION_SHEET_CANCEL @"Cancel"

#define RECORDER_LINE_HEIGHT 0.4
#define RECORDER_HEIGHT 50
#define RECORDER_VERTICAL_MARGIN 5
#define RECORDER_MESSAGE_HEIGHT 20

#define PLAYER_LINE_HEIGHT 0.4
#define PLAYER_UI_HEIGHT 50
#define PLAYER_UI_VERTICAL_MARGIN 5

#define INVITE_CONTACT_BUTTON_HEIGHT 50
#define TUTORIAL_VIEW_HEIGHT 60

@interface DashboardViewController ()

// Contacts
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactBubbleViews;
@property (weak, nonatomic) UIScrollView *contactScrollView;
@property (nonatomic) BOOL retrieveNewContact;
@property (nonatomic, strong) Contact *contactToAdd;
@property (nonatomic, strong) UITextView *noAddressBookAccessLabel;
// Record
@property (strong, nonatomic) UIView *recorderContainer;
@property (nonatomic,strong) EZAudioPlotGL *audioPlot;
@property (nonatomic,strong) EZMicrophone *microphone;
@property (nonatomic,strong) UIView *recorderLine;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic) SystemSoundID recordSound;
@property (nonatomic, strong) UILabel *recorderMessage;
@property (strong, nonatomic) NSDate* lastRecordSoundDate;
@property (nonatomic) BOOL silentMode;
// Player
@property (strong, nonatomic) UIView *playerContainer;
@property (nonatomic, strong) FDWaveformView *playerWaveView;
@property (nonatomic,strong) UIView *playerLine;
@property (nonatomic, strong) AVAudioPlayer *mainPlayer;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic, strong) ContactView *lastContactPlayed;
@property (nonatomic) BOOL isUsingHeadSet;
// Current user
@property (nonatomic, strong) NSString *currentUserPhoneNumber;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImageView *currentUserProfilePicture;
// Others
@property (weak, nonatomic) UIButton *menuButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UIView *tutorialView;
@property (strong, nonatomic) NSMutableArray *nonAttributedUnreadMessages;
@property (nonatomic, strong) Contact *resendContact;
@property (nonatomic, strong) UITapGestureRecognizer *oneTapResendRecognizer;

@end

@implementation DashboardViewController 

// ------------------------------
#pragma mark Life cycle
// ------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contactScrollView.hidden = YES;
    self.retrieveNewContact = YES;
    
    [self updateReplayButtonAppearance];
    
    // Sound callback
    AudioServicesAddSystemSoundCompletion(1113, CFRunLoopGetMain(), kCFRunLoopDefaultMode, soundMuteNotificationCompletionProc,(__bridge void *)(self));
    self.silentMode = NO;
    
    // Init address book
    self.addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(self.addressBook,MyAddressBookExternalChangeCallback, (__bridge void *)(self));
    
    // Init recorder container
    self.recorderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - RECORDER_HEIGHT, self.view.bounds.size.width, RECORDER_HEIGHT)];
    self.recorderContainer.backgroundColor = [ImageUtils red];
    [self.view addSubview:self.recorderContainer];
    self.recorderContainer.hidden = YES;
    
    // Init player container
    self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - PLAYER_UI_HEIGHT, self.view.bounds.size.width, PLAYER_UI_HEIGHT)];
    self.playerContainer.backgroundColor = [ImageUtils green];
    [self.view addSubview:self.playerContainer];
    self.playerContainer.hidden = YES;
    
    // Init resend gesture
    self.oneTapResendRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleResendTapGesture)];
    self.oneTapResendRecognizer.delegate = self;
    self.oneTapResendRecognizer.numberOfTapsRequired = 1;
    
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
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"audio.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:kAVSampleRateKey] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: kAVNumberOfChannelsKey] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    
    // AudioPlot
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    self.audioPlot = [self allocAndInitAudioPlot];
    
    // Recoder line
    self.recorderLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.audioPlot.bounds.size.height/2, 0, RECORDER_LINE_HEIGHT)];
    self.recorderLine.backgroundColor = [UIColor whiteColor];
    [self.audioPlot addSubview:self.recorderLine];
    
    // player wave view
    self.playerWaveView = [[FDWaveformView alloc] initWithFrame:CGRectMake(0, PLAYER_UI_VERTICAL_MARGIN, self.playerContainer.frame.size.width, self.playerContainer.frame.size.height - 2 * PLAYER_UI_VERTICAL_MARGIN)];
    [self.playerContainer addSubview:self.playerWaveView];
    
    // player line
    self.playerLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.playerWaveView.bounds.size.height/2, 0, RECORDER_LINE_HEIGHT)];
    self.playerLine.backgroundColor = [ImageUtils transparentWhite];
    [self.playerWaveView addSubview:self.playerLine];
    
    // Current User
    self.currentUserPhoneNumber = [SessionUtils getCurrentUserPhoneNumber];
    self.currentUserProfilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(30,1,47,47)];
    self.currentUserProfilePicture.layer.cornerRadius = self.currentUserProfilePicture.bounds.size.height/2;
    self.currentUserProfilePicture.clipsToBounds = YES;
    self.currentUserProfilePicture.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.currentUserProfilePicture.layer.borderWidth = 0.5;
    [ImageUtils setWithoutCachingImageView:self.currentUserProfilePicture withURL:[GeneralUtils getUserProfilePictureURLFromUserId:[SessionUtils getCurrentUserId]]];
}

// Make sure scroll view has been resized (necessary because layout constraints change scroll view size)
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setScrollViewSizeForContactCount:(int)[self.contacts count]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Add Contact Segue"]) {
        ((AddContactViewController *) [segue destinationViewController]).delegate = self;
    }
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
                existingContact.isPending = NO;
                
                //Use server name if blank in address book
                NSString *firstName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
                
                if (firstName && [firstName length] > 0) {
                    contact.firstName = firstName;
                }
                contact.lastName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
                existingContact.phoneNumber = contact.phoneNumber;
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
void MyAddressBookExternalChangeCallback (ABAddressBookRef notificationAddressBook,CFDictionaryRef info,void *context)
{
    DashboardViewController * dashboardController = (__bridge DashboardViewController *)context;
    dashboardController.retrieveNewContact = YES;
    dashboardController.addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(dashboardController.addressBook, MyAddressBookExternalChangeCallback, (__bridge void *)(dashboardController));
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
    [TrackingUtils trackNumberOfContacts:[self.contacts count]];
    
    //Because of bug when user quits app while playing a message
    [self endPlayerUIAnimated:NO];
    
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

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[SessionUtils getCurrentUserFirstName]
                                                       delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:ACTION_SHEET_1_OPTION_2, ACTION_SHEET_1_OPTION_1, ACTION_SHEET_1_OPTION_3, nil];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *_currentView in actionSheet.subviews) {
        if ([_currentView isKindOfClass:[UILabel class]]) {
            CGRect frame = ((UILabel *)_currentView).frame;
            [(UILabel *)_currentView setFont:[UIFont fontWithName:@"Avenir-Heavy" size:18.f]];
            ((UILabel *)_currentView).frame = CGRectMake(frame.origin.x, 0, frame.size.width, 80);
            [(UILabel *)_currentView.superview addSubview:self.currentUserProfilePicture];
        }
    }
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
    
    self.recorderMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.recorderContainer.bounds.size.width, self.recorderContainer.bounds.size.height)];
    
    self.recorderMessage.text = message;
    self.recorderMessage.font = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    self.recorderMessage.textAlignment = NSTextAlignmentCenter;
    self.recorderMessage.textColor = color;
    [self.recorderContainer addSubview:self.recorderMessage];
}

- (void)startRecordSound
{
    self.lastRecordSoundDate = [NSDate date];
    AudioServicesPlaySystemSound(1113);
    
    //For custom sound
    //AudioServicesPlaySystemSound (self.recordSound);
}

- (void)setRecorderLineWidth:(float)width {
    CGRect frame = self.recorderLine.frame;
    frame.size.width = width;
    self.recorderLine.frame = frame;
}

// ----------------------------------
#pragma mark Sending Messages
// ----------------------------------

- (void)handleResendTapGesture
{
    if (self.resendContact) {
        [self addRecorderMessage:@"Sending..." color:[UIColor whiteColor]];
        [self sendRecordtoContact:self.resendContact];
    } else {
        [self quitRecordingModeAnimated:NO];
    }
}

- (void)sendRecordtoContact:(Contact *)contact
{
    self.recorderContainer.userInteractionEnabled = NO;
    NSData *audioData = [[NSData alloc] initWithContentsOfURL:self.recorder.url];
    [ApiUtils sendMessage:audioData toUser:contact.identifier success:^{
        // Update last message date
        contact.lastMessageDate = [[NSDate date] timeIntervalSince1970];
        self.resendContact = nil;
        [self messageSentWithError:NO];
    } failure:^{
        self.resendContact = contact;
        [self messageSentWithError:YES];
    }];
}

- (void)messageSentWithError:(BOOL)error
{
    if (error) {
        [self addRecorderMessage:@"Failed, tap to resend." color:[UIColor whiteColor]];
        self.recorderContainer.userInteractionEnabled = YES;
        [self enableAllContactViews];
        [self.recorderContainer addGestureRecognizer:self.oneTapResendRecognizer];
    } else {
        [self addRecorderMessage:@"Sent!" color:[UIColor whiteColor]];
        
        [self quitRecordingModeAnimated:YES];
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
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerUIAnimated:NO];
    }
    [self disableAllContactViews];
    
    [self recordingUIForContactView:view];
    
    // Case where we had a pending message
    if (!self.recorderContainer.isHidden) {
        [self.audioPlot clear];
        [self setRecorderLineWidth:0];
        self.resendContact = nil;
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
    [self.recorder record];
}

//User stop pressing screen
- (void)longPressOnContactBubbleViewEnded:(NSUInteger)contactId
{
    // Stop recording
    [self.recorder stop];
    [self.microphone stopFetchingAudio];
    
    self.recorderLine.frame = [[self.recorderLine.layer presentationLayer] frame];
    [self.recorderLine.layer removeAllAnimations];
    [self setRecorderLineWidth:0];
    [self.audioPlot clear];
    [self.audioPlot removeFromSuperview];
    [self addRecorderMessage:@"Sending..." color:[UIColor whiteColor]];
}

- (void)startedPlayingAudioFileByView:(ContactView *)contactView
{
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerUIAnimated:NO];
    }
    [self.playerContainer.layer removeAllAnimations];
    
    // Waveform
    [self.playerWaveView setAudioURL:[GeneralUtils getPlayedAudioURL]];
    self.playerWaveView.progressSamples = 10000;
    
    self.lastContactPlayed = contactView;
    
    // Init player
    self.mainPlayer = [[AVAudioPlayer alloc] initWithData:contactView.nextMessageAudioData error:nil];
    [self.mainPlayer setVolume:kAudioPlayerVolume];
    
    [self updateReplayButtonAppearance];
    
    // Player UI
    NSTimeInterval duration = self.mainPlayer.duration;
    [self playerUI:duration ByContactView:contactView];
    
    // play
    [self.mainPlayer play];
    
    // MixPanel
    [TrackingUtils trackPlayWithDuration:duration];
}

- (void)quitRecordingModeAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:1 animations:^{
            self.recorderContainer.alpha = 0;
        } completion:^(BOOL dummy){
            [self enableAllContactViews];
            self.recorderContainer.hidden = YES;
            self.recorderContainer.alpha = 1;
        }];
    } else {
        [self enableAllContactViews];
        [self setRecorderLineWidth:0];
        [self.audioPlot clear];
        [self.audioPlot removeFromSuperview];
        self.recorderContainer.hidden = YES;
    }
}

- (BOOL)isRecording {
    return self.recorder.isRecording;
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
                                                           otherButtonTitles:ACTION_SHEET_PENDING_OPTION_1, ACTION_SHEET_PENDING_OPTION_2, nil];
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
    self.playerContainer.alpha = 1;
    [self setPlayerLineWidth:0];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.playerWaveView.renderingInProgress = NO;
                         self.playerWaveView.progressSamples = self.playerWaveView.totalSamples;
                         [self setPlayerLineWidth:self.playerWaveView.bounds.size.width];
                     } completion:^(BOOL finished){
                         if (finished) {
                             [self endPlayerUIAnimated:YES];
                         }
                     }];
}

- (void)endPlayerUIAnimated:(BOOL)animated
{
    self.playerWaveView.progressSamples = 0;
    // Remove proximity state (here because player delegate not working)
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
    [self.playerWaveView.layer removeAllAnimations];
    
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            self.playerContainer.alpha = 0;
        } completion:^(BOOL dummy){
            if (dummy) {
                self.playerContainer.hidden = YES;
            }
        }];
    } else {
        self.playerContainer.hidden = YES;
        [self setPlayerLineWidth:0];
    }
    
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

- (void)updateReplayButtonAppearance
{
    if (self.mainPlayer) {
        self.replayButton.hidden = NO;
    } else {
        self.replayButton.hidden = YES;
    }
}

- (IBAction)replayButtonClicked:(id)sender {
    [self endPlayerUIAnimated:NO];
    
    [self playerUI:([self.mainPlayer duration]) ByContactView:self.lastContactPlayed];
    
    [self.mainPlayer play];
    [TrackingUtils trackReplay];
}

- (void)setPlayerLineWidth:(float)width {
    CGRect frame = self.playerLine.frame;
    frame.size.width = width;
    self.playerLine.frame = frame;
}

//- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
//{
//    if (!person) { // cancel clicked
//        self.contactToAdd = nil;
//        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//    } else {
//        ABMultiValueRef phones =ABRecordCopyValue(person, kABPersonPhoneProperty);
//        NSMutableArray* mobileNumbers = [NSMutableArray new];
//        for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
//            [mobileNumbers addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, i))];
//        }
//        
//        BOOL isAttributed = NO;
//        for (NSString *mobile in mobileNumbers) {
//            for (ContactView *contactBubble in self.contactBubbleViews) {
//                if ([mobile isEqualToString:contactBubble.contact.phoneNumber]) {
//                    if (contactBubble.pendingContact) {
//                        [contactBubble setPendingContact:NO];
//                        contactBubble.contact.isPending = NO;
//                        self.contactToAdd = nil;
//                    }
//                    isAttributed = YES;
//                    break;
//                }
//            }
//            if (isAttributed) {
//                break;
//            }
//        }
//        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//    }
//}

// ----------------------------------------------------------
#pragma mark ActionSheetProtocol
// ----------------------------------------------------------
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    
    // Invite contact
    if ([buttonTitle isEqualToString:ACTION_SHEET_1_OPTION_1]) {
        [self performSegueWithIdentifier:@"Invite Contacts Segue" sender:nil];
        
    // Add New Contact
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_1_OPTION_2]) {
        [self performSegueWithIdentifier:@"Add Contact Segue" sender:nil];
    }
    
    // Other
    else if ([buttonTitle isEqualToString:ACTION_SHEET_1_OPTION_3]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_SHEET_2_OPTION_1, ACTION_SHEET_2_OPTION_2, ACTION_SHEET_2_OPTION_3, nil];
        
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    // Profile
    else if ([buttonTitle isEqualToString:ACTION_SHEET_2_OPTION_1]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_SHEET_PROFILE_OPTION_1, ACTION_SHEET_PROFILE_OPTION_2, ACTION_SHEET_PROFILE_OPTION_3, nil];
        
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    // Share
    else if ([buttonTitle isEqualToString:ACTION_SHEET_2_OPTION_2]) {
        NSString *shareString = @"Download Waved, the fastest messaging app.";
        
        NSURL *shareUrl = [NSURL URLWithString:kProdAFHeardWebsite];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [activityViewController setValue:@"You should download Waved." forKey:@"subject"];
        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop, UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard];
        
        [activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
            if (completed) {
                [TrackingUtils trackShareSuccessful:YES];
            } else {
                [TrackingUtils trackShareSuccessful:NO];
            }
        }];
        
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    
    //Send feedback
    else if ([buttonTitle isEqualToString:ACTION_SHEET_2_OPTION_3]) {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=Feedback for Waved on iOS (v%@)", kFeedbackEmail,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
    
    // Add contact
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PENDING_OPTION_1]) {
        [self performSegueWithIdentifier:@"Add Contact Segue" sender:nil];
    }
    
    // Block contact
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PENDING_OPTION_2]) {
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
    
    // Picture
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_1]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_SHEET_PICTURE_OPTION_1, ACTION_SHEET_PICTURE_OPTION_2, nil];
        
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    // Camera
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PICTURE_OPTION_1]) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
    }
    
    // Library
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PICTURE_OPTION_2]) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    
    // First Name
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_2] || [buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_3]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:buttonTitle message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [alert textFieldAtIndex:0];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.text = [buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_2] ? [SessionUtils getCurrentUserFirstName] : [SessionUtils getCurrentUserLastName];
        [textField becomeFirstResponder];
        [alert addSubview:textField];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:ACTION_SHEET_PROFILE_OPTION_2] || [alertView.title isEqualToString:ACTION_SHEET_PROFILE_OPTION_3]) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if (buttonIndex == 0) // cancel
            return;
        if ([textField.text length] <= 0) {
            [GeneralUtils showMessage:[alertView.title stringByAppendingString:@" must between 1 and 20 characters."] withTitle:nil];
        }
        if (buttonIndex == 1) {
            [alertView.title isEqualToString:ACTION_SHEET_PROFILE_OPTION_2] ? [ApiUtils updateFirstName:textField.text success:nil failure:nil] : [ApiUtils updateLastName:textField.text success:nil failure:nil];
        }
    }
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
    EZAudioPlotGL *audioPlot = [[EZAudioPlotGL alloc] initWithFrame:CGRectMake(0, RECORDER_VERTICAL_MARGIN, self.recorderContainer.bounds.size.width, self.recorderContainer.bounds.size.height - RECORDER_VERTICAL_MARGIN * 2)];
    audioPlot.backgroundColor = [ImageUtils red];
    audioPlot.color           = [UIColor whiteColor];
    audioPlot.plotType        = EZPlotTypeRolling;
    audioPlot.shouldFill      = YES;
    audioPlot.shouldMirror    = YES;
    [audioPlot setRollingHistoryLength:1290]; // todo BT make this precise & robust
    audioPlot.gain = 8;
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


// ----------------------------------------------------------
#pragma mark System Sound callback
// ----------------------------------------------------------
void soundMuteNotificationCompletionProc(SystemSoundID  ssID,void* clientData){
    double diff = [[NSDate date] timeIntervalSinceDate:((__bridge DashboardViewController *)clientData).lastRecordSoundDate];
    ((__bridge DashboardViewController *)clientData).silentMode = diff < 0.1;
}

- (NSTimeInterval)delayBeforeRecording
{
    if (self.silentMode) {
        return 0;
    } else {
        return kMinAudioDuration;
    }
}


// --------------------------
// Profile picture change
// --------------------------

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (image) {
        CGSize rescaleSize = {kProfilePictureSize, kProfilePictureSize};
        image = [ImageUtils imageWithImage:[ImageUtils cropBiggestCenteredSquareImageFromImage:image withSide:image.size.width] scaledToSize:rescaleSize];
        [self.currentUserProfilePicture setImage:image];
        
        NSString *encodedImage = [ImageUtils encodeToBase64String:image];
        [ApiUtils updateProfilePicture:encodedImage success:nil failure:nil];
    } else {
        NSLog(@"Failed to get image");
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didFinishedAddingContact
{
    [self showLoadingIndicator];
    
    self.retrieveNewContact = YES;
    
    [self retrieveUnreadMessagesAndNewContacts];
}


@end
