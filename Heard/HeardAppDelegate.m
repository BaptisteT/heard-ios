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

@implementation HeardAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Manage the network activity indicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    //Mixpanel
    [Mixpanel sharedInstanceWithToken:kProdMixPanelToken];
    
    // Notification received when app closed
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(remoteNotif) {
        // todo BT (later)
    }
    
    if ([SessionUtils isSignedIn]) {
        WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
        [welcomeViewController performSegueWithIdentifier:@"Dashboard Push Segue From Welcome" sender:nil];
        
        // register for remote
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
    
    return YES;
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    UIViewController *visibleController = [self getVisibleController];
    
    if ([visibleController isKindOfClass:[DashboardViewController class]]) {
        [(DashboardViewController *)visibleController requestAddressBookAccess];
//        [(DashboardViewController *)visibleController retrieveAndDisplayUnreadMessages];
    }
}



// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    // Convert the binary data token into an NSString
    NSString *deviceTokenAsString = stringFromDeviceTokenData(devToken);
    
    // Show the device token obtained from apple to the log
    NSLog(@"deviceToken: %@", deviceTokenAsString);
    
    // Send push token
    [ApiUtils updatePushToken:deviceTokenAsString success:nil failure:nil];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    // todo BT (later)
    // Handle this case to ask the user to change his mind
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // The user receives a notif while using the app
    Message *newMessage = [Message rawMessageToInstance:[userInfo valueForKey:@"message"]];
    NSNumber *badgeNumber = [[userInfo valueForKey:@"aps"] valueForKey:@"badge"];
    
    // Update badge
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badgeNumber integerValue]];
    
    // Add unread message
    UIViewController *visibleController = [self getVisibleController];
    if ([visibleController isKindOfClass:[DashboardViewController class]]) {
        [(DashboardViewController *)visibleController addUnreadMessage:newMessage];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
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
    return navigationController.visibleViewController;
}

@end
