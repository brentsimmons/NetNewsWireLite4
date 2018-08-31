//
//  NNWExtras.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


//extern BOOL RSIsEmpty(id obj);
//extern NSString *RSURLDecodedString(NSString *s);
//extern BOOL RSStringIsEmpty(NSString *s);
//extern NSArray *RSArraySeparatedByFirstInstanceOfCharacter(NSString *s, unichar ch);
extern NSString *RSDocumentsFilePath(NSString *filename);
//extern NSString *RSStringReplaceAll (NSString *stringToSearch, NSString *searchFor, NSString *replaceWith);
extern CGRect CGRectCenteredHorizontallyInContainingRect(CGRect rectToCenter, CGRect containingRect);
extern NSString *RSApplicationSupportFile(NSString *filename);
extern void RSPostNotificationOnMainThread(NSString *notificationName);

@interface NSObject (NNWExtras)
- (void)postNotificationOnMainThread:(NSString *)notificationName;
@end


@interface NSString (NNWExtras)
+ (NSString *)UUIDString;
+ (NSString *)stringWithUTF8EncodedData:(NSData *)data;
+ (NSString *)onewayHashOfString:(NSString *)s;
+ (NSString *)stringByStrippingSuffix:(NSString *)s suffix:(NSString *)suffix;
+ (NSString *)stringWithDecodedEntities:(NSString *)s;
+ (NSString *)stringWithCollapsedWhitespace:(NSString *)s;
+ (NSString *)rs_stringWithStrippedHTML:(NSString *)htmlString maxCharacters:(NSInteger)maxCharacters;
+ (NSString *)stringWithQueryStripped:(NSString *)s;
+ (NSString *)stripPrefix:(NSString *)s prefix:(NSString *)prefix;
+ (NSString *)stripSuffix:(NSString *)s suffix:(NSString *)suffix;
- (BOOL)caseSensitiveContains:(NSString *)searchFor;
- (BOOL)caseInsensitiveContains:(NSString *)searchFor;
- (NSString *)substringAfterFirstOccurenceOfString:(NSString *)stringToFind;
- (NSUInteger)sumOfCharacterCodes;
@end

@interface NSMutableString (NNWExtras)
- (void)replaceEntity38WithAmpersand;
- (void)replaceEntity39WithSingleQuote;
- (void)replaceEntityAmpWithAmpersand;
- (void)replaceEntityQuotWithDoubleQuote;
- (void)replaceXMLCharacterReferences;
@end

@interface NSArray (NNWExtras)
- (id)safeObjectAtIndex:(NSUInteger)ix;
@end

@interface NSMutableArray (NNWExtras)
- (void)safeAddObject:(id)obj;
@end
	
@interface NSDictionary (NNWExtras)
- (BOOL)boolForKey:(id)key;
- (NSInteger)integerForKey:(id)key;
- (id)safeObjectForKey:(id)key;
- (NSString *)httpPostArgsString;
@end


@interface NSMutableDictionary (NNWExtras)
- (void)safeSetObject:(id)obj forKey:(id)key;
- (void)setBool:(BOOL)fl forKey:(id)key;
- (void)setInteger:(NSInteger)n forKey:(id)key;
@end


@interface NSDate (NNWExtras)
+ (void)handleSignificantDateTimeChange;
+ (NSString *)contextualDateStringWithDate:(NSDate *)d;
@end


@interface NSTimer (NNWExtras)
- (void)invalidateIfValid;
@end

@interface UIColor (NNWExtras)
+ (UIColor *)colorWithHexString:(NSString *)hexString;
+ (UIColor *)unreadCountBackgroundColor;
+ (UIColor *)slateBlueColor;
+ (UIColor *)webViewBackgroundColor;
+ (UIColor *)coolDarkGrayColor;
+ (UIColor *)veryBrightBlueColor;
- (UIColor *)lightened;
- (UIColor *)darkened;	
@end
	
@interface UIImage (NNWExtras)
+ (UIImage *)imageInRoundRect:(UIImage *)sourceImage size:(CGSize)size radius:(CGFloat)radius frameColor:(UIColor *)frameColor;
+ (UIImage *)scaledImage:(UIImage *)sourceImage toSize:(CGSize)targetSize;
+ (UIImage *)grayBackgroundGradientImageWithStartGray:(CGFloat)startGray endGray:(CGFloat)endGray topLineGray:(CGFloat)topLineGray size:(CGSize)size;
+ (UIImage *)gradientImageWithStartColor:(UIColor *)startColor endColor:(UIColor *)endColor topLineColor:(UIColor *)topLineColor size:(CGSize)size;
+ (UIImage *)gradientImageWithHexColorStrings:(NSString *)startColorString endColorString:(NSString *)endColorString topLineString:(NSString *)topLineString size:(CGSize)size;
@end


@interface UITableView (BCExtras)
- (void)deselectCurrentRow;
@end

@interface UIViewController (BCExtras)
- (void)playMediaAtURL:(NSURL *)url;
- (BOOL)orientationIsPortrait;
- (float)navigationBarHeight;
- (float)tabBarHeight;
- (float)appFrameHeight;
- (float)appFrameWidth;
- (CGRect)appFrame;
@end

@interface UIWebView (NNWExtras)
- (void)releaseSafelyToWorkAroundOddWebKitCrashes;
@end

