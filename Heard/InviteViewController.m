//
//  ShareInvitationViewControllerViewController.m
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "InviteViewController.h"
#import "Constants.h"
#import "GeneralUtils.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AddContactViewController.h"
#import "TrackingUtils.h"
#import "SessionUtils.h"
#import "MBProgressHUD.h"
#import "ApiUtils.h"
#import "ImageUtils.h"
#import "ImageUtils.h"
#import "CameraUtils.h"
#import "EditContactsViewController.h"

#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable(@"cancel_button_title",kStringFile,@"comment")

#define ACTION_OTHER_MENU_OPTION_1_ON NSLocalizedStringFromTable(@"emoji_mode_on_menu",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_1_OFF NSLocalizedStringFromTable(@"emoji_mode_off_menu",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_2 NSLocalizedStringFromTable(@"hide_contacts_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_3 NSLocalizedStringFromTable(@"edit_profile_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_4 NSLocalizedStringFromTable(@"feedback_button_title",kStringFile,@"comment")
#define ACTION_OTHER_MENU_OPTION_5 NSLocalizedStringFromTable(@"rate_button_title",kStringFile,@"comment")


#define ACTION_SHEET_PROFILE_OPTION_1 NSLocalizedStringFromTable(@"edit_picture_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PROFILE_OPTION_2 NSLocalizedStringFromTable(@"edit_first_name_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PROFILE_OPTION_3 NSLocalizedStringFromTable(@"edit_last_name_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PICTURE_OPTION_1 NSLocalizedStringFromTable(@"camera_button_title",kStringFile,@"comment")
#define ACTION_SHEET_PICTURE_OPTION_2 NSLocalizedStringFromTable(@"library_button_title",kStringFile,@"comment")


@interface InviteViewController () <UIActionSheetDelegate>

@property (strong, nonatomic) UIActionSheet *menuActionSheet;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation InviteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// ----------------------------------------------------------
#pragma mark Share options
// ----------------------------------------------------------

- (IBAction)smsShare:(id)sender {
    if ([MFMessageComposeViewController canSendText]) {
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"%@ %@.",
                               NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"), kProdAFHeardWebsite];
        viewController.messageComposeDelegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];

    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"text_access_error_message",kStringFile,@"comment") withTitle:nil];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (result == MessageComposeResultSent) {
        [TrackingUtils trackInvite:@"SMS" Success:@"True"];
    } else {
        [TrackingUtils trackInvite:@"SMS" Success:@"False"];
    }
}
- (IBAction)AddContactButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Add Contact Modal Segue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString:@"Add Contact Modal Segue"]) {
        ((AddContactViewController *) [segue destinationViewController]).contacts = self.contacts;
    } else if ([segueName isEqualToString: @"Edit Contacts Segue"]) {
        ((EditContactsViewController *) [segue destinationViewController]).delegate = self.delegate;
        ((EditContactsViewController *) [segue destinationViewController]).contacts = self.contacts;
    }
}


- (IBAction)emailShare:(id)sender {
    NSString *email = [NSString stringWithFormat:@"mailto:?subject=%@&body=%@ %@.",
                       NSLocalizedStringFromTable(@"invite_mail_subject",kStringFile, @"comment"),
                       NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"), kProdAFHeardWebsite];
    
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    
    [TrackingUtils trackInvite:@"Email" Success:nil];
}

- (IBAction)facebookShare:(id)sender {
    // Check if the Facebook app is installed and we can present
    // the message dialog
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
    params.link = [NSURL URLWithString:kProdAFHeardWebsite];
    
    // If the Facebook app is installed and we can present the share dialog
    if ([FBDialogs canPresentMessageDialogWithParams:params]) {
        // Present message dialog
        [FBDialogs presentMessageDialogWithLink:[NSURL URLWithString:kProdAFHeardWebsite]
                                        handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                            if(error) {
                                                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"fb_messenger_error",kStringFile,@"comment") withTitle:nil];
                                            }
                                        }];
        
        [TrackingUtils trackInvite:@"Facebook" Success:nil];
    }  else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"no_fb_messenger",kStringFile,@"comment") withTitle:nil];
    }
}

- (IBAction)whatsappShare:(id)sender {
    NSString *whatsapp = [NSString stringWithFormat:@"whatsapp://send?text=%@ %@.",
                       NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"),
                          kProdAFHeardWebsite];
    
    whatsapp = [whatsapp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *whatsappURL = [NSURL URLWithString:whatsapp];
    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
        [[UIApplication sharedApplication] openURL: whatsappURL];
        
        [TrackingUtils trackInvite:@"Whatsapp" Success:nil];
    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"no_whatsapp_messenger",kStringFile,@"comment") withTitle:nil];
    }
}

