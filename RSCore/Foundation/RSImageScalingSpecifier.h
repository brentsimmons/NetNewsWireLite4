//
//  RSImageScalingSpecifier.h
//  padlynx
//
//  Created by Brent Simmons on 10/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum _RSImageScalingContentMode {
	RSImageScalingContentModeAspectFit, //preserve aspect ratio, don't fill rect -- okay if empty space
	RSImageScalingContentModeAspectFill //preserve aspect ratio, fill rect, even if cropped
} RSImageScalingContentMode;


@interface RSImageScalingSpecifier : NSObject {
@private
	NSURL *URL;
	UIImage *scaledImage;
	BOOL roundedCorners;
	CGFloat cornerRadius;
	RSImageScalingContentMode contentMode;
	CGSize targetSize;
}


/*Convenience. You can also just use init and the properties.*/

+ (RSImageScalingSpecifier *)imageScalingSpecifierWithTargetSize:(CGSize)aTargetSize roundedCorners:(BOOL)aRoundedCornersFlag;
+ (RSImageScalingSpecifier *)imageScalingSpecifierWithURL:(NSURL *)aURL targetSize:(CGSize)aTargetSize roundedCorners:(BOOL)aRoundedCornersFlag;
+ (RSImageScalingSpecifier *)imageScalingSpecifierWithURL:(NSURL *)aURL targetSize:(CGSize)aTargetSize roundedCorners:(BOOL)aRoundedCornersFlag cornerRadius:(CGFloat)aCornerRadius contentMode:(RSImageScalingContentMode)aThumbnailContentMode;

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, retain) UIImage *scaledImage;
@property (nonatomic, assign) BOOL roundedCorners; //default YES
@property (nonatomic, assign) CGFloat cornerRadius; //default 5.0
@property (nonatomic, assign) RSImageScalingContentMode contentMode; //default RSThumbnailContentModeAspectFit
@property (nonatomic, assign) CGSize targetSize; //default 90 x 90

- (BOOL)isEqualToImageScalingSpecifier:(RSImageScalingSpecifier *)otherImageScalingSpecifier;
- (BOOL)isEqualToImageScalingSpecifierIgnoringURL:(RSImageScalingSpecifier *)otherImageScalingSpecifier;


@end
