/*
 RSFoundationExtras.h
 RSCore
 
 Created by Brent Simmons on Mon May 24 2010.
 Copyright (c) 2010 NewsGator Technologies, Inc. All rights reserved.
 */


#import <Foundation/Foundation.h>
#import <pthread.h>


/*This file and the .m are both really huge because Objective-C, categories, and static libraries don't play well together.
 This is our work-around to get all the categories to load.*/


#pragma mark Paths

NSString *RSAppName(void); //kCFBundleNameKey in Info.plist
NSString *RSAppIdentifier(void); //kCFBundleIdentifierKey in Info.plist, like com.newsgator.NetNewsWire


/****** DEPRECATED - DON'T USE - SEE RSAppDelegateProtocols.h ******/
void RSSetAppName(NSString *appName); //In case you don't want to use Info.plist. Call this early.


/*On iPhone OS, checks for NSApplicationSupportDirectory and uses NSDocumentDirectory.
 Calls NSSearchPathForDirectoriesInDomains with domainMask as NSUserDomainMask and expandTilde as YES.
 NSSearchPathForDirectoriesInDomains returns an array: this returns first object in array. */
NSString *RSUserDirectoryPath(NSSearchPathDirectory directory);

NSString *RSAppSupportFolderPath(void); //Mac: ~/Library/Application Support/appName/ iPhone: Documents/
NSString *RSAppSupportFilePath(NSString *filename); //Mac: ~/Library/Application Support/appName/filename iPhone: Documents/filename
//#if !TARGET_OS_IPHONE
//NSString *RSEnsureAppSupportSubFolderExists(NSString *folderName);
//#endif
/*~/Library/Caches/ -- not tested on iOS*/
											
//#if !TARGET_OS_IPHONE
////NSString *RSCacheFolder(BOOL createIfNeeded); //~/Library/Caches
////NSString *RSCacheFolderForApp(BOOL createIfNeeded); //~/Library/Caches/appName
////NSString *RSCacheFolderForAppSubFolder(NSString *subfolderName, BOOL createIfNeeded); //~/Library/Caches/appName/subfolderName
//#endif
/****** END OF DEPRECATED AREA ******/


#pragma mark -
#pragma mark Geometry

CGRect CGRectCenteredHorizontallyInRect(CGRect rectToCenter, CGRect containingRect);
CGRect CGRectCenteredVerticallyInRect(CGRect rectToCenter, CGRect containingRect);
CGRect CGRectCenteredInRect(CGRect rectToCenter, CGRect containingRect);

void RSLogCGRect(CGRect aRect, NSString *messageStart); //prints (via NSLog) a CGRect as a dictionary


#pragma mark -
#pragma mark NSObject

BOOL RSIsEmpty(id obj); //Arrays, dictionaries, data, etc. Nil is empty and 0-length or 0-count things are empty.

@interface NSObject (RSCore)

- (void)rs_enqueueNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo;
- (void)rs_postNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo;

@end


#pragma mark -
#pragma mark Keys

/*Common keys needed for NSDictionary -- particular in userInfo dictionaries for notifications.*/

extern NSString *RSNameKey;


#pragma mark -
#pragma mark pthread Locking

/*The following four are deprecated. Don't use them.*/
void initLockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage);
void lockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage);
void unlockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage);
void destroyLockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage);

/*Use these. They all return pthread error code. 0 is success, anything else is an error.*/
int RSLockCreateRecursive(pthread_mutex_t *lockToCreate);
int RSLockCreate(pthread_mutex_t *lockToCreate);
int RSLockLock(pthread_mutex_t *lock);
int RSLockUnlock(pthread_mutex_t *lock);
int RSLockDestroy(pthread_mutex_t *lock);
	

#pragma mark -
#pragma mark Total Hack

void RSExchangeImplementations(Class c, SEL orig, SEL new);


#pragma mark -
#pragma mark NSUserDefaults Utilities

void RSPrefsAddObserver(id observer, NSString *key); //don't use this
NSString *RSUserDefaultsPathWithKey(NSString *key); //@"values.%@"
#if !TARGET_OS_IPHONE
NSFont *RSPrefsGetFont(NSString *nameKey, NSString *sizeKey);
NSColor *RSPrefsGetColor(NSString *key); //defaults to white if not in prefs
#endif


#pragma mark -

@interface NSArray (RSCore)

- (id)rs_safeObjectAtIndex:(NSUInteger)anIndex;
- (BOOL)rs_containsObjectIdenticalTo:(id)obj;
- (BOOL)rs_containsAtLeastOneObjectIdenticalToObjectInArray:(NSArray *)otherArray;

