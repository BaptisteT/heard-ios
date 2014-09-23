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
#import "EditContactsViewController.h"
#import "CustomActionSheet.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CameraUtils.h"
#import "PotentialContact.h"
#import "InviteContactView.h"
#import "InviteContactsViewController.h"

#define ACTION_OTHER_MENU_OPTION_1 NSLocalizedStringFromTable(@"hide_contacts_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_2 NSLocalizedStringFromTable(@"edit_profile_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_3 NSLocalizedStringFromTable(@"share_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_4 NSLocalizedStringFromTable(@"feedback_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_5 NSLocalizedStringFromTable(@"rate_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_6 NSLocalizedStringFromTable(@"log_out_button_title",kStringFile,@"comment")
#define ACTION_PENDING_OPTION_1 NSLocalizedStringFromTable(@"add_to_contact_button_title",kStringFile,@"comment")
#define ACTION_PENDING_OPTION_2 NSLocalizedStringFromTable(@"block_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PROFILE_OPTION_1 NSLocalizedStringFromTable(@"edit_picture_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PROFILE_OPTION_2 NSLocalizedStringFromTable(@"edit_first_name_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PROFILE_OPTION_3 NSLocalizedStringFromTable(@"edit_last_name_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PICTURE_OPTION_1 NSLocalizedStringFromTable(@"camera_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PICTURE_OPTION_2 NSLocalizedStringFromTable(@"library_button_title",kStringFile,@"comment")
#define ACTION_FAILED_MESSAGES_OPTION_1 NSLocalizedStringFromTable(@"resend_button_title",kStringFile,@"comment")
#define ACTION_FAILED_MESSAGES_OPTION_2 NSLocalizedStringFromTable(@"delete_button_title",kStringFile,@"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")

#define RECORDER_HEIGHT 70
#define PLAYER_UI_HEIGHT 70
#define NO_MESSAGE_VIEW_HEIGHT 60

@interface DashboardViewController ()

// Contacts
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactViews;
@property (weak, nonatomic) UIScrollView *contactScrollView;
@property (nonatomic) BOOL retrieveNewContact;
@property (nonatomic, strong) Contact *contactToAdd;
@property (nonatomic, strong) ContactView *inviteContactView;
// Record
@property (strong, nonatomic) UIView *recorderContainer;
@property (nonatomic,strong) UIView *recorderLine;
@property (nonatomic, strong) AVAudioRecorder *recorder;
// Player
@property (strong, nonatomic) UIView *playerContainer;
@property (nonatomic,strong) UIView *playerLine;
@property (nonatomic, strong) AVAudioPlayer *mainPlayer;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic) BOOL isUsingHeadSet;
@property (nonatomic, strong) AVAudioPlayer *soundPlayer;
@property (strong, nonatomic) UILabel *messageDateLabel;
// Current user
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImageView *profilePicture;
@property (weak, nonatomic) ContactView *currentUserContactView;
// Others
@property (weak, nonatomic) UIButton *menuButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (strong, nonatomic) NSMutableArray *nonAttributedUnreadMessages;
@property (strong, nonatomic) NSMutableArray *lastMessagesPlayed;
// Action sheets
@property (strong, nonatomic) CustomActionSheet *menuActionSheet;
@property (strong, nonatomic) ContactView *lastSelectedContactView;
// Alertview
@property (strong, nonatomic) UIAlertView *blockAlertView;
// Authorization Request View
@property (strong, nonatomic) IBOutlet UIView *authRequestView;
@property (weak, nonatomic) IBOutlet UIImageView *permissionImage;
@property (weak, nonatomic) IBOutlet UITextView *permissionMessage;
@property (weak, nonatomic) IBOutlet UITextView *permissionNote;
@property (strong, nonatomic) IBOutlet UIButton *authRequestAllowButton;
@property (strong, nonatomic) IBOutlet UIButton *authRequestSkipButton;
@property (nonatomic) BOOL contactAuthViewSeen;
@property (nonatomic) BOOL pushAuthViewSeen;
// Tuto
@property (nonatomic) BOOL displayOpeningTuto;
@property (nonatomic, strong) UIView *bottomTutoView;
@property (nonatomic, strong) UILabel *bottomTutoViewLabel;
@property (strong, nonatomic) IBOutlet UIView *openingTutoView;
@property (strong, nonatomic) IBOutlet UILabel *openingTutoDescLabel;
@property (strong, nonatomic) IBOutlet UIButton *openingTutoSkipButton;
@property (weak, nonatomic) IBOutlet UIView *openingTutoDescView;
@property (strong, nonatomic) UIImageView *openingTutoArrow;
//Invite new contacts
@property (strong, nonatomic) NSMutableDictionary *indexedContacts;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation DashboardViewController 

