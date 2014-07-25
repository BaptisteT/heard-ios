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
#import "AddContactViewController.h"
#import "AddressbookUtils.h"
#import "MBProgressHUD.h"
#import "TutorialViewController.h"

#define ACTION_MAIN_MENU_OPTION_1 @"Invite Friends"
#define ACTION_MAIN_MENU_OPTION_2 @"Add New Contact"
#define ACTION_MAIN_MENU_OPTION_3 @"Other"
#define ACTION_OTHER_MENU_OPTION_1 @"Edit Profile"
#define ACTION_OTHER_MENU_OPTION_2 @"Share"
#define ACTION_OTHER_MENU_OPTION_3 @"Feedback"
#define ACTION_PENDING_OPTION_1 @"Add Contact"
#define ACTION_PENDING_OPTION_2 @"Block User"
#define ACTION_SHEET_PROFILE_OPTION_1 @"Picture"
#define ACTION_SHEET_PROFILE_OPTION_2 @"First Name"
#define ACTION_SHEET_PROFILE_OPTION_3 @"Last Name"
#define ACTION_SHEET_PICTURE_OPTION_1 @"Camera"
#define ACTION_SHEET_PICTURE_OPTION_2 @"Library"
#define ACTION_CONTACT_MENU_OPTION_1 @"Replay last message"
#define ACTION_CONTACT_MENU_OPTION_2 @"View in address book"
#define ACTION_CONTACT_MENU_OPTION_3 @"Block contact"
#define ACTION_SHEET_CANCEL @"Cancel"

#define RECORDER_LINE_HEIGHT 0.4
#define RECORDER_HEIGHT 50
#define RECORDER_VERTICAL_MARGIN 5
#define RECORDER_MESSAGE_HEIGHT 20

#define PLAYER_UI_HEIGHT 5

#define INVITE_CONTACT_BUTTON_HEIGHT 50
#define TUTORIAL_VIEW_HEIGHT 60

#define USER_PROFILE_VIEW_SIZE 60
#define USER_PROFILE_PICTURE_SIZE 50
#define USER_PROFILE_PICTURE_MARGIN 5


@interface DashboardViewController ()

// Contacts
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactViews;
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
@property (nonatomic, strong) UILabel *recorderMessage;
@property (strong, nonatomic) NSDate* lastRecordSoundDate;
@property (nonatomic) BOOL silentMode;
// Player
@property (strong, nonatomic) UIView *playerContainer;
@property (nonatomic,strong) UIView *playerLine;
@property (nonatomic, strong) AVAudioPlayer *mainPlayer;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic, strong) ContactView *lastContactPlayed;
@property (nonatomic) BOOL isUsingHeadSet;
// Current user
@property (nonatomic, strong) NSString *currentUserPhoneNumber;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImageView *profilePicture;
@property (nonatomic, strong) UIView *profileContainer;
@property (nonatomic, strong) UILabel *usernameLabel;

// Others
@property (weak, nonatomic) UIButton *menuButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UIView *tutorialView;
@property (strong, nonatomic) NSMutableArray *nonAttributedUnreadMessages;
@property (nonatomic, strong) Contact *resendContact;
@property (nonatomic, strong) UITapGestureRecognizer *oneTapResendRecognizer;

