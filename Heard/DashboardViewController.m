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
#import "AddressbookUtils.h"
#import "MBProgressHUD.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CameraUtils.h"
#import "PotentialContact.h"
#import "EmojiView.h"
#import <MediaPlayer/MPVolumeView.h>
#import "CreateGroupsViewController.h"
#import "Group.h"
#import "GroupView.h"
#import "GroupUtils.h"
#import "ManageGroupsViewController.h"
#import "InviteViewController.h"

#define ACTION_PENDING_OPTION_1 NSLocalizedStringFromTable(@"add_to_contact_button_title",kStringFile,@"comment")
#define ACTION_PENDING_OPTION_2 NSLocalizedStringFromTable(@"block_button_title",kStringFile,@"comment")

#define ACTION_FAILED_MESSAGES_OPTION_1 NSLocalizedStringFromTable(@"resend_button_title",kStringFile,@"comment")
#define ACTION_FAILED_MESSAGES_OPTION_2 NSLocalizedStringFromTable(@"delete_button_title",kStringFile,@"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")

#define RECORDER_HEIGHT 70
#define PLAYER_UI_HEIGHT 70
#define NO_MESSAGE_VIEW_HEIGHT 40
#define NO_MESSAGE_VIEW_WIDTH 280

@interface DashboardViewController ()

// Groups
@property (strong, nonatomic) NSMutableArray *groups;
// Contacts
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactViews;
@property (weak, nonatomic) UIScrollView *contactScrollView;
@property (nonatomic) BOOL retrieveNewContact;
@property (nonatomic, strong) ContactView *clickedPendingView;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat screenHeight;
@property (nonatomic) NSInteger contactsPerRow;
@property (nonatomic) CGFloat contactMargin;
// Record
@property (strong, nonatomic) UIView *recorderContainer;
@property (nonatomic,strong) UIView *recorderLine;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (strong, nonatomic) UILabel *recorderLabel;
// Player
@property (strong, nonatomic) UIView *playerContainer;
@property (nonatomic,strong) UIView *playerLine;
@property (nonatomic, strong) AVAudioPlayer *mainPlayer;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic) BOOL isUsingHeadSet;
@property (nonatomic, strong) AVAudioPlayer *soundPlayer;
@property (strong, nonatomic) UILabel *playerLabel;
@property (nonatomic) BOOL LoudSpeakerMode;
@property (nonatomic) BOOL earDetected;
@property (strong, nonatomic) IBOutlet UIButton *speakerButton;
// Current user
@property (weak, nonatomic) ContactView *currentUserContactView;
// Others
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) NSMutableArray *nonAttributedUnreadMessages;
@property (strong, nonatomic) NSMutableArray *lastMessagesPlayed;
// Action sheets
@property (strong, nonatomic) UIActionSheet *menuActionSheet;
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
// Tuto
@property (nonatomic) BOOL isFirstOpening;
@property (nonatomic) BOOL displayOpeningTuto;
@property (nonatomic, strong) UIView *bottomTutoView;
@property (nonatomic, strong) UILabel *bottomTutoViewLabel;
@property (strong, nonatomic) UIView *openingTutoView;
@property (strong, nonatomic) UIView *openingTutoBarView;
@property (strong, nonatomic) UILabel *openingTutoDescLabel;
@property (strong, nonatomic) UIButton *openingTutoSkipButton;
@property (strong, nonatomic) UIView *openingTutoDescView;
@property (strong, nonatomic) UIImageView *openingTutoArrow;
// Invite new contacts
@property (strong, nonatomic) NSMutableDictionary *indexedContacts;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *topBarBackground;
// Emoji View
@property (strong, nonatomic) NSData *emojiData;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton;
@property (strong, nonatomic) UIScrollView *emojiScrollView;

@end

@implementation DashboardViewController 