- (BOOL)rs_writeToFile:(NSString *)f useBinaryFormat:(BOOL)useBinaryFormat;

@end

BOOL RSWriteArrayOrDictionaryToFileUsingBinaryFormat(NSString *f, id obj);


#pragma mark -
#if !TARGET_OS_IPHONE

@interface NSAttributedString (RSCore)

+ (NSAttributedString *)rs_truncatedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font andUnderlining:(BOOL)flUnderline;
+ (NSAttributedString *)rs_truncatedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font;
+ (NSAttributedString *)rs_truncatedBlueUnderlinedString:(NSString *)s withFont:(NSFont *)font;
+ (NSAttributedString *)rs_truncatedRedUnderlinedString:(NSString *)s withFont:(NSFont *)font;
+ (NSAttributedString *)rs_attributedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font;

+ (NSAttributedString *)rs_attributedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font andBackgroundColor:(NSColor *)backgroundColor;

@end
#endif


#pragma mark -

@interface NSBundle (RSCore)

- (NSString *)rs_pathForResourceWithSuffix:(NSString *)filenameWithSuffix;

@end


#pragma mark -


@interface NSData (RSCore)

+ (NSData *)rs_md5HashWithString:(NSString *)s;
- (NSData *)rs_md5Hash;
- (NSString *)rs_usefulString; //Create a string when encoding isn't known: may not be correct encoding, but useful. May return nil, but probably very rare.
- (NSString *)base64EncodedStringWithLineLength:(NSInteger)lineLength; //0 for no line breaks

- (BOOL)dataIsPNG;

@end


#pragma mark -


typedef enum _RSCalendarGroup {
	RSCalendarFuture,
	RSCalendarToday,
	RSCalendarYesterday,
	RSCalendarDayBeforeYesterday,
	RSCalendarPast,
} RSCalendarGroup;


@interface NSDate (RSCore)

+ (NSDate *)rs_dateWithNumberOfDaysInThePast:(NSUInteger)numberOfDays;
- (NSString *)rs_hourMinuteString; //no date -- just time with kCFDateFormatterShortStyle
- (NSString *)rs_shortDateOnlyString; //no time
- (NSString *)rs_shortDateAndTimeString;
- (NSString *)rs_mediumDateOnlyString;
- (NSString *)rs_mediumTimeOnlyString;
- (NSString *)rs_mediumDateAndTimeString;
- (NSString *)rs_longDateAndTimeString;
- (NSString *)rs_contextualDateString; //hour-minute string if today, otherwise date

- (BOOL)rs_isToday;
- (RSCalendarGroup)rs_calendarGroup;
- (void)rs_year:(NSInteger *)year month:(NSInteger *)month;
- (void)rs_year:(NSInteger *)year month:(NSInteger *)month dayOfMonth:(NSInteger *)dayOfMonth;

- (NSString *)rs_w3cString; //@"yyyy-MM-dd'T'HH:mm:sszzz"
- (NSString *)rs_isoString; //@"yyyy-MM-dd'T'HH:mm:ss'Z'"
- (NSString *)rs_unixTimestampStringWithNoDecimal; //like 1275012558 -- used with Google Reader syncing and OAuth


@end


#pragma mark -


@interface NSDictionary (RSCore)

- (NSString *)rs_httpPostArgsString;

- (BOOL)rs_boolForKey:(NSString *)key;
- (NSInteger)rs_integerForKey:(NSString *)key;
- (double)rs_doubleForKey:(NSString *)key;
- (NSString *)rs_stringForKey:(NSString *)key;

- (BOOL)rs_writeToFile:(NSString *)f useBinaryFormat:(BOOL)useBinaryFormat;

- (id)rs_objectForCaseInsensitiveKey:(NSString *)key; //http headers, for example

@end


#pragma mark -

@interface NSMutableArray (RSCore)

- (void)rs_safeAddObject:(id)obj;
- (void)rs_safeRemoveObjectAtIndex:(NSUInteger)ix;
- (void)rs_addObjectIfNotIdentical:(id)obj;
- (void)rs_addObjectsThatAreNotIdentical:(NSArray *)objectsToAdd;
- (void)rs_addUniqueObject:(id)obj;

+ (NSMutableArray *)rs_mutableArrayWithArray:(NSArray *)originalArray objectsTransformedBySelector:(SEL)aSelector transformer:(id)transformer;


@end


#pragma mark -


@interface NSMutableDictionary (RSCore)