//Action sheets
@property (strong, nonatomic) UIActionSheet *mainMenuActionSheet;
@property (strong, nonatomic) UIActionSheet *contactMenuActionSheet;
@property (strong, nonatomic) ContactView *lastSelectedContactView;

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
    self.replayButton.hidden = YES;
    
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
    
    // Init resend gesture
    self.oneTapResendRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleResendTapGesture)];
    self.oneTapResendRecognizer.delegate = self;
    self.oneTapResendRecognizer.numberOfTapsRequired = 1;
    
    // Init no adress book access label
    [self initNoAddressBookAccessLabel]; // we do it here to avoid to resize text in a parrallel thread
    
    //Current User phone number
    self.currentUserPhoneNumber = [SessionUtils getCurrentUserPhoneNumber];
    
    //Action sheet menu profile container
    self.profileContainer = [[UIView alloc] initWithFrame:CGRectMake(8, -8 - USER_PROFILE_VIEW_SIZE, 304, USER_PROFILE_VIEW_SIZE)];
    self.profileContainer.layer.cornerRadius = 3;
    self.profileContainer.backgroundColor = [UIColor colorWithRed:240/256.0 green:240/256.0 blue:240/256.0 alpha:0.98];
    
    //Menu profile picture
    self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(USER_PROFILE_PICTURE_MARGIN,USER_PROFILE_PICTURE_MARGIN,USER_PROFILE_PICTURE_SIZE,USER_PROFILE_PICTURE_SIZE)];
    self.profilePicture.layer.cornerRadius = USER_PROFILE_PICTURE_SIZE/2;
    self.profilePicture.clipsToBounds = YES;
    self.profilePicture.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.profilePicture.layer.borderWidth = 0.5;
    [self.profileContainer addSubview:self.profilePicture];
    
    //Action sheet menu name label
    float usernameOffset = self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width + USER_PROFILE_PICTURE_MARGIN;
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(usernameOffset, 0,
                                                                       self.profileContainer.bounds.size.width - 2 * usernameOffset, self.profileContainer.bounds.size.height)];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.font = [UIFont systemFontOfSize:15.0];
    self.usernameLabel.textColor = [UIColor grayColor];
    [self.profileContainer addSubview:self.usernameLabel];
    
    // Create bubble with contacts
    self.contacts = ((HeardAppDelegate *)[[UIApplication sharedApplication] delegate]).contacts;
    // We remove contact if we do not have access to address book
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        [self.contacts removeAllObjects];
    }
    [self displayContactViews];

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
    
    // Init player container
    self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - PLAYER_UI_HEIGHT, self.view.bounds.size.width, PLAYER_UI_HEIGHT)];
    self.playerContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.playerContainer];
    self.playerContainer.hidden = YES;
    
    // player line
    self.playerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, PLAYER_UI_HEIGHT)];
    self.playerLine.backgroundColor = [ImageUtils green];
    [self.playerContainer addSubview:self.playerLine];
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
            if (duration > 0) {
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

- (void)showTutorialController
{
    TutorialViewController *tutorial = [self.storyboard instantiateViewControllerWithIdentifier:@"TutorialViewController"];
    
    tutorial.view.backgroundColor = [ImageUtils tutorialBlue];
    
    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:tutorial animated:YES completion:NULL];
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
                self.addressBookFormattedContacts = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
                [self matchPhoneContactsWithHeardUsers];
            } else {
                // User denied access
                [self noAddressBookAccessMode];
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        self.addressBookFormattedContacts = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
        [self matchPhoneContactsWithHeardUsers];

        if (self.noAddressBookAccessLabel) {
            [self.noAddressBookAccessLabel removeFromSuperview];
        }
    }
    else {
        // The user has previously denied access
        [self noAddressBookAccessMode];
    }
}

- (void)matchPhoneContactsWithHeardUsers
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
            }
            else if (existingContact.isPending) {
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

    ABAddressBookRevert(notificationAddressBook);
}

//After adding a contact with AddContactViewController (delegate method) or after adding pending contact
- (void)didFinishedAddingContact
{
    [GeneralUtils showMessage:@"Contact successfully added." withTitle:nil];
    
    [self requestAddressBookAccessAndRetrieveFriends];
}


// ----------------------------------
#pragma mark Contact Views
// ----------------------------------

- (void)displayContactViews
{
    [TrackingUtils trackNumberOfContacts:[self.contacts count]];
    
    self.contactScrollView.hidden = NO;
    
    NSUInteger contactCount = [self.contacts count];
    if (contactCount == 0) {
        return;
    }
    self.contactViews = [[NSMutableArray alloc] initWithCapacity:contactCount];
    
    // Create bubbles
    for (Contact *contact in self.contacts) {
        [self createContactViewWithContact:contact andPosition:1];
    }
    
    [self reorderContactViews];
}

