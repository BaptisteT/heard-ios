//
//  CameraViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 11/24/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "CameraViewController.h"
#import "PhotoView.h"
#import "Constants.h"
#import "KeyboardUtils.h"
#import "ImageUtils.h"
#import "Constants.h"
#import "GeneralUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define ALERT_VIEW_HEIGHT 40
#define ALERT_VIEW_WIDTH 280
#define TEXT_FIELD_HEIGHT 40

@interface CameraViewController ()

// Camera
@property (nonatomic) BOOL displayCamera;
@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (weak, nonatomic) IBOutlet UIButton *cameraFlipButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *takePictureButton;
// Edit
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UITextView *photoDescriptionField;
@property (weak, nonatomic) IBOutlet UIButton *photoConfirmButton;
@property (nonatomic, strong) UIPanGestureRecognizer *panningRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIButton *saveToCameraRollButton;
@property (weak, nonatomic) IBOutlet UIButton *photoDeleteButton;
@property (weak, nonatomic) IBOutlet UIButton *photoLibraryButton;
//Alert
@property (nonatomic, strong) UIView *alertView;
@property (nonatomic, strong) UILabel *alertLabel;


@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self allocAndInitFullScreenCamera];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.backgroundColor = [UIColor blackColor];
    
    double yOrigin = (self.textPosition > 0 && self.textPosition < 1) ? self.textPosition * self.view.frame.size.height : self.view.frame.size.height - TEXT_FIELD_HEIGHT;
    self.photoDescriptionField = [[UITextView alloc] initWithFrame:CGRectMake(0, yOrigin, self.view.frame.size.width, TEXT_FIELD_HEIGHT)];
    self.photoDescriptionField.textColor = [UIColor whiteColor];
    self.photoDescriptionField.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
    self.photoDescriptionField.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.65];
    [self.view addSubview:self.photoDescriptionField];
    self.photoDescriptionField.delegate = self;
    self.photoDescriptionField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.photoDescriptionField.textAlignment = NSTextAlignmentCenter;
    if (self.text && self.text.length > 0) {
        self.photoDescriptionField.text = self.text;
        [self textViewDidChange:self.photoDescriptionField];
    }
    
    if (self.image) {
        self.displayCamera = NO;
        self.imageView.image = self.image;
        self.photoDescriptionField.hidden = !self.photoDescriptionField.text || self.photoDescriptionField.text.length == 0;
    } else {
        self.photoDescriptionField.hidden = YES;
        self.displayCamera = YES;
    }
    
    // Libray Button
    self.photoLibraryButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [[self.photoLibraryButton layer] setBorderWidth:0.8f];
    [[self.photoLibraryButton layer] setBorderColor:[UIColor blackColor].CGColor];
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (nil != group) {
            // Chooses the photo at the last index
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
                // The end of the enumeration is signaled by asset == nil.
                if (alAsset) {
                    ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                    UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
                    [self.photoLibraryButton setImage:latestPhoto forState:UIControlStateNormal];
                    // Stop the enumerations
                    *stop = YES; *innerStop = YES;
                }
            }];
        }
        *stop = NO;
    } failureBlock:^(NSError *error) {
        NSLog(@"error: %@", error);
    }];
    
    // observe keyboard show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.panningRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanningGesture:)];
    [self.photoDescriptionField addGestureRecognizer:self.panningRecognizer];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    [self.imageView addGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willResignActiveCallback)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.displayCamera) {
        [self presentViewController:self.imagePickerController animated:NO completion:NULL];
    } else if (self.imageView.image) {
        self.photoConfirmButton.hidden = NO;
        self.photoDeleteButton.hidden = NO;
        self.saveToCameraRollButton.hidden = NO;
    }
}

- (void)willResignActiveCallback {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized && self.imageView.image) {
        [self.delegate savePhoto:self.imageView.image text:self.photoDescriptionField.text andTextPosition:(float)self.photoDescriptionField.frame.origin.y / self.view.frame.size.height];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

// ----------------------------------------------------------
#pragma mark ImagePickerController
// ----------------------------------------------------------
- (IBAction)cancelPhotoButtonClicked:(id)sender {
    self.imageView.image = nil;
    self.photoDescriptionField.text = nil;
    self.textPosition = 0;
    self.photoDescriptionField.hidden = YES;
    self.photoDescriptionField.frame = CGRectMake(0, 0, self.view.frame.size.width, TEXT_FIELD_HEIGHT);
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:self.imagePickerController animated:NO completion:NULL];
}

