//
//  VideoCamera.h
//  LightWork
//
//  Created by Shun Lee on 20/6/2017.
//  Copyright © 2017 mustardLabs. All rights reserved.
//

//#ifndef VideoCamera_h
//#define VideoCamera_h
//
//
//#endif /* VideoCamera_h */

#import <opencv2/videoio/cap_ios.h>

@interface VideoCamera : CvVideoCamera

@property BOOL letterboxPreview;

- (void)setPointOfInterestInParentViewSpace:(CGPoint)point;

@end
