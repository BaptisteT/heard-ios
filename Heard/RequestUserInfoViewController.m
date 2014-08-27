//
//  RequestUserInfoViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "RequestUserInfoViewController.h"
#import "GeneralUtils.h"
#import "ImageUtils.h"
#import "MBProgressHUD.h"
#import "SessionUtils.h"
#import "ApiUtils.h"
#import "TrackingUtils.h"
#import "DashboardViewController.h"
#import "Constants.h"

#define BORDER_SIZE 0.5
#define ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable(@"camera_button_title",kStringFile,@"comment")
#define ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable(@"library_button_title",kStringFile,@"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")


@interface RequestUserInfoViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *profilePictureContainer;
@property (weak, nonatomic) IBOutlet UIView *firstNameTextFieldContainer;
@property (weak, nonatomic) IBOutlet UIView *lastNameTextFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (strong, nonatomic) UIActionSheet *pictureActionSheet;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureImageView;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation RequestUserInfoViewController


// ----------------------
// Life Cycle
// ----------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Weird bug on 3.5 screen screen
    if ([[UIScreen mainScreen] bounds].size.height>480.0f) {
        [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
    }
    
    [GeneralUtils addBottomBorder:self.firstNameTextFieldContainer borderSize:BORDER_SIZE];
    [GeneralUtils addBottomBorder:self.lastNameTextFieldContainer borderSize:BORDER_SIZE];
    
    self.profilePictureContainer.layer.cornerRadius = self.profilePictureContainer.bounds.size.height/2;
    self.profilePictureContainer.layer.borderWidth = 0.5;
    self.profilePictureContainer.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    self.firstNameTextField.delegate = self;
    self.lastNameTextField.delegate = self;
    
    [self.firstNameTextField becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Dashboard Push Segue"]) {
        ((DashboardViewController *) [segue destinationViewController]).isSignUp = YES;
    }
}

// ----------------------
// Button Pressed
// ----------------------

- (IBAction)backButtonPressed:(id)sender {
    
    [[[UIAlertView alloc] initWithTitle:nil
                message:NSLocalizedStringFromTable(@"back_to_phone_verification_confirmation_message",kStringFile,@"comment")
                               delegate:self
                      cancelButtonTitle:NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")
                      otherButtonTitles:NSLocalizedStringFromTable(@"confirm_button_title",kStringFile,@"comment"), nil] show];
}

- (IBAction)nextButtonPressed:(id)sender {
    
    if (![GeneralUtils validName:self.firstNameTextField.text]) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"first_name_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    } else if (![GeneralUtils validName:self.lastNameTextField.text]) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"last_name_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    } else if (!self.profilePictureImageView.image) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"profile_picture_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    }
    
    [self signupUser];
}

- (IBAction)profilePicturePressed:(id)sender {
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


- (void)signupUser
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    typedef void (^SuccessBlock)(NSString *authToken, Contact *contact);
    SuccessBlock successBlock = ^(NSString *authToken, Contact *contact) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [SessionUtils securelySaveCurrentUserToken:authToken];
        [SessionUtils saveUserInfo:contact];
        
        [TrackingUtils identifyWithMixpanel:contact signup:YES];
        
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
        [self performSegueWithIdentifier:@"Dashboard Push Segue" sender:nil];
    };
    
    typedef void (^FailureBlock)();
    FailureBlock failureBlock = ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"sign_up_error_message",kStringFile,@"comment") withTitle:nil];
    };
    
    [ApiUtils createUserWithPhoneNumber:self.phoneNumber
                              firstName:self.firstNameTextField.text
                               lastName:self.lastNameTextField.text
                                picture:[ImageUtils encodeToBase64String:self.profilePictureImageView.image]
                                   code:self.smsCode
                                success:successBlock failure:failureBlock];
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


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.firstNameTextField) {
        [self.lastNameTextField becomeFirstResponder];
    } else if (theTextField == self.lastNameTextFieldContainer) {
        [self.lastNameTextField resignFirstResponder];
    }
    
    return YES;
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
    
    CGSize rescaleSize = {kProfilePictureSize, kProfilePictureSize};
    
    if (image) {
        self.profilePictureImageView.image = [ImageUtils imageWithImage:[ImageUtils cropBiggestCenteredSquareImageFromImage:image withSide:image.size.width] scaledToSize:rescaleSize];
    } else {
        NSLog(@"Failed to get image");
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.firstNameTextField becomeFirstResponder];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.firstNameTextField becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1)  {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

@end