// ------------------------------
#pragma mark Life cycle
// ------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.retrieveNewContact = YES;
    self.pushAuthViewSeen = NO;
    self.contactAuthViewSeen = NO;
    self.authRequestView.hidden = YES;
    self.openingTutoView.hidden = YES;
    self.displayOpeningTuto = [GeneralUtils isFirstOpening];
    
    self.openingTutoDescView.layer.cornerRadius = 5;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self retrieveFriendsFromAddressBook];
    });
    
    //Perms
    self.authRequestAllowButton.clipsToBounds = YES;
    self.authRequestAllowButton.layer.cornerRadius = 5;
    
    // Init address book
    self.addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(self.addressBook,MyAddressBookExternalChangeCallback, (__bridge void *)(self));
    
    //Init no message view
    self.bottomTutoView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT)];
    self.bottomTutoView.backgroundColor = [ImageUtils blue];
    
    self.bottomTutoViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT)];
    self.bottomTutoViewLabel.font = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    self.bottomTutoViewLabel.textAlignment = NSTextAlignmentCenter;
    self.bottomTutoViewLabel.textColor = [UIColor whiteColor];
    self.bottomTutoViewLabel.backgroundColor = [UIColor clearColor];
    [self.bottomTutoView addSubview:self.bottomTutoViewLabel];
    [self.view addSubview:self.bottomTutoView];
    
    // Preload profile picture
    self.profilePicture = [UIImageView new];
    [self.profilePicture setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:[SessionUtils getCurrentUserId]]];
    
    // Get contacts
    self.contacts = ((HeardAppDelegate *)[[UIApplication sharedApplication] delegate]).contacts;
    if (self.contacts.count == 0) {
        // add me contact
        Contact *meContact = [Contact createContactWithId:[SessionUtils getCurrentUserId] phoneNumber:[SessionUtils getCurrentUserPhoneNumber] firstName:[SessionUtils getCurrentUserFirstName] lastName:[SessionUtils getCurrentUserLastName]];
        meContact.lastMessageDate = [[NSDate date] timeIntervalSince1970];
        [self.contacts addObject:meContact];
    }
    
    //Create invite contact view
    self.inviteContactView = [[InviteContactView alloc] init];
    self.inviteContactView.delegate = self;
    [self.contactScrollView addSubview:self.inviteContactView];
    [self addNameLabelForView:self.inviteContactView];
    
    // Create contact views
    [self displayContactViews];
    
    // Ask micro access
    AVAudioSession* session = [AVAudioSession sharedInstance];
    BOOL success; NSError* error;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    if (!success)
        NSLog(@"AVAudioSession error setting category:%@",error);
    [session setActive:YES error:nil];
    
    // Add observers
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(routeChangeCallback:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(proximityStateDidChangeCallback)
                                                 name: UIDeviceProximityStateDidChangeNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willResignActiveCallback)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];

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
    
    // Init recorder container
    self.recorderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, RECORDER_HEIGHT)];
    self.recorderContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.recorderContainer];
    self.recorderContainer.hidden = YES;
    
    // Recoder line
    self.recorderLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, RECORDER_HEIGHT)];
    self.recorderLine.backgroundColor = [ImageUtils transparentRed];
    [self.recorderContainer addSubview:self.recorderLine];
    
    // Init player container
    self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, PLAYER_UI_HEIGHT)];
    self.playerContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.playerContainer];
    self.playerContainer.hidden = YES;
    
    // player line
    self.playerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, PLAYER_UI_HEIGHT)];
    self.playerLine.backgroundColor = [ImageUtils transparentGreen];
    [self.playerContainer addSubview:self.playerLine];
    
    //player date label
    self.messageDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 25, 120, 25)];
    self.messageDateLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:15.0];
    self.messageDateLabel.textAlignment = NSTextAlignmentCenter;
    self.messageDateLabel.textColor = [UIColor grayColor];
    self.messageDateLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    self.messageDateLabel.hidden = YES;
    self.messageDateLabel.text = @"";
    self.messageDateLabel.clipsToBounds = YES;
    self.messageDateLabel.layer.cornerRadius = 5;
    [self.playerContainer addSubview:self.messageDateLabel];
    
    // Go to access view controller if acces has not yet been granted
    if (!self.contactAuthViewSeen && ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        self.contactAuthViewSeen = YES;
        [self displayContactAuthView];
    } else if (!self.pushAuthViewSeen && ![GeneralUtils pushNotifRequestSeen]) {
        self.pushAuthViewSeen = YES;
        [self displayPushAuthView];
    } else {
        [GeneralUtils registerForRemoteNotif];
    }
    
    if (self.displayOpeningTuto) {
        [self prepareAndDisplayTuto];
    }
    
    // Update app info
    [ApiUtils updateAppInfoAndExecuteSuccess:nil failure:nil];
}


// Make sure scroll view has been resized (necessary because layout constraints change scroll view size)
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setScrollViewSizeForContactCount:(int)MAX([self.contactViews count],[ContactUtils numberOfNonHiddenContacts:self.contacts])];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];   //it hides
    
    // Retrieve messages & contacts
    [self retrieveUnreadMessagesAndNewContacts];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Add Contact Segue"]) {
        ((AddContactViewController *) [segue destinationViewController]).delegate = self;
    } else if ([segueName isEqualToString: @"Edit Contacts Segue"]) {
        ((EditContactsViewController *) [segue destinationViewController]).delegate = self;
        ((EditContactsViewController *) [segue destinationViewController]).contacts = self.contacts;
    } else if ([segueName isEqualToString:@"Invite Contacts Segue"]) {
        ((InviteContactsViewController *) [segue destinationViewController]).message = sender;
         ((InviteContactsViewController *) [segue destinationViewController]).indexedContacts = self.indexedContacts;
    }
}


// ------------------------------
#pragma mark UI Modes
// ------------------------------
- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration priority:(BOOL)prority
{
    [self endTutoMode];
    if (self.displayOpeningTuto && !prority) {
        return;
    }
    self.bottomTutoViewLabel.text = message;
    self.bottomTutoView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomTutoView.frame = CGRectMake(self.bottomTutoView.frame.origin.x,
                                             self.bottomTutoView.frame.origin.y - self.bottomTutoView.frame.size.height,
                                             self.bottomTutoView.frame.size.width,
                                             self.bottomTutoView.frame.size.height);
    } completion:^(BOOL finished) {
        if (finished && self.bottomTutoView) {
            if (duration > 0) {
                [UIView animateWithDuration:0.5 delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.bottomTutoView.frame = CGRectMake(self.bottomTutoView.frame.origin.x,
                                                         self.bottomTutoView.frame.origin.y + self.bottomTutoView.frame.size.height,
                                                         self.bottomTutoView.frame.size.width,
                                                         self.bottomTutoView.frame.size.height);
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self endTutoMode];
                    }
                }];
            }
        }
    }];
}

- (void)endTutoMode
{
    if (!self.bottomTutoView) {
        return;
    }
    
    [self.bottomTutoView.layer removeAllAnimations];
    self.bottomTutoView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT);
}


// ------------------------------
#pragma mark Get Contact
// ------------------------------

- (void)requestAddressBookAccessAndRetrieveFriends
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        return;
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self matchPhoneContactsWithHeardUsers];
    }
    else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"contact_access_error_message",kStringFile, @"comment") withTitle:nil];
    }
}

