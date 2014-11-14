//
//  HeardAppDelegate.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "HeardAppDelegate.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "SessionUtils.h"
#import "WelcomeViewController.h"
#import "ApiUtils.h"
#import "Message.h"
#import "DashboardViewController.h"
#import "GeneralUtils.h"
#import "Mixpanel.h"
#import "Constants.h"
#import "TrackingUtils.h"
#import "ContactUtils.h"
#import "Flurry.h"
#import <FacebookSDK/FacebookSDK.h>
#import "GroupUtils.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface HeardAppDelegate()

@property (nonatomic, strong) UIAlertView *apiMessageAlertView;
@property (nonatomic, strong) NSURL *redirectURL;
@property (nonatomic, strong) NSString *messageContent;
@property (nonatomic, strong) NSString *messageType;

@end

@implementation HeardAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Manage the network activity indicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    //Mixpanel
    if (PRODUCTION && !DEBUG) {
        [Mixpanel sharedInstanceWithToken:kProdMixPanelToken];
        
        //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
        [Flurry setCrashReportingEnabled:YES];
        
        // Replace YOUR_API_KEY with the api key in the downloaded package
        [Flurry startSession:kProdFlurryToken];
        
        //Crash report with Fabric
        [Fabric with:@[CrashlyticsKit]];
    }
    
    // Contacts & groups
    self.contacts = [ContactUtils retrieveContactsInMemory];
    self.groups = [GroupUtils retrieveGroupsInMemory];
    
    // ios8 silent Notif
    [GeneralUtils registerForSilentRemoteNotif];

    // Check API related message
    [ApiUtils checkAppVersionAndExecuteSucess:^(NSDictionary *result){
        self.messageType = [result valueForKeyPath:@"message_type"];
        if (self.messageType) {
            self.messageContent = [result valueForKeyPath:@"message_content"];
            NSString *messageURL = [result valueForKeyPath:@"redirect_url"];
            if (messageURL && [messageURL length] > 0) {
                self.redirectURL = [NSURL URLWithString:messageURL];
            }
            if ([self.messageType isEqualToString:@"Beta request"]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                           message:self.messageContent
                                          delegate:self
                                 cancelButtonTitle:@"NO"
                                 otherButtonTitles:@"YES",nil];
                [alert show];
            } else {
                [self createObsoleteAPIAlertView];
            }
        }
    }];
    
    // Track 1st open app
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if(![[prefs objectForKey:kFirstOpeningPref] boolValue]) {
        [TrackingUtils trackFirstOpenApp];
    }
    
    if ([SessionUtils isSignedIn]) {
        WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
        [welcomeViewController performSegueWithIdentifier:@"Dashboard Push Segue From Welcome" sender:nil];
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [TrackingUtils trackOpenApp];
    
    // Handle the user leaving the app while the Facebook login dialog is being shown
    // For example: when the user presses the iOS "home" button while the login dialog is active
    [FBAppCall handleDidBecomeActive];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    UIViewController *visibleController = [self getVisibleController];
    
    if ([visibleController isKindOfClass:[DashboardViewController class]]) {
        // Retrieve new messages
        [(DashboardViewController *)visibleController retrieveUnreadMessagesAndNewContacts];
    }
}

// Save contacts before termination
- (void)applicationWillTerminate:(UIApplication *)application
{
    [ContactUtils saveContactsInMemory:self.contacts];
    [GroupUtils saveGroupsInMemory:self.groups];
}

// Save contacts before termination
// Not sure which method is called
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [ContactUtils saveContactsInMemory:self.contacts];
    [GroupUtils saveGroupsInMemory:self.groups];
    
    UIViewController *visibleController = [self getVisibleController];
    
    // Reorder dashboard
    if ([visibleController isKindOfClass:[DashboardViewController class]]) {
        // Clean UI
        [(DashboardViewController *)visibleController endPlayerAtCompletion:NO];
        [(DashboardViewController *)visibleController removeViewOfHiddenContacts];
        [(DashboardViewController *)visibleController reorderContactViews];
    }
}


// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    // Convert the binary data token into an NSString
    NSString *deviceTokenAsString = stringFromDeviceTokenData(devToken);
    
    // Send push token
    [ApiUtils updatePushToken:deviceTokenAsString success:nil failure:nil];
    
    // Update stats
    if ([SessionUtils isSignedIn]) {
        [ApiUtils updateAppInfoAndExecuteSuccess:nil failure:nil];
    }
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    // Update stats
    if ([SessionUtils isSignedIn]) {
        [ApiUtils updateAppInfoAndExecuteSuccess:nil failure:nil];
    }
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    UIApplicationState state = [application applicationState];
    
    //Unread message push
    if ([userInfo valueForKey:@"message"]) {
        if (state == UIApplicationStateActive) {
            // Add unread message
            UIViewController *visibleController = [self getVisibleController];
            if ([visibleController isKindOfClass:[DashboardViewController class]]) {
                [(DashboardViewController *)visibleController retrieveUnreadMessagesAndNewContacts];
                [(DashboardViewController *)visibleController playSound:kReceivedSound ofType:@"aif"];
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
        }
    //Read message push
    } else if ([userInfo valueForKey:@"receiver_id"] && [userInfo valueForKey:@"message_id"]) {
        if (state == UIApplicationStateActive) {
            UIViewController *visibleController = [self getVisibleController];
            if ([visibleController isKindOfClass:[DashboardViewController class]]) {
                NSUInteger contactId = [[userInfo valueForKey:@"receiver_id"] unsignedIntegerValue];
                NSUInteger messageId = [[userInfo valueForKey:@"message_id"] unsignedIntegerValue];
                
                [(DashboardViewController *)visibleController message:messageId listenedByContact:contactId];
            }
        }
    //Is Recording push
    } else if ([userInfo valueForKey:@"recorder_id"] && [userInfo valueForKey:@"is_recording"]) {
        if (state == UIApplicationStateActive) {
            UIViewController *visibleController = [self getVisibleController];
            if ([visibleController isKindOfClass:[DashboardViewController class]]) {
                NSUInteger contactId = [[userInfo valueForKey:@"recorder_id"] unsignedIntegerValue];
                BOOL isRecording = [[userInfo valueForKey:@"is_recording"] boolValue];
                
                [(DashboardViewController *)visibleController contact:contactId isRecording:isRecording];
            }
        }
    }
}

NSString* stringFromDeviceTokenData(NSData *deviceToken)
{
    const char *data = [deviceToken bytes];
    NSMutableString* token = [NSMutableString string];
    for (int i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    return token;
}

// get visible view controller
- (UIViewController *)getVisibleController
{
    UINavigationController *navigationController = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([navigationController respondsToSelector:@selector(visibleViewController)]) {
        return navigationController.visibleViewController;
    } else {
        return nil;
    }
}

// API related alert
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.apiMessageAlertView) {
        if (self.redirectURL) {
            [[UIApplication sharedApplication] openURL:self.redirectURL];
        }
        if ([self.messageType isEqualToString:@"Blocking alert"]) {
            [self createObsoleteAPIAlertView];
        }
    } else {
        if (buttonIndex == 1) {
            if (self.redirectURL) {
                [[UIApplication sharedApplication] openURL:self.redirectURL];
            }
        }
    }
}

- (void)createObsoleteAPIAlertView
{
    self.apiMessageAlertView = [[UIAlertView alloc] initWithTitle:@""
                                                          message:self.messageContent
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
    [self.apiMessageAlertView show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Dashboard Push Segue From Welcome"]) {
        ((DashboardViewController *) [segue destinationViewController]).isSignUp = NO;
    }
}

// During the Facebook login flow, your app passes control to the Facebook iOS app or Facebook in a mobile browser.
// After authentication, your app will be called back with the session information.
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}


@end
