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

@interface CameraViewController ()

// Camera
@property (nonatomic) BOOL displayCamera;
@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (weak, nonatomic) IBOutlet UIButton *cameraFlipButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *takePictureButton;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self allocAndInitFullScreenCamera];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.backgroundColor = [UIColor blackColor];
    
    self.displayCamera = !self.imageView.image;
}

- (void)viewWillAppear:(BOOL)animated
{
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
    [self.delegate savePhoto:self.imageView.image andText:self.photoDescriptionField.text];
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
    
    // todo bt
    // Keyboard + label
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


@end