// ------------------------------
#pragma mark Life cycle
// ------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.retrieveNewContact = YES;
    self.authRequestView.hidden = YES;
    self.openingTutoView.hidden = YES;
    self.isFirstOpening = [GeneralUtils isFirstOpening];
    self.displayOpeningTuto = self.isFirstOpening;
    
    self.openingTutoDescView.layer.cornerRadius = 5;
    
    //Contact scrollview variables
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.screenWidth = screenRect.size.width;
    self.screenHeight = screenRect.size.height;
    
    self.contactsPerRow = self.screenWidth / (kContactSize + kContactMinimumMargin);
    self.contactMargin = (self.screenWidth - (self.contactsPerRow * kContactSize))/(self.contactsPerRow + 1);
    
    //Perms
    self.authRequestAllowButton.clipsToBounds = YES;
    self.authRequestAllowButton.layer.cornerRadius = self.authRequestAllowButton.bounds.size.height/2;
    
    [GeneralUtils addBottomBorder:self.topBarBackground borderSize:0.5];
    
    //Init no message view
    self.bottomTutoView = [[UIView alloc] initWithFrame:CGRectMake(self.screenWidth/2 - NO_MESSAGE_VIEW_WIDTH/2, self.view.bounds.size.height - 4 * NO_MESSAGE_VIEW_HEIGHT, NO_MESSAGE_VIEW_WIDTH, NO_MESSAGE_VIEW_HEIGHT)];
    
    self.bottomTutoView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    self.bottomTutoView.clipsToBounds = YES;
    self.bottomTutoView.layer.cornerRadius = 5;
    
    self.bottomTutoViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, NO_MESSAGE_VIEW_WIDTH, NO_MESSAGE_VIEW_HEIGHT)];
    self.bottomTutoViewLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0];
    self.bottomTutoViewLabel.textAlignment = NSTextAlignmentCenter;
    self.bottomTutoViewLabel.textColor = [UIColor whiteColor];
    self.bottomTutoViewLabel.backgroundColor = [UIColor clearColor];
    [self.bottomTutoView addSubview:self.bottomTutoViewLabel];
    [self.view addSubview:self.bottomTutoView];
    self.bottomTutoView.alpha = 0;
    
    // Get contacts
    self.contacts = ((HeardAppDelegate *)[[UIApplication sharedApplication] delegate]).contacts;
    if (self.contacts.count == 0) {
        // add me contact
        Contact *meContact = [Contact createContactWithId:[SessionUtils getCurrentUserId] phoneNumber:[SessionUtils getCurrentUserPhoneNumber] firstName:[SessionUtils getCurrentUserFirstName] lastName:[SessionUtils getCurrentUserLastName]];
        meContact.lastMessageDate = [[NSDate date] timeIntervalSince1970];
        [self.contacts addObject:meContact];
    }
    
    // Create Groups
    self.groups = ((HeardAppDelegate *)[[UIApplication sharedApplication] delegate]).groups;
    
    //Create invite contact view
    self.inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contactMargin, kContactMinimumMargin, kContactSize, kContactSize)];
    [self.inviteButton addTarget:self action:@selector(inviteButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.inviteButton setImage:[UIImage imageNamed:@"invite-button"] forState:UIControlStateNormal];
    [self.contactScrollView addSubview:self.inviteButton];
    
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
    
    // Init player container
    self.playerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, PLAYER_UI_HEIGHT)];
    self.playerContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.playerContainer];
    self.playerContainer.hidden = YES;
    [self.view bringSubviewToFront:self.speakerButton];
    
    // player line
    self.playerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, PLAYER_UI_HEIGHT)];
    self.playerLine.backgroundColor = [ImageUtils transparentGreen];
    [self.playerContainer addSubview:self.playerLine];
    
    //player date label
    self.playerLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 120/2, 25, 120, 25)];
    self.playerLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    self.playerLabel.textAlignment = NSTextAlignmentCenter;
    self.playerLabel.textColor = [UIColor grayColor];
    self.playerLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    self.playerLabel.hidden = YES;
    self.playerLabel.text = @"";
    self.playerLabel.clipsToBounds = YES;
    self.playerLabel.layer.cornerRadius = 5;
    [self.playerContainer addSubview:self.playerLabel];
    
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
    
    // Init recorder container
    self.recorderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, RECORDER_HEIGHT)];
    self.recorderContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.recorderContainer];
    self.recorderContainer.hidden = YES;
    
    // Recoder line
    self.recorderLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, RECORDER_HEIGHT)];
    self.recorderLine.backgroundColor = [ImageUtils transparentRed];
    [self.recorderContainer addSubview:self.recorderLine];
    
    //Recorder label
    self.recorderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 120/2, 25, 120, 25)];
    self.recorderLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    self.recorderLabel.textAlignment = NSTextAlignmentCenter;
    self.recorderLabel.textColor = [UIColor grayColor];
    self.recorderLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    self.recorderLabel.hidden = YES;
    self.recorderLabel.text = @"";
    self.recorderLabel.clipsToBounds = YES;
    self.recorderLabel.layer.cornerRadius = 5;
    self.recorderLabel.text = NSLocalizedStringFromTable(@"recorder_label",kStringFile, @"comment");
    [self.recorderContainer addSubview:self.recorderLabel];
    
    if (self.displayOpeningTuto) {
        [self initOpeningTutoView];
        [self prepareAndDisplayTuto];
        // Update app info
        [ApiUtils updateAppInfoAndExecuteSuccess:nil failure:nil];
    } else {
        [GeneralUtils registerForRemoteNotif];
        if (![GeneralUtils isRegisteredForRemoteNotification]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"notification_error_title",kStringFile,@"comment")
                                        message:NSLocalizedStringFromTable(@"notification_error_message",kStringFile,  @"comment")
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
    
    // Init address book
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(self.addressBook,MyAddressBookExternalChangeCallback, (__bridge void *)(self));
    
    // Go to access view controller if acces has not yet been granted
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        [self displayContactAuthView];
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
    
    [self.openingTutoView setFrame:CGRectMake(0,0,self.contactScrollView.contentSize.width,self.screenHeight - 70)];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([[prefs objectForKey:kSpeakerPref] isEqualToString:@"Off"]) {
        self.LoudSpeakerMode = NO;
    } else {
        self.LoudSpeakerMode = YES;
    }
    
    // Retrieve messages & contacts
    [self retrieveUnreadMessagesAndNewContacts];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Create Group From Dashboard"]) {
        ((CreateGroupsViewController *) [segue destinationViewController]).delegate = self;
        ((CreateGroupsViewController *) [segue destinationViewController]).contacts = [self getGroupPermittedContacts];
    } else if ([segueName isEqualToString:@"Manage Groups From Dashboard"]) {
        ((ManageGroupsViewController *) [segue destinationViewController]).contacts = [self getGroupPermittedContacts];
        ((ManageGroupsViewController *) [segue destinationViewController]).groups = [NSMutableArray arrayWithArray:self.groups];
        ((ManageGroupsViewController *) [segue destinationViewController]).delegate = self;
    } else if ([segueName isEqualToString:@"Invite Modal Segue"]) {
        ((InviteViewController *) [segue destinationViewController]).contacts = self.contacts;
        ((InviteViewController *) [segue destinationViewController]).delegate = self;
    }
}