- (IBAction)settingsButtonClicked:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *emojiMenuButton;
    
    if ([[prefs objectForKey:kEmojiPref] isEqualToString:@"Off"]) {
        emojiMenuButton = ACTION_OTHER_MENU_OPTION_1_OFF;
    } else {
        emojiMenuButton = ACTION_OTHER_MENU_OPTION_1_ON;
    }
    
    self.menuActionSheet = [[UIActionSheet alloc]
                            initWithTitle:[NSString  stringWithFormat:@"Waved v.%@", [[NSBundle mainBundle]  objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                            delegate:self
                            cancelButtonTitle:ACTION_SHEET_CANCEL
                            destructiveButtonTitle:nil
                            otherButtonTitles: emojiMenuButton, ACTION_OTHER_MENU_OPTION_2, ACTION_OTHER_MENU_OPTION_3, ACTION_OTHER_MENU_OPTION_4, ACTION_OTHER_MENU_OPTION_5, nil];
    [self.menuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    
    
    /* -------------------------------------------------------------------------
     SETTINGS MENU
     ---------------------------------------------------------------------------*/
    
    //Emoji Mode
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_1_OFF] || [buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_1_ON]) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        if ([[prefs objectForKey:kEmojiPref] isEqualToString:@"Off"]) {
            [prefs setObject:@"On" forKey:kEmojiPref];
        } else {
            [prefs setObject:@"Off" forKey:kEmojiPref];
        }
    }
    
    // Edit contacts
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_2]) {
        [self performSegueWithIdentifier:@"Edit Contacts Segue" sender:nil];
    }
    
    // Profile
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_3]) {
        [actionSheet dismissWithClickedButtonIndex:2 animated:NO];
        UIActionSheet *newActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                    delegate:self
                                                           cancelButtonTitle:ACTION_SHEET_CANCEL
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:ACTION_SHEET_PROFILE_OPTION_1, ACTION_SHEET_PROFILE_OPTION_2, ACTION_SHEET_PROFILE_OPTION_3, nil];
        
        [newActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
    
    //Send feedback
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_4]) {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=Feedback for Waved on iOS (v%@)", kFeedbackEmail,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
    
    // Rate us
    else if ([buttonTitle isEqualToString:ACTION_OTHER_MENU_OPTION_5]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kProdAFHeardWebsite]];
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
        NSString *preFillText =  [buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_2] ? [SessionUtils getCurrentUserFirstName] : [SessionUtils getCurrentUserLastName];
        [actionSheet dismissWithClickedButtonIndex:0 animated:NO];
        if ([GeneralUtils systemVersionIsGreaterThanOrEqualTo:@"8.0"]) {
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:buttonTitle message:@"" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
             {
                 textField.text = preFillText;
                 textField.textAlignment = NSTextAlignmentCenter;
             }];
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                           style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *action) {
                                               NSLog(@"Cancel action");
                                           }];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                           [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                           NSString *newText = ((UITextField *)alertController.textFields[0]).text;
                                           
                                           if ([buttonTitle isEqualToString:ACTION_SHEET_PROFILE_OPTION_2]) {
                                               [ApiUtils updateFirstName:newText success:^{
                                                   [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                   [GeneralUtils showMessage:NSLocalizedStringFromTable(@"first_name_edit_success_message",kStringFile, @"comment") withTitle:nil];
                                                   // change first name me contact
                                                   [self.delegate updateCurrentUserFirstName:newText lastName:nil picture:nil];
                                               } failure:^{
                                                   [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                   [GeneralUtils showMessage:NSLocalizedStringFromTable(@"first_name_edit_error_message",kStringFile, @"comment") withTitle:nil];
                                               }];
                                           } else {
                                               [ApiUtils updateLastName:newText success:^{
                                                   [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                   [GeneralUtils showMessage:NSLocalizedStringFromTable(@"last_name_edit_success_message",kStringFile, @"comment") withTitle:nil];
                                                   // change first name me contact
                                                   [self.delegate updateCurrentUserFirstName:nil lastName:newText picture:nil];
                                               } failure:^{
                                                   [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                   [GeneralUtils showMessage:NSLocalizedStringFromTable(@"last_name_edit_error_message",kStringFile, @"comment") withTitle:nil];
                                               }];
                                           }
                                       }];
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:NO completion:nil];
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:buttonTitle message:@"" delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"cancel_button_title",kStringFile, @"comment") otherButtonTitles:NSLocalizedStringFromTable(@"ok_button_title",kStringFile, @"comment"), nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField *textField = [alert textFieldAtIndex:0];
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = preFillText;
            [textField becomeFirstResponder];
            [alert addSubview:textField];
            [alert show];
        }
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
}


// --------------------------
#pragma mark Profile picture change
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
            [self.delegate updateCurrentUserFirstName:nil lastName:nil picture:image];
            
            
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"picture_edit_success_message",kStringFile, @"comment") withTitle:nil];
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
    
    if ([navigationController.viewControllers indexOfObject:viewController] == 2) {
        [CameraUtils addCircleOverlayToEditView:viewController];
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
}

@end