- (void)reorderContactViews
{
    // Sort contact
    [self.contactViews sortUsingComparator:^(ContactView *contactView1, ContactView * contactView2) {
        if (contactView1.contact.lastMessageDate < contactView2.contact.lastMessageDate) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedAscending;
        }
    }];
    
    // Create bubbles
    int position = 1;
    for (ContactView *contactView in self.contactViews) {
        [contactView setOrderPosition:position];
        position ++;
    }
    
    // Pending contact UI
    [self showContactViewAsPending];
    
    // Resize view
    [self setScrollViewSizeForContactCount:(int)[self.contacts count]];
    
    if ([GeneralUtils isFirstOpening]) {
        [self showTutorialController];
        
        //Show util user does something
        [self tutorialModeWithDuration:0];
    }
}

- (void)displayAdditionnalContact:(Contact *)contact
{
    if (!self.contactViews) {
        self.contactViews = [[NSMutableArray alloc] initWithCapacity:[self.contacts count]];
    }
    [self createContactViewWithContact:contact andPosition:(int)[self.contactViews count]+1];
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
    [self.contactViews addObject:contactView];
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
    for (ContactView *contactView in self.contactViews) {
        if (contactView.contact.isPending && contactView.contact.identifier != kAdminId) {
            [contactView setPendingContact:YES];
        } else {
            [contactView setPendingContact:NO];
        }
    }
}

- (void)blockContact:(ContactView *)contactView
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiUtils blockUser:contactView.contact.identifier AndExecuteSuccess:^{
        // block user + delete bubble / contact
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        NSInteger holePosition = 0;
        [contactView removeFromSuperview];
        holePosition = contactView.orderPosition;
        [self.contacts removeObject:contactView.contact];
        [contactView.nameLabel removeFromSuperview];
        
        if (contactView.unreadMessages) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - contactView.unreadMessages.count];
        }
        [self.contactViews removeObject:contactView];
        
        // Change position of other bubbles
        [self reorderContactViews];
    }failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [GeneralUtils showMessage:@"Failed to hide contact, please try again." withTitle:nil];
    }];

}


// ----------------------------------
#pragma mark Messages
// ----------------------------------

// Retrieve unread messages and display alert
- (void) retrieveUnreadMessagesAndNewContacts
{
    void (^successBlock)(NSArray*,BOOL) = ^void(NSArray *messages, BOOL newContactOnServer) {
        //Reset unread messages
        [self resetUnreadMessages];
        BOOL areAttributed = YES;
        for (Message *message in messages) {
            areAttributed &= [self attributeMessageToExistingContacts:message];
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:messages.count];
        
        // Check if we have new contacts
        // App launch - Change in address book - Message from unknown - New user added current user - 0 contact
        if (self.retrieveNewContact || !areAttributed || newContactOnServer || self.contacts.count == 0) {
            [self requestAddressBookAccessAndRetrieveFriends];
            self.retrieveNewContact = NO;
        } else {
            [self hideLoadingIndicator];
            [self reorderContactViews];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *) = ^void(NSURLSessionDataTask *task){
        [self hideLoadingIndicator];
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtils invalidTokenResponse:task]) {
            [SessionUtils redirectToSignIn];
        }
    };
    [self showLoadingIndicator];
    [ApiUtils getUnreadMessagesAndExecuteSuccess:successBlock failure:failureBlock];
}

- (void)resetUnreadMessages
{
    for (ContactView *contactView in self.contactViews) {
        [contactView resetUnreadMessages];
    }
    self.nonAttributedUnreadMessages = nil;
}

