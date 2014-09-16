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

#define ACTION_MAIN_MENU_OPTION_1 NSLocalizedStringFromTable(@"invite_friends_button_title",kStringFile,@"comment")
#define ACTION_MAIN_MENU_OPTION_2 NSLocalizedStringFromTable(@"add_new_contact_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_1 NSLocalizedStringFromTable(@"edit_profile_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_2 NSLocalizedStringFromTable(@"hide_contacts_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_3 NSLocalizedStringFromTable(@"share_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_4 NSLocalizedStringFromTable(@"feedback_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_5 NSLocalizedStringFromTable(@"log_out_button_title",kStringFile,@"comment")
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

#define RECORDER_HEIGHT 5
#define PLAYER_UI_HEIGHT 5
#define INVITE_CONTACT_BUTTON_HEIGHT 50
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
@property (strong, nonatomic) CustomActionSheet *mainMenuActionSheet;
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
@property (strong, nonatomic) IBOutlet UILabel *openingTutoActionLabel;
@property (strong, nonatomic) IBOutlet UILabel *openingTutoDescLabel;
@property (strong, nonatomic) IBOutlet UIButton *openingTutoSkipButton;

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
    
    // Create contact views
    [self displayContactViews];
    
    // Ask micro access
    AVAudioSession* session = [AVAudioSession sharedInstance];
    BOOL success; NSError* error;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
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
    
    // Add background transition observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hide) name:@"UIApplicationWillResignActiveNotification" object:nil];
    
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
    self.recorderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - RECORDER_HEIGHT, self.view.bounds.size.width, RECORDER_HEIGHT)];
    self.recorderContainer.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.recorderContainer];
    self.recorderContainer.hidden = YES;
    
    // Recoder line
    self.recorderLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, RECORDER_HEIGHT)];
    self.recorderLine.backgroundColor = [ImageUtils red];
    [self.recorderContainer addSubview:self.recorderLine];
    
    // Init player container
    self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - PLAYER_UI_HEIGHT, self.view.bounds.size.width, PLAYER_UI_HEIGHT)];
    self.playerContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.playerContainer];
    self.playerContainer.hidden = YES;
    
    // player line
    self.playerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, PLAYER_UI_HEIGHT)];
    self.playerLine.backgroundColor = [ImageUtils green];
    [self.playerContainer addSubview:self.playerLine];
    
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
    }
}

- (void)hide
{
    [self dismissViewControllerAnimated:NO completion:NO];
}

