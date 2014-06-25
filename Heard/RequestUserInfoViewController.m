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

#define BORDER_SIZE 0.5
#define ACTION_SHEET_OPTION_1 @"Camera"
#define ACTION_SHEET_OPTION_2 @"Library"
#define ACTION_SHEET_CANCEL @"Cancel"
#define PROFILE_PICTURE_SIZE 200

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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
    [GeneralUtils addBottomBorder:self.firstNameTextFieldContainer borderSize:BORDER_SIZE];
    [GeneralUtils addBottomBorder:self.lastNameTextFieldContainer borderSize:BORDER_SIZE];
    
    self.profilePictureContainer.layer.cornerRadius = self.profilePictureContainer.bounds.size.height/2;
    self.profilePictureContainer.layer.borderWidth = 0.5;
    self.profilePictureContainer.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    self.firstNameTextField.delegate = self;
    self.lastNameTextField.delegate = self;
    
    [self.firstNameTextField becomeFirstResponder];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    
    if (![GeneralUtils validName:self.firstNameTextField.text]) {
        [GeneralUtils showMessage:@"First name must between 1 and 20 characters." withTitle:nil];
        return;
    } else if (![GeneralUtils validName:self.lastNameTextField.text]) {
        [GeneralUtils showMessage:@"Last name must between 1 and 20 characters." withTitle:nil];
        return;
    } else if (!self.profilePictureImageView.image) {
        [GeneralUtils showMessage:@"Please provide a profile picture." withTitle:nil];
        return;
    }
    
    [self signupUser];
}

- (void)signupUser
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    typedef void (^SuccessBlock)(NSString *authToken, Contact *contact);
    SuccessBlock successBlock = ^(NSString *authToken, Contact *contact) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [SessionUtils securelySaveCurrentUserToken:authToken];
        [SessionUtils saveUserInfo:contact.identifier phoneNumber:self.phoneNumber];
        
        [TrackingUtils identifyWithMixpanel:contact signingUp:YES];
        
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
        [self performSegueWithIdentifier:@"Dashboard Push Segue" sender:nil];
    };
    
    typedef void (^FailureBlock)();
    FailureBlock failureBlock = ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [GeneralUtils showMessage:@"We failed to sign you up, please try again." withTitle:nil];
    };
    
    [ApiUtils createUserWithPhoneNumber:self.phoneNumber
                              firstName:self.firstNameTextField.text
                               lastName:self.lastNameTextField.text
                                picture:[ImageUtils encodeToBase64String:self.profilePictureImageView.image]
                                   code:self.smsCode
                                success:successBlock failure:failureBlock];
}

- (IBAction)profilePicturePressed:(id)sender {
    self.pictureActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:ACTION_SHEET_OPTION_1, ACTION_SHEET_OPTION_2, nil];
    
    [self.pictureActionSheet showInView:[UIApplication sharedApplication].keyWindow];
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
    
    CGSize rescaleSize = {PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE};
    
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

@end
