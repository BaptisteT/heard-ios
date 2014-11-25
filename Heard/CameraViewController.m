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

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self allocAndInitFullScreenCamera];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.backgroundColor = [UIColor blackColor];
    [ImageUtils outerGlow:self.photoConfirmButton];
    
    double yOrigin = (self.textPosition > 0 && self.textPosition < 1) ? self.textPosition * self.view.frame.size.height : self.view.frame.size.height - 40;
    self.photoDescriptionField = [[UITextView alloc] initWithFrame:CGRectMake(0, yOrigin, self.view.frame.size.width, 40)];
    self.photoDescriptionField.textColor = [UIColor whiteColor];
    self.photoDescriptionField.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
    self.photoDescriptionField.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [self.view addSubview:self.photoDescriptionField];
    self.photoDescriptionField.delegate = self;
    self.photoDescriptionField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.photoDescriptionField.textAlignment = NSTextAlignmentCenter;
    if (self.text && self.text.length > 0) {
        self.photoDescriptionField.text = self.text;
    }
    
    if (self.image) {
        self.displayCamera = NO;
        self.imageView.image = self.image;
        self.photoDescriptionField.hidden = NO;
    } else {
        self.photoDescriptionField.hidden = YES;
        self.displayCamera = YES;
    }
    
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.displayCamera) {
        [self presentViewController:self.imagePickerController animated:NO completion:NULL];
    } 
}

// ----------------------------------------------------------
#pragma mark ImagePickerController
// ----------------------------------------------------------
- (IBAction)cancelPhotoButtonClicked:(id)sender {
    self.imageView.image = nil;
    self.photoDescriptionField.text = nil;
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
    UIImage *image =  [editInfo objectForKey:UIImagePickerControllerOriginalImage];
    UIImageOrientation orientation;
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // Force portrait, and avoid mirror of front camera
        orientation = self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
    } else {
        orientation = UIImageOrientationRight;
    }

    self.imageView.image = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:orientation];;

    [self closeCamera];
    
    // Open keyboard
    self.photoDescriptionField.hidden = NO;
    [self.photoDescriptionField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.05f];
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

- (void)closeCamera
{
    self.displayCamera = NO;
    [self dismissViewControllerAnimated:NO completion:nil];
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
    [KeyboardUtils pushUpTopView:self.photoDescriptionField whenKeyboardWillShowNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.photoDescriptionField.textAlignment = NSTextAlignmentCenter;
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