- (IBAction)checkButtonClicked:(id)sender {
    [self.delegate savePhoto:self.imageView.image text:self.photoDescriptionField.text andTextPosition:(float)self.photoDescriptionField.frame.origin.y / self.view.frame.size.height];
    [self dismissViewControllerAnimated:NO completion:nil];
}


// ----------------------------------------------------------
#pragma mark ImagePickerController
// ----------------------------------------------------------

// Alloc the impage picker controller
- (void) allocAndInitFullScreenCamera
{
    // Create custom camera view
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.delegate = self;
    
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    // Custom buttons
    imagePickerController.showsCameraControls = NO;
    imagePickerController.allowsEditing = NO;
    imagePickerController.navigationBarHidden=YES;
    
    NSString *xibName = @"CameraOverlayView";
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:xibName owner:self options:nil];
    UIView* myView = [ nibViews objectAtIndex: 0];
    myView.frame = self.view.frame;
    
    imagePickerController.cameraOverlayView = myView;
    
    double cameraHeight = self.view.frame.size.width * kCameraAspectRatio;
    double translationFactor = (self.view.frame.size.height - cameraHeight) / 2;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, translationFactor);
    imagePickerController.cameraViewTransform = translate;
    
    double rescalingRatio = self.view.frame.size.height / cameraHeight;
    CGAffineTransform scale = CGAffineTransformScale(translate, rescalingRatio, rescalingRatio);
    imagePickerController.cameraViewTransform = scale;
    
    // flash disactivated by default
    imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    self.imagePickerController = imagePickerController;
}

// Display the relevant part of the photo once taken
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editInfo
{
    UIImage *originalImage =  [editInfo objectForKey:UIImagePickerControllerOriginalImage];
    UIImageOrientation orientation;
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // Force portrait, and avoid mirror of front camera
        orientation = self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
    } else {
        if(originalImage.size.width <= originalImage.size.height) {
            orientation = originalImage.imageOrientation;
        } else {
            orientation = UIImageOrientationRight;
        }
    }
    
    CGSize originalSize = ((UIImage *)[editInfo objectForKey:UIImagePickerControllerOriginalImage]).size;
    CGFloat scaleRatio = kPhotoWidth/MIN(originalSize.width, originalSize.height);
    
    UIImage *image = [UIImage imageWithCGImage:originalImage.CGImage scale:1.0 orientation:orientation];
    
    self.imageView.image = [ImageUtils imageWithImage:image scaledToSize:CGSizeMake(image.size.width * scaleRatio, image.size.height * scaleRatio)];

    [self closeCamera];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum) {
        self.displayCamera = NO;
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        [self closeCamera];
    }
}


- (IBAction)takePictureButtonClicked:(id)sender {
    [self.imagePickerController takePicture];
}

- (IBAction)flipCameraButtonClicked:(id)sender
{
    if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront){
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    } else {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self closeCamera];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)libraryButtonClicked:(id)sender {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
}

- (void)closeCamera
{
    self.displayCamera = NO;
    [self dismissViewControllerAnimated:NO completion:nil];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (IBAction)savePhotoToCameraRoll:(id)sender {
    if (self.imageView.image.imageOrientation == UIImageOrientationLeftMirrored) {
        UIImageWriteToSavedPhotosAlbum([UIImage imageWithCGImage:[self.imageView.image CGImage]
                                                           scale:1.0
                                                     orientation: UIImageOrientationRight],
                                       self,
                                       @selector(photo:hasBeenSaveInPhotoAlbumWithError:usingContextInfo:),
                                       nil);
    } else {
        UIImageWriteToSavedPhotosAlbum(self.imageView.image,
                                       self,
                                       @selector(photo:hasBeenSaveInPhotoAlbumWithError:usingContextInfo:),
                                       nil);
    }
}

- (void)photo:(UIImage *)photo hasBeenSaveInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo
{
    if (error) {
        [self displayAlert:@"We could not save to your camera roll."];
    } else {
        [self displayAlert:@"Successfully saved!"];
    }
}

- (void)displayAlert:(NSString *)alert
{
    if (!self.alertView) {
        [self initAlertView];
    }
    
    self.alertLabel.text = alert;
    [self.alertView.layer removeAllAnimations];
    self.alertView.alpha = 0;
    
    [UIView animateWithDuration:1 animations:^{
        self.alertView.alpha = 1;
    } completion:^(BOOL finished) {
        if (finished && self.alertView) {
            [UIView animateWithDuration:1 delay:2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.alertView.alpha = 0;
            } completion:nil];
        }
    }];
}

