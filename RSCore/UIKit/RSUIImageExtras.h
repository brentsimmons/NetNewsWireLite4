//
//  RSUIImageExtras.h
//  RSCoreTests
//
//  Created by Brent Simmons on 7/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RSImageScalingSpecifier;

UIImage *RSScaleImageWithSpecifier(UIImage *image, RSImageScalingSpecifier *imageScalingSpecifier);
UIImage *RSScaleImage(UIImage *image, CGSize targetSize, BOOL roundedCorners, CGFloat cornerRadius); //Call from background thread on iOS 3.x and 4 and up


@interface UIImage (RSCore)

- (NSData *)rs_pngOrJPEGRepresentation; //If PNG fails, returns JPEG with highest quality.
- (NSData *)rs_jpegOrPNGRepresentation;

/*For thumbnails, mainly. If height or width is greater than the corresponding dimension in expectedSize, then the resulting UIImage has a scale factor of 2 -- as long as we're running on a retina display. If not on retina, the scale is 1, and it just calls -[UIImage imageWithData:]. Important note: we expect the image to be a PNG or a JPEG. It has probably been archived on disk via rs_pngOrJPEGRepresentation.*/

+ (UIImage *)rs_imageWithData:(NSData *)imageData expectedSize:(CGSize)expectedSize;


@end