// ------------------------------
#pragma mark UI Modes
// ------------------------------
- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration priority:(BOOL)prority
{
    if ((self.displayOpeningTuto && !prority)) {
        return;
    }
    self.bottomTutoViewLabel.text = message;
    
    [self.bottomTutoView.layer removeAllAnimations];
    self.bottomTutoView.alpha = 0;
    
    [UIView animateWithDuration:1 animations:^{
        self.bottomTutoView.alpha = 1;
    } completion:^(BOOL finished) {
        if (finished && self.bottomTutoView) {
            if (duration > 0) {
                [UIView animateWithDuration:1 delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.bottomTutoView.alpha = 0;
                } completion:nil];
            }
        }
    }];
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
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:NSLocalizedStringFromTable(@"contact_access_error_message",kStringFile, @"comment")
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)matchPhoneContactsWithHeardUsers
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
        [ApiUtils getMyContacts:contactsInfo atSignUp:self.isSignUp success:^(NSArray *contacts, NSArray *futureContacts, NSArray *groups, BOOL destroyFutures) {
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
                
                //Remove users to create indexedContacts for the InviteContactsViewController
                [self.addressBookFormattedContacts removeObjectForKey:contact.phoneNumber];
            }
            if (destroyFutures) {
                NSMutableArray *discardedContacts = [NSMutableArray array];
                for (Contact *contact in self.contacts) {
                    if (contact.isFutureContact) {
                        [self removeViewOfContact:contact];
                        [discardedContacts addObject:contact];
                    }
                }
                [self.contacts removeObjectsInArray:discardedContacts];
            } else {
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
                            break;
                        }
                    }
                    if (!remove) {
                        [self.contacts addObject:contact];
                        [self displayAdditionnalContact:contact];
                    }
                    
                    //Remove future users to create indexedContacts for the InviteContactsViewController
                    [self.addressBookFormattedContacts removeObjectForKey:phoneNumber];
                }
            }
            for (Group *group in groups) {
                // Check current user belongs to this group
                if (![self user:[SessionUtils getCurrentUserId] belongsToGroup:group]) {
                    continue;
                }
                Group *existingGroup = [GroupUtils findGroupFromId:group.identifier inGroupsArray:self.groups];
                if (!existingGroup && group.memberIds.count > 1) {
                    // Add group
                    [self.groups addObject:group];
                    [self createContactViewWithGroup:group andPosition:0];
                } else {
                    if (group.memberIds.count > 1) {
                        existingGroup.memberIds = group.memberIds;
                        existingGroup.memberFirstName = group.memberFirstName;
                        existingGroup.memberLastName = group.memberLastName;
                        [[self getViewOfGroup:existingGroup] setContactPicture];
                    } else {
                        [self deleteGroupAndAssociatedView:existingGroup];
                    }
                }
            }
            
            // Distribute non attributed messages
            [self distributeNonAttributedMessages];
            
        } failure: ^void(NSURLSessionDataTask *task){
            if ([SessionUtils invalidTokenResponse:task]) {
                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"authentification_error_message",kStringFile,@"comment") withTitle:NSLocalizedStringFromTable(@"authentification_error_title",kStringFile,@"comment")];
                [SessionUtils redirectToSignIn:self.navigationController];
            }
        }];
        self.isSignUp = NO;
    });
}

// Address book changes callback
void MyAddressBookExternalChangeCallback (ABAddressBookRef notificationAddressBook,CFDictionaryRef info,void *context)
{
    DashboardViewController * dashboardController = (__bridge DashboardViewController *)context;
    dashboardController.retrieveNewContact = YES;
    dashboardController.addressBookFormattedContacts = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:dashboardController.addressBook];
    ABAddressBookRevert(notificationAddressBook);
}

//After adding a contact with AddContactViewController (delegate method) or after adding pending contact
- (void)didFinishedAddingContact
{
    [GeneralUtils showMessage: [NSLocalizedStringFromTable(@"add_contact_success_message",kStringFile,@"comment") stringByReplacingOccurrencesOfString:@"TRUCHOV" withString:self.clickedPendingView.contact.firstName]
                    withTitle:nil];
    // make non pending
    self.clickedPendingView.contact.isPending = NO;
    [self.clickedPendingView resetDiscussionStateAnimated:NO];
    self.clickedPendingView = nil;
}

// ----------------------------------
#pragma mark Contact Views
// ----------------------------------

- (void)displayContactViews
{
    [TrackingUtils trackNumberOfContacts:self.contacts.count];
    
    NSUInteger nonHiddenContactsCount = [ContactUtils numberOfNonHiddenContacts:self.contacts];
    NSUInteger numberOfGroups = self.groups.count;
    if (nonHiddenContactsCount + numberOfGroups == 0) {
        return;
    }
    self.contactViews = [[NSMutableArray alloc] initWithCapacity:nonHiddenContactsCount];
    
    // Create bubbles
    for (Contact *contact in self.contacts) {
        if (!contact.isHidden) {
            [self createContactViewWithContact:contact andPosition:1];
        }
    }
    for (Group *group in self.groups) {
        [self createContactViewWithGroup:group andPosition:1];
    }
    [self reorderContactViews];
}

- (void)createContactViewWithGroup:(Group *)group andPosition:(NSInteger)position
{
    // Check that view does not exist
    if ([self getViewOfGroup:group])
        return;
    
    GroupView *groupView = [[GroupView alloc] initWithGroup:group];
    if (group.groupName.length == 0) { // ie. info are missing
        void(^successBlock)(Group *) = ^void(Group *serverGroup) {
            group.groupName = serverGroup.groupName;
            group.memberIds = serverGroup.memberIds;
            group.memberFirstName = serverGroup.memberFirstName;
            group.memberLastName = serverGroup.memberLastName;
            [self addNameLabelToView:groupView withText:group.groupName];
            [groupView setContactPicture];
        };
        [ApiUtils getNewGroupInfo:group.identifier AndExecuteSuccess:successBlock failure:nil];
    } else {
        [self addNameLabelToView:groupView withText:group.groupName];
    }
    groupView.delegate = self;
    groupView.orderPosition = position;
    [self.contactViews addObject:groupView];
    [self.contactScrollView insertSubview:groupView atIndex:0];
}