- (void)matchPhoneContactsWithHeardUsers
{
    self.addressBookFormattedContacts = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
    
    NSMutableDictionary *contactsInfo = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * adressBookWithFormattedKey = [NSMutableDictionary new];
    for (NSString* phoneNumber in self.addressBookFormattedContacts) {
        PotentialContact *object = [self.addressBookFormattedContacts objectForKey:phoneNumber];
        [adressBookWithFormattedKey setObject:object forKey:object.phoneNumber];
        
        [contactsInfo setObject:[NSArray arrayWithObjects:object.facebookId,[NSNumber numberWithBool:object.hasPhoto],[NSNumber numberWithBool:object.isFavorite], nil] forKey:object.phoneNumber];
    }
    // The keys are now formatted numbers (to use local names for retrieved contacts)
    self.addressBookFormattedContacts = adressBookWithFormattedKey;
    
    // Get contacts and compare with contact in memory
    [ApiUtils getMyContacts:contactsInfo atSignUp:self.isSignUp success:^(NSArray *contacts, NSArray *futureContacts) {
        [self hideLoadingIndicator];
        
        for (Contact *contact in contacts) {
            Contact *existingContact = [ContactUtils findContact:contact inContactsArray:self.contacts];
            if (!existingContact) {
                [self.contacts addObject:contact];
    
                //Use server name if blank in address book
                NSString *firstName = ((PotentialContact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
                if (firstName && [firstName length] > 0) {
                    contact.firstName = firstName;
                }
                contact.lastName = ((PotentialContact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
                contact.lastMessageDate = 0;
                [self displayAdditionnalContact:contact];
            }
            else if (existingContact.isFutureContact) {
                existingContact.identifier = contact.identifier;
                existingContact.isFutureContact = NO;
            }
            else if (existingContact.isPending) {
                // Mark as non pending
                existingContact.isPending = NO;
                
                //Use server name if blank in address book
                NSString *firstName = ((PotentialContact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
                if (firstName && [firstName length] > 0) {
                    contact.firstName = firstName;
                }
                contact.lastName = ((PotentialContact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
                existingContact.phoneNumber = contact.phoneNumber;
            }
        }
        for (NSDictionary *futureContact in futureContacts) {
            NSString *phoneNumber = (NSString *)[futureContact objectForKey:@"phone_number"];
            Contact *contact = [Contact createContactWithId:0 phoneNumber:phoneNumber
                                                  firstName:((PotentialContact *)[self.addressBookFormattedContacts objectForKey:phoneNumber]).firstName
                                                   lastName:((PotentialContact *)[self.addressBookFormattedContacts objectForKey:phoneNumber]).lastName];
            contact.facebookId = (NSString *)[futureContact objectForKey:@"facebook_id"];
            contact.isFutureContact = YES;
            contact.recordId = ((PotentialContact *)[self.addressBookFormattedContacts objectForKey:phoneNumber]).recordId;
            // Security check
            BOOL remove = NO;
            for (Contact *normalContact in self.contacts) {
                if ([normalContact.phoneNumber isEqualToString:phoneNumber] || ([normalContact.firstName isEqualToString:contact.firstName] && [normalContact.lastName isEqualToString:contact.lastName])) {
                    remove = YES;
                }
            }
            if (!remove) {
                [self.contacts addObject:contact];
                [self displayAdditionnalContact:contact];
            }
        }
        self.addressBookFormattedContacts = nil;
        
        // Distribute non attributed messages
        [self distributeNonAttributedMessages];
        
    } failure: ^void(NSURLSessionDataTask *task){
        [self hideLoadingIndicator];
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtils invalidTokenResponse:task]) {
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"authentification_error_message",kStringFile,@"comment") withTitle:NSLocalizedStringFromTable(@"authentification_error_title",kStringFile,@"comment")];
            [SessionUtils redirectToSignIn:self.navigationController];
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
- (void)didFinishedAddingContact:(NSString *)contactName
{
    [GeneralUtils showMessage: [NSLocalizedStringFromTable(@"add_contact_success_message",kStringFile,@"comment") stringByReplacingOccurrencesOfString:@"TRUCHOV" withString:contactName]
                    withTitle:nil];
    [self requestAddressBookAccessAndRetrieveFriends];
}

// ----------------------------------
#pragma mark Contact Views
// ----------------------------------

- (void)displayContactViews
{
    [TrackingUtils trackNumberOfContacts:[self.contacts count]];
    
    NSUInteger nonHiddenContactsCount = [ContactUtils numberOfNonHiddenContacts:self.contacts];
    if (nonHiddenContactsCount == 0) {
        return;
    }
    self.contactViews = [[NSMutableArray alloc] initWithCapacity:nonHiddenContactsCount];
    
    // Create bubbles
    for (Contact *contact in self.contacts) {
        if (!contact.isHidden) {
            [self createContactViewWithContact:contact andPosition:1];
        }
    }
    [self reorderContactViews];
}

- (void)reorderContactViews
{
    if ([self isRecording] || [self.mainPlayer isPlaying]) {
        return;
    }
    
    // Sort contact
    [self.contactViews sortUsingComparator:^(ContactView *contactView1, ContactView * contactView2) {
        if (contactView1.contact.lastMessageDate < contactView2.contact.lastMessageDate) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedAscending;
        }
    }];
    
    int position = 1;
    for (ContactView *contactView in self.contactViews) {
        // Order view
        [contactView setOrderPosition:position];
        position ++;
        
        // Set discussion state
        [contactView resetDiscussionStateAnimated:NO];
        
        // Load picture if it fails
        if (!contactView.pictureIsLoaded) {
            [contactView setContactPicture];
        }
    }
    
    // Resize view
    [self setScrollViewSizeForContactCount:(int)[self.contactViews count]];
}

- (void)displayAdditionnalContact:(Contact *)contact
{
    if (!self.contactViews) {
        self.contactViews = [[NSMutableArray alloc] initWithCapacity:[ContactUtils numberOfNonHiddenContacts:self.contacts]];
    }
    // Check that contact does not exist
    if ([self getViewOfContact:contact])
        return;
    
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
    
    if ([GeneralUtils isCurrentUser:contact]) {
        self.currentUserContactView = contactView;
    }
    
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
    [self.contactScrollView insertSubview:contactView atIndex:0];
}

// Add name below contact
- (void)addNameLabelForView:(ContactView *)contactView
{
    Contact *contact = contactView.contact;
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(contactView.frame.origin.x - kContactMargin/4, contactView.frame.origin.y + kContactSize, contactView.frame.size.width + kContactMargin/2, kContactNameHeight)];
    
    if ([GeneralUtils isAdminContact:contact]) {
        nameLabel.text = @"Waved";
        nameLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:14.0];
    //Invite contact
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
    [self.contactScrollView insertSubview:nameLabel atIndex:0];
}


- (void)blockContact:(ContactView *)contactView
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiUtils blockUser:contactView.contact.identifier AndExecuteSuccess:^{
        // block user + delete bubble / contact
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [contactView removeFromSuperview];
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
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"block_failure_error_message",kStringFile, @"comment") withTitle:nil];
    }];
}

- (void)removeContactView:(ContactView *)contactView
{
    contactView.contact.isHidden = YES;
    [self.contactViews removeObject:contactView];
    [contactView removeFromSuperview];
    [contactView.nameLabel removeFromSuperview];
}

- (void)removeViewOfContact:(Contact *)contact
{
    [self removeContactView:[self getViewOfContact:contact]];
}

- (void)displayViewOfContact:(Contact *)contact
{
    contact.isHidden = NO;
    [self displayAdditionnalContact:contact];
}

- (ContactView *)getViewOfContact:(Contact *)contact
{
    for (ContactView *contactView in self.contactViews) {
        if (contactView.contact == contact) {
            return contactView;
        }
    }
    return nil;
}

- (void)removeViewOfHiddenContacts
{
    NSMutableArray *viewsToRemove = [NSMutableArray new];
    for (ContactView *contactView in self.contactViews) {
        if (contactView.contact.isHidden && (!contactView.unreadMessages || contactView.unreadMessages.count == 0)) {
            [viewsToRemove addObject:contactView];
        }
    }
    for (ContactView *contactView in viewsToRemove) {
        [self removeContactView:contactView];
    }
}

// ----------------------------------
#pragma mark Messages
// ----------------------------------

// Retrieve unread messages and display alert
- (void) retrieveUnreadMessagesAndNewContacts
{
    // Come back to top
    [self.contactScrollView setContentOffset:CGPointMake(0, -self.contactScrollView.contentInset.top) animated:YES];
    
    void (^successBlock)(NSArray*,BOOL,NSArray*) = ^void(NSArray *messages, BOOL newContactOnServer, NSArray *unreadMessageContacts) {
        //Reset unread messages
        [self resetUnreadMessages];
        
        // Attribute messages and reorder view
        BOOL areAttributed = YES;
        for (Message *message in messages) {
            areAttributed &= [self attributeMessageToExistingContacts:message];
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:messages.count];
        [self reorderContactViews];
        
        // Clean / robust / somewhere else
        for (ContactView *contactView in self.contactViews) {
            BOOL idFound = NO;
            for (NSString *id in unreadMessageContacts) {
                if (contactView.contact.identifier == [id intValue]) {
                    idFound = YES;
                    break;
                }
            }
            if (idFound || (contactView.contact.isFutureContact && contactView.contact.lastMessageDate > 0)) {
                contactView.messageNotReadByContact = YES;
            } else {
                contactView.messageNotReadByContact = NO;
            }
            [contactView resetDiscussionStateAnimated:NO];
        }
        
        // Check if we have new contacts
        // App launch or Change in address book or Message from unknown or New user added current user
        if (self.retrieveNewContact || !areAttributed || newContactOnServer) {
            [self requestAddressBookAccessAndRetrieveFriends];
            self.retrieveNewContact = NO;
        } else {
            [self hideLoadingIndicator];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *) = ^void(NSURLSessionDataTask *task){
        [self hideLoadingIndicator];
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtils invalidTokenResponse:task]) {
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"authentification_error_message",kStringFile,@"comment") withTitle:NSLocalizedStringFromTable(@"authentification_error_title",kStringFile,@"comment")];
            [SessionUtils redirectToSignIn:self.navigationController];
        }
    };
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
            Contact *contact = [ContactUtils findContactFromId:message.senderId inContactsArray:self.contacts];
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