- (void)rs_safeSetObject:(id)obj forKey:(id)key; //If obj or key are nil, does nothing
- (void)rs_setInteger:(NSInteger)anInteger forKey:(id)key;
- (void)rs_setBool:(BOOL)flag forKey:(id)key;

@end


#pragma mark -

@interface NSMutableSet (RSCore)

- (void)rs_addObject:(id)obj;

@end


#pragma mark -

@interface NSMutableString (RSCore)


+ (NSMutableString *)rs_mutableStringWithStrippedHTML:(NSString *)htmlString maxCharacters:(NSUInteger)maxCharacters;

- (void)rs_replaceEntity38WithAmpersand;
- (void)rs_replaceXMLCharacterReferences; //Replace references for <>'"&
- (void)rs_safeAppendString:(NSString *)stringToAppend;
- (void)rs_collapseWhitespace; //Collapses multiple space, \n, \r, and \t to single occurrences and then trims whitespace completely from start and end
- (void)rs_replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement;

+ (NSMutableString *)rs_mutableStringByAddingThreeStrings:(NSString *)s1 s2:(NSString *)s2 s3:(NSString *)s3; //s1, s2, and s3 may be nil. Guaranteed to at least return @""

@end


#pragma mark -

@interface NSNotificationCenter (RSCore)

- (void)rs_postNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo;

@end


#pragma mark -

@interface NSNotificationQueue (RSCore)

- (void)rs_enqueueIdleNotification:(NSNotification *)note;

@end


#pragma mark -

@interface NSNumber (RSCore)

- (NSNumber *)numberIncremented;


@end


#pragma mark -


extern NSString *RSEmptyString; //@""

extern NSString *RSSemicolon; //@";";
extern NSString *RSLtReference; //@"&lt;";
extern NSString *RSLtReferenceDecimal; //@"&#60;";
extern NSString *RSLtReferenceHexUppercase; //@"&#x3C;";
extern NSString *RSLtReferenceHexLowercase; //@"&#x3c;";
extern NSString *RSLeftCaret; //@"<";
extern NSString *RSGtReference; //@"&gt;";
extern NSString *RSGtReferenceDecimal; //@"&#62;";
extern NSString *RSGtReferenceHexUppercase; //@"&#x3E;";
extern NSString *RSGtReferenceHexLowercase; //@"&#x3e;";
extern NSString *RSRightCaret; //@">";
extern NSString *RSQuotReference; //@"&quot;";
extern NSString *RSQuotReferenceDecimal; //@"&#34;";
extern NSString *RSQuotReferenceHex; //@"&#x22;";
extern NSString *RSQuote; //@"\"";
extern NSString *RSAposReference; //@"&apos;";
extern NSString *RSAposReferenceDecimal; //@"&#39;";
extern NSString *RSAposReferenceHex; //@"&#x27;";
extern NSString *RSSingleQuote; //@"'";
extern NSString *RSAmpReference; //@"&amp;";
extern NSString *RSAmpReferenceDecimal; //@"&#38;";
extern NSString *RSAmpReferenceHex; //@"&#x26;";
extern NSString *RSSpaceReference; //@"&nbsp;";
extern NSString *RSSpace; //@" ";
extern NSString *RSDashReference; //@"&mdash;";"
extern NSString *RSDash;  //@"-";
extern NSString *RSLeftDoubleQuote; //@"&ldquo;";
extern NSString *RSRightDoubleQuote; //@"&rdquo;";
extern NSString *RSAmpersand; //@"&";
extern NSString *RSStartHTTP; //@"http://";

BOOL RSStringIsEmpty(NSString *s);
BOOL RSEqualNotEmptyStrings(NSString *x, NSString *y);
BOOL RSEqualStrings(NSString *x, NSString *y); //if both are nil, they're considered equal
NSString *RSStringReplaceAll(NSString *stringToSearch, NSString *searchFor, NSString *replaceWith);
NSDictionary *RSDictionaryFromURLString(NSString *s);
NSString *RSURLWithFeedURL(NSString *s);
BOOL RSURLIsFeedURL(NSString *s);
NSString *RSStringCreateLink(NSString *text, NSString *URL);
NSString *RSAddStrings(NSString *s1, NSString *s2); //either may be nil
NSString *RSStringStripHTML(NSString *htmlString);
NSArray *RSArraySeparatedByFirstInstanceOfCharacter(NSString *s, unichar ch);
NSString *RSStringStartingAfterCharacter(NSString *s, unichar ch);
NSString *RSQueryStringFromURLString(NSString *s);
NSDictionary *RSDictionaryFromURLParametersString(NSString *s);
NSString *RSURLDecodedString(NSString *s);
NSString *RSStringUsefulStringWithData (NSData *d);
NSString *RSStringMailToLinkWithTitleAndBody(NSString *title, NSString *body);
BOOL RSStringIsWebOrFileURLString(NSString *URLString); //http(s) or file
NSString *RSStringByAddingPercentEscapes(NSString *s);
NSUInteger RSStringIndexOfFirstInstanceOfCharacter(NSString *s, unichar ch);


