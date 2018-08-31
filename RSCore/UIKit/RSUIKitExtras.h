//
//  RSUIKitExtras.h
//  RSCoreTests
//
//  Created by Brent Simmons on 5/25/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *RSWillAnimateRotationToInterfaceOrientation;

extern NSString *RSViewControllerWillRotateNotification;
extern NSString *RSViewControllerRotationAnimationDurationKey; //NSNumber in userInfo, may not always be there
extern NSString *RSViewControllerNewOrientationKey; //NSNumber in userInfo, may not always be there

extern NSString *RSViewControllerDidRotateNotification;

BOOL RSRunningOnOS4OrBetter(void);

BOOL RSRunningOnOS41OrBetter(void);

BOOL RSRunningOnRetinaDisplay(void);

BOOL RSRunningOniPad(void);

BOOL RSDeviceHasPhone(void);


@interface UIColor (RSCore)

+ (UIColor *)rs_colorWithHexString:(NSString *)hexString;

+ (UIColor *)rs_veryDarkBlueColor; //141c2e -- seen in popover frames
+ (UIColor *)rs_mediumBlueGrayColor; //787e8b
+ (UIColor *)rs_almostWhiteColor; //fbfbfc
+ (UIColor *)rs_lightBlueGrayBackgroundColor; //d9dce1

@end


@interface UILabel (RSCore)

+ (UILabel *)rs_nonOpaqueLabelWithNumberOfLines:(NSUInteger)aNumberOfLines;

@end


@interface UIView (RSCore)

+ (UIView *)rs_viewWithZeroFrame; //initWithFrame:CGRectZero
+ (UIView *)rs_viewWithWindowFrame; //initWithFrame:[UIScreen mainScreen].applicationFrame
+ (UIView *)rs_viewWithFrame:(CGRect)frame; //convenience

- (UIView *)rs_firstSubviewOfClass:(Class)aClass;


@end


@interface NSBundle (RSUICore)

- (UIImage *)rs_imageForResourceNamed:(NSString *)filename; //filename should include suffix
- (CGImageRef)rs_CGImageForResourceNamed:(NSString *)filename;

	
@end



@interface UIResponder (RSCore)

/*Starts with self, then chains through nextResponder. Returns yes if any responder implements the selector.*/

- (BOOL)rs_performSelectorViaResponderChain:(SEL)aSelector withObject:(id)anObject;

@end
