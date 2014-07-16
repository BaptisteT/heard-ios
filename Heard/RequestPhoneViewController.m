//
//  PhoneViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "RequestPhoneViewController.h"
#import "GeneralUtils.h"
#import "CodeConfirmationViewController.h"
#import "ApiUtils.h"
#import "MBProgressHUD.h"
#import "RMPhoneFormat.h"

#define BORDER_SIZE 0.5
#define DEFAULT_COUNTRY @"USA"
#define DEFAULT_COUNTRY_CODE 1
#define DEFAULT_COUNTRY_LETTER_CODE @"us"


@interface RequestPhoneViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (nonatomic, strong) NSString *rawPhoneNumber;
@property (nonatomic, strong) RMPhoneFormat *phoneFormat;
@property (weak, nonatomic) IBOutlet UILabel *countryNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *tutoLabel;
@property (weak, nonatomic) IBOutlet UIView *countryNameContainer;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation RequestPhoneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.rawPhoneNumber = @"";
    
    [self updateCountryName:DEFAULT_COUNTRY code:[NSNumber numberWithInt:DEFAULT_COUNTRY_CODE] letterCode:DEFAULT_COUNTRY_LETTER_CODE];
    
    self.phoneTextField.delegate = self;
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
    [GeneralUtils addBottomBorder:self.textFieldContainer borderSize:BORDER_SIZE];
    [GeneralUtils addTopBorder:self.textFieldContainer borderSize:BORDER_SIZE];
    [GeneralUtils addRightBorder:self.countryCodeButton borderSize:BORDER_SIZE];
    
    //Autoresize bug
    [self.tutoLabel sizeToFit];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.phoneTextField becomeFirstResponder];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    if ([self.phoneFormat isPhoneNumberValid:self.rawPhoneNumber]) {
        NSString *internationalPhoneNumber = [NSString stringWithFormat:@"+%@%@", [self.countryCodeButton.titleLabel.text substringFromIndex:1], self.rawPhoneNumber];
        [self sendCodeRequest:internationalPhoneNumber];
    } else {
        [GeneralUtils showMessage:nil withTitle:@"Invalid phone number"];
    }
}

- (IBAction)countryCodeButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Country Code Segue" sender:nil];
}


- (IBAction)countryNameButtonPressed:(UILongPressGestureRecognizer *)sender {
    switch (sender.state) {
        case 1: // object pressed
        case 2:
            [self.countryNameContainer.layer setBackgroundColor:[UIColor lightGrayColor].CGColor];
            [self.countryNameContainer.layer setOpacity:0.4];
            break;
        case 3: // object released
            [self.countryNameContainer.layer setBackgroundColor:[UIColor clearColor].CGColor];
            [self.countryNameContainer.layer setOpacity:1];
            [self performSegueWithIdentifier:@"Country Code Segue" sender:nil];
            break;
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Code Confirmation Push Segue"]) {
        ((CodeConfirmationViewController *) [segue destinationViewController]).phoneNumber = (NSString *)sender;
    }
    
    if ([segueName isEqualToString: @"Country Code Segue"]) {
        ((CountryCodeViewController *) [segue destinationViewController]).delegate = self;
    }
}

- (void)sendCodeRequest:(NSString *)phoneNumber
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [ApiUtils requestSmsCode:phoneNumber retry:NO success:^() {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [self performSegueWithIdentifier:@"Code Confirmation Push Segue" sender:phoneNumber];
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:@"We failed to send your confirmation code, the provided phone number might be invalid." withTitle:nil];
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (string.length > 0) {
        self.rawPhoneNumber = [self.rawPhoneNumber stringByAppendingString:string];
    } else {
        NSString *newString = [[textField.text substringToIndex:range.location] stringByAppendingString:[textField.text substringFromIndex:range.location + range.length]];
        
        NSString *numberString = @"";
        
        for (int i=0; i<[newString length]; i++) {
            if (isdigit([newString characterAtIndex:i])) {
                numberString = [numberString stringByAppendingFormat:@"%c",[newString characterAtIndex:i]];
            }
        }
        
        self.rawPhoneNumber = numberString;
    }
    
    textField.text = [self.phoneFormat format:self.rawPhoneNumber];
    
    return NO;
}

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode
{
    self.phoneFormat = [[RMPhoneFormat alloc] initWithDefaultCountry:letterCode];
    
    [self.countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", code] forState: UIControlStateNormal];
    self.phoneTextField.text = [self.phoneFormat format:self.rawPhoneNumber];
    
    self.countryNameLabel.text = countryName;
}

@end
