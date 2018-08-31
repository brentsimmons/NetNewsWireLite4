//
//  RSImageUtilities.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 10/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <ImageIO/ImageIO.h>
#endif
#import "RSImageUtilities.h"



CGImageRef RSCGImageFromDataWithMaxPixelSize(NSData *imageData, NSInteger maxPixelSize) {
    CGImageSourceRef imageSourceRef = (CGImageSourceRef)CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
	if (imageSourceRef == nil)
		return nil;
	size_t numberOfImages = CGImageSourceGetCount(imageSourceRef);
	size_t indexOfImage;
	for (indexOfImage = 0; indexOfImage < numberOfImages; indexOfImage++) {
		NSDictionary *oneImageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSourceRef, indexOfImage, NULL);
		NSInteger oneImagePixelWidth = [[oneImageProperties objectForKey:(NSString *)kCGImagePropertyPixelWidth] integerValue];
		if (oneImagePixelWidth < 1 || oneImagePixelWidth > maxPixelSize)
			continue;
		NSInteger oneImagePixelHeight = [[oneImageProperties objectForKey:(NSString *)kCGImagePropertyPixelHeight] integerValue];
		if (oneImagePixelHeight > 0 && oneImagePixelHeight <= maxPixelSize) {
			CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSourceRef, indexOfImage, NULL);
			if (cgImage != NULL)
				return (CGImageRef)cgImage;
		}
	}
	return RSCGImageThumbnailFromImageSourceWithMaxPixelSize(imageSourceRef, maxPixelSize);
}


CGImageRef RSCGImageThumbnailFromImageSourceWithMaxPixelSize(CGImageSourceRef imageSourceRef, NSInteger maxPixelSize) {
	NSDictionary *thumbnailOptions = [NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform, (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent, [NSNumber numberWithInteger:maxPixelSize], (id)kCGImageSourceThumbnailMaxPixelSize, nil];
	CGImageRef cgImage = CGImageSourceCreateThumbnailAtIndex(imageSourceRef, 0, (CFDictionaryRef)thumbnailOptions);
	if (cgImage == nil)
		return nil;
	return cgImage;
}



CGImageRef RSCGImageWithFilePath(NSString *filePath) {
	CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:filePath], NULL);
	CGImageRef cgImage = nil;
	if (imageSourceRef != nil) {
		cgImage = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
		CFRelease(imageSourceRef);
	}
	return cgImage;	
}


CGImageRef RSCGImageInResources(NSString *filename) {
	NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
	if (RSStringIsEmpty(filePath))
		return nil;
	return RSCGImageWithFilePath(filePath);
}