- (void)reorderContactViews
{
    if ([self isRecording] || [self.mainPlayer isPlaying]) {
        return;
    }
    
    // Sort contact
    [self.contactViews sortUsingComparator:^(ContactView *contactView1, ContactView * contactView2) {
        if (self.displayOpeningTuto && contactView1 == self.currentUserContactView) {
            return (NSComparisonResult)NSOrderedAscending;
        } else if (self.displayOpeningTuto && contactView2 == self.currentUserContactView) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if ([contactView1 getLastMessageExchangedDate] < [contactView2 getLastMessageExchangedDate]) {
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
    // Check that view does not exist
    if ([self getViewOfContact:contact])
        return;
    
    [self createContactViewWithContact:contact andPosition:(int)[self.contactViews count]+1];
}

// Set Scroll View size from the number of contacts
- (void)setScrollViewSizeForContactCount:(int)count
{
    NSUInteger rows = count / self.contactsPerRow + 1;
    
    float rowHeight = kContactMinimumMargin + kContactSize + kContactNameHeight;
    self.contactScrollView.contentSize = CGSizeMake(self.screenWidth, MAX(self.screenHeight - self.contactScrollView.frame.origin.y, rows * rowHeight + self.contactsPerRow * kContactMinimumMargin)) ;
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
            [self addNameLabelToView:contactView];
        };
        [ApiUtils getNewContactInfo:contact.identifier AndExecuteSuccess:successBlock failure:nil];
    } else {
        [self addNameLabelToView:contactView];
    }
    
    contactView.delegate = self;
    contactView.orderPosition = position;
    [self.contactViews addObject:contactView];
    [self.contactScrollView insertSubview:contactView atIndex:0];
}

// Add name below contact
- (void)addNameLabelToView:(ContactView *)contactView
{
    Contact *contact = contactView.contact;
    NSString *text;
    if ([GeneralUtils isAdminContact:contact]) {
        text = @"Waved";
    } else if (contact.firstName) {
        text = [NSString stringWithFormat:@"%@", contact.firstName ? contact.firstName : @""];
    } else {
        text = [NSString stringWithFormat:@"%@", contact.lastName ? contact.lastName : @""];
    }
    [self addNameLabelToView:contactView withText:text];
}

- (void)addNameLabelToView:(ContactView *)contactView withText:(NSString *)text
{
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(contactView.frame.origin.x - self.contactMargin/4, contactView.frame.origin.y + kContactSize, contactView.frame.size.width + self.contactMargin/2, kContactNameHeight)];
    nameLabel.text = text;
    if ([contactView isGroupContactView]) {
        nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Regular" size:14.0];
    } else {
        nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0];
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
        
        [self.contactViews removeObject:contactView];
        if (contactView.unreadMessages) {
            [self resetApplicationBadgeNumber];
        }
        
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
        if (![contactView isGroupContactView] && contactView.contact == contact) {
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

- (void)updateCurrentUserFirstName:(NSString *)firstName lastName:(NSString *)lastName picture:(UIImage *)picture
{
    if (self.currentUserContactView) {
        if (picture) {
            self.currentUserContactView.imageView.image = picture;
        }
        
        if (firstName) {
            self.currentUserContactView.contact.firstName = firstName;
            self.currentUserContactView.nameLabel.text = firstName;
        }
        
        if (lastName) {
            self.currentUserContactView.contact.lastName = lastName;
        }
    }
}


// ----------------------------------
#pragma mark Groups
// ----------------------------------

- (NSMutableArray *)getGroupPermittedContacts {
    NSMutableArray *permittedContactsArray = [NSMutableArray new];
    for (Contact *contact in self.contacts) {
        if (![GeneralUtils isCurrentUser:contact] && !contact.isFutureContact && ![GeneralUtils isAdminContact:contact]) {
            [permittedContactsArray addObject:contact];
        }
    }
    // Sort contact
    [permittedContactsArray sortUsingComparator:^(Contact *contact1, Contact * contact2) {
        if ([contact1.firstName compare:contact2.firstName] == NSOrderedAscending) {
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedDescending;
        }
    }];
    return permittedContactsArray;
}

- (void)addNewGroup:(Group *)group
{
    [self.groups addObject:group];
    [GroupUtils saveGroupsInMemory:self.groups];
    [self createContactViewWithGroup:group andPosition:1];
}

- (GroupView *)getViewOfGroup:(Group *)group
{
    for (ContactView *contactView in self.contactViews) {
        if ([contactView isGroupContactView] && [contactView contactIdentifier] == group.identifier) {
            return (GroupView *)contactView;
        }
    }
    return nil;
}

- (BOOL)message:(Message *)message belongsToContactView:(ContactView *)contactView
{
    return [message getSenderOrGroupIdentifier] == [contactView contactIdentifier] && ([message isGroupMessage] == [contactView isGroupContactView]);
}

- (void)deleteGroupAndAssociatedView:(Group *)group
{
    GroupView * contactView = [self getViewOfGroup:group];
    if (contactView) {
        [self.contactViews removeObject:contactView];
        [contactView removeFromSuperview];
        [contactView.nameLabel removeFromSuperview];
    }
    [self.groups removeObject:group];
    [GroupUtils saveGroupsInMemory:self.groups];
    [self reorderContactViews];
}

- (void)updateGroupAndAssociatedView:(Group *)group
{
    for (Group *existingGroup in self.groups) {
        if (existingGroup.identifier == group.identifier) {
            existingGroup.memberIds = group.memberIds;
            existingGroup.memberFirstName = group.memberFirstName;
            existingGroup.memberLastName = group.memberLastName;
            break;
        }
    }
    [GroupUtils saveGroupsInMemory:self.groups];
    GroupView * contactView = [self getViewOfGroup:group];
    if (contactView) {
        [contactView setContactPicture];
    }
}

- (BOOL)user:(NSInteger)userId belongsToGroup:(Group *)group
{
    for (NSNumber *memberId in group.memberIds) {
        if ([memberId integerValue] == userId) {
            return YES;
        }
    }
    return NO;
}

- (void)inviteButtonClicked
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        [self displayContactAuthView];
    } else {
        [self performSegueWithIdentifier:@"Invite Modal Segue" sender:nil];
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
        // Attribute messages and reorder view
        BOOL areAttributed = YES;
        for (Message *message in messages) {
            areAttributed &= [self attributeMessageToExistingContacts:message];
        }
        [self resetApplicationBadgeNumber];
        [self reorderContactViews];
        
        // Check contact with unread state
        // Clean / robust / somewhere else
        for (ContactView *contactView in self.contactViews) {
            BOOL idFound = NO;
            for (NSString *id in unreadMessageContacts) {
                if (![contactView isGroupContactView] && [contactView contactIdentifier] == [id intValue]) {
                    idFound = YES;
                    break;
                }
            }
            if (idFound || (contactView.contact.isFutureContact && [contactView getLastMessageExchangedDate] > 0)) {
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
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *) = ^void(NSURLSessionDataTask *task){
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
        if ([self message:message belongsToContactView:contactView]) {
            [contactView addUnreadMessage:message];
            
            // Update last message date to sort contacts even if no push
            [contactView updateLastMessageDate:MAX([contactView getLastMessageExchangedDate],message.createdAt)];
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
            if ([self message:message belongsToContactView:contactView]) {
                [contactView addUnreadMessage:message];
                isAttributed = YES;
                // Update last message date to sort contacts even if no push
                [contactView updateLastMessageDate:MAX([contactView getLastMessageExchangedDate],message.createdAt)];
                break;
            }
        }
        
        if (!isAttributed) {
            if ([message isGroupMessage]) {
                // Create group if needed
                Group *group = [GroupUtils findGroupFromId:[message getSenderOrGroupIdentifier] inGroupsArray:self.groups];
                if (!group) {
                    group = [Group createGroupWithId:[message getSenderOrGroupIdentifier] groupName:nil memberIds:nil memberFirstNames:nil memberLastNames:nil];
                    group.lastMessageDate = message.createdAt;
                    [self.groups addObject:group];
                }
                // create view (if needed) and add message
                [self createContactViewWithGroup:group andPosition:[self.contactViews count]+1];
                [[self getViewOfGroup:group] addUnreadMessage:message];
            } else {
                // create contact if does not exists
                Contact *contact = [ContactUtils findContactFromId:[message getSenderOrGroupIdentifier] inContactsArray:self.contacts];
                if (!contact) {
                    contact = [Contact createContactWithId:[message getSenderOrGroupIdentifier] phoneNumber:nil firstName:nil lastName:nil];
                    contact.lastMessageDate = message.createdAt;
                    if (![GeneralUtils isAdminContact:contact])
                        contact.isPending = YES;
                    [self.contacts addObject:contact];
                }
                // create view and add message
                [self displayAdditionnalContact:contact];
                [[self getViewOfContact:contact] addUnreadMessage:message];
            }
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

- (void)contact:(NSUInteger)contactId isRecording:(BOOL)flag
{
    for (ContactView *contactView in self.contactViews) {
        if (contactId == contactView.contact.identifier) {
            [contactView setContactIsRecordingProperty:flag];
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
    // If not the same sender, start again
    if (self.lastMessagesPlayed.count>0 && [((Message *)[self.lastMessagesPlayed lastObject]) getSenderOrGroupIdentifier] != [message getSenderOrGroupIdentifier]) {
        self.lastMessagesPlayed = [NSMutableArray new];
    }
    [self.lastMessagesPlayed addObject:message];
}

- (IBAction)menuButtonClicked:(id)sender {
    if ([self getGroupPermittedContacts].count < 2) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"insufficient_contacts_for_group_message", kStringFile, "comment") withTitle:nil];
    } else {
        [self performSegueWithIdentifier:@"Manage Groups From Dashboard" sender:nil];
    }
}

- (IBAction)speakerButtonClicked:(id)sender {
    if (self.LoudSpeakerMode) {
        [self tutoMessage:NSLocalizedStringFromTable(@"speaker_button_on_message", kStringFile, "comment") withDuration:1 priority:NO];
        self.LoudSpeakerMode = NO;
    } else {
        [self tutoMessage:NSLocalizedStringFromTable(@"speaker_button_off_message", kStringFile, "comment") withDuration:1 priority:NO];
        self.LoudSpeakerMode = YES;
    }
    //TODO BB speaker toggle + toast
}

- (void)setLoudSpeakerMode:(BOOL)loudSpeakerMode
{
    _LoudSpeakerMode = loudSpeakerMode;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (loudSpeakerMode) {
        [self.speakerButton setImage:[UIImage imageNamed:@"speaker-on"] forState:UIControlStateNormal];
        [prefs setObject:@"On" forKey:kSpeakerPref];
        //show Toast
    } else {
        [self.speakerButton setImage:[UIImage imageNamed:@"speaker-off"] forState:UIControlStateNormal];
        [prefs setObject:@"Off" forKey:kSpeakerPref];
        //show Toast
    }
    [self proximityStateDidChangeCallback];
}



// ----------------------------------------------------------
#pragma mark Recording Mode
// ----------------------------------------------------------

- (void)disableAllContactViews
{
    [self hideStatusBarComponents:YES];
    self.contactScrollView.clipsToBounds = NO;
    
    for (ContactView *view in self.contactViews) {
        view.userInteractionEnabled = NO;
    }
}

- (void)enableAllContactViews
{
    //Show menu and title
    [self hideStatusBarComponents:NO];
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
    [ApiUtils sendMessage:audioData toContactView:contactView success:^{
        [contactView message:nil sentWithError:NO]; // no need to pass the message here
    } failure:^{
        [contactView message:audioData sentWithError:YES];
    }];
    [self.recorder prepareToRecord];
}


- (NSData *)getLastRecordedData
{
    if (self.emojiData) {
        NSData *lastRecordedData = self.emojiData;
        self.emojiData = nil;
        return lastRecordedData;
    } else {
        return [[NSData alloc] initWithContentsOfURL:self.recorder.url];
    }
}

// ----------------------------------------------------------
#pragma mark ContactViewDelegate Protocole
// ----------------------------------------------------------

- (void)updateFrameOfContactView:(ContactView *)view
{
    NSInteger row = view.orderPosition / self.contactsPerRow + 1;
    NSInteger horizontalPosition = 1 + view.orderPosition - (view.orderPosition/self.contactsPerRow) * self.contactsPerRow;
    if (horizontalPosition > self.contactsPerRow) {
        horizontalPosition = 1;
    }
    float rowHeight = kContactMinimumMargin + kContactSize + kContactNameHeight;
    view.frame = CGRectMake(self.contactMargin + (horizontalPosition - 1) * (kContactSize + self.contactMargin), kContactMinimumMargin + (row - 1)* rowHeight, kContactSize, kContactSize);
    
    // Update frame of Name Label tool
    view.nameLabel.frame = CGRectMake(view.frame.origin.x - self.contactMargin/4, view.frame.origin.y + kContactSize, view.frame.size.width + self.contactMargin/2, kContactNameHeight);
}

//Create recording mode screen
- (void)startedLongPressOnContactView:(ContactView *)contactView
{
    [self hideOpeningTuto];
    
    //Show recorder label
    self.recorderLabel.hidden = NO;
    
    if ([self.mainPlayer isPlaying]) {
        [self endPlayerAtCompletion:NO];
    }
    
    [self playSound:kStartRecordSound ofType:@""];
    [self disableAllContactViews];
    
    // Case where we had a pending message
    if (!self.recorderContainer.isHidden) {
        [self setRecorderLineWidth:0];
    }

    self.recorderContainer.hidden = NO;
    
    float finalWidth = self.recorderContainer.bounds.size.width;
    
    [UIView animateWithDuration:kMaxAudioDuration
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
    //Hide recorder label
    self.recorderLabel.hidden = YES;
    
    // Remove UI
    self.recorderLine.frame = [[self.recorderLine.layer presentationLayer] frame];
    [self.recorderLine.layer removeAllAnimations];
    self.recorderContainer.hidden = YES;
    [self setRecorderLineWidth:0];
    
    [self enableAllContactViews];
    
    // Stop recording
    [self.recorder stop];
    [self playSound:kEndRecordSound ofType:@""];
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
    [self.mainPlayer prepareToPlay];
    [self addMessagesToLastMessagesPlayed:message];
    
    //Show message date
    self.playerLabel.hidden = NO;
    self.playerLabel.text = [GeneralUtils dateToAgeString:message.createdAt];
    
    // Player UI
    NSTimeInterval duration = self.mainPlayer.duration;
    [self playerUI:duration ByContactView:contactView];
    
    // play
    [self.mainPlayer play];
}

- (BOOL)isRecording {
    return self.recorder.isRecording;
}


- (void)pendingContactClicked:(ContactView *)contactView
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        [self displayContactAuthView];
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:NSLocalizedStringFromTable(@"contact_access_error_message",kStringFile, @"comment")
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else {
        self.clickedPendingView = contactView;
        UIActionSheet *pendingActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                        delegate:self
                                                               cancelButtonTitle:ACTION_SHEET_CANCEL
                                                          destructiveButtonTitle:nil
                                                               otherButtonTitles:ACTION_PENDING_OPTION_1, ACTION_PENDING_OPTION_2, nil];
        [pendingActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)failedMessagesModeTapGestureOnContact:(ContactView *)contactView
{
    self.lastSelectedContactView = contactView;
    NSString *partial_message = contactView.failedMessages.count > 1 ? NSLocalizedStringFromTable(@"multiple_messages_send_failure_error_message",kStringFile, @"comment") : NSLocalizedStringFromTable(@"one_message_send_failure_error_message",kStringFile, @"comment");
    NSString *title = [NSString stringWithFormat:@"%lu %@",(unsigned long)contactView.failedMessages.count,partial_message];
    UIActionSheet *failedActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                    delegate:self
                                                           cancelButtonTitle:ACTION_SHEET_CANCEL
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:ACTION_FAILED_MESSAGES_OPTION_1, ACTION_FAILED_MESSAGES_OPTION_2, nil];
    [failedActionSheet showInView:[UIApplication sharedApplication].keyWindow];
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
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    if (volumeViewSlider.value < 0.5f) {
        [volumeViewSlider setValue:0.5f animated:YES];
    }
    
    // Set proximity check
    self.disableProximityObserver = NO;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    //Hide menu and title
    [self hideStatusBarComponents:YES];
    self.contactScrollView.clipsToBounds = NO;
    
    self.playerContainer.hidden = NO;
    self.playerContainer.alpha = 1;
    [self setPlayerLineWidth:0];
    self.earDetected = NO;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self setPlayerLineWidth:self.playerContainer.bounds.size.width];
                     } completion:^(BOOL finished){
                         // MixPanel
                         NSString *speakerMode = self.isUsingHeadSet ? @"HeadSet" : (!self.LoudSpeakerMode ? @"Ear Speaker" : self.earDetected ? @"Ear Detected" : @"Loud Speaker");
                         [TrackingUtils trackPlayWithDuration:duration andSpeakerMode:speakerMode];
                         // End player
                         if (finished) {
                             [self endPlayerAtCompletion:YES];
                         }
                     }];
}


- (void)endPlayerAtCompletion:(BOOL)completed
{
    if (self.displayOpeningTuto) {
        [self hideOpeningTuto];
        self.displayOpeningTuto = NO;
        [GeneralUtils registerForRemoteNotif];
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
    [self hideStatusBarComponents:NO];
    self.contactScrollView.clipsToBounds = YES;
    self.playerLabel.hidden = YES;
    
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
     PENDING MENU
     ---------------------------------------------------------------------------*/
    
    // Add contact
    else if ([buttonTitle isEqualToString:ACTION_PENDING_OPTION_1]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [AddressbookUtils createContactWithFormattedNumber:self.clickedPendingView.contact.phoneNumber firstName:self.clickedPendingView.contact.firstName lastName:self.clickedPendingView.contact.lastName];
        
        [self didFinishedAddingContact];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [TrackingUtils trackAddPendingContact];
    }
    
    // Block user
    else if ([buttonTitle isEqualToString:ACTION_PENDING_OPTION_2]) {
        for (ContactView * bubbleView in self.contactViews) {
            if (bubbleView.contact.identifier == self.clickedPendingView.contact.identifier) {
                [self blockContact:bubbleView];
                break;
            }
        }
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
    if ([alertView.message isEqualToString:NSLocalizedStringFromTable(@"contact_access_error_message",kStringFile, @"comment")] || [alertView.message isEqualToString:NSLocalizedStringFromTable(@"notification_error_message",kStringFile, @"comment")]) {
        [GeneralUtils openSettings];
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
    if (self.isUsingHeadSet || [UIDevice currentDevice].proximityState || !self.LoudSpeakerMode) {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        if ([UIDevice currentDevice].proximityState) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:@"dummy" forKey:kUserPhoneToEarPref];
            self.earDetected = YES;
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


// ----------------------------------------------------------
#pragma mark Motion event (shake)
// ----------------------------------------------------------

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
    {
        if ([self isRecording]) {
            // do nothing
        } else if (self.lastMessagesPlayed && self.lastMessagesPlayed.count > 0){
            if ([self.mainPlayer isPlaying]) {
                [self.mainPlayer stop];
                self.mainPlayer.currentTime = 0;
                [self.playerLine.layer removeAllAnimations];
                [self endPlayerUIForAllContactViews];
            }
            // Add last messages played to contact view
            for (ContactView *contactView in self.contactViews) {
                if ([self message:(Message *)self.lastMessagesPlayed[0] belongsToContactView:contactView]) {
                    [contactView addPlayedMessages:self.lastMessagesPlayed];
                    [self resetLastMessagesPlayed];
                    [self resetApplicationBadgeNumber];
                    [contactView playNextMessage];
                    [TrackingUtils trackReplay];
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

- (void)playSound:(NSString *)sound ofType:(NSString *)type
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
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:sound ofType:type];
        NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    }
    if (error || ![self.soundPlayer prepareToPlay]) {
        NSLog(@"%@",error);
    } else {
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
    
    [self.view bringSubviewToFront:self.authRequestView];
    self.authRequestView.hidden = NO;
}

- (IBAction)authRequestAllowButtonClicked:(id)sender
{
    if ([self.authRequestAllowButton.titleLabel.text isEqualToString:NSLocalizedStringFromTable(@"contact_access_button_title", kStringFile, @"comment")]) {
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            [self performSelectorOnMainThread:@selector(contactAuthRequested:) withObject:[NSNumber numberWithBool:granted] waitUntilDone:YES];
        });
    }
}

- (IBAction)authRequestSkipButtonClicked:(id)sender {
    [self hideAuthRequestView];
}

- (void)hideAuthRequestView
{
    self.authRequestView.hidden = YES;
}

- (void)contactAuthRequested:(NSNumber *)granted
{
    [self hideAuthRequestView];
    
    if ([granted boolValue]) {
        [self matchPhoneContactsWithHeardUsers];
    }
}

// -------------------------------------------
#pragma mark Opening Tuto
// -------------------------------------------
- (void)prepareAndDisplayTuto
{
    [self displayOpeningTutoWithActionLabel:NSLocalizedStringFromTable(@"hold_tuto_action_label", kStringFile, @"comment") forOrigin:self.currentUserContactView.frame.origin.x + self.currentUserContactView.frame.size.width/2];
    
    [self.contactScrollView bringSubviewToFront:self.openingTutoView];
    [self.contactScrollView bringSubviewToFront:self.currentUserContactView];
    [self.contactScrollView bringSubviewToFront:self.currentUserContactView.nameLabel];
}

- (void)openingTutoSkipButtonClicked
{
    [self hideOpeningTuto];
    self.displayOpeningTuto = NO;
    [GeneralUtils registerForRemoteNotif];
}

- (void)initOpeningTutoView
{
    float boxWidth = 260;
    float boxHeight = 50;
    float boxY = 210;
    float separatorWidth = 1;
    
    self.openingTutoView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.screenWidth, self.screenHeight - 70)];
    self.openingTutoView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    self.openingTutoDescView = [[UIView alloc] initWithFrame:CGRectMake(self.openingTutoView.frame.size.width/2 - boxWidth/2,
                                                                        boxY,
                                                                        boxWidth, boxHeight)];
    self.openingTutoDescView.backgroundColor = [UIColor whiteColor];
    self.openingTutoDescView.clipsToBounds = YES;
    self.openingTutoDescView.layer.cornerRadius = 5;
    
    [self.openingTutoView addSubview:self.openingTutoDescView];
    
    self.openingTutoDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,boxWidth - boxHeight - separatorWidth, boxHeight)];
    self.openingTutoDescLabel.textAlignment = NSTextAlignmentCenter;
    self.openingTutoDescLabel.textColor = [ImageUtils blue];
    self.openingTutoDescLabel.font = [self.openingTutoDescLabel.font fontWithSize:18.0];
    
    [self.openingTutoDescView addSubview:self.openingTutoDescLabel];
    
    self.openingTutoSkipButton = [[UIButton alloc] initWithFrame:CGRectMake(boxWidth - boxHeight, 0, boxHeight, boxHeight)];
    [self.openingTutoSkipButton setTitle:@"Skip" forState:UIControlStateNormal];
    self.openingTutoSkipButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0];
    [self.openingTutoSkipButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.openingTutoSkipButton addTarget:self
                 action:@selector(openingTutoSkipButtonClicked)
       forControlEvents:UIControlEventTouchUpInside];
    
    [self.openingTutoDescView addSubview:self.openingTutoSkipButton];
    
    UIView *separatingBar = [[UIView alloc] initWithFrame:CGRectMake(boxWidth - boxHeight - separatorWidth, 0, separatorWidth, boxHeight)];
    separatingBar.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.openingTutoDescView addSubview:separatingBar];
    
    self.openingTutoView.hidden = YES;
    
    [self.contactScrollView addSubview:self.openingTutoView];
    self.contactScrollView.scrollEnabled = NO;
    
    self.openingTutoBarView = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.screenWidth, 70)];
    self.openingTutoBarView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    
    self.openingTutoBarView.hidden = YES;
    
    [self.view addSubview:self.openingTutoBarView];
}