@interface NSString (RSCore)

+ (NSString *)rs_stringWithContentsOfUTF8EncodedFile:(NSString *)filePath;
+ (NSString *)rs_stringWithUTF8EncodedData:(NSData *)data;

- (NSString *)rs_md5HashString;
- (NSString *)rs_stringByStrippingURLQuery; //Will return self if no URL query
- (NSString *)rs_stringByStrippingSuffix:(NSString *)suffix;
- (NSString *)rs_stringByStrippingCaseInsensitiveSuffix:(NSString *)suffix; //Will return self if it doesn't have the suffix
- (NSString *)rs_stringByStrippingPrefix:(NSString *)prefix; //will return self if it doesn't have the suffix
- (NSString *)rs_stringByStrippingCaseInsensitivePrefix:(NSString *)prefix;
- (NSString *)rs_stringByTrimmingCharactersFromEnd:(NSUInteger)numberOfCharactersToTrim; //If numberOfCharactersToTrim is >= length of string, it returns @""
- (BOOL)rs_contains:(NSString *)searchFor;
- (BOOL)rs_caseInsensitiveContains:(NSString *)searchFor;
+ (NSString *)rs_stringByAddingStrings:(NSString *)string1 string2:(NSString *)string2;
- (NSString *)rs_stringByInserting2XSignifier; //Add an @2X in the right place for a URL string
- (NSString *)rs_stringByMakingPlainTextTitle; //Replaces XML character references, collapses whitespace, removes some common HTML
- (NSString *)rs_stringWithURLEncoding;
+ (NSString *)rs_stringWithURLEncodedNameValuePair:(NSString *)name value:(NSString *)value;
+ (NSString *)rs_stringWithURLEncodedNameValuePairsFromDictionarySortedByKey:(NSDictionary *)aDictionary;
+ (NSString *)rs_uuidString;
- (NSString *)rs_stringByTrimmingWhitespace;
- (NSString *)rs_stringByCollapsingWhitespace;
- (NSString *)rs_replaceAll:(NSString *)searchFor with:(NSString *)replaceWith;
- (NSString *)rs_URLStringWithUsernameAndPasswordRemoved;
- (NSString *)rs_substringAfterFirstOccurenceOfString:(NSString *)stringToFind;
- (NSString *)rs_ellipsizeAfterNWords:(NSUInteger)n;
- (NSString *)rs_URLStringSafeForFileSystem;
- (NSString *)rs_stringByReplacingReservedXMLCharactersWithReferences;
+ (NSString *)rs_stringWithStrippedHTML:(NSString *)htmlString maxCharacters:(NSUInteger)maxCharacters;
+ (NSString *)rs_stringWithCollapsedWhitespace:(NSString *)s;
+ (NSString *)rs_stringWithCollapsedNonAlphaNumericCharacters:(NSString *)s;
+ (NSString *)rs_stringWithCollapsedNonNumbericCharacters:(NSString *)s;
- (NSString *)rs_substringToFirstOccurenceOfString:(NSString *)stringToFind;
+ (void)rs_splitFilenameWithSuffix:(NSString *)filenameWithSuffix intoFilename:(NSString **)filenameWithoutSuffix andSuffix:(NSString **)suffix;
- (NSString *)rs_stringByReplacingXMLCharacterReferences;
#pragma mark Gigabyte, Megabyte, Kilobyte strings

+ (NSString *)rs_byteString:(NSUInteger)numberOfBytes;
+ (NSString *)rs_kilobyteString:(NSUInteger)numberOfBytes;
+ (NSString *)rs_megabyteString:(NSUInteger)numberOfBytes;
+ (NSString *)rs_gigabyteString:(NSUInteger)numberOfBytes;

/*Thumbnails -- pulling from HTML*/

- (BOOL)rs_isIgnorableImgURLString; //Don't want things like analytics image trackers
+ (NSString *)rs_firstImgURLStringInHTML:(NSString *)html;

@end


#pragma mark -

@interface NSTimer (RSCore)

/*Invalidating a timer that isn't valid can cause a crash. This makes it easy to avoid.*/
- (void)rs_invalidateIfValid;

@end

