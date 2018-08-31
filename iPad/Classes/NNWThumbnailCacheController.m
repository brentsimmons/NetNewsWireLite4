//
//  NNWThumbnailCacheController.m
//  nnwipad
//
//  Created by Brent Simmons on 3/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWThumbnailCacheController.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"


@implementation NNWThumbnailCacheController


+ (id)sharedController {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


- (CGSize)bestSizeForTargetSize:(CGSize)targetSize imageSize:(CGSize)imageSize {
	if (CGSizeEqualToSize(imageSize, targetSize))
		return imageSize;
	CGFloat scaleFactor = MAX(targetSize.width / imageSize.width, targetSize.height / imageSize.height);
	CGRect r = CGRectMake(0, 0, imageSize.width * scaleFactor, imageSize.height * scaleFactor);
	return CGRectIntegral(r).size;
}


- (UIImage *)resizedImageWithData:(NSData *)imageData targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners {
	if (RSIsEmpty(imageData))
		return nil;
	UIImage *image = [[[UIImage imageWithData:imageData] retain] autorelease];
	if (image == nil)
		return image;
	if (image.size.width < targetSize.width || image.size.height < targetSize.height)
		return image;
	if (image != nil) {
		/*Try to resize in background. Not always possible, but almost always possible.*/
		UIImage *resizedImage = image;
		if (!CGSizeEqualToSize(image.size, targetSize))
			resizedImage = TLResizedImage(image, [self bestSizeForTargetSize:targetSize imageSize:image.size], kCGInterpolationHigh);
		if (resizedImage != nil && roundedCorners) {
			resizedImage = TLRoundedCornerImage(resizedImage, 2, 0);
		}
		if (resizedImage != nil)
			return resizedImage;
	}
	return image; //Better than nothing. NetNewsWire clips it when drawing. The main thread scaling wasn't working, so this.
}


@end
