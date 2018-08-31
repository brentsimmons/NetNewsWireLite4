//
//  RSUIImageExtras.m
//  RSCoreTests
//
//  Created by Brent Simmons on 7/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSUIImageExtras.h"
#import "RSImageScalingSpecifier.h"
#import "RSMimeTypes.h"
#import "RSUIKitExtras.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"

@interface NSObject (HappyCompiler)
- (float)scale;
- (UIImage *)initWithCGImage:(CGImageRef)anImage scale:(float)scale orientation:(UIInterfaceOrientation)orientation;
@end


@implementation UIImage (RSCore)


#pragma mark Serializing and De-serializing

- (NSData *)rs_pngOrJPEGRepresentation {
	NSData *imageData = UIImagePNGRepresentation(self);
	if (imageData == nil)
		imageData = UIImageJPEGRepresentation(self, 1.0f);
	return imageData;
}


- (NSData *)rs_jpegOrPNGRepresentation {
	NSData *imageData = UIImageJPEGRepresentation(self, 1.0f);
	if (imageData == nil)
		imageData = UIImagePNGRepresentation(self);
	return imageData;
}


+ (UIImage *)rs_imageWithData:(NSData *)imageData expectedSize:(CGSize)expectedSize {
	/*If or height or width is greater than the corresponding dimension in expectedSize,
	 then the scale is 2x -- unless we're not running on a retina display.*/
	if (RSRunningOnRetinaDisplay()) {
		CGDataProviderRef imageDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
		CGImageRef cgImage = nil;
		if (RSDataIsPNG(imageData))
			cgImage = CGImageCreateWithPNGDataProvider(imageDataProvider, nil, true, kCGRenderingIntentDefault);
		else
			cgImage = CGImageCreateWithJPEGDataProvider(imageDataProvider, nil, true, kCGRenderingIntentDefault);
		CGDataProviderRelease(imageDataProvider);
		if (cgImage == nil)
			return [UIImage imageWithData:imageData]; //just in case it works even though creating a CGImage failed
		CGFloat scaleToUse = 1.0f;
		if (CGImageGetWidth(cgImage) > expectedSize.width + 0.1 || CGImageGetHeight(cgImage) > expectedSize.height + 0.1)
			scaleToUse = 2.0f;
		UIImage *image = [[[UIImage alloc] initWithCGImage:cgImage scale:scaleToUse orientation:UIImageOrientationUp] autorelease];
		CGImageRelease(cgImage);
		return image;		
	}
	return [UIImage imageWithData:imageData];
}


#pragma mark Resizing, scaling, rounded corners

- (CGSize)rs_bestSizeForTargetSize:(CGSize)targetSize {
	CGSize imageSize = self.size;
	if (CGSizeEqualToSize(imageSize, targetSize))
		return imageSize;
	CGFloat scaleFactor = MIN(targetSize.width / imageSize.width, targetSize.height / imageSize.height);
	CGRect r = CGRectMake(0, 0, imageSize.width * scaleFactor, imageSize.height * scaleFactor);
	return CGRectIntegral(r).size;
}


- (CGSize)unscaledSize {
	/*If image is 50 x 75, but scale is 2, return 100 x 150*/
	static BOOL didCheckForScaleProperty = NO;
	static BOOL hasScaleProperty = NO;
	if (!didCheckForScaleProperty) {
		hasScaleProperty = [self respondsToSelector:@selector(scale)];
		didCheckForScaleProperty = YES;
	}
	if (!hasScaleProperty)
		return self.size;
	CGSize imageSize = self.size;
	imageSize.height = imageSize.height * self.scale;
	imageSize.width = imageSize.width * self.scale;
	return imageSize;
}