- (void)message:(NSUInteger)messageId listenedByContact:(NSUInteger)contactId
{
    for (ContactView *contactView in self.contactViews) {
        if (contactId == contactView.contact.identifier) {
            //TODO BB: Check that message from server matches last message sent
            contactView.messageNotReadByContact = NO;
            
            [contactView resetDiscussionStateAnimated:YES];
            break;
        }
    }
}

- (void)resetLastMessagesPlayed
{
    self.lastMessagesPlayed = nil;
}

- (void)addMessagesToLastMessagesPlayed:(Message *)message
{
    if (!self.lastMessagesPlayed) {
        self.lastMessagesPlayed = [NSMutableArray new];
    }
    // Check that it's the same sender
    if (self.lastMessagesPlayed.count>0 && ((Message *)[self.lastMessagesPlayed lastObject]).senderId != message.senderId) {
        self.lastMessagesPlayed = [NSMutableArray new];
    }
    [self.lastMessagesPlayed addObject:message];
}

// ------------------------------
#pragma mark Click & navigate
// ------------------------------

- (IBAction)menuButtonClicked:(id)sender {
    if (self.displayOpeningTuto) {
        [self hideOpeningTuto];
        self.displayOpeningTuto = NO;
    }
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        [self displayContactAuthView];
    } else if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"contact_access_error_message",kStringFile, @"comment") withTitle:nil];
    } else {
        self.menuActionSheet = [[CustomActionSheet alloc]
                                    initWithTitle:[NSString  stringWithFormat:@"Waved v.%@", [[NSBundle mainBundle]  objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                    delegate:self
                                    cancelButtonTitle:ACTION_SHEET_CANCEL
                                    destructiveButtonTitle:nil
                                    otherButtonTitles:ACTION_OTHER_MENU_OPTION_1, ACTION_OTHER_MENU_OPTION_2, ACTION_OTHER_MENU_OPTION_3, ACTION_OTHER_MENU_OPTION_4, ACTION_OTHER_MENU_OPTION_5, ACTION_OTHER_MENU_OPTION_6, nil];
        [self.menuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}


// ----------------------------------------------------------
#pragma mark Recording Mode
// ----------------------------------------------------------

- (void)disableAllContactViews
{
    //Hide menu and title
    self.menuButton.hidden = YES;
    self.titleLabel.hidden = YES;
    self.contactScrollView.clipsToBounds = NO;
    
    for (ContactView *view in self.contactViews) {
        view.userInteractionEnabled = NO;
    }
}

- (void)enableAllContactViews
{
    //Show menu and title
    self.menuButton.hidden = NO;
    self.titleLabel.hidden = NO;
    self.contactScrollView.clipsToBounds = YES;
    
    for (ContactView *view in self.contactViews) {
        view.userInteractionEnabled = YES;
    }
}

- (void)setRecorderLineWidth:(float)width {
    CGRect frame = self.recorderLine.frame;
    frame.size.width = width;
    self.recorderLine.frame = frame;
}

// ----------------------------------
#pragma mark Sending Messages
// ----------------------------------

- (void)sendMessageToContact:(ContactView *)contactView
{
    NSData *audioData = [self getLastRecordedData];
    [ApiUtils sendMessage:audioData toUser:contactView.contact success:^{
        [contactView message:nil sentWithError:NO]; // no need to pass the message here
    } failure:^{
        [contactView message:audioData sentWithError:YES];
    }];
}

- (NSData *)getLastRecordedData
{
    return [[NSData alloc] initWithContentsOfURL:self.recorder.url];
}

- (void)inviteContactsWithMessage:(Message *)message
{
    if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        [self displayContactAuthView];
        return;
    }
    
    [self performSegueWithIdentifier:@"Invite Contacts Segue" sender:message];
}

- (void)retrieveFriendsFromAddressBook
{
    ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    //Structure: @{ "A": @[ @[@"Artois", @"Jonathan", @"(415)-509-9382", @"not selected], @["Azta", "Lorainne", @"06 92 83 48 58", @"selected"]], "B": etc.
    self.indexedContacts = [[NSMutableDictionary alloc] init];
    
    for (CFIndex i = 0 ; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        
        if ((firstName && [firstName length] > 0) || (lastName && [lastName length] > 0)) {
            for (int i=0; i<ABMultiValueGetCount(phoneNumbers);i++) {
                NSString *number = (__bridge NSString *) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                NSError *aError = nil;
                NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:number error:&aError];
                
                if (aError == nil && ([phoneUtil getNumberType:nbPhoneNumber] == NBEPhoneNumberTypeMOBILE
                                      || [phoneUtil getNumberType:nbPhoneNumber] == NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE) ) {
                    NSMutableArray *contact = [[NSMutableArray alloc] initWithObjects:lastName && [lastName length] > 0 ? lastName : firstName,
                                               firstName && lastName && [lastName length] > 0 ? firstName : @"",
                                               number,
                                               @"not selected", nil];
                    
                    NSString *key = [[contact[0] substringToIndex:1] uppercaseString];
                    
                    if ([self.indexedContacts objectForKey:key]) {
                        [[self.indexedContacts objectForKey:key] addObject:contact];
                    } else {
                        [self.indexedContacts setValue:[[NSMutableArray alloc] initWithObjects:contact, nil]
                                                forKey:key];
                    }
                }
            }
        }
        
        CFRelease(person);
        CFRelease(phoneNumbers);
    }
    
    CFRelease(people);
    
    //Order contacts alphabetically
    for (NSString *key in [self.indexedContacts allKeys]) {
        [self.indexedContacts setObject:[[self.indexedContacts objectForKey:key]
                                         sortedArrayUsingComparator:^NSComparisonResult(NSArray *contact1, NSArray *contact2) {
                                             return [contact1[0] localizedCaseInsensitiveCompare:contact2[0]];
                                         }]
                                 forKey:key];
    }
}

// ----------------------------------------------------------
#pragma mark ContactViewDelegate Protocole
// ----------------------------------------------------------

- (void)updateFrameOfContactView:(ContactView *)view
{
    NSInteger row = view.orderPosition / 3 + 1;
    NSInteger horizontalPosition = 3 - (3*(view.orderPosition/3) + 2 - view.orderPosition);
    float rowHeight = kContactMargin + kContactSize + kContactNameHeight;
    view.frame = CGRectMake(kContactMargin + (horizontalPosition - 1) * (kContactSize + kContactMargin), kContactMargin + (row - 1)* rowHeight, kContactSize, kContactSize);
    
    // Update frame of Name Label tool
    view.nameLabel.frame = CGRectMake(view.frame.origin.x - kContactMargin/4, view.frame.origin.y + kContactSize, view.frame.size.width + kContactMargin/2, kContactNameHeight);
}

//Create recording mode screen
- (void)startedLongPressOnContactView:(ContactView *)contactView
{
    [self hideOpeningTuto];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (![prefs objectForKey:kUserCanceledPref]) {
        [self tutoMessage:NSLocalizedStringFromTable(@"shake_to_cancel_tuto",kStringFile, @"comment")  withDuration:0 priority:NO];
    }
    
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerAtCompletion:NO];
    }
    
    [self playSound:kStartRecordSound];
    [self disableAllContactViews];
    
    // Case where we had a pending message
    if (!self.recorderContainer.isHidden) {
        [self setRecorderLineWidth:0];
    }

    self.recorderContainer.hidden = NO;
    
    float finalWidth = self.recorderContainer.bounds.size.width;
    
    [UIView animateWithDuration:30
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self setRecorderLineWidth:finalWidth];
                     } completion:nil];
    [NSThread sleepForTimeInterval:.1];
    [self.recorder record];
}

