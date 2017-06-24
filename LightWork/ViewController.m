//
//  ViewController.m
//  LightWork
//
//  Created by Shun Lee on 20/6/2017.
//  Copyright © 2017 mustardLabs. All rights reserved.
//

#import <Photos/Photos.h>
#import <Social/Social.h>

#import <opencv2/core.hpp>
#import <opencv2/imgcodecs.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>

#import "ViewController.h"
#import "VideoCamera.h"

@interface ViewController () <CvVideoCameraDelegate> {
    cv::Mat originalStillMat;
    cv::Mat updatedStillMatGray;
    cv::Mat updatedStillMatRGBA;
    cv::Mat updatedVideoMatGray;
    cv::Mat updatedVideoMatRGBA;
}

@property IBOutlet UIImageView *imageView; // imageview to host default image & camera preview
@property IBOutlet UIActivityIndicatorView *activityIndicatorView; // loading indicator to show when saving images
@property IBOutlet UIToolbar *toolbar; // toolbar at the bottom to switch between cameras and save images

@property VideoCamera *videoCamera; // custom camera implementation
@property BOOL saveNextFrame;

- (IBAction)onTapToSetPointOfInterest: (UITapGestureRecognizer *)tapGesture;
- (IBAction)onColorModeSelected:(UISegmentedControl *)segmentedControl;
- (IBAction)onSwitchCameraButtonPressed;
- (IBAction)onSaveButtonPressed;

- (void)refresh;
- (void)processImage:(cv::Mat &)mat;
- (void)processImageHelper:(cv::Mat &)mat;
- (void)saveImage:(UIImage *)image;
- (void)showSaveImageFailureAlertWithMessage:(NSString *)message;
- (void)showSaveImageSuccessAlertWithImage:(UIImage *)image;
- (UIAlertAction *)shareImageActionWithTitle:(NSString *)title
                                 serviceType:(NSString *)serviceType image:(UIImage *)image;
- (void)startBusyMode;
- (void)stopBusyMode;

@end

@implementation ViewController

#pragma mark
#pragma mark View Initialization methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *originalStillImage = [UIImage imageNamed:@"Fleur.jpg"]; // load default image
    UIImageToMat(originalStillImage, originalStillMat); // convert image to matrix 
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 30; // higher rate = smoother but drains battery faster
    self.videoCamera.letterboxPreview = YES;
}

// runs after viewDidLoad
// will be called after orientation changes
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    switch ([UIDevice currentDevice].orientation) { 
        case UIDeviceOrientationPortraitUpsideDown:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    [self refresh];
}

# pragma mark 
# pragma mark Helper methods
-(void)refresh {
    if (self.videoCamera.running) {
        // Hide the still image.
        self.imageView.image = nil;
        
        // Restart the video.
        [self.videoCamera stop];
        [self.videoCamera start];
    }
    
    else {
        // Refresh the still image.
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            cv::cvtColor(originalStillMat, updatedStillMatGray,
                         cv::COLOR_RGBA2GRAY);
            [self processImage:updatedStillMatGray];
            image = MatToUIImage(updatedStillMatGray);
        } else {
            cv::cvtColor(originalStillMat, updatedStillMatRGBA,
                         cv::COLOR_RGBA2BGRA);
            [self processImage:updatedStillMatRGBA];
            cv::cvtColor(updatedStillMatRGBA, updatedStillMatRGBA,
                         cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedStillMatRGBA);
        }
        self.imageView.image = image;
    }
}


- (void)processImage:(cv::Mat &)mat {
    if (self.videoCamera.running) {
        switch (self.videoCamera.defaultAVCaptureVideoOrientation) {
            case AVCaptureVideoOrientationLandscapeLeft:
            case AVCaptureVideoOrientationLandscapeRight:
                // The landscape video is captured upside-down.
                // Rotate it by 180 degrees.
                cv::flip(mat, mat, -1);
                break;
            default:
                break;
        }
    }
    
    [self processImageHelper:mat];
    
    if (self.saveNextFrame) {
        // The video frame, 'mat', is not safe for long-running
        // operations such as saving to file. Thus, we copy its
        // data to another cv::Mat first.
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            mat.copyTo(updatedVideoMatGray);
            image = MatToUIImage(updatedVideoMatGray);
        } else {
            cv::cvtColor(mat, updatedVideoMatRGBA, cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedVideoMatRGBA);
        }
        [self saveImage:image];
        self.saveNextFrame = NO;
    }
}

- (void)processImageHelper:(cv::Mat &)mat {
    // TODO: Implement in Chapter 3.
}

- (void)saveImage:(UIImage *)image {
    // Try to save the image to a temporary file.
    NSString *outputPath = [NSString stringWithFormat:@"%@%@",
                            NSTemporaryDirectory(), @"output.png"];
    if (![UIImagePNGRepresentation(image) writeToFile:outputPath
                                           atomically:YES]) {
        
        // Show an alert describing the failure.
        [self showSaveImageFailureAlertWithMessage:@"The image could not be saved to the temporary directory."];
        
        return;
    }
    
    // Try to add the image to the Photos library.
    NSURL *outputURL = [NSURL URLWithString:outputPath];
    PHPhotoLibrary *photoLibrary =
    [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary performChanges:^{
        [PHAssetChangeRequest
         creationRequestForAssetFromImageAtFileURL:outputURL];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            // Show an alert describing the success, with sharing
            // options.
            [self showSaveImageSuccessAlertWithImage:image];
        } else {
            // Show an alert describing the failure.
            [self showSaveImageFailureAlertWithMessage:
             error.localizedDescription];
        }
    }];
}