// Add a message we just received
- (BOOL)attributeMessageToExistingContacts:(Message *)message
{
    for (ContactView *contactView in self.contactViews) {
        if (message.senderId == contactView.contact.identifier) {
            [contactView addUnreadMessage:message];
            
            // Update last message date to sort contacts even if no push
            contactView.contact.lastMessageDate = MAX(contactView.contact.lastMessageDate,message.createdAt);
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
        for (ContactView *contactView in self.contactViews) {
            if (message.senderId == contactView.contact.identifier) {
                [contactView addUnreadMessage:message];
                isAttributed = YES;
                // Update last message date to sort contacts even if no push
                contactView.contact.lastMessageDate = MAX(contactView.contact.lastMessageDate,message.createdAt);
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
            [[self.contactViews lastObject] addUnreadMessage:message];
        }
    }
    
    // Redisplay correctly
    self.nonAttributedUnreadMessages = nil;
    [self reorderContactViews];
}


// ------------------------------
#pragma mark Click & navigate
// ------------------------------
- (IBAction)menuButtonClicked:(id)sender {

    self.mainMenuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:ACTION_MAIN_MENU_OPTION_1, ACTION_MAIN_MENU_OPTION_2 , ACTION_MAIN_MENU_OPTION_3, nil];
    [self.mainMenuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

// ----------------------------------------------------------
#pragma mark Recording Mode
// ----------------------------------------------------------

- (void)recordingUIForContactView:(ContactView *)contactView
{
    [contactView startRecordingUI];
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

- (void)recordSound
{
    self.lastRecordSoundDate = [NSDate date];
    AudioServicesPlaySystemSound(1113);
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
#pragma mark ContactViewDelegate Protocole
// ----------------------------------------------------------

- (void)doubleTappedOnContactView:(ContactView *)contactView
{
    self.lastSelectedContactView = contactView;
    
    //Show contact menu action sheet
    
     //No message to replay
    if (contactView.contact.lastPlayedMessageId == 0) {
        
        //Waved contact
        if (contactView.contact.identifier == 1) {
            self.contactMenuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                      delegate:self
                                                             cancelButtonTitle:ACTION_SHEET_CANCEL
                                                        destructiveButtonTitle:nil
                                                             otherButtonTitles:ACTION_CONTACT_MENU_OPTION_3, nil];
        } else {
            self.contactMenuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                      delegate:self
                                                             cancelButtonTitle:ACTION_SHEET_CANCEL
                                                        destructiveButtonTitle:nil
                                                             otherButtonTitles:ACTION_CONTACT_MENU_OPTION_2, ACTION_CONTACT_MENU_OPTION_3, nil];
        }
    //Message to replay
    } else {
        
        //Waved contact
        if (contactView.contact.identifier == 1) {
            self.contactMenuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                      delegate:self
                                                             cancelButtonTitle:ACTION_SHEET_CANCEL
                                                        destructiveButtonTitle:nil
                                                             otherButtonTitles:ACTION_CONTACT_MENU_OPTION_1, ACTION_CONTACT_MENU_OPTION_3, nil];
        } else {
            self.contactMenuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                      delegate:self
                                                             cancelButtonTitle:ACTION_SHEET_CANCEL
                                                        destructiveButtonTitle:nil
                                                             otherButtonTitles:ACTION_CONTACT_MENU_OPTION_1, ACTION_CONTACT_MENU_OPTION_2, ACTION_CONTACT_MENU_OPTION_3, nil];
        }
    }
    
    [self.contactMenuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

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
- (void)startedLongPressOnContactView:(ContactView *)contactView
{
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerUIAnimated:NO];
    }
    [self disableAllContactViews];
    
    [self recordingUIForContactView:contactView];
    
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
- (void)endedLongPressOnContactView:(ContactView *)contactView
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
    
    self.lastContactPlayed = contactView;
    
    //Change last played message id in contact
    contactView.contact.lastPlayedMessageId = contactView.nextMessageId;
    
    // Init player
    self.mainPlayer = [[AVAudioPlayer alloc] initWithData:contactView.nextMessageAudioData error:nil];
    [self.mainPlayer setVolume:kAudioPlayerVolume];
    
    // Player UI
    NSTimeInterval duration = self.mainPlayer.duration;
    [self playerUI:duration ByContactView:contactView];
    
    // play
    [self.mainPlayer play];
    
    // MixPanel
    [TrackingUtils trackPlayWithDuration:duration];
}

- (void)startedReplayingAudioFile:(NSData *)audioData ByView:(ContactView *)contactView
{
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerUIAnimated:NO];
    }
    
    [self.playerContainer.layer removeAllAnimations];
    
    self.lastContactPlayed = contactView;
    
    // Init player
    self.mainPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil];
    [self.mainPlayer setVolume:kAudioPlayerVolume];
    
    // Player UI
    NSTimeInterval duration = self.mainPlayer.duration;
    [self playerUI:duration ByContactView:contactView];
    
    // play
    [self.mainPlayer play];
    
    // Mixpanel
    [TrackingUtils trackReplay];
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
    self.contactToAdd = contact;
    UIActionSheet *pendingActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                    delegate:self
                                                           cancelButtonTitle:ACTION_SHEET_CANCEL
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:ACTION_PENDING_OPTION_1, ACTION_PENDING_OPTION_2, nil];
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
    for (ContactView *contactView in self.contactViews) {
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
    
    self.replayButton.hidden = YES;
    [self playerUIForContactView:contactView];
    self.playerContainer.hidden = NO;
    self.playerContainer.alpha = 1;
    [self setPlayerLineWidth:0];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self setPlayerLineWidth:self.playerContainer.bounds.size.width];
                     } completion:^(BOOL finished){
                         if (finished) {
                             [self endPlayerUIAnimated:YES];
                         }
                     }];
}

