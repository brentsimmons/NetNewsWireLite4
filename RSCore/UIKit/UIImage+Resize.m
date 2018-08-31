// UIImage+Resize.m
// Created by Trevor Harmon on 8/5/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"

// Private helper methods
@interface UIImage ()
- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality;
- (CGAffineTransform)transformForOrientation:(CGSize)newSize;
@end

@implementation UIImage (Resize)

// Returns a copy of this image that is cropped to the given bounds
// Note that the bounds will be adjusted using CGRectIntegral
- (UIImage *)croppedImage:(CGRect)bounds {
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], bounds);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

// Returns a copy of this image that is squared to the thumbnail size.
// If transparentBorder is non-zero, a transparent border of the given size will be added around the edges of the thumbnail. (Adding a transparent border of at least one pixel in size has the side-effect of antialiasing the edges of the image when rotating it using Core Animation.)
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality {
    UIImage *resizedImage = [self resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                       bounds:CGSizeMake(thumbnailSize, thumbnailSize)
                                         interpolationQuality:quality];
    
    // Crop out any part of the image that's larger than the thumbnail size
    // The cropped rect must be centered on the resized image
    // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
    CGRect cropRect = CGRectMake(roundf((resizedImage.size.width - thumbnailSize) / 2),
                                 roundf((resizedImage.size.height - thumbnailSize) / 2),
                                 (CGFloat)thumbnailSize,
                                 (CGFloat)thumbnailSize);
    UIImage *croppedImage = [resizedImage croppedImage:cropRect];
    
    UIImage *transparentBorderImage = borderSize ? [croppedImage transparentBorderImage:borderSize] : croppedImage;

    return [transparentBorderImage roundedCornerImage:cornerRadius borderSize:borderSize];
}

// Returns a rescaled copy of the image, taking into account its orientation
// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
    BOOL drawTransposed;
    
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;
            
        default:
            drawTransposed = NO;
    }
    
    return [self resizedImage:newSize
                    transform:[self transformForOrientation:newSize]
               drawTransposed:drawTransposed
         interpolationQuality:quality];
}


// Resizes the image according to the given content mode, taking into account the image's orientation
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode bounds:(CGSize)bounds interpolationQuality:(CGInterpolationQuality)quality {
	
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    CGFloat ratio;
    
    switch (contentMode) {
        case UIViewContentModeScaleAspectFill:
            ratio = MAX(horizontalRatio, verticalRatio);
            break;
            
        case UIViewContentModeScaleAspectFit:
            ratio = MIN(horizontalRatio, verticalRatio);
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException format:@"Unsupported content mode: %d", contentMode];
    }
    
    CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
//	UIImage *newImage = self;
//    if (![self hasAlpha])
//		newImage = [self imageWithAlpha];
    return [self resizedImage:newSize interpolationQuality:quality];
}

UIImage *PLResizedImage(UIImage *sourceImage, CGSize newSize, UIViewContentMode contentMode) {
//	BOOL drawTransposed;    
//    switch (sourceImage.imageOrientation) {
//        case UIImageOrientationLeft:
//        case UIImageOrientationLeftMirrored:
//        case UIImageOrientationRight:
//        case UIImageOrientationRightMirrored:
//            drawTransposed = YES;
//            break;
//            
//        default:
//            drawTransposed = NO;
//    }
    return [sourceImage resizedImageWithContentMode:contentMode bounds:newSize interpolationQuality:kCGInterpolationHigh];	
}


UIImage *TLResizedImage(UIImage *sourceImage, CGSize newSize, CGInterpolationQuality quality) {
//	BOOL drawTransposed;    
//    switch (sourceImage.imageOrientation) {
//        case UIImageOrientationLeft:
//        case UIImageOrientationLeftMirrored:
//        case UIImageOrientationRight:
//        case UIImageOrientationRightMirrored:
//            drawTransposed = YES;
//            break;
//            
//        default:
//            drawTransposed = NO;
//    }
    return [sourceImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:newSize interpolationQuality:quality];
	//    return [sourceImage resizedImage:newSize transform:[sourceImage transformForOrientation:newSize] drawTransposed:drawTransposed interpolationQuality:quality];		
}



#pragma mark -
#pragma mark Private helper methods

// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
// If the new size is not integral, it will be rounded up
- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = self.CGImage;
//    NSLog(@"bitsPerComponent: %d", CGImageGetBitsPerComponent(imageRef));
//	NSLog(@"bitmapInfo: %d", CGImageGetBitmapInfo(imageRef));
//	NSLog(@"bitsPerPixel: %d", CGImageGetBitsPerPixel(imageRef));
//	NSLog(@"bytesPerRow: %d", CGImageGetBytesPerRow(imageRef));
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB(); 
//	CFShow(CGImageGetColorSpace(imageRef));
//	CFShow(CGImageGetDataProvider(imageRef));
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                8, //CGImageGetBitsPerComponent(imageRef),
                                               CGImageGetBytesPerRow(imageRef), //0,// 4 * newRect.size.width,
											    colorSpaceRef, // CGImageGetColorSpace(imageRef),
												kCGImageAlphaPremultipliedLast); //CGImageGetBitmapInfo(imageRef));
    if (bitmap == nil) {
		CGColorSpaceRelease(colorSpaceRef);
		return nil;
	}
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, quality);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    CGColorSpaceRelease(colorSpaceRef);
    return newImage;
}


static const CGFloat pi_float = 3.14159265358979323846264338327950288f;
static const CGFloat pi_divided_by_two_float = 1.57079632679489661923132169163975144f;


// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, pi_float);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, pi_divided_by_two_float);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, (0 - pi_divided_by_two_float));
            break;
		case UIImageOrientationUp:
		case UIImageOrientationUpMirrored:
			break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
		case UIImageOrientationUp:
		case UIImageOrientationDown:
		case UIImageOrientationLeft:
		case UIImageOrientationRight:
			break;			
    }
    
    return transform;
}

@end
