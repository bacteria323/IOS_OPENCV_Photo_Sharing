//
//  VideoCamera.h
//  LightWork
//
//  Created by Shun Lee on 20/6/2017.
//  Copyright © 2017 mustardLabs. All rights reserved.
//

// import in angle brackets <> are global imports. | Import in normal parentheses "" import files in the relative path
// refer to http://blog.teamtreehouse.com/beginners-guide-objective-c-classes-objects for more information 
#import <opencv2/videoio/cap_ios.h>

@interface VideoCamera : CvVideoCamera // colon is for class inheritance, ie VideoCamer inherits CvVideoCamera

@property BOOL letterboxPreview;

- (void)setPointOfInterestInParentViewSpace:(CGPoint)point;

@end