//User stop pressing screen
- (void)endedLongPressRecording
{
    [self endTutoMode];
    
    // Stop recording
    [self.recorder stop];
    
    // Remove UI
    self.recorderLine.frame = [[self.recorderLine.layer presentationLayer] frame];
    [self.recorderLine.layer removeAllAnimations];
    self.recorderContainer.hidden = YES;
    [self setRecorderLineWidth:0];
    
    [self enableAllContactViews];
    
    // stop sound
    [self playSound:kEndRecordSound];
}

- (void)startedPlayingAudioMessagesOfView:(ContactView *)contactView
{
    [self hideOpeningTuto];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (![prefs objectForKey:kUserPhoneToEarPref] && !self.isUsingHeadSet) {
        [self tutoMessage:NSLocalizedStringFromTable(@"phone_to_ear_tuto",kStringFile, @"comment") withDuration:0 priority:NO];
    }
    
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerAtCompletion:NO];
    }
    self.lastSelectedContactView = contactView;
    [self.playerContainer.layer removeAllAnimations];
    
    // Init player
    Message *message = (Message *)contactView.unreadMessages[0];
    self.mainPlayer = [[AVAudioPlayer alloc] initWithData:message.audioData error:nil];
    [self addMessagesToLastMessagesPlayed:message];
    
    //Show message date
    self.messageDateLabel.hidden = NO;
    self.messageDateLabel.text = [GeneralUtils dateToAgeString:message.createdAt];
    
    // Player UI
    NSTimeInterval duration = self.mainPlayer.duration;
    [self playerUI:duration ByContactView:contactView];
    
    // play
    [self.mainPlayer play];
    
    // MixPanel
    [TrackingUtils trackPlayWithDuration:duration];
}