- (void)displayOpeningTutoWithActionLabel:(NSString *)actionLabel forOrigin:(float)x
{
    [self hideStatusBarComponents:YES];
    self.titleLabel.hidden = NO;
    self.topBarBackground.hidden = NO;
    
    if (self.openingTutoArrow) {
        [self.openingTutoArrow removeFromSuperview];
    }
    
    self.openingTutoArrow = [[UIImageView alloc] initWithFrame:CGRectMake(x - 100/2,110,100,100)];
    self.openingTutoArrow.image = [UIImage imageNamed:@"tuto-arrow"];
    [self.openingTutoView addSubview:self.openingTutoArrow];
    
    [self.openingTutoDescLabel setText:actionLabel];
    [self.openingTutoSkipButton setTitle:NSLocalizedStringFromTable(@"skip_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    
    self.openingTutoView.hidden = NO;
    self.openingTutoBarView.hidden = NO;
}

- (void)hideOpeningTuto
{
    [self hideStatusBarComponents:NO];
    self.openingTutoView.hidden = YES;
    self.openingTutoBarView.hidden = YES;
    self.contactScrollView.scrollEnabled = YES;
}

- (void)resetApplicationBadgeNumber {
    NSInteger sum = 0;
    for (ContactView *contactView in self.contactViews) {
        if (contactView.unreadMessages) {
            sum += [contactView.unreadMessages count];
        }
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:sum];
}


// ----------------------------------------------------------
#pragma mark Emoji init and delegate
// ----------------------------------------------------------

- (IBAction)emojiButtonClicked:(id)sender {
    // todo bt
    // display emoji scroll view
    if (!self.emojiScrollView) {
        [self initEmojiScrollView];
    }
    if (self.emojiScrollView.hidden) {
        self.emojiScrollView.frame = CGRectMake(self.emojiScrollView.frame.origin.x, self.view.frame.size.height, self.emojiScrollView.frame.size.width, self.emojiScrollView.frame.size.height);
        self.emojiScrollView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.emojiScrollView.frame = self.contactScrollView.frame;
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.emojiScrollView.frame = CGRectMake(self.emojiScrollView.frame.origin.x, self.view.frame.size.height, self.emojiScrollView.frame.size.width, self.emojiScrollView.frame.size.height);
        } completion:^(BOOL finished) {
            self.emojiScrollView.hidden = YES;
        }];
    }
}