- (UIImage *)rs_imageScaledToSize:(CGSize)targetSize {
	/* https://devforums.apple.com/message/30804#30804 */
	/*PBS 7 July 2010: Thread-safe on iOS4 -- and it handles scaling properly.
	 But this can be used *only* on the main thread on iOS 3.x.*/
	
	//TODO: use ImageIO.framework instead -- I betcha it's *way* faster.
	
	CGSize scaledTargetSize = targetSize;
	
//	CGSize unscaledSize = [self unscaledSize];
//	if (unscaledSize.width > targetSize.width + .1 || unscaledSize.height > targetSize.height + .1) {
//		targetSize.height = targetSize.height * 2;
//		targetSize.width = targetSize.width * 2;
//	}
	
	UIImage *sourceImage = self;
	UIImage *newImage = nil;
	
	CGSize imageSize = sourceImage.size;
	
	/*Retina display: if unscaled image.width or .height is greater than corresponding dimension in targetSize,
	 then double targetSize. This will be a 2x image.*/
	
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGFloat scaleFactor = 0.0f;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	
	CGPoint thumbnailPoint = CGPointMake(0.0f,0.0f);
	
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
		
		CGFloat widthFactor = targetWidth / width;
		CGFloat heightFactor = targetHeight / height;
		
		if (widthFactor < heightFactor) 
			scaleFactor = widthFactor;
		else
			scaleFactor = heightFactor;
		
		scaledWidth  = width * scaleFactor;
		scaledHeight = height * scaleFactor;
		
		// center the image
		
		if (widthFactor < heightFactor) {
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5f; 
		} else if (widthFactor > heightFactor) {
			thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5f;
		}
	}
	
	// this is actually the interesting part:
	
	if (RSRunningOnOS4OrBetter())
		UIGraphicsBeginImageContextWithOptions(scaledTargetSize, NO, 0.0f);
	else
		UIGraphicsBeginImageContext(targetSize);
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	CGContextRelease(context);
	
	return newImage;
}


- (UIImage *)rs_imageWithRoundedCorners:(CGFloat)cornerRadius {
	/*Should be called on background thread on iOS 4. But *main-thread only* on iOS 3.x.*/
	CGSize imageSize = self.size;
	if (RSRunningOnOS4OrBetter())
		UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0f);
	else			
		UIGraphicsBeginImageContext(imageSize);
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	NSUInteger strokeWidth = 1;
	CGContextSetLineWidth(context, strokeWidth);
	
	CGRect r = CGRectMake(0, 0, imageSize.width, imageSize.height);
	if (cornerRadius > imageSize.width/2.0f)
		cornerRadius = imageSize.width/2.0f;
	if (cornerRadius > imageSize.height/2.0f)
		cornerRadius = imageSize.height/2.0f;    
	
	CGFloat minx = CGRectGetMinX(r);// + 0.5;
	CGFloat midx = CGRectGetMidX(r);
	CGFloat maxx = CGRectGetMaxX(r);// - 0.5;
	CGFloat miny = CGRectGetMinY(r);// + 0.5;
	CGFloat midy = CGRectGetMidY(r);
	CGFloat maxy = CGRectGetMaxY(r);// - 0.5;
	CGContextSaveGState(context);
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, cornerRadius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, cornerRadius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, cornerRadius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, cornerRadius);
	CGContextClosePath(context);
	CGContextClip(context);
	
	[self drawInRect:r blendMode:kCGBlendModeNormal alpha:1.0f];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRestoreGState(context);
	UIGraphicsEndImageContext();
	CGContextRelease(context);
	
	return newImage;	
}


- (UIImage *)rs_imageScaledToSize:(CGSize)targetSize cornerRadius:(CGFloat)cornerRadius {
	/*Scale *and* make rounded corners. Should be called on background thread on iOS 4. But *main-thread only* on iOS 3.x.*/
	UIImage *scaledImage = [self rs_imageScaledToSize:targetSize];
	if (scaledImage == nil)
		return nil; //shouldn't happen
	return [scaledImage rs_imageWithRoundedCorners:cornerRadius];
}