- (void)showSaveImageFailureAlertWithMessage:(NSString *)message {
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:@"Failed to save image"
                                message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [self stopBusyMode];
                                                     }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showSaveImageSuccessAlertWithImage:(UIImage *)image {
    
    // Create a "Saved image" alert.
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:@"Saved image"
                                message:@"The image has been added to your Photos library. Would you like to share it with your friends?"
                                preferredStyle:UIAlertControllerStyleAlert];
    
    // If the user has a Facebook account on this device, add a
    // "Post on Facebook" button to the alert.
    if ([SLComposeViewController
         isAvailableForServiceType:SLServiceTypeFacebook]) {
        UIAlertAction* facebookAction = [self
                                         shareImageActionWithTitle:@"Post on Facebook"
                                         serviceType:SLServiceTypeFacebook image:image];
        [alert addAction:facebookAction];
    }
    
    // If the user has a Twitter account on this device, add a
    // "Tweet" button to the alert.
    if ([SLComposeViewController
         isAvailableForServiceType:SLServiceTypeTwitter]) {
        UIAlertAction* twitterAction = [self
                                        shareImageActionWithTitle:@"Tweet"
                                        serviceType:SLServiceTypeTwitter image:image];
        [alert addAction:twitterAction];
    }
    
    // If the user has a Sina Weibo account on this device, add a
    // "Post on Sina Weibo" button to the alert.
    if ([SLComposeViewController
         isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
        UIAlertAction* sinaWeiboAction = [self
                                          shareImageActionWithTitle:@"Post on Sina Weibo"
                                          serviceType:SLServiceTypeSinaWeibo image:image];
        [alert addAction:sinaWeiboAction];
    }
    
    // If the user has a Tencent Weibo account on this device, add a
    // "Post on Tencent Weibo" button to the alert.
    if ([SLComposeViewController
         isAvailableForServiceType:SLServiceTypeTencentWeibo]) {
        UIAlertAction* tencentWeiboAction = [self
                                             shareImageActionWithTitle:@"Post on Tencent Weibo"
                                             serviceType:SLServiceTypeTencentWeibo image:image];
        [alert addAction:tencentWeiboAction];
    }
    
    // Add a "Do not share" button to the alert.
    UIAlertAction* doNotShareAction = [UIAlertAction
                                       actionWithTitle:@"Do not share"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * _Nonnull action) {
                                           [self stopBusyMode];
                                       }];
    [alert addAction:doNotShareAction];
    
    // Show the alert.
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction *)shareImageActionWithTitle:(NSString *)title
                                 serviceType:(NSString *)serviceType image:(UIImage *)image {

    UIAlertAction* action = [UIAlertAction actionWithTitle:title
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * _Nonnull action) {
            SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
            
            [composeViewController addImage:image];
            
            [self presentViewController:composeViewController
                               animated:YES completion:^{
                                   [self stopBusyMode];
                               }];
            
        }];
    return action;
    
}



- (IBAction)onColorModeSelected: (UISegmentedControl *)segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            self.videoCamera.grayscaleMode = NO;
            break;
        default:
            self.videoCamera.grayscaleMode = YES;
            break;
    }
    [self refresh];
}


-(IBAction)onSaveButtonPressed {
    [self startBusyMode];
    if (self.videoCamera.running) {
        self.saveNextFrame = YES;
    } else {
        [self saveImage:self.imageView.image];
    }
}

-(IBAction)onSwitchCameraButtonPressed {
    if (self.videoCamera.running) {
        switch (self.videoCamera.defaultAVCaptureDevicePosition) {
            case AVCaptureDevicePositionFront:
                self.videoCamera.defaultAVCaptureDevicePosition =
                AVCaptureDevicePositionBack;
                [self refresh];
                break;
            default:
                [self.videoCamera stop];
                [self refresh];
                break;
        }
    }
    
    else {
        // Hide the still image.
        self.imageView.image = nil;
        
        self.videoCamera.defaultAVCaptureDevicePosition =
        AVCaptureDevicePositionFront;
        [self.videoCamera start];
    }
}

// When user selects a point on the image
-(IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture
{
    if (tapGesture.state == UIGestureRecognizerStateEnded)
    {
        if (self.videoCamera.running)
        {
            CGPoint tapPoint = [tapGesture locationInView:self.imageView];
            [self.videoCamera setPointOfInterestInParentViewSpace:tapPoint];
        }
    }
}





- (void)startBusyMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView startAnimating];
        for (UIBarItem *item in self.toolbar.items) {
            item.enabled = NO;
        }
    });
}

- (void)stopBusyMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
        for (UIBarItem *item in self.toolbar.items) {
            item.enabled = YES;
        }
    });
}

@end
