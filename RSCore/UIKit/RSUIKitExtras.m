//
//  RSUIKitExtras.m
//  RSCoreTests
//
//  Created by Brent Simmons on 5/25/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSFoundationExtras.h"
#import "RSUIKitExtras.h"


NSString *RSWillAnimateRotationToInterfaceOrientation = @"RSWillAnimateRotationToInterfaceOrientation";

NSString *RSViewControllerWillRotateNotification = @"RSViewControllerWillRotateNotification";
NSString *RSViewControllerRotationAnimationDurationKey = @"RSRotationAnimationDurationKey";
NSString *RSViewControllerNewOrientationKey = @"RSViewControllerNewOrientationKey";

NSString *RSViewControllerDidRotateNotification = @"RSViewControllerDidRotateNotification";

BOOL RSRunningOnOS4OrBetter(void) {
	static BOOL didCheckIfOnOS4 = NO;
	static BOOL runningOnOS4OrBetter = NO;
	if (!didCheckIfOnOS4) {
		NSString *systemVersion = [UIDevice currentDevice].systemVersion;
		NSInteger majorSystemVersion = 3;
		if (systemVersion != nil && [systemVersion length] > 0) { //Can't imagine it would be empty, but.
			NSString *firstCharacter = [systemVersion substringToIndex:1];
			majorSystemVersion = [firstCharacter integerValue];			
		}
		runningOnOS4OrBetter = (majorSystemVersion >= 4);
		didCheckIfOnOS4 = YES;
	}
	return runningOnOS4OrBetter;
}

BOOL RSRunningOnOS41OrBetter(void) {
	static BOOL didCheckIfOnOS41 = NO;
	static BOOL runningOnOS41OrBetter = NO;
	if (!didCheckIfOnOS41) {
		NSString *systemVersion = [UIDevice currentDevice].systemVersion;
		NSInteger majorSystemVersion = 3;
		NSInteger minorSystemVersion = 0;
		if (systemVersion != nil && [systemVersion length] > 0) { //Can't imagine it would be empty, but.
			NSString *firstCharacter = [systemVersion substringToIndex:1];
			majorSystemVersion = [firstCharacter integerValue];	
			
			systemVersion = [systemVersion substringFromIndex:2];
			firstCharacter = [systemVersion substringToIndex:1];
			minorSystemVersion = [firstCharacter integerValue];
		}
		runningOnOS41OrBetter = ((majorSystemVersion >= 4)&&(minorSystemVersion >= 1));
		didCheckIfOnOS41 = YES;
	}
	return runningOnOS41OrBetter;
}

@interface NSObject (ScreenScaleStub)
- (CGFloat)scale; //needed to keep compiler happy on iPad
@end

BOOL RSRunningOnRetinaDisplay(void) {
	static BOOL didCheckIfRetinaDisplay = NO;
	static BOOL runningOnRetinaDisplay = NO;
	if (!didCheckIfRetinaDisplay) {
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [UIScreen mainScreen].scale > 1.1)
			runningOnRetinaDisplay = YES;
		didCheckIfRetinaDisplay = YES;
	}
	return runningOnRetinaDisplay;
}

BOOL RSRunningOniPad(void) {
	
	static BOOL didCheckIfRunningOniPad = NO;
	static BOOL runningOniPad = NO;
	
	if(!didCheckIfRunningOniPad) {
		if ([UIDevice instancesRespondToSelector:@selector(userInterfaceIdiom)]) {
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) 
				runningOniPad = YES;
		}
		didCheckIfRunningOniPad = YES;
	}
	return runningOniPad;
}

BOOL RSDeviceHasPhone(void)
{
	static BOOL didCheckIfDeviceHasPhone = NO;
	static BOOL deviceHasPhone = NO;
	
	if(!didCheckIfDeviceHasPhone) {
		if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:+11111"]])
			deviceHasPhone = YES;
		didCheckIfDeviceHasPhone = YES;
	}
	return deviceHasPhone;
}

#pragma mark -

@implementation UIColor (RSCore)

