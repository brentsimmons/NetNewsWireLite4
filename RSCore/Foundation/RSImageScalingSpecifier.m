//
//  RSImageScalingSpecifier.m
//  padlynx
//
//  Created by Brent Simmons on 10/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSImageScalingSpecifier.h"


@implementation RSImageScalingSpecifier

@synthesize URL;
@synthesize scaledImage;
@synthesize roundedCorners;
@synthesize cornerRadius;
@synthesize contentMode;
@synthesize targetSize;


#pragma mark Class Methods

+ (RSImageScalingSpecifier *)imageScalingSpecifierWithTargetSize:(CGSize)aTargetSize roundedCorners:(BOOL)aRoundedCornersFlag {
	RSImageScalingSpecifier *imageScalingSpecifier = [[[RSImageScalingSpecifier alloc] init] autorelease];
	imageScalingSpecifier.targetSize = aTargetSize;
	imageScalingSpecifier.roundedCorners = aRoundedCornersFlag;
	return imageScalingSpecifier;
}


+ (RSImageScalingSpecifier *)imageScalingSpecifierWithURL:(NSURL *)aURL targetSize:(CGSize)aTargetSize roundedCorners:(BOOL)aRoundedCornersFlag {
	RSImageScalingSpecifier *imageScalingSpecifier = [self imageScalingSpecifierWithTargetSize:aTargetSize roundedCorners:aRoundedCornersFlag];
	imageScalingSpecifier.URL = aURL;
	return imageScalingSpecifier;
}


+ (RSImageScalingSpecifier *)imageScalingSpecifierWithURL:(NSURL *)aURL targetSize:(CGSize)aTargetSize roundedCorners:(BOOL)aRoundedCornersFlag cornerRadius:(CGFloat)aCornerRadius contentMode:(RSImageScalingContentMode)aThumbnailContentMode {
	RSImageScalingSpecifier *imageScalingSpecifier = [self imageScalingSpecifierWithURL:aURL targetSize:aTargetSize roundedCorners:aRoundedCornersFlag];
	imageScalingSpecifier.cornerRadius = aCornerRadius;
	imageScalingSpecifier.contentMode = aThumbnailContentMode;
	return imageScalingSpecifier;
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	roundedCorners = YES;
	cornerRadius = 5.0f;
	contentMode = RSImageScalingContentModeAspectFit;
	targetSize = CGSizeMake(90.0f, 90.0f);
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[URL release];
	[scaledImage release];
	[super dealloc];
}


#pragma mark Comparing

- (BOOL)isEqualToImageScalingSpecifier:(RSImageScalingSpecifier *)otherImageScalingSpecifier {
	return (self == otherImageScalingSpecifier) || (self.roundedCorners == otherImageScalingSpecifier.roundedCorners && self.contentMode == otherImageScalingSpecifier.contentMode && CGSizeEqualToSize(self.targetSize, otherImageScalingSpecifier.targetSize) && abs(self.cornerRadius - otherImageScalingSpecifier.cornerRadius) < 1 && [self.URL isEqual:otherImageScalingSpecifier.URL]);
}


- (BOOL)isEqualToImageScalingSpecifierIgnoringURL:(RSImageScalingSpecifier *)otherImageScalingSpecifier {
	return (self == otherImageScalingSpecifier) || (self.roundedCorners == otherImageScalingSpecifier.roundedCorners && self.contentMode == otherImageScalingSpecifier.contentMode && CGSizeEqualToSize(self.targetSize, otherImageScalingSpecifier.targetSize) && abs(self.cornerRadius - otherImageScalingSpecifier.cornerRadius) < 1);
}


@end
