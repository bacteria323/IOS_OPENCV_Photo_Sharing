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

#import "ViewController.h"

@interface ViewController () <CvVideoCameraDelegate> {
//@interface ViewController () {
    cv::Mat originalStillMat;
    cv::Mat updatedStillMatGray;
    cv::Mat updatedStillMatRGBA;
    cv::Mat updatedVideoMatGray;
    cv::Mat updatedVideoMatRGBA;
}

@property IBOutlet UIImageView *imageView;
@property IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property IBOutlet UIToolbar *toolbar;

@property VideoCamera *videoCamera;
@property BOOL saveNextFrame;

- (IBAction)onTapToSetPointOfInterest: (UITapGestureRecognizer *)tapGesture;
- (IBAction)onColorModeSelected:(UISegmentedControl *)segmentedControl;
- (IBAction)onSwitchCameraButtonPressed;
- (IBAction)onSaveButtonPressed;

- (void)refresh;
- (void)processImage:(cv::Mat &)mat;
//- (void)processImageHelper:(cv::Mat &)mat;
//- (void)saveImage:(UIImage *)image;
//- (void)showSaveImageFailureAlertWithMessage:(NSString *)message;
//- (void)showSaveImageSuccessAlertWithImage:(UIImage *)image;
//- (UIAlertAction *)shareImageActionWithTitle:(NSString *)title
//                                 serviceType:(NSString *)serviceType image:(UIImage *)image;
//- (void)startBusyMode;
//- (void)stopBusyMode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIImage *originalStillImage = [UIImage imageNamed:@"Fleur.jpg"];
    UIImageToMat(originalStillImage, originalStillMat);
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.letterboxPreview = YES;
}

// TODO
- (void)processImage:(cv::Mat &)mat {
    
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
    NSLog(@"Save button pressed");
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            self.videoCamera.defaultAVCaptureVideoOrientation =
            AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.videoCamera.defaultAVCaptureVideoOrientation =
            AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.videoCamera.defaultAVCaptureVideoOrientation =
            AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            self.videoCamera.defaultAVCaptureVideoOrientation =
            AVCaptureVideoOrientationPortrait;
            break;
    }
    
    [self refresh];
}

-(void)refresh {
    
}

//
//- (IBAction)onTapToSetPointOfInterest:
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
