#import "VideoCamera.h"

@interface VideoCamera ()

// CALayer - An object that manages image-based content and allows you to perform animations on that content
@property (nonatomic, retain) CALayer *customPreviewLayer;

@end

@implementation VideoCamera

@synthesize customPreviewLayer = _customPreviewLayer;

#pragma mark
#pragma mark Overriding methods

// get device's horizontal resolution
- (int)imageWidth {
    
    // CvVideoCamera inherits from abstract class CvAbstractCamera which has the property: AVCaptureSession *captureSession
    // AvCaptureSession is an object that manages capture activity and coordinates the flow of data from input devices to capture outputs
    // so self.captureSession.outputs returns array of instances that subclass AVCaptureOutput
    // lastObject simply gets the last item in the array
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoWidth = [[videoSettings objectForKey:@"Width"] intValue];
    return videoWidth;
}

// get device's vertical resolution
- (int)imageHeight {
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoHeight = [[videoSettings objectForKey:@"Height"] intValue];
    return videoHeight;
}

// Bug in opencv 3.1 because it uses this method to make assumptions about the camera's resolution. We override it to remove the bugs.
- (void)updateSize {
    // Do nothing.
}

// method to layout the video preview
- (void)layoutPreviewLayer {
    
    if (self.parentView != nil) {
        
        // Center the video preview.
        self.customPreviewLayer.position = CGPointMake(
                                                       0.5 * self.parentView.frame.size.width,
                                                       0.5 * self.parentView.frame.size.height);
        
        // Find the device's video aspect ratio.
        CGFloat videoAspectRatio = self.imageWidth / (CGFloat)self.imageHeight;
        
        // Scale the video preview while maintaining its aspect ratio.
        CGFloat boundsW;
        CGFloat boundsH;
        
        if (self.imageHeight > self.imageWidth) { // portrait mode 
            if (self.letterboxPreview) { // height set to device height but width is smaller to maintain aspect ratio
                boundsH = self.parentView.frame.size.height;
                boundsW = boundsH * videoAspectRatio;
            } else { // full screen height and width
                boundsW = self.parentView.frame.size.width;
                boundsH = boundsW / videoAspectRatio;
            }
        } else { // horizontal mode
            if (self.letterboxPreview) { // width set to device width but height is reduced with black bars
                boundsW = self.parentView.frame.size.width;
                boundsH = boundsW / videoAspectRatio;
            } else { // normal full screen horizontal mode
                boundsH = self.parentView.frame.size.height;
                boundsW = boundsH * videoAspectRatio;
            }
        }
        self.customPreviewLayer.bounds = CGRectMake(0.0, 0.0, boundsW, boundsH);
    }
}

- (void)setPointOfInterestInParentViewSpace:(CGPoint)parentViewPoint {
    
    if (!self.running) {
        return;
    }
    
    // Find the current capture device.
    NSArray *captureDevices =
    [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice;
    for (captureDevice in captureDevices) {
        if (captureDevice.position ==
            self.defaultAVCaptureDevicePosition) {
            break;
        }
    }
    
    BOOL canSetFocus = [captureDevice
                        isFocusModeSupported:AVCaptureFocusModeAutoFocus] &&
    captureDevice.isFocusPointOfInterestSupported;
    
    BOOL canSetExposure = [captureDevice
                           isExposureModeSupported:AVCaptureExposureModeAutoExpose] &&
    captureDevice.isExposurePointOfInterestSupported;
    
    if (!canSetFocus && !canSetExposure) {
        return;
    }
    
    if (![captureDevice lockForConfiguration:nil]) {
        return;
    }
    
    // Find the preview's offset relative to the parent view.
    CGFloat offsetX = 0.5 * (self.parentView.bounds.size.width -
                             self.customPreviewLayer.bounds.size.width);
    CGFloat offsetY = 0.5 * (self.parentView.bounds.size.height -
                             self.customPreviewLayer.bounds.size.height);
    
    // Find the focus coordinates, proportional to the preview size.
    CGFloat focusX = (parentViewPoint.x - offsetX) /
    self.customPreviewLayer.bounds.size.width;
    CGFloat focusY = (parentViewPoint.y - offsetY) /
    self.customPreviewLayer.bounds.size.height;
    
    if (focusX < 0.0 || focusX > 1.0 ||
        focusY < 0.0 || focusY > 1.0) {
        // The point is outside the preview.
        return;
    }
    
    // Adjust the focus coordinates based on the orientation.
    // They should be in the landscape-right coordinate system.
    switch (self.defaultAVCaptureVideoOrientation) {
        case AVCaptureVideoOrientationPortraitUpsideDown: {
            CGFloat oldFocusX = focusX;
            focusX = 1.0 - focusY;
            focusY = oldFocusX;
            break;
        }
        case AVCaptureVideoOrientationLandscapeLeft: {
            focusX = 1.0 - focusX;
            focusY = 1.0 - focusY;
            break;
        }
        case AVCaptureVideoOrientationLandscapeRight: {
            // Do nothing.
            break;
        }
        default: { // Portrait
            CGFloat oldFocusX = focusX;
            focusX = focusY;
            focusY = 1.0 - oldFocusX;
            break;
        }
    }
    
    if (self.defaultAVCaptureDevicePosition ==
        AVCaptureDevicePositionFront) {
        // De-mirror the X coordinate.
        focusX = 1.0 - focusX;
    }
    
    CGPoint focusPoint = CGPointMake(focusX, focusY);
    
    if (canSetFocus) {
        // Auto-focus on the selected point.
        captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        captureDevice.focusPointOfInterest = focusPoint;
    }
    
    if (canSetExposure) {
        // Auto-expose for the selected point.
        captureDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        captureDevice.exposurePointOfInterest = focusPoint;
    }
    
    [captureDevice unlockForConfiguration];
}

@end