// ------------------------------
#pragma mark UI Modes
// ------------------------------
- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration
{
    [self endTutoMode];
    
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
//    [self.contactScrollView addSubview:contactView];
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
                    contactView.messageNotReadByContact = YES;
                    idFound = YES;
                    continue;
                }
            }
            if (!idFound) {
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
        self.mainMenuActionSheet = [[CustomActionSheet alloc] initWithTitle:nil
                                                               delegate:self
                                                      cancelButtonTitle:ACTION_SHEET_CANCEL
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:ACTION_MAIN_MENU_OPTION_1, ACTION_MAIN_MENU_OPTION_2, nil];
        
        __weak __typeof__(self) weakSelf = self;
        void (^titleTapBlock)() = ^void() {
            CustomActionSheet *newActionSheet = [[CustomActionSheet alloc]
                                             initWithTitle:[NSString  stringWithFormat:@"Waved v.%@", [[NSBundle mainBundle]  objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                             delegate:weakSelf
                                             cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                             otherButtonTitles:ACTION_OTHER_MENU_OPTION_1, ACTION_OTHER_MENU_OPTION_2, ACTION_OTHER_MENU_OPTION_3, ACTION_OTHER_MENU_OPTION_4, ACTION_OTHER_MENU_OPTION_5, nil];
            [newActionSheet showInView:[UIApplication sharedApplication].keyWindow];
        };
        
        [self.mainMenuActionSheet addTitleViewWithUsername:[NSString stringWithFormat:@"%@ %@", [SessionUtils getCurrentUserFirstName], [SessionUtils getCurrentUserLastName]]
                                                     image:self.profilePicture.image
                                            andOneTapBlock:titleTapBlock];
        [self.mainMenuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}


// ----------------------------------------------------------
#pragma mark Recording Mode
// ----------------------------------------------------------

- (void)disableAllContactViews
{
    for (ContactView *view in self.contactViews) {
        view.userInteractionEnabled = NO;
    }
}

- (void)enableAllContactViews
{
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
    [ApiUtils sendMessage:audioData toUser:contactView.contact.identifier success:^{
        [contactView message:nil sentWithError:NO]; // no need to pass the message here
    } failure:^{
        [contactView message:audioData sentWithError:YES];
    }];
}

- (NSData *)getLastRecordedData
{
    return [[NSData alloc] initWithContentsOfURL:self.recorder.url];
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
    
    // Update frame of Name Label too
    view.nameLabel.frame = CGRectMake(view.frame.origin.x - kContactMargin/4, view.frame.origin.y + kContactSize, view.frame.size.width + kContactMargin/2, kContactNameHeight);
}

//Create recording mode screen
- (void)startedLongPressOnContactView:(ContactView *)contactView
{
    [self hideOpeningTuto];
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
    // Stop recording
    [self.recorder stop];
    [self playSound:kEndRecordSound];
    
    // Remove UI
    self.recorderLine.frame = [[self.recorderLine.layer presentationLayer] frame];
    [self.recorderLine.layer removeAllAnimations];
    self.recorderContainer.hidden = YES;
    [self setRecorderLineWidth:0];
    
    [self enableAllContactViews];
}

- (void)startedPlayingAudioMessagesOfView:(ContactView *)contactView
{
    [self hideOpeningTuto];
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerAtCompletion:NO];
    }
    self.lastSelectedContactView = contactView;
    [self.playerContainer.layer removeAllAnimations];
    
    // Init player
    Message *message = (Message *)contactView.unreadMessages[0];
    self.mainPlayer = [[AVAudioPlayer alloc] initWithData:message.audioData error:nil];
    [self addMessagesToLastMessagesPlayed:message];
    
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
        [self displayOpeningTutoWithActionLabel:NSLocalizedStringFromTable(@"menu_tuto_action_label", kStringFile, @"comment") andDescLabel:NSLocalizedStringFromTable(@"menu_tuto_desc_label", kStringFile, @"comment")];
        self.displayOpeningTuto = NO;
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
     MAIN MENU
    ---------------------------------------------------------------------------*/
    
    // Invite contact
    if ([buttonTitle isEqualToString:ACTION_MAIN_MENU_OPTION_1]) {
        [self performSegueWithIdentifier:@"Invite Contacts Segue" sender:nil];
        
    // Add New Contact
    } else if ([buttonTitle isEqualToString:ACTION_MAIN_MENU_OPTION_2]) {
        [self performSegueWithIdentifier:@"Add Contact Segue" sender:nil];
    }
    
    /* -------------------------------------------------------------------------
     OTHER MENU
     ---------------------------------------------------------------------------*/
    
    // Profile
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_1]) {
        [actionSheet dismissWithClickedButtonIndex:2 animated:NO];
        CustomActionSheet *newActionSheet = [[CustomActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:ACTION_SHEET_CANCEL
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:ACTION_SHEET_PROFILE_OPTION_1, ACTION_SHEET_PROFILE_OPTION_2, ACTION_SHEET_PROFILE_OPTION_3, nil];
        
        [newActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    // Edit contacts
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_2]) {
        [self performSegueWithIdentifier:@"Edit Contacts Segue" sender:nil];
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
    
    // Log out
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_5]) {
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:buttonTitle message:nil delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"cancel_button_title",kStringFile, @"comment") otherButtonTitles:NSLocalizedStringFromTable(@"ok_button_title",kStringFile, @"comment"), nil];
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

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
    {
        // cancel recording
        if ([self isRecording]) {
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
            [self endedLongPressRecording];
            for (ContactView *contactView in self.contactViews) {
                [contactView cancelRecording];
            }
            [self tutoMessage:NSLocalizedStringFromTable(@"cancel_success_message",kStringFile, @"comment") withDuration:2];
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
                    continue;
                }
            }
        } else {
            [self tutoMessage:NSLocalizedStringFromTable(@"no_last_message_played_message",kStringFile, @"comment") withDuration:2];
        }
    }
}

// ----------------------------------------------------------
#pragma mark Sounds
// ----------------------------------------------------------

- (void)playSound:(NSString *)sound
{
    if ([sound isEqualToString:kStartRecordSound]) {
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:@"/System/Library/Audio/UISounds/Tink.caf"] error:nil];
        [self.soundPlayer prepareToPlay];
    } else if ([sound isEqualToString:kEndRecordSound]) {
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:@"/System/Library/Audio/UISounds/Tock.caf"] error:nil];
    } else  {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:sound ofType:@"aif"];
        NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    }
    
    float appPlayerVolume = [MPMusicPlayerController applicationMusicPlayer].volume;
    if (appPlayerVolume > 0.25) {
        [self.soundPlayer setVolume:1/(4*appPlayerVolume)];
    }
    [self.soundPlayer play];
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
    [self displayOpeningTutoWithActionLabel:NSLocalizedStringFromTable(@"hold_tuto_action_label", kStringFile, @"comment") andDescLabel:NSLocalizedStringFromTable(@"hold_tuto_desc_label", kStringFile, @"comment")];
    [self.contactScrollView bringSubviewToFront:self.openingTutoView];
    // only me visible + 1st contact
    for (ContactView *contactView in self.contactViews) {
        if ([GeneralUtils isCurrentUser:contactView.contact]) {
            if (contactView.orderPosition != 1) {
                // todo BT
                NSLog(@"me should be first");
            }
            [self.contactScrollView bringSubviewToFront:contactView];
            [self.contactScrollView bringSubviewToFront:contactView.nameLabel];
            continue;
        }
    }
}

- (IBAction)openingTutoSkipButtonClicked:(id)sender {
    [self hideOpeningTuto];
    self.displayOpeningTuto = NO;
}

- (void)displayOpeningTutoWithActionLabel:(NSString *)actionLabel andDescLabel:(NSString *)descLabel
{
    [self.openingTutoActionLabel setText:actionLabel];
    [self.openingTutoDescLabel setText:descLabel];
    [self.openingTutoSkipButton setTitle:NSLocalizedStringFromTable(@"skip_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    self.openingTutoView.hidden = NO;
}

- (void)hideOpeningTuto
{
    self.openingTutoView.hidden = YES;
}


@end