- (void)initAlertView
{
    self.alertView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - ALERT_VIEW_WIDTH/2, self.view.bounds.size.height/2 - ALERT_VIEW_HEIGHT/2, ALERT_VIEW_WIDTH, ALERT_VIEW_HEIGHT)];
    
    self.alertView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    self.alertView.clipsToBounds = YES;
    self.alertView.layer.cornerRadius = 5;
    self.alertView.alpha = 0;
    [self.view addSubview:self.alertView];
    
    self.alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ALERT_VIEW_WIDTH, ALERT_VIEW_HEIGHT)];
    self.alertLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0];
    self.alertLabel.textAlignment = NSTextAlignmentCenter;
    self.alertLabel.textColor = [UIColor whiteColor];
    self.alertLabel.backgroundColor = [UIColor clearColor];
    self.alertLabel.numberOfLines = 1;
    self.alertLabel.adjustsFontSizeToFitWidth = YES;
    [self.alertView addSubview:self.alertLabel];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// ----------------------------------------------------------
#pragma mark Textfield
// ----------------------------------------------------------

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    // Update char count
    NSInteger charCount = [textView.text length] + [text length] - range.length;
    NSInteger remainingCharCount = kPhotoDescriptionMaxLength - charCount;
    if (remainingCharCount >= 0 ) {
        return YES;
    } else {
        return NO;
    }
}

-(void)textViewDidChange:(UITextView *)textView
{
    CGRect frame = textView.frame;
    frame.size.height = [textView sizeThatFits:textView.bounds.size].height;
    frame.origin.y = textView.frame.size.height - frame.size.height + frame.origin.y;
    textView.frame = frame;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.photoDescriptionField.hidden = NO;
    self.photoDescriptionField.textAlignment = NSTextAlignmentLeft;
    if (self.photoDescriptionField.frame.origin.y != self.view.frame.size.height - self.photoDescriptionField.frame.size.height) {
        self.textPosition = (float)self.photoDescriptionField.frame.origin.y / self.view.frame.size.height;
    } else {
        self.textPosition = 0;
    }
    [KeyboardUtils pushUpTopView:self.photoDescriptionField whenKeyboardWillShowNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.photoDescriptionField.textAlignment = NSTextAlignmentCenter;
    if (self.textPosition > 0) {
        double yOrigin = self.textPosition * self.view.frame.size.height;
        NSTimeInterval animationDuration = 0.25;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        self.photoDescriptionField.frame = CGRectMake(0, yOrigin, self.view.frame.size.width, self.photoDescriptionField.frame.size.height);
        [UIView commitAnimations];
    }
    if (self.photoDescriptionField.text.length == 0) {
        self.photoDescriptionField.hidden = YES;
        CGRect initialFrame = self.photoDescriptionField.frame;
        self.photoDescriptionField.frame = CGRectMake(initialFrame.origin.x, self.view.frame.size.height-initialFrame.size.height, initialFrame.size.width, initialFrame.size.height);
    }
}

- (void)handleTapGesture {
    if ([self.photoDescriptionField isFirstResponder]) {
        [self.photoDescriptionField endEditing:YES];
    } else {
        [self.photoDescriptionField becomeFirstResponder];
    }
}

- (void)handlePanningGesture:(UIPanGestureRecognizer *)recognizer
{
    if (self.photoDescriptionField.text.length == 0) {
        return;
    }
    if ([self.photoDescriptionField isFirstResponder]) {
        [self.photoDescriptionField endEditing:YES];
    }
    static CGPoint initialCenter;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        initialCenter = self.photoDescriptionField.center;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged || recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGPoint translation = [recognizer translationInView:self.view];
        CGPoint newCenterPoint = CGPointMake(initialCenter.x,initialCenter.y + translation.y);
        self.photoDescriptionField.center = newCenterPoint;
    }
}




@end