- (BOOL)isRecording {
    return self.recorder.isRecording;
}


- (void)pendingContactClicked:(Contact *)contact
{
    self.contactToAdd = contact;
    CustomActionSheet *pendingActionSheet = [[CustomActionSheet alloc] initWithTitle:nil
                                                                    delegate:self
                                                           cancelButtonTitle:ACTION_SHEET_CANCEL
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:ACTION_PENDING_OPTION_1, ACTION_PENDING_OPTION_2, nil];
    [pendingActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)failedMessagesModeTapGestureOnContact:(ContactView *)contactView
{
    self.lastSelectedContactView = contactView;
    NSString *partial_message = contactView.failedMessages.count > 1 ? NSLocalizedStringFromTable(@"multiple_messages_send_failure_error_message",kStringFile, @"comment") : NSLocalizedStringFromTable(@"one_message_send_failure_error_message",kStringFile, @"comment");
    NSString *title = [NSString stringWithFormat:@"%lu %@",contactView.failedMessages.count,partial_message];
    CustomActionSheet *pendingActionSheet = [[CustomActionSheet alloc] initWithTitle:title
                                                                    delegate:self
                                                           cancelButtonTitle:ACTION_SHEET_CANCEL
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:ACTION_FAILED_MESSAGES_OPTION_1, ACTION_FAILED_MESSAGES_OPTION_2, nil];
    [pendingActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}


// ----------------------------------------------------------
#pragma mark Player Mode
// ----------------------------------------------------------

- (void)endPlayerUIForAllContactViews
{
    for (ContactView *contactView in self.contactViews) {
        contactView.isPlaying = NO;
        [contactView resetDiscussionStateAnimated:NO];
    }
}

// Audio Playing UI + volume setting
- (void)playerUI:(NSTimeInterval)duration ByContactView:(ContactView *)contactView
{
    // Min volume (legal / deprecated ?)
    MPMusicPlayerController *appPlayer = [MPMusicPlayerController applicationMusicPlayer];
    if (appPlayer.volume < 0.5) {
        [appPlayer setVolume:0.5];
    }
    
    // Set loud speaker and proximity check
    self.disableProximityObserver = NO;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    //Hide menu and title
    self.menuButton.hidden = YES;
    self.titleLabel.hidden = YES;
    self.contactScrollView.clipsToBounds = NO;
    
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
                             [self endPlayerAtCompletion:YES];
                         }
                     }];
}


- (void)endPlayerAtCompletion:(BOOL)completed
{
    if (self.displayOpeningTuto) {
        [self.contactScrollView bringSubviewToFront:self.openingTutoView];
        [self.contactScrollView bringSubviewToFront:self.menuButton];
        [self displayOpeningTutoWithActionLabel:NSLocalizedStringFromTable(@"menu_tuto_action_label", kStringFile, @"comment") forOrigin:self.menuButton.frame.origin.x + self.menuButton.frame.size.width/2];
    }
    
    // Check that audio is playing or completed
    if (![self.mainPlayer isPlaying] && !completed) {
        return;
    }

    // Remove proximity state
    if ([UIDevice currentDevice].proximityState) {
        self.disableProximityObserver = YES;
    } else {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    }
    
    // End contact player UI
    [self endPlayerUIForAllContactViews];
    
    //Show menu and title
    self.menuButton.hidden = NO;
    self.titleLabel.hidden = NO;
    self.contactScrollView.clipsToBounds = YES;
    
    self.messageDateLabel.hidden = YES;
    
    // End central player UI
    [self.mainPlayer stop];
    self.mainPlayer.currentTime = 0;
    [self.playerLine.layer removeAllAnimations];
    self.playerContainer.hidden = YES;
    [self setPlayerLineWidth:0];
    
    if (self.lastSelectedContactView) {
        [self.lastSelectedContactView messageFinishPlaying:completed];
    }
}