- (UIImage *)rs_hack_imageScaledOnMainThreadToSize:(CGSize)targetSize cornerRadius:(CGFloat)cornerRadius {
	/*I hope this code never executes -- or, if it does, it executes in hell.
	 This is a hack, and it should go away, so I'm deliberately not going to make the code pretty. It still works, though. This code is clever in its way -- it relies on waitUntilDone:YES and a mutable dictionary to get the result back from running on the main thread. It's pure evil, in other words. The good news is that it's never needed on iOS 4, since we can reliably resize images in the background on iOS 4.*/
	NSMutableDictionary *hackDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
	[hackDictionary rs_setInteger:(NSInteger)(targetSize.width) forKey:@"width"];
	[hackDictionary rs_setInteger:(NSInteger)(targetSize.height) forKey:@"height"];
//	[hackDictionary setObject:self forKey:@"image"];	//it's self
	if (cornerRadius > 0.1) {
		[hackDictionary rs_setBool:YES forKey:@"roundedCorners"];
		[hackDictionary setObject:[NSNumber numberWithFloat:cornerRadius] forKey:@"cornerRadius"];
	}
	[self performSelectorOnMainThread:@selector(rs_hack_scaleImageOnMainThreadWithHackDictionary:) withObject:hackDictionary waitUntilDone:YES];
	return [hackDictionary objectForKey:@"scaledImage"];	
}


- (void)rs_hack_scaleImageOnMainThreadWithHackDictionary:(NSMutableDictionary *)hackDictionary {
	/*Seems only to happen with Windows icons. Not an issue for TapLynx in general. Called from rs_hack_imageScaledOnMainThreadToSize. On main thread now.*/
	NSInteger targetHeight = [[hackDictionary objectForKey:@"height"] integerValue];
	NSInteger targetWidth = [[hackDictionary objectForKey:@"width"] integerValue];
	CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
	BOOL roundedCorners = [hackDictionary rs_boolForKey:@"roundedCorners"];
	CGFloat cornerRadius = 0.0f;
	if (roundedCorners)
		cornerRadius = [[hackDictionary objectForKey:@"cornerRadius"] floatValue];
	UIImage *image = nil;
	if (roundedCorners)
		image = [self rs_imageScaledToSize:targetSize cornerRadius:cornerRadius];
	else
		image = [self rs_imageScaledToSize:targetSize];
	[hackDictionary rs_safeSetObject:image forKey:@"scaledImage"];
}



@end


#pragma mark -
#pragma mark C

UIImage *RSScaleImageWithSpecifier(UIImage *image, RSImageScalingSpecifier *imageScalingSpecifier) {
	CGSize targetSize = [image rs_bestSizeForTargetSize:imageScalingSpecifier.targetSize];
	
	/*iOS 4 and up*/
	if (RSRunningOnOS4OrBetter()) {
		if (imageScalingSpecifier.roundedCorners)
			return [image rs_imageScaledToSize:targetSize cornerRadius:imageScalingSpecifier.cornerRadius];
		return [image rs_imageScaledToSize:targetSize];
	}
	
	/*iOS 3.x*/
	UIViewContentMode contentMode = UIViewContentModeScaleAspectFit;
	if (imageScalingSpecifier.contentMode == RSImageScalingContentModeAspectFill)
		contentMode = UIViewContentModeScaleAspectFill;
	UIImage *resizedImage = PLResizedImage(image, imageScalingSpecifier.targetSize, contentMode);
	if (resizedImage == nil)
		return [image rs_hack_imageScaledOnMainThreadToSize:targetSize cornerRadius:imageScalingSpecifier.cornerRadius]; //darn
	if (!imageScalingSpecifier.roundedCorners)
		return resizedImage;
	return TLRoundedCornerImage(resizedImage, imageScalingSpecifier.cornerRadius, 0);
	
}
								   

UIImage *RSScaleImage(UIImage *image, CGSize targetSize, BOOL roundedCorners, CGFloat cornerRadius) {
	RSImageScalingSpecifier *imageScalingSpecifier = [RSImageScalingSpecifier imageScalingSpecifierWithTargetSize:targetSize roundedCorners:roundedCorners];
	imageScalingSpecifier.cornerRadius = cornerRadius;
	return RSScaleImageWithSpecifier(image, imageScalingSpecifier);
}