- (void)hideEmojiScrollViewAndDisplayEmoji:(EmojiView *)emojiView
{
    [self.view addSubview:emojiView];
    self.emojiScrollView.hidden = YES;
}

- (void)initEmojiScrollView
{
    self.emojiScrollView = [[UIScrollView alloc] initWithFrame:self.contactScrollView.frame];
    self.emojiScrollView.contentSize = self.emojiScrollView.frame.size;
    self.emojiScrollView.hidden = YES;
    self.emojiScrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [self.view addSubview:self.emojiScrollView];
//    self.emojiScrollView.contentSize = CGSizeMake(self.screenWidth, MAX(self.screenHeight - self.contactScrollView.frame.origin.y, rows * rowHeight + self.contactsPerRow * kContactMinimumMargin))
    for(int i=1;i<=kNbEmojis;i++) {
        EmojiView *emojiView = [[EmojiView alloc] initWithIdentifier:i];
        emojiView.delegate = self;
        [self.emojiScrollView addSubview:emojiView];
    }

}

- (void)updateEmojiLocation:(CGPoint)location
{
    // clean
    [self removeEmojiOverlayOnContactViews];
    
    // Animation on contact view
    ContactView *contactView = [self findContactViewAtLocation:location];
    if (contactView) {
        [contactView addEmojiOverlay];
    }
}

