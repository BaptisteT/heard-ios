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

#define ACTION_MAIN_MENU_OPTION_1 @"Invite Friends"
#define ACTION_MAIN_MENU_OPTION_2 @"Add New Contact"
#define ACTION_OTHER_MENU_OPTION_1 @"Edit Profile"
#define ACTION_OTHER_MENU_OPTION_2 @"Edit Contacts"
#define ACTION_OTHER_MENU_OPTION_3 @"Share"
#define ACTION_OTHER_MENU_OPTION_4 @"Feedback"
#define ACTION_PENDING_OPTION_1 @"Add Contact"
#define ACTION_PENDING_OPTION_2 @"Block User"
#define ACTION_SHEET_PROFILE_OPTION_1 @"Picture"
#define ACTION_SHEET_PROFILE_OPTION_2 @"First Name"
#define ACTION_SHEET_PROFILE_OPTION_3 @"Last Name"
#define ACTION_SHEET_PICTURE_OPTION_1 @"Camera"
#define ACTION_SHEET_PICTURE_OPTION_2 @"Library"
#define ACTION_CONTACT_MENU_OPTION_1 @"Replay Last"
#define ACTION_CONTACT_MENU_OPTION_3 @"Block"
#define ACTION_CONTACT_MENU_OPTION_4 @"Hide"
#define ACTION_FAILED_MESSAGES_OPTION_1 @"Resend"
#define ACTION_FAILED_MESSAGES_OPTION_2 @"Delete"
#define ACTION_SHEET_CANCEL @"Cancel"


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
@property (nonatomic, strong) UITextView *noAddressBookAccessLabel;
// Record
@property (strong, nonatomic) UIView *recorderContainer;
@property (nonatomic,strong) UIView *recorderLine;
@property (nonatomic, strong) AVAudioRecorder *recorder;
// Player
@property (strong, nonatomic) UIView *playerContainer;
@property (nonatomic,strong) UIView *playerLine;
@property (nonatomic, strong) AVAudioPlayer *mainPlayer;
@property (nonatomic, strong) AVAudioPlayer *recordSoundPlayer;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic) BOOL isUsingHeadSet;
// Current user
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImageView *profilePicture;
@property (weak, nonatomic) ContactView *currentUserContactView;
// Others
@property (weak, nonatomic) UIButton *menuButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UIView *tutoView;
@property (nonatomic, strong) UILabel *tutoViewLabel;
@property (strong, nonatomic) NSMutableArray *nonAttributedUnreadMessages;
//Action sheets
@property (strong, nonatomic) CustomActionSheet *mainMenuActionSheet;
@property (strong, nonatomic) CustomActionSheet *contactMenuActionSheet;
@property (strong, nonatomic) ContactView *lastSelectedContactView;
//Alertview
@property (strong, nonatomic) UIAlertView *blockAlertView;

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
    
    // Init address book
    self.addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(self.addressBook,MyAddressBookExternalChangeCallback, (__bridge void *)(self));
    
    //Init no message view
    self.tutoView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT)];
    self.tutoView.backgroundColor = [ImageUtils blue];
    
    self.tutoViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT)];
    self.tutoViewLabel.font = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    self.tutoViewLabel.textAlignment = NSTextAlignmentCenter;
    self.tutoViewLabel.textColor = [UIColor whiteColor];
    self.tutoViewLabel.backgroundColor = [UIColor clearColor];
    [self.tutoView addSubview:self.tutoViewLabel];
    [self.view addSubview:self.tutoView];
    
    // Init no adress book access label
    [self initNoAddressBookAccessLabel]; // we do it here to avoid to resize text in a parrallel thread
    
    // Preload profile picture
    self.profilePicture = [UIImageView new];
    [self.profilePicture setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:[SessionUtils getCurrentUserId]]];
    
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
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                       withOptions:AVAudioSessionCategoryOptionMixWithOthers
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
    
    //
    self.recordSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:@"/System/Library/Audio/UISounds/Tink.caf"] error:nil];
    [self.recordSoundPlayer prepareToPlay];

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

- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration
{
    [self endTutoMode];
    
    self.tutoViewLabel.text = message;
    self.tutoView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.tutoView.frame = CGRectMake(self.tutoView.frame.origin.x,
                                             self.tutoView.frame.origin.y - self.tutoView.frame.size.height,
                                             self.tutoView.frame.size.width,
                                             self.tutoView.frame.size.height);
    } completion:^(BOOL finished) {
        if (finished && self.tutoView) {
            if (duration > 0) {
                [UIView animateWithDuration:0.5 delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.tutoView.frame = CGRectMake(self.tutoView.frame.origin.x,
                                                         self.tutoView.frame.origin.y + self.tutoView.frame.size.height,
                                                         self.tutoView.frame.size.width,
                                                         self.tutoView.frame.size.height);
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
    if (!self.tutoView) {
        return;
    }
    
    [self.tutoView.layer removeAllAnimations];
    self.tutoView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, NO_MESSAGE_VIEW_HEIGHT);
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
    // Remove hidden contact without message
    [self removeViewOfHiddenContacts];
    
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
    [self setScrollViewSizeForContactCount:(int)[self.contactViews count]];
    
    if ([GeneralUtils isFirstOpening]) {
        //Show util user does something
        [self tutoMessage:@"Hold a contact to record." withDuration:0];
    }
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
    [self.contactScrollView addSubview:contactView];
}

// Add name below contact
- (void)addNameLabelForView:(ContactView *)contactView
{
    Contact *contact = contactView.contact;
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(contactView.frame.origin.x - kContactMargin/4, contactView.frame.origin.y + kContactSize, contactView.frame.size.width + kContactMargin/2, kContactNameHeight)];
    
    // Attach single tap gesture recogniser
    UITapGestureRecognizer *recogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapOnNameLabel:)];
    recogniser.numberOfTapsRequired = 1;
    [nameLabel addGestureRecognizer:recogniser];
    nameLabel.userInteractionEnabled = YES;
    
    if ([GeneralUtils isAdminContact:contact]) {
        nameLabel.text = @"Waved";
        nameLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:14.0];
    } else if ([GeneralUtils isCurrentUser:contact]) {
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
        [GeneralUtils showMessage:@"Failed to block contact, please try again." withTitle:nil];
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
    void (^successBlock)(NSArray*,BOOL) = ^void(NSArray *messages, BOOL newContactOnServer) {
        //Reset unread messages
        [self resetUnreadMessages];
        BOOL areAttributed = YES;
        for (Message *message in messages) {
            areAttributed &= [self attributeMessageToExistingContacts:message];
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:messages.count];
        
        // Check if we have new contacts
        // App launch or Change in address book or Message from unknown or New user added current user
        if (self.retrieveNewContact || !areAttributed || newContactOnServer) {
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

- (void)singleTapOnNameLabel:(UITapGestureRecognizer *)sender
{
    // Find corresponding contact views (not very elegant..)
    self.lastSelectedContactView = nil;
    for (ContactView *contactView in self.contactViews) {
        if (contactView.nameLabel == (UILabel *)sender.view) {
            self.lastSelectedContactView = contactView;
            continue;
        }
    }
    if (!self.lastSelectedContactView) {
        return;
    }
    
    // Init contact menu action sheet
    self.contactMenuActionSheet = [CustomActionSheet new];
    self.contactMenuActionSheet.delegate = self;
    
    // Add buttons
    // Message to replay
    if (self.lastSelectedContactView.contact.lastPlayedMessageId != 0) {
        [self.contactMenuActionSheet addButtonWithTitle:ACTION_CONTACT_MENU_OPTION_1];
    }
    
    [self.contactMenuActionSheet addButtonWithTitle:ACTION_CONTACT_MENU_OPTION_4];
    [self.contactMenuActionSheet addButtonWithTitle:ACTION_SHEET_CANCEL];
    self.contactMenuActionSheet.cancelButtonIndex = self.contactMenuActionSheet.numberOfButtons - 1;
    
    // Add title
    NSString *firstName = self.lastSelectedContactView.contact.firstName ? self.lastSelectedContactView.contact.firstName : @"";
    NSString *lastName = self.lastSelectedContactView.contact.lastName ? self.lastSelectedContactView.contact.lastName : @"";


    // One tap on title block
    void (^titleTapBlock)() = nil;
    __weak __typeof__(self) weakSelf = self;
    if ([GeneralUtils isCurrentUser:self.lastSelectedContactView.contact]) {
        titleTapBlock = ^void() {
            UIActionSheet *newActionSheet = [[UIActionSheet alloc]
                                             initWithTitle:[NSString  stringWithFormat:@"Waved v.%@", [[NSBundle mainBundle]  objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                             delegate:weakSelf
                                             cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                             otherButtonTitles:ACTION_OTHER_MENU_OPTION_1, ACTION_OTHER_MENU_OPTION_2, ACTION_OTHER_MENU_OPTION_3, ACTION_OTHER_MENU_OPTION_4, nil];
            [newActionSheet showInView:[UIApplication sharedApplication].keyWindow];
        };
    } else if (![GeneralUtils isAdminContact:self.lastSelectedContactView.contact]) { // not Waved
        titleTapBlock = ^void() {
            ABRecordRef person = [AddressbookUtils findContactForNumber:self.lastSelectedContactView.contact.phoneNumber];
            if (!person) {
                [GeneralUtils showMessage:@"We could not retrieve this contact" withTitle:nil];
                [TrackingUtils trackFailedToOpenContact:self.lastSelectedContactView.contact.phoneNumber];
                return;
            }
            ABPersonViewController *personViewController = [[ABPersonViewController alloc] init];
            personViewController.personViewDelegate = weakSelf;
            personViewController.displayedPerson = person;
            personViewController.allowsEditing = NO;
            [weakSelf.navigationController pushViewController:personViewController animated:YES];
            weakSelf.navigationController.navigationBarHidden = NO;
        };
    }

    [self.contactMenuActionSheet addTitleViewWithUsername:[NSString stringWithFormat:@"%@ %@", firstName, lastName]
                                                    image:self.lastSelectedContactView.imageView.image
     andOneTapBlock:titleTapBlock];
    [self.contactMenuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (IBAction)menuButtonClicked:(id)sender {

    self.mainMenuActionSheet = [[CustomActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:ACTION_MAIN_MENU_OPTION_1, ACTION_MAIN_MENU_OPTION_2, nil];
    
    __weak __typeof__(self) weakSelf = self;
    void (^titleTapBlock)() = ^void() {
        UIActionSheet *newActionSheet = [[UIActionSheet alloc]
                                         initWithTitle:[NSString  stringWithFormat:@"Waved v.%@", [[NSBundle mainBundle]  objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                         delegate:weakSelf
                                         cancelButtonTitle:ACTION_SHEET_CANCEL
                                         destructiveButtonTitle:nil
                                         otherButtonTitles:ACTION_OTHER_MENU_OPTION_1, ACTION_OTHER_MENU_OPTION_2, ACTION_OTHER_MENU_OPTION_3, ACTION_OTHER_MENU_OPTION_4, nil];
        [newActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    };
    
    [self.mainMenuActionSheet addTitleViewWithUsername:[NSString stringWithFormat:@"%@ %@", [SessionUtils getCurrentUserFirstName], [SessionUtils getCurrentUserLastName]]
                                                 image:self.profilePicture.image
                                        andOneTapBlock:titleTapBlock];
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
    NSData *audioData = [[NSData alloc] initWithContentsOfURL:self.recorder.url];
    [ApiUtils sendMessage:audioData toUser:contactView.contact.identifier success:^{
        [contactView message:nil sentWithError:NO]; // no need to pass the message here
    } failure:^{
        [contactView message:audioData sentWithError:YES];
    }];
}

- (void)resendMessagestoContact:(ContactView *)contactView
{
    // Resend Messages
    for (NSData *audioData in contactView.failedMessages) {
        [ApiUtils sendMessage:audioData toUser:contactView.contact.identifier success:^{
            [contactView message:nil sentWithError:NO];
        } failure:^{
            [contactView message:audioData sentWithError:YES];
        }];
    }
    
    [contactView deleteFailedMessages];
    [contactView startLoadingAnimationWithStrokeColor:[ImageUtils red]];
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
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerUIAnimated:NO];
    }
    
    float appPlayerVolume = [MPMusicPlayerController applicationMusicPlayer].volume;
    if (appPlayerVolume > 0.25) {
        [self.recordSoundPlayer setVolume:1/(4*appPlayerVolume)];
    }
    [self.recordSoundPlayer play];
    [self disableAllContactViews];
    
    [self recordingUIForContactView:contactView];
    
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
    [self.recordSoundPlayer play];
    
    // Remove UI
    self.recorderLine.frame = [[self.recorderLine.layer presentationLayer] frame];
    [self.recorderLine.layer removeAllAnimations];
    self.recorderContainer.hidden = YES;
    [self setRecorderLineWidth:0];
    [self enableAllContactViews];
}

- (void)startedPlayingAudioFileByView:(ContactView *)contactView
{
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerUIAnimated:NO];
    }
    [self.playerContainer.layer removeAllAnimations];
    
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

- (void)failedMessagesModeTapGestureOnContact:(ContactView *)contactView
{
    self.lastSelectedContactView = contactView;
    NSString *plural = contactView.failedMessages.count > 1 ? @"s" : @"";
    NSString *title = [NSString stringWithFormat:@"%lu message%@ failed to send",contactView.failedMessages.count,plural];
    UIActionSheet *pendingActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                    delegate:self
                                                           cancelButtonTitle:ACTION_SHEET_CANCEL
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:ACTION_FAILED_MESSAGES_OPTION_1, ACTION_FAILED_MESSAGES_OPTION_2, nil];
    [pendingActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}


// ----------------------------------------------------------
#pragma mark Player Mode
// ----------------------------------------------------------

- (void)playerUIForContactView:(ContactView *)contactView
{
    [contactView startPlayingUI];
}

- (void)endPlayerUIForAllContactViews
{
    for (ContactView *contactView in self.contactViews) {
        [contactView endRecordingPlayingUI];
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
    
    /* -------------------------------------------------------------------------
     OTHER MENU
     ---------------------------------------------------------------------------*/
    
    // Profile
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_1]) {
        [actionSheet dismissWithClickedButtonIndex:2 animated:NO];
        UIActionSheet *newActionSheet = [[UIActionSheet alloc] initWithTitle:nil
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
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_4]) {
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
    
    // Block
    else if ([buttonTitle isEqualToString:ACTION_CONTACT_MENU_OPTION_3]) {
        
        self.blockAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                         message:[NSString stringWithFormat:@"Are you sure you want to remove %@ from your contacts?", self.lastSelectedContactView.contact.firstName ? self.lastSelectedContactView.contact.firstName : self.lastSelectedContactView.contact.lastName]
                                                        delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Cancel", @"Block", nil];
        [self.blockAlertView show];
    }
    // Hide
    else if ([buttonTitle isEqualToString:ACTION_CONTACT_MENU_OPTION_4]) {
        [self removeContactView:self.lastSelectedContactView];
        self.lastSelectedContactView = nil;
        [self reorderContactViews];
    }
    
    /* -------------------------------------------------------------------------
     FAILED MESSAGES MENU
     ---------------------------------------------------------------------------*/
    
    // Resend
    else if ([buttonTitle isEqualToString:ACTION_FAILED_MESSAGES_OPTION_1]) {
        [self resendMessagestoContact:self.lastSelectedContactView];
    }
    
    // Delete
    else if ([buttonTitle isEqualToString:ACTION_FAILED_MESSAGES_OPTION_2]) {
        [self.lastSelectedContactView deleteFailedMessages];
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
    
    if (alertView == self.blockAlertView && buttonIndex == 1) {
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
            // Update image
            self.profilePicture.image = image;
            if (self.currentUserContactView) {
                self.currentUserContactView.imageView.image = image;
            }
            [GeneralUtils showMessage:@"Profile picture successfully updated." withTitle:nil];
            
            // Reset the cache
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
        if (self.recorder.isRecording) {
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
            [self endedLongPressRecording];
            for (ContactView *contactView in self.contactViews) {
                [contactView endRecordingPlayingUI];
            }
            [self tutoMessage:@"Message canceled" withDuration:2];
        }
    }
}


// ----------------------------------------------------------
#pragma mark Address Book Delegate
// ----------------------------------------------------------

- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
    return YES;
}

@end