- (void)setPlayerLineWidth:(float)width {
    CGRect frame = self.playerLine.frame;
    frame.size.width = width;
    self.playerLine.frame = frame;
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
#pragma mark ActionSheetProtocol
// ----------------------------------------------------------
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    

    /* -------------------------------------------------------------------------
     OTHER MENU
     ---------------------------------------------------------------------------*/
    
    // Edit contacts
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_1]) {
        [self performSegueWithIdentifier:@"Edit Contacts Segue" sender:nil];
    }
    
    // Profile
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_2]) {
        [actionSheet dismissWithClickedButtonIndex:2 animated:NO];
        CustomActionSheet *newActionSheet = [[CustomActionSheet alloc] initWithTitle:nil
                                                                            delegate:self
                                                                   cancelButtonTitle:ACTION_SHEET_CANCEL
                                                              destructiveButtonTitle:nil
                                                                   otherButtonTitles:ACTION_SHEET_PROFILE_OPTION_1, ACTION_SHEET_PROFILE_OPTION_2, ACTION_SHEET_PROFILE_OPTION_3, nil];
        
        [newActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    // Share
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_3]) {
        NSString *shareString = NSLocalizedStringFromTable(@"invite_text_message",kStringFile, @"comment");
        
        NSURL *shareUrl = [NSURL URLWithString:kProdAFHeardWebsite];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [activityViewController setValue:NSLocalizedStringFromTable(@"share_mail_object_message",kStringFile, @"comment") forKey:@"subject"];
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
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_4]) {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=Feedback for Waved on iOS (v%@)", kFeedbackEmail,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
    
    // Rate us
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_5]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAppStoreLink]];
    }
    
    // Log out
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_6]) {
        [SessionUtils redirectToSignIn:self.navigationController];
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
        
        [self didFinishedAddingContact:self.contactToAdd.firstName];
    }
    
    // Block user
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
        CustomActionSheet *actionSheet = [[CustomActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_SHEET_PICTURE_OPTION_1, ACTION_SHEET_PICTURE_OPTION_2, nil];
        
        [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    
    // First Name
    else if ([buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_2] || [buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_3]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:buttonTitle message:@"" delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"cancel_button_title",kStringFile, @"comment") otherButtonTitles:NSLocalizedStringFromTable(@"ok_button_title",kStringFile, @"comment"), nil];
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
     FAILED MESSAGES MENU
     ---------------------------------------------------------------------------*/
    
    // Resend
    else if ([buttonTitle isEqualToString:ACTION_FAILED_MESSAGES_OPTION_1]) {
        [self.lastSelectedContactView resendFailedMessages];
    }
    
    // Delete
    else if ([buttonTitle isEqualToString:ACTION_FAILED_MESSAGES_OPTION_2]) {
        [self.lastSelectedContactView deleteFailedMessages];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // First name
    if ([alertView.title isEqualToString:ACTION_SHEET_PROFILE_OPTION_2]) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if (buttonIndex == 0) // cancel
            return;
        
        if ([textField.text length] <= 0) {
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"first_name_error_message",kStringFile, @"comment") withTitle:nil];
        }
        if (buttonIndex == 1) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [ApiUtils updateFirstName:textField.text success:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"first_name_edit_success_message",kStringFile, @"comment") withTitle:nil];
            } failure:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"first_name_edit_error_message",kStringFile, @"comment") withTitle:nil];
            }];
        }
    }
    // Last name
    else if ([alertView.title isEqualToString:ACTION_SHEET_PROFILE_OPTION_3]) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if (buttonIndex == 0) // cancel
            return;
        
        if ([textField.text length] <= 0) {
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"last_name_error_message",kStringFile, @"comment") withTitle:nil];
        }
        if (buttonIndex == 1) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [ApiUtils updateLastName:textField.text success:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"last_name_edit_success_message",kStringFile, @"comment") withTitle:nil];
            } failure:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"last_name_edit_error_message",kStringFile, @"comment") withTitle:nil];
            }];
        }
    }
    // block
    else if (alertView == self.blockAlertView && buttonIndex == 1) {
        [self blockContact:self.lastSelectedContactView];
    }
}


// ----------------------------------------------------------
#pragma mark Observer callback
// ----------------------------------------------------------
-(void)willResignActiveCallback {
    // Dismiss modal
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)routeChangeCallback:(NSNotification*)notification {
    self.isUsingHeadSet = [AudioUtils usingHeadsetInAudioSession:[AVAudioSession sharedInstance]];
}

- (void)setIsUsingHeadSet:(BOOL)isUsingHeadSet {
    _isUsingHeadSet = isUsingHeadSet;
    [self proximityStateDidChangeCallback];
}

- (void)proximityStateDidChangeCallback {
    BOOL success; NSError* error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (self.isUsingHeadSet || [UIDevice currentDevice].proximityState ) {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        if ([UIDevice currentDevice].proximityState) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:@"dummy" forKey:kUserPhoneToEarPref];
        }
    } else {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        if (self.disableProximityObserver) {
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        }
    }
    if (!success)
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
}



// --------------------------
// Profile picture change
// --------------------------

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    self.imagePickerController = [CameraUtils allocCameraWithSourceType:sourceType delegate:self];
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image =  [info objectForKey:UIImagePickerControllerEditedImage] ? [info objectForKey:UIImagePickerControllerEditedImage] : [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (image) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        CGSize rescaleSize = {kProfilePictureSize, kProfilePictureSize};
        image = [ImageUtils imageWithImage:[ImageUtils cropBiggestCenteredSquareImageFromImage:image withSide:image.size.width] scaledToSize:rescaleSize];
        
        NSString *encodedImage = [ImageUtils encodeToBase64String:image];
        [ApiUtils updateProfilePicture:encodedImage success:^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            // Update image
            self.profilePicture.image = image;
            if (self.currentUserContactView) {
                self.currentUserContactView.imageView.image = image;
            }
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"picture_edit_success_message",kStringFile, @"comment") withTitle:nil];
            
            // Reset the cache
            [ImageUtils setWithoutCachingImageView:self.profilePicture withURL:[GeneralUtils getUserProfilePictureURLFromUserId:[SessionUtils getCurrentUserId]]];
        }failure:^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        }];
    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"picture_edit_error_message",kStringFile, @"comment") withTitle:nil];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ((UINavigationController *)self.imagePickerController != navigationController || self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera ) {
        return;
    }
    if ([navigationController.viewControllers indexOfObject:viewController] == 2)
    {
        [CameraUtils addCircleOverlayToEditView:viewController];
    }
}


// ----------------------------------------------------------
#pragma mark Motion event (shake)
// ----------------------------------------------------------

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
    {
        // cancel recording
        if ([self isRecording]) {
            [self endedLongPressRecording];
            for (ContactView *contactView in self.contactViews) {
                [contactView cancelRecording];
            }
            [self.inviteContactView cancelRecording];
            
            [self tutoMessage:NSLocalizedStringFromTable(@"cancel_success_message",kStringFile, @"comment") withDuration:3 priority:NO];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:@"dummy" forKey:kUserCanceledPref];
        } else if (self.lastMessagesPlayed && self.lastMessagesPlayed.count > 0){
            if ([self.mainPlayer isPlaying]) {
                [self.mainPlayer stop];
                [self endPlayerUIForAllContactViews];
            }
            // Add last messages played to contact view
            NSInteger contactId = ((Message *)self.lastMessagesPlayed[0]).senderId;
            for (ContactView *contactView in self.contactViews) {
                if (contactView.contact.identifier == contactId) {
                    [contactView addPlayedMessages:self.lastMessagesPlayed];
                    [self resetLastMessagesPlayed];
                    [contactView playNextMessage];
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs setObject:@"dummy" forKey:kUserReplayedPref];
                    break;
                }
            }
        } else {
            [self tutoMessage:NSLocalizedStringFromTable(@"no_last_message_played_message",kStringFile, @"comment") withDuration:2 priority:NO];
        }
    }
}