- (void)emojiDropped:(EmojiView *)emojiView atLocation:(CGPoint)location
{
    ContactView *contactView = [self findContactViewAtLocation:location];
    if (contactView) {
        [contactView removeEmojiOverlay];
        NSString *soundName = [NSString stringWithFormat:@"%@%lu.%d",@"emoji-sound-",(long)emojiView.identifier,1];
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"];
        NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
        self.emojiData = [NSData dataWithContentsOfURL:soundURL];
        CGPoint destinationPoint = [emojiView.superview convertPoint:contactView.center fromView:self.contactScrollView];
        [UIView transitionWithView:emojiView
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionNone
                        animations:^{[emojiView setFrame:CGRectMake(destinationPoint.x,destinationPoint.y,0,0)];}
                        completion:^(BOOL completed) {
                            [contactView sendRecording];
                            [self.emojiScrollView addSubview:emojiView];
                            [emojiView setFrame:[emojiView getInitialFrame]];
                        }];
    } else {
        CGFloat finalSize = 10;
        [UIView transitionWithView:emojiView
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionNone
                        animations:^{[emojiView setFrame:CGRectMake(self.emojiButton.center.x - finalSize/2,self.emojiButton.center.y - finalSize/2,finalSize,finalSize)];}
                        completion:^(BOOL completed) {
                            [self.emojiScrollView addSubview:emojiView];
                            emojiView.frame = [emojiView getInitialFrame];
                        }];
    }
}

- (void)removeEmojiOverlayOnContactViews
{
    for (ContactView *contactView in self.contactViews) {
        [contactView removeEmojiOverlay];
    }
}

- (ContactView *)findContactViewAtLocation:(CGPoint)location
{
    for (ContactView *contactView in self.contactViews) {
        if (CGRectContainsPoint([self.view convertRect:contactView.frame fromView:self.contactScrollView],location)) {
            return contactView;
        }
    }
    return nil;
}

- (void)hideStatusBarComponents:(BOOL)flag {
    self.titleLabel.hidden = flag;
    self.topBarBackground.hidden = flag;
    self.menuButton.hidden = flag;
    self.emojiButton.hidden = flag;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