- (void)endPlayerUIAnimated:(BOOL)animated
{
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
    [self.playerLine.layer removeAllAnimations];
    
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            self.playerContainer.alpha = 0;
        } completion:^(BOOL dummy){
            if (dummy) {
                self.playerContainer.hidden = YES;
                [self unhideReplayButton];
            }
        }];
    } else {
        self.playerContainer.hidden = YES;
        [self setPlayerLineWidth:0];
        [self unhideReplayButton];
    }
    
}

- (void)showLoadingIndicator
{
    self.contactScrollView.hidden = YES;
    self.replayButton.hidden = YES;
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
    [self unhideReplayButton];
    if (self.activityView) {
        [self.activityView stopAnimating];
        [self.activityView removeFromSuperview];
    }
}

- (void)unhideReplayButton
{
    if (self.mainPlayer.duration > 0) {
        self.replayButton.hidden = NO;
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

// ----------------------------------------------------------
#pragma mark ActionSheetProtocol
// ----------------------------------------------------------
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    
    /* -------------------------------------------------------------------------
     MAIN MENU
    ---------------------------------------------------------------------------*/
    
    // Invite contact
    if ([buttonTitle isEqualToString:ACTION_MAIN_MENU_OPTION_1]) {
        [self performSegueWithIdentifier:@"Invite Contacts Segue" sender:nil];
        
    // Add New Contact
    } else if ([buttonTitle isEqualToString:ACTION_MAIN_MENU_OPTION_2]) {
        [self performSegueWithIdentifier:@"Add Contact Segue" sender:nil];
    }
    
    // Other
    else if ([buttonTitle isEqualToString:ACTION_MAIN_MENU_OPTION_3]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Waved v.%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                                           delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_OTHER_MENU_OPTION_1, ACTION_OTHER_MENU_OPTION_2, ACTION_OTHER_MENU_OPTION_3, nil];
        
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    /* -------------------------------------------------------------------------
     OTHER MENU
     ---------------------------------------------------------------------------*/
    
    // Profile
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_1]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_SHEET_PROFILE_OPTION_1, ACTION_SHEET_PROFILE_OPTION_2, ACTION_SHEET_PROFILE_OPTION_3, nil];
        
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    // Share
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_2]) {
        NSString *shareString = @"Download Waved, the fastest way to say a lot.";
        
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
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_3]) {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=Feedback for Waved on iOS (v%@)", kFeedbackEmail,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
    
    /* -------------------------------------------------------------------------
     PENDING MENU
     ---------------------------------------------------------------------------*/
    
    // Add contact
    else if ([buttonTitle isEqualToString:ACTION_PENDING_OPTION_1]) {
        [TrackingUtils trackAddContactSuccessful:YES Present:YES Pending:YES];
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        NSString *decimalNumber = [AddressbookUtils getDecimalNumber:self.contactToAdd.phoneNumber];
        
        [AddressbookUtils createOrEditContactWithDecimalNumber:decimalNumber
                                               formattedNumber:self.contactToAdd.phoneNumber
                                                     firstName:self.contactToAdd.firstName
                                                      lastName:self.contactToAdd.lastName];
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [self didFinishedAddingContact];
    }
    
    // Block contact
    else if ([buttonTitle isEqualToString:ACTION_PENDING_OPTION_2]) {
        for (ContactView * bubbleView in self.contactViews) {
            if (bubbleView.contact.identifier == self.contactToAdd.identifier) {
                [self blockContact:bubbleView];
                break;
            }
        }
    }
    
    /* -------------------------------------------------------------------------
     PROFILE MENU
     ---------------------------------------------------------------------------*/
    
    // Picture
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_1]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_SHEET_PICTURE_OPTION_1, ACTION_SHEET_PICTURE_OPTION_2, nil];
        
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
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
    
    /* -------------------------------------------------------------------------
     PROFILE PICTURE MENU
     ---------------------------------------------------------------------------*/
    
    // Camera
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PICTURE_OPTION_1]) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
    }
    
    // Library
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PICTURE_OPTION_2]) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    
    /* -------------------------------------------------------------------------
     CONTACT MENU
     ---------------------------------------------------------------------------*/
    
    // Replay
    else if ([buttonTitle isEqualToString:ACTION_CONTACT_MENU_OPTION_1]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        NSUInteger contactLastMessageId = self.lastSelectedContactView.contact.lastPlayedMessageId;
        
        if (contactLastMessageId == 0) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            return;
        }
        
        [ApiUtils downloadAudioFileAtURL:[Message getMessageURL:contactLastMessageId] success:^void(NSData *data) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            [self startedReplayingAudioFile:data ByView:self.lastSelectedContactView];
        } failure:^(){
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [GeneralUtils showMessage:@"Failed to retrieve last message, please try again" withTitle:nil];
        }];
    }
    
    // Call/Text
    else if ([buttonTitle isEqualToString:ACTION_CONTACT_MENU_OPTION_2]) {
        
    }
    
    // Hide
    else if ([buttonTitle isEqualToString:ACTION_CONTACT_MENU_OPTION_3]) {
        [self blockContact:self.lastSelectedContactView];
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
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [alertView.title isEqualToString:ACTION_SHEET_PROFILE_OPTION_2] ? [ApiUtils updateFirstName:textField.text success:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:@"First name successfully updated." withTitle:nil];
            } failure:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:@"We couldn't update your first name, please try again." withTitle:nil];
            }]: [ApiUtils updateLastName:textField.text success:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:@"Last name successfully updated." withTitle:nil];
            } failure:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:@"We couldn't update your last name, please try again." withTitle:nil];
            }];
        }
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    
    if (actionSheet == self.mainMenuActionSheet) {
        self.profilePicture.image = nil;
        
        self.usernameLabel.text = [NSString stringWithFormat:@"%@ %@", [SessionUtils getCurrentUserFirstName], [SessionUtils getCurrentUserLastName]];
        [self.profilePicture setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:[SessionUtils getCurrentUserId]]];
        
        [actionSheet addSubview:self.profileContainer];
    }
    
    if (actionSheet == self.contactMenuActionSheet) {
        self.profilePicture.image = nil;
        
        NSString *firstName = self.lastSelectedContactView.contact.firstName ? self.lastSelectedContactView.contact.firstName : @"";
        NSString *lastName = self.lastSelectedContactView.contact.lastName ? self.lastSelectedContactView.contact.lastName : @"";
        
        self.usernameLabel.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        [self.profilePicture setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:self.lastSelectedContactView.contact.identifier]];
        
        [actionSheet addSubview:self.profileContainer];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.mainMenuActionSheet || actionSheet == self.contactMenuActionSheet) {
        [self.profileContainer removeFromSuperview];
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
    return self.silentMode ? 0 : kMinAudioDuration;
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
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        CGSize rescaleSize = {kProfilePictureSize, kProfilePictureSize};
        image = [ImageUtils imageWithImage:[ImageUtils cropBiggestCenteredSquareImageFromImage:image withSide:image.size.width] scaledToSize:rescaleSize];
        
        NSString *encodedImage = [ImageUtils encodeToBase64String:image];
        [ApiUtils updateProfilePicture:encodedImage success:^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [GeneralUtils showMessage:@"Profile picture successfully updated." withTitle:nil];
            [ImageUtils setWithoutCachingImageView:self.profilePicture withURL:[GeneralUtils getUserProfilePictureURLFromUserId:[SessionUtils getCurrentUserId]]];
        }failure:^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        }];
    } else {
        [GeneralUtils showMessage:@"We could not update your profile picture, please try again." withTitle:nil];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


@end