// ----------------------------------------------------------
#pragma mark Sounds
// ----------------------------------------------------------

- (void)playSound:(NSString *)sound
{
    if ([self.soundPlayer isPlaying]) {
        [self.soundPlayer stop];
    }
    NSError* error;
    if ([sound isEqualToString:kStartRecordSound]) {
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:@"/System/Library/Audio/UISounds/Tink.caf"] error:&error];
    } else if ([sound isEqualToString:kEndRecordSound]) {
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:@"/System/Library/Audio/UISounds/Tock.caf"] error:&error];
    } else  {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:sound ofType:@"aif"];
        NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    }
    if (error || ![self.soundPlayer prepareToPlay]) {
        NSLog(@"%@",error);
    } else {
        float appPlayerVolume = [MPMusicPlayerController applicationMusicPlayer].volume;
        if (appPlayerVolume > 0.25) {
            [self.soundPlayer setVolume:1/(4*appPlayerVolume)];
        }
        [self.soundPlayer play];
    }
}

// ----------------------------------------------------------
#pragma mark Address Book Delegate
// ----------------------------------------------------------

- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
    return YES;
}


// -------------------------------------------
#pragma mark Auth Request View
// -------------------------------------------
- (void)displayContactAuthView
{
    self.permissionMessage.text = NSLocalizedStringFromTable(@"contact_permission_message", kStringFile, @"comment");
    self.permissionNote.text = NSLocalizedStringFromTable(@"contact_permission_note", kStringFile, @"comment");
    
    self.permissionImage.image = [UIImage imageNamed:@"contact-perm"];
    
    [self.authRequestSkipButton setTitle:NSLocalizedStringFromTable(@"skip_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    [self.authRequestAllowButton setTitle:NSLocalizedStringFromTable(@"contact_access_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    self.authRequestView.hidden = NO;
}

- (void)displayPushAuthView
{
    self.permissionMessage.text = NSLocalizedStringFromTable(@"notif_permission_message", kStringFile, @"comment");
    self.permissionNote.text = NSLocalizedStringFromTable(@"notif_permission_note", kStringFile, @"comment");
    
    self.permissionImage.image = [UIImage imageNamed:@"notif-perm"];

    [self.authRequestSkipButton setTitle:NSLocalizedStringFromTable(@"skip_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    [self.authRequestAllowButton setTitle:NSLocalizedStringFromTable(@"notify_me_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    self.authRequestView.hidden = NO;
}

- (IBAction)authRequestAllowButtonClicked:(id)sender
{
    if ([self.authRequestAllowButton.titleLabel.text isEqualToString:NSLocalizedStringFromTable(@"contact_access_button_title", kStringFile, @"comment")]) {
        [self requestContactAuth];
        [self closeContactRequest];
    } else if ([self.authRequestAllowButton.titleLabel.text isEqualToString:NSLocalizedStringFromTable(@"notify_me_button_title", kStringFile, @"comment")]) {
        [GeneralUtils registerForRemoteNotif];
        [self hideAuthRequestView];
    }
}

- (IBAction)authRequestSkipButtonClicked:(id)sender {
    [self closeContactRequest];
}

- (void)closeContactRequest
{
    if (!self.pushAuthViewSeen && ![GeneralUtils pushNotifRequestSeen]) {
        self.pushAuthViewSeen = YES;
        [self displayPushAuthView];
    } else {
        [self hideAuthRequestView];
    }
}

- (void)hideAuthRequestView
{
    self.authRequestView.hidden = YES;
}

// Display address book access request
- (void)requestContactAuth {
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            [self matchPhoneContactsWithHeardUsers];
        }
    });
}

// -------------------------------------------
#pragma mark Opening Tuto
// -------------------------------------------
- (void)prepareAndDisplayTuto
{
    ContactView *firstContactView = ((ContactView *)[self.contactViews firstObject]);
    
    [self displayOpeningTutoWithActionLabel:NSLocalizedStringFromTable(@"hold_tuto_action_label", kStringFile, @"comment") forOrigin:firstContactView.frame.origin.x + firstContactView.frame.size.width/2];
    [self.contactScrollView bringSubviewToFront:self.openingTutoView];
    // only me visible + 1st contact
    for (ContactView *contactView in self.contactViews) {
        if ([GeneralUtils isCurrentUser:contactView.contact]) {
            if (contactView.orderPosition != 1) {
                NSLog(@"me should be first");
            }
            [self.contactScrollView bringSubviewToFront:contactView];
            [self.contactScrollView bringSubviewToFront:contactView.nameLabel];
            break;
        }
    }
}

- (IBAction)openingTutoSkipButtonClicked:(id)sender {
    [self hideOpeningTuto];
    self.displayOpeningTuto = NO;
}

- (void)displayOpeningTutoWithActionLabel:(NSString *)actionLabel forOrigin:(float)x
{
    if (self.openingTutoArrow) {
        [self.openingTutoArrow removeFromSuperview];
    }
    
    self.openingTutoArrow = [[UIImageView alloc] initWithFrame:CGRectMake(x - 100/2,110,100,100)];
    self.openingTutoArrow.image = [UIImage imageNamed:@"tuto-arrow.png"];
    [self.openingTutoView addSubview:self.openingTutoArrow];
    
    [self.openingTutoDescLabel setText:actionLabel];
    [self.openingTutoSkipButton setTitle:NSLocalizedStringFromTable(@"skip_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    
    self.openingTutoView.hidden = NO;
}

- (void)hideOpeningTuto
{
    self.openingTutoView.hidden = YES;
}


@end
