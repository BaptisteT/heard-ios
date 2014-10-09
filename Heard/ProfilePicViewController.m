//
//  ProfilePicViewController.m
//  Heard
//
//  Created by Bastien Beurier on 10/8/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ProfilePicViewController.h"
#import "Constants.h"
#import "CameraUtils.h"
#import "ImageUtils.h"
#import "GeneralUtils.h"
#import <FacebookSDK/FacebookSDK.h>
#import "HeardAppDelegate.h"
#import "MBProgressHUD.h"
#import "ApiUtils.h"
#import "SessionUtils.h"
#import "TrackingUtils.h"
#import "RequestUserInfoViewController.h"

#define ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable(@"camera_button_title",kStringFile,@"comment")
#define ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable(@"library_button_title",kStringFile,@"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")

@interface ProfilePicViewController ()
@property (weak, nonatomic) IBOutlet UIView *profilePictureContainer;
@property (weak, nonatomic) IBOutlet UIView *facebookButton;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *profilePictureFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *profilePictureSecondLabel;

@property (strong, nonatomic) UIActionSheet *pictureActionSheet;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation ProfilePicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.profilePictureContainer.clipsToBounds = YES;
    self.profilePictureContainer.layer.cornerRadius = self.profilePictureContainer.bounds.size.height/2;
    
    self.profilePictureContainer.layer.borderWidth = 2;
    self.profilePictureContainer.layer.borderColor = [ImageUtils blue].CGColor;
    
    self.facebookButton.clipsToBounds = YES;
    self.facebookButton.layer.cornerRadius = 2;
}
- (IBAction)profilePictureClicked:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.pictureActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:ACTION_SHEET_OPTION_1, ACTION_SHEET_OPTION_2, nil];
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.pictureActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:ACTION_SHEET_OPTION_2, nil];
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.pictureActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:ACTION_SHEET_OPTION_1, nil];
    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"camera_and_library_access_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    }
    
    [self.pictureActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (IBAction)facebookButtonClicked:(id)sender {
    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
        
        // If the session state is not any of the two "open" states when the button is clicked
    }
    
    // Display loading
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         // Call sessionStateChanged:state:error method to handle session state changes
         [self sessionStateChanged:session state:state error:error];
     }];

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_1]) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
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
    
    CGSize rescaleSize = {kProfilePictureSize, kProfilePictureSize};
    
    if (image) {
        self.profilePictureImageView.image = [ImageUtils imageWithImage:[ImageUtils cropBiggestCenteredSquareImageFromImage:image withSide:image.size.width] scaledToSize:rescaleSize];
        
        [self performSegueWithIdentifier:@"Name Push Segue" sender:nil];
    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"picture_error",kStringFile,@"comment") withTitle:@""];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ((UINavigationController *)self.imagePickerController != navigationController || self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {
        return;
    }
    if ([navigationController.viewControllers indexOfObject:viewController] == 2)
    {
        [CameraUtils addCircleOverlayToEditView:viewController];
    }
}

// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        // Show the user the logged-in UI
        // Request information about the user
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                
                //Get info
                [self signupUserWithFistName:[result objectForKey:@"first_name"] lastName:[result objectForKey:@"last_name"] fbId:[result objectForKey:@"id"] gender:[result objectForKey:@"gender"] locale:[result objectForKey:@"locale"]];
            } else {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"facebook_error",kStringFile,@"comment") withTitle:@""];
            }
            
            [FBSession.activeSession closeAndClearTokenInformation];
        }];
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}

- (void)signupUserWithFistName:(NSString *)firstName
                      lastName:(NSString *)lastName
                          fbId:(NSString *)fbId
                        gender:(NSString *)gender
                        locale:(NSString *)locale
{
    typedef void (^SuccessBlock)(NSString *authToken, Contact *contact);
    SuccessBlock successBlock = ^(NSString *authToken, Contact *contact) {
        [SessionUtils securelySaveCurrentUserToken:authToken];
        [SessionUtils saveUserInfo:contact];
        
        [TrackingUtils identifyWithMixpanel:contact signup:YES];
        
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self performSegueWithIdentifier:@"Dashboard Push Segue From Profile Picture" sender:nil];
    };
    
    typedef void (^FailureBlock)();
    FailureBlock failureBlock = ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"sign_up_error_message",kStringFile,@"comment") withTitle:nil];
    };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [ApiUtils createUserWithFBInfoPhoneNumber:self.phoneNumber
                                         fbId:fbId
                                    firstName:firstName
                                     lastName:lastName
                                       gender:gender
                                       locale:locale
                                         code:self.smsCode
                                      success:successBlock
                                      failure:failureBlock];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Name Push Segue"]) {
        ((RequestUserInfoViewController *) [segue destinationViewController]).phoneNumber = self.phoneNumber;
        ((RequestUserInfoViewController *) [segue destinationViewController]).smsCode = self.smsCode;
        ((RequestUserInfoViewController *) [segue destinationViewController]).profilePicture = self.profilePictureImageView.image;
    }
}


@end