+ (UIColor *)rs_colorWithHexString:(NSString *)hexString {
	NSString *s = RSStringReplaceAll(hexString, @"#", @"");
	s = [NSString rs_stringWithCollapsedWhitespace:s];
	if (RSStringIsEmpty(s))
		return [UIColor blackColor];
	NSString *redString = [s substringToIndex:2];
	NSString *greenString = [s substringWithRange:NSMakeRange(2, 2)];
	NSString *blueString = [s substringWithRange:NSMakeRange(4, 2)];
	unsigned int red = 0, green = 0, blue = 0;
	[[NSScanner scannerWithString:redString] scanHexInt:&red];  	
	[[NSScanner scannerWithString:greenString] scanHexInt:&green];  	
	[[NSScanner scannerWithString:blueString] scanHexInt:&blue];  	
	return [UIColor colorWithRed:(CGFloat)red/255.0f green:(CGFloat)green/255.0f blue:(CGFloat)blue/255.0f alpha:1.0f];	
}


+ (UIColor *)rs_veryDarkBlueColor {
	static UIColor *veryDarkBlueColor = nil;
	if (veryDarkBlueColor == nil)
		veryDarkBlueColor = [[UIColor rs_colorWithHexString:@"141c2e"] retain];
	return veryDarkBlueColor;
}


+ (UIColor *)rs_mediumBlueGrayColor {
	static UIColor *mediumBlueGrayColor = nil;
	if (mediumBlueGrayColor == nil)
		mediumBlueGrayColor = [[UIColor rs_colorWithHexString:@"787e8b"] retain];
	return mediumBlueGrayColor;
}


+ (UIColor *)rs_lightBlueGrayBackgroundColor {
	static UIColor *lightBlueGrayBackgroundColor = nil;
	if (lightBlueGrayBackgroundColor == nil)
		lightBlueGrayBackgroundColor = [[UIColor rs_colorWithHexString:@"d9dce1"] retain];
	return lightBlueGrayBackgroundColor;
}


+ (UIColor *)rs_almostWhiteColor {
	static UIColor *mediumBlueGrayColor = nil;
	if (mediumBlueGrayColor == nil)
		mediumBlueGrayColor = [[UIColor rs_colorWithHexString:@"fbfbfc"] retain];
	return mediumBlueGrayColor;
}


@end


@implementation UILabel (RSCore)

+ (UILabel *)rs_nonOpaqueLabelWithNumberOfLines:(NSUInteger)aNumberOfLines {
	UILabel *nonOpaqueLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	nonOpaqueLabel.opaque = NO;
	nonOpaqueLabel.numberOfLines = aNumberOfLines;
	nonOpaqueLabel.backgroundColor = [UIColor clearColor];
	return nonOpaqueLabel;
}


@end


@implementation UIView (RSCore)

+ (UIView *)rs_viewWithFrame:(CGRect)frame {
	return [[[self alloc] initWithFrame:frame] autorelease];
}


+ (UIView *)rs_viewWithZeroFrame {
	return [self rs_viewWithFrame:CGRectZero];
}


+ (UIView *)rs_viewWithWindowFrame {
	return [self rs_viewWithFrame:[UIScreen mainScreen].applicationFrame];
}


- (UIView *)rs_firstSubviewOfClass:(Class)aClass {
	for (UIView *oneSubview in self.subviews) {
		if ([oneSubview isKindOfClass:aClass])
			return oneSubview;
	}
	return nil;
}

@end


#pragma mark -

@implementation NSBundle (RSUICore)

- (UIImage *)rs_imageForResourceNamed:(NSString *)filename { //filename should include suffix
	NSString *path = [[NSBundle mainBundle] rs_pathForResourceWithSuffix:filename];
	if (RSStringIsEmpty(path))
		return nil;
	return [UIImage imageWithContentsOfFile:path];
}


- (CGImageRef)rs_CGImageForResourceNamed:(NSString *)filename {
	UIImage *image = [self rs_imageForResourceNamed:filename];
	if (image == nil)
		return nil;
	return image.CGImage;
}


@end


#pragma mark -

@implementation UIResponder (RSCore)

- (BOOL)rs_performSelectorViaResponderChain:(SEL)aSelector withObject:(id)anObject {
	UIResponder *nomad = self;
	while (nomad != nil) {
		if ([nomad respondsToSelector:aSelector]) {
			[nomad performSelector:aSelector withObject:anObject];
			return YES;
		}
		nomad = [nomad nextResponder];
	}
	return NO;
}

@end

