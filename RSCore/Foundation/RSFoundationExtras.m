/*
 RSFoundationExtras.m
 RSCore
 
 Created by Brent Simmons on Mon May 24 2010.
 Copyright (c) 2010 NewsGator Technologies, Inc. All rights reserved.
 */


#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import "RSEntityDecoder.h"
#import "RSFileUtilities.h"
#import "RSFoundationExtras.h"


#pragma mark Paths


static NSString *rs_appName = nil;

NSString *RSAppName(void) {
	if (rs_appName == nil)
		rs_appName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey] retain];
	return rs_appName;
}


static NSString *rs_appIdentifier = nil;

NSString *RSAppIdentifier(void) {
	if (rs_appIdentifier == nil)
		rs_appIdentifier = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey] retain];
	return rs_appIdentifier;
}



/****** DEPRECATED - DON'T USE ANY OF THESE PATH THINGS - INSTEAD SEE RSAppDelegateProtocols.h*/


void RSSetAppName(NSString *appName) {
	[rs_appName autorelease];
	rs_appName = [appName retain];
}


NSString *RSUserDirectoryPath(NSSearchPathDirectory directory) {
#if TARGET_OS_IPHONE
	if (directory == NSApplicationSupportDirectory) //iPhone doesn't have this
		directory = NSDocumentDirectory;
#endif
	return [NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES) rs_safeObjectAtIndex:0];
}



NSString *RSAppSupportFolderPath(void) { //Mac: ~/Library/Application Support/appName/  iPhone: Documents/
	static NSString *appSupportFolder = nil;
	if (appSupportFolder != nil)
		return appSupportFolder;
#if !TARGET_OS_IPHONE
	@synchronized([NSString class]) { //prevent possible race
		NSString *baseFolder = RSUserDirectoryPath(NSApplicationSupportDirectory);
		NSString *appFolder = [baseFolder stringByAppendingPathComponent:RSAppName()];
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:&error];
		appSupportFolder = [appFolder retain];
	}
#else //iPhone
	appSupportFolder = [RSUserDirectoryPath(NSDocumentDirectory) retain];
#endif
	return appSupportFolder;
}


NSString *RSAppSupportFilePath(NSString *filename) {
	return [RSAppSupportFolderPath() stringByAppendingPathComponent:filename];
}


//#if !TARGET_OS_IPHONE
//NSString *RSEnsureAppSupportSubFolderExists(NSString *folderName) {
//	NSString *folderPath = RSAppSupportFilePath(folderName);
//	RSSureFolder(folderPath);
//	return folderPath;
//}
//#endif


/*~/Library/Caches/appName on Macs -- these next three not tested on iOS*/

//#if !TARGET_OS_IPHONE
//NSString *RSCacheFolder(BOOL createIfNeeded) {
//	static NSString *userCacheFolder = nil;
//	if (!userCacheFolder) {
//		
//		NSArray *directories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//		if ([directories count] > 0)
//			userCacheFolder = [[directories objectAtIndex:0] retain];
//		
//		if (RSIsEmpty(userCacheFolder))
//			userCacheFolder = [[@"~/Library/Caches" stringByExpandingTildeInPath] retain];
//	}
//	if (createIfNeeded && !RSFileExists(userCacheFolder))
//		RSFolderCreate(userCacheFolder);
//	return userCacheFolder;
//}
//
//
//NSString *RSCacheFolderForApp(BOOL createIfNeeded) {
//	NSString *cacheFolderForApp = [RSCacheFolder(createIfNeeded) stringByAppendingPathComponent:RSAppName()];
//	if (createIfNeeded && !RSFileExists(cacheFolderForApp))
//		RSFolderCreate(cacheFolderForApp);
//	return cacheFolderForApp;
//}
//
//
//NSString *RSCacheFolderForAppSubFolder(NSString *subfolderName, BOOL createIfNeeded) {
//	NSString *folder = [RSCacheFolderForApp(createIfNeeded) stringByAppendingPathComponent:subfolderName];
//	if (createIfNeeded && !RSFileExists(folder))
//		RSFolderCreate(folder);
//	return folder;
//}
//#endif

/******* END OF DEPRECATION THING ********/


#pragma mark -
#pragma mark Geometry

CGRect CGRectCenteredHorizontallyInRect(CGRect rectToCenter, CGRect containingRect) {
	rectToCenter.origin.x = CGRectGetMidX(containingRect) - (rectToCenter.size.width / 2);
	return rectToCenter;
}


CGRect CGRectCenteredVerticallyInRect(CGRect rectToCenter, CGRect containingRect) {
	rectToCenter.origin.y = CGRectGetMidY(containingRect) - (rectToCenter.size.height / 2);
	return rectToCenter;
}


CGRect CGRectCenteredInRect(CGRect rectToCenter, CGRect containingRect) {
	rectToCenter = CGRectCenteredHorizontallyInRect(rectToCenter, containingRect);
	return CGRectCenteredVerticallyInRect(rectToCenter, containingRect);
}


void RSLogCGRect(CGRect aRect, NSString *messageStart) {
	CFDictionaryRef rectDictionary = CGRectCreateDictionaryRepresentation(aRect);
	NSLog(@"%@ : %@", messageStart, (id)rectDictionary);
	[NSMakeCollectable(rectDictionary) autorelease];
//	CFRelease(rectDictionary);
}


#pragma mark -
#pragma mark Objects

BOOL RSIsEmpty(id obj) {
	return obj == nil || ([obj respondsToSelector:@selector(length)] && [(NSData *)obj length] == 0) || ([obj respondsToSelector:@selector(count)] && [obj count] == 0);
}


@implementation NSObject (RSCore)

- (void)rs_enqueueNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo {
	/*Uses NSNotificationQueue to post a potentially-coalesced notification. obj should normall be nil or self, and userInfo should usually be nil, to get the benefit of coalescing.*/
	NSNotification *note = [NSNotification notificationWithName:notificationName object:obj userInfo:userInfo];
	if ([NSThread isMainThread])
		[[NSNotificationQueue defaultQueue] rs_enqueueIdleNotification:note];
	else		
		[[NSNotificationQueue defaultQueue] performSelectorOnMainThread:@selector(rs_enqueueIdleNotification:) withObject:note waitUntilDone:NO];
}


- (void)rs_postNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo {
	/*Legacy; deprecated. Better to call [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread...*/
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:notificationName object:obj userInfo:userInfo];
}

@end


#pragma mark -
#pragma mark Keys

/*Common keys needed for NSDictionary -- particular in userInfo dictionaries for notifications.*/

NSString *RSNameKey = @"name";


#pragma mark -
#pragma mark pthread Locking

static void logAndExit(NSString *exitLogMessage) {
	NSLog(@"%@", exitLogMessage);
	exit(-1);					
}


void initLockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage) {
	if (pthread_mutex_init(mutexLock, nil) != 0)
		logAndExit(exitLogMessage);
}

void lockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage) {
	if (pthread_mutex_lock(mutexLock) != 0)
		logAndExit(exitLogMessage);
}


void unlockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage) {
	if (pthread_mutex_unlock(mutexLock) != 0)
		logAndExit(exitLogMessage);
}


void destroyLockOrExit(pthread_mutex_t *mutexLock, NSString *exitLogMessage) {
	if (pthread_mutex_destroy(mutexLock) != 0)
		logAndExit(exitLogMessage);
}


int RSLockCreateRecursive(pthread_mutex_t *lockToCreate) {
	pthread_mutexattr_t lockAttributes;
	int pthreadErrorCode = pthread_mutexattr_init(&lockAttributes);
	if (pthreadErrorCode != 0)
		return pthreadErrorCode;
	pthread_mutexattr_settype(&lockAttributes, PTHREAD_MUTEX_RECURSIVE);
	pthreadErrorCode = pthread_mutex_init(lockToCreate, &lockAttributes);
	pthread_mutexattr_destroy(&lockAttributes);
	return pthreadErrorCode;
}


int RSLockCreate(pthread_mutex_t *lockToCreate) {
	return pthread_mutex_init(lockToCreate, NULL);
}


int RSLockLock(pthread_mutex_t *lock) {
	return pthread_mutex_lock(lock);
}


int RSLockUnlock(pthread_mutex_t *lock) {
	return pthread_mutex_unlock(lock);
}


int RSLockDestroy(pthread_mutex_t *lock) {
	return pthread_mutex_destroy(lock);
}


#pragma mark -
#pragma mark Total Hack

void RSExchangeImplementations(Class c, SEL orig, SEL new) {
	/* http://www.cocoadev.com/index.pl?MethodSwizzling
	 Don't use this. This is only for the navbar -- it's the only way to over-ride drawRect,
	 since we can't set up a navbar subclass programatically. (You can do so in IB,
	 but you can't do it programatically.)*/
	Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
		method_exchangeImplementations(origMethod, newMethod);	
}


#pragma mark -
#pragma mark NSUserDefaults Utilities

NSString *RSUserDefaultsPathWithKey(NSString *key) {
	return RSAddStrings(@"values.", key);
}

#if !TARGET_OS_IPHONE
void RSPrefsAddObserver(id observer, NSString *key) {
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:observer forKeyPath:RSUserDefaultsPathWithKey(key) options:0 context:nil];
}
#endif

#if !TARGET_OS_IPHONE
NSFont *RSPrefsGetFont(NSString *nameKey, NSString *sizeKey) {
	NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:nameKey];
	float fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:sizeKey];//RSPrefsGetFloat(sizeKey);
	if (fontSize < 6.0f)
		fontSize = 11.0f;
	NSFont *font = nil;
	if (!RSIsEmpty(fontName))
		font = [NSFont fontWithName:fontName size:(CGFloat)fontSize];
	if (!font)
		font = [NSFont systemFontOfSize:(CGFloat)fontSize];
	if (!font)
		font = [NSFont systemFontOfSize:11.0f];
	if (!font)
		font = [NSFont fontWithName:@"Lucida Grande" size:11.0f];
	return font;	
}


NSColor *RSPrefsGetColor(NSString *key) {
	NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	if (colorData == nil)
		return [NSColor whiteColor];
	return [NSUnarchiver unarchiveObjectWithData:colorData];
}
#endif


#pragma mark -

BOOL RSWriteArrayOrDictionaryToFileUsingBinaryFormat(NSString *f, id obj) {
	
	if (RSIsEmpty(f))
		return NO;
	if (![obj isKindOfClass:[NSDictionary class]] && ![obj isKindOfClass:[NSArray class]])
		return NO;
	
	@synchronized([NSDictionary class]) {
		CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)f, kCFURLPOSIXPathStyle, FALSE);
		CFWriteStreamRef stream = CFWriteStreamCreateWithFile(NULL, fileURL);
		if (!stream)
			goto fileURL_cleanup;
		if (!CFWriteStreamOpen(stream))
			goto stream_cleanup;
		(void)CFPropertyListWriteToStream(obj, stream, kCFPropertyListBinaryFormat_v1_0, NULL);
		CFWriteStreamClose(stream);
		
	stream_cleanup:
		CFRelease(stream);
	fileURL_cleanup:
		CFRelease(fileURL);
	}
	
	return YES;
}


@implementation NSArray (RSCore)

- (id)rs_safeObjectAtIndex:(NSUInteger)anIndex {
	if ([self count] < 1 || anIndex >= [self count])
		return nil;
	return [self objectAtIndex:anIndex];
}


- (BOOL)rs_containsObjectIdenticalTo:(id)obj {
	return obj != nil && [self indexOfObjectIdenticalTo:obj] != NSNotFound;
}


- (BOOL)rs_writeToFile:(NSString *)f useBinaryFormat:(BOOL)useBinaryFormat {
	if (useBinaryFormat)
		return RSWriteArrayOrDictionaryToFileUsingBinaryFormat(f, self);
	return [self writeToFile:f atomically:YES];
}


- (BOOL)rs_containsAtLeastOneObjectIdenticalToObjectInArray:(NSArray *)otherArray {
	if (RSIsEmpty(otherArray))
		return NO;
	NSUInteger i = 0, ct = [self count];
	for (i = 0; i < ct; i++) {
		if ([otherArray rs_containsObjectIdenticalTo:[self objectAtIndex:i]])
			return YES;
	}
	return NO;	
}


@end


#pragma mark -

#if !TARGET_OS_IPHONE

@implementation NSAttributedString (RSCore)

+ (NSAttributedString *)rs_truncatedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font 
							andUnderlining:(BOOL)flUnderline {
	
	/*Ellipsizes a string. If color is nil, then no color is set.
	 If font is nil, then the font is system font of size 11.0.*/
	
	NSMutableDictionary *atts = [NSMutableDictionary dictionary];
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSFont *fontToUse = font;
	
	[atts setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	
	if (fontToUse == nil)
		fontToUse = [NSFont systemFontOfSize:11.0f];
	[atts setObject:fontToUse forKey:NSFontAttributeName];
	
	if (color != nil)
		[atts setObject:color forKey:NSForegroundColorAttributeName];
	
	if (flUnderline)
		[atts setObject:[NSNumber numberWithInteger:1] forKey:NSUnderlineStyleAttributeName];
	return [[[NSAttributedString alloc] initWithString:s attributes:atts] autorelease];
}


+ (NSAttributedString *)rs_truncatedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font {
	return [self rs_truncatedString:s withColor:color andFont:font andUnderlining:NO];
}


+ (NSAttributedString *)rs_truncatedBlueUnderlinedString:(NSString *)s withFont:(NSFont *)font {
	/*For strings that look like links.*/	
	return [self rs_truncatedString:s withColor:[NSColor blueColor] andFont:font andUnderlining:YES];
}


+ (NSAttributedString *)rs_truncatedRedUnderlinedString:(NSString *)s withFont:(NSFont *)font {
	/*The mouse-down state of links.*/	
	return [self rs_truncatedString:s withColor:[NSColor redColor] andFont:font andUnderlining:YES];
}


+ (NSAttributedString *)rs_attributedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font {
	
	NSMutableDictionary *atts = [NSMutableDictionary dictionaryWithCapacity:2];
	NSFont *fontToUse = font;
	
	if (fontToUse == nil)
		fontToUse = [NSFont systemFontOfSize:11.0];
	[atts setObject:fontToUse forKey:NSFontAttributeName];
	
	if (color != nil)
		[atts setObject:color forKey:NSForegroundColorAttributeName];
	
	return [[[NSAttributedString alloc] initWithString:s attributes:atts] autorelease];
}


+ (NSAttributedString *)rs_attributedString:(NSString *)s withColor:(NSColor *)color andFont:(NSFont *)font andBackgroundColor:(NSColor *)backgroundColor {	
	NSMutableDictionary *atts = [NSMutableDictionary dictionaryWithCapacity:3];
	[atts setObject:font ? font : [NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
	if (color)
		[atts setObject:color forKey:NSForegroundColorAttributeName];
	if (backgroundColor)
		[atts setObject:backgroundColor forKey:NSBackgroundColorAttributeName];
	return [[[NSAttributedString alloc] initWithString:s attributes:atts] autorelease];
}



@end

#endif


#pragma mark -

@implementation NSBundle (RSCore)

- (NSString *)rs_pathForResourceWithSuffix:(NSString *)filenameWithSuffix {
	NSString *filenameWithoutSuffix = nil;
	NSString *suffix = nil;
	[NSString rs_splitFilenameWithSuffix:filenameWithSuffix intoFilename:&filenameWithoutSuffix andSuffix:&suffix];
	return [self pathForResource:filenameWithoutSuffix ofType:suffix];
}


@end


#pragma mark -

@implementation NSData (RSCore)

+ (NSData *)rs_md5HashWithString:(NSString *)s {
	const char *utf8String = [s UTF8String];
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	CC_MD5(utf8String, (CC_LONG)strlen(utf8String), hash);
	return [NSData dataWithBytes:(const void *)hash length:CC_MD5_DIGEST_LENGTH];	
}


- (NSData *)rs_md5Hash {
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	CC_MD5([self bytes], (CC_LONG)[self length], hash);
	return [NSData dataWithBytes:(const void *)hash length:CC_MD5_DIGEST_LENGTH];		
}


- (NSString *)rs_usefulString {
	
	/*Used by parsers to get a useful string given the data. It may not be the *perfect*
	 string encoding -- but at least a useful string encoding, so that you can actually
	 look inside the string and find what the encoding is supposed to be.
	 May return nil.*/
	
	NSString *s = nil;
	if ([self length] > 2) { /*Check for UTF-16 BOM*/
		
		unsigned char firstChar = 0, secondChar = 0;
		BOOL isUnicode = NO;		
		[self getBytes:&firstChar range:NSMakeRange (0, 1)];
		[self getBytes:&secondChar range:NSMakeRange (1, 1)];		
		if (firstChar == 0xff && secondChar == 0xfe)
			isUnicode = YES;
		else if (firstChar == 0xfe && secondChar == 0xff)
			isUnicode = YES;		
		if (isUnicode)
			s = [[[NSString alloc] initWithData:self encoding:NSUnicodeStringEncoding] autorelease];
		if (s != nil)
			return s;
	}
	
	s = [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSISOLatin1StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSMacOSRomanStringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSASCIIStringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSWindowsCP1251StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSWindowsCP1252StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSWindowsCP1253StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSWindowsCP1254StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:self encoding:NSWindowsCP1250StringEncoding] autorelease];
	return s;
}


static char base64EncodingTable [64] = {
	'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
	'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
	'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',	
	'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
};


- (NSString *)base64EncodedStringWithLineLength:(NSInteger)lineLength {
	
	/*This code was adapted from code written by Dave Winer and posted here:  http://www.scripting.com/midas/base64/source.html */
	
	/*
	 [Dave's original comments...]
	 encode the handle. some funny stuff about linelength -- it only makes
	 sense to make it a multiple of 4. if it's not a multiple of 4, we make it
	 so (by only checking it every 4 characters. 
	 
	 further, if it's 0, we don't add any line breaks at all.
	 */
	
	NSUInteger ixtext = 0;
	NSUInteger lentext = [self length];
	if (lentext < 1)
		return @"";
	NSUInteger ctremaining;
	unsigned char inbuf [3], outbuf [4];
	unsigned short i;
	unsigned short charsonline = 0, ctcopy;
	const unsigned char *rawData = [self bytes];
	NSMutableString *encodedString = [NSMutableString stringWithCapacity:lentext * 2]; //encoding expands 	
	
	while (true) {
		
		ctremaining = lentext - ixtext;		
		if (ctremaining <= 0)
			break;
		
		for (i = 0; i < 3; i++) { 
			unsigned long ix = ixtext + i;			
			if (ix < lentext)
				inbuf [i] = rawData [ix];
			else
				inbuf [i] = 0;
		}
		
		outbuf [0] = (inbuf [0] & 0xFC) >> 2;		
		outbuf [1] = (unsigned char)((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);		
		outbuf [2] = (unsigned char)((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
		outbuf [3] = inbuf [2] & 0x3F;		
		ctcopy = 4;
		if (ctremaining == 1)
			ctcopy = 2;
		else if (ctremaining == 2)
			ctcopy = 3;
		
		for (i = 0; i < ctcopy; i++) {
			NSString *charString = [NSString stringWithFormat: @"%c", base64EncodingTable [outbuf [i]]];			
			[encodedString appendString: charString];
		}		
		
		static const unichar equalsCharacter = '=';
		for (i = ctcopy; i < 4; i++)
			CFStringAppendCharacters((CFMutableStringRef)encodedString, &equalsCharacter, 1);
		
		ixtext += 3;		
		charsonline += 4;
		
		static const unichar lineFeedCharacter = '\n';		
		if (lineLength > 0) { /*DW 4/8/97 -- 0 means no line breaks*/			
			if (charsonline >= lineLength) {				
				charsonline = 0;				
				CFStringAppendCharacters((CFMutableStringRef)encodedString, &lineFeedCharacter, 1);
				//[encodedString appendString:@"\n"];
			}
		}
	}
	
	return encodedString;
}


- (BOOL)dataIsPNG {
	/* http://www.w3.org/TR/PNG/#5PNG-file-signature : "The first eight bytes of a PNG datastream always contain the following (decimal) values: 137 80 78 71 13 10 26 10" */
	const unsigned char *bytes = (const unsigned char *)[self bytes];
	return bytes[0] == 137 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G' && bytes[4] == 13 && bytes[5] == 10 && bytes[6] == 26 && bytes[7] == 10;	
}


@end


#pragma mark -


@implementation NSDate(RSCore)

+ (NSDate *)rs_dateWithNumberOfDaysInThePast:(NSUInteger)numberOfDays {
	NSTimeInterval ti = 60 * 60 * 24 * numberOfDays;
	return [NSDate dateWithTimeIntervalSinceNow:-(ti)];
}


- (NSString *)rs_hourMinuteString {
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
	}
	return [dateFormatter stringFromDate:self];	
}


- (NSString *)rs_shortDateOnlyString {
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterNoStyle];
	}
	return [dateFormatter stringFromDate:self];		
}


- (NSString *)rs_shortDateAndTimeString {
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
	}
	return [dateFormatter stringFromDate:self];		
}


- (NSString *)rs_mediumDateOnlyString {
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:kCFDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterNoStyle];
	}
	return [dateFormatter stringFromDate:self];		
}


- (NSString *)rs_mediumTimeOnlyString {
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterMediumStyle];
	}
	return [dateFormatter stringFromDate:self];		
}


- (NSString *)rs_mediumDateAndTimeString {
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:kCFDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterMediumStyle];
	}
	return [dateFormatter stringFromDate:self];		
}


- (NSString *)rs_longDateAndTimeString {
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:kCFDateFormatterLongStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterLongStyle];
	}
	return [dateFormatter stringFromDate:self];		
}


- (NSString *)rs_contextualDateString {
	if ([self rs_isToday])
		return [self rs_hourMinuteString];
	return [self rs_mediumDateOnlyString];
}


- (BOOL)rs_isToday {
	return [self rs_calendarGroup] == RSCalendarToday;
}


static NSCalendar *rs_cachedCalendar(void) {
	static NSCalendar *cachedCalendar = nil;
	if (cachedCalendar == nil)
		cachedCalendar = [[NSCalendar currentCalendar] retain];
	return cachedCalendar;
}


- (RSCalendarGroup)rs_calendarGroup {
	
	/*Returns one of:
	 RSCalendarFuture,
	 RSCalendarToday,d
	 RSCalendarYesterday,
	 RSCalendarDayBeforeYesterday,
	 RSCalendarPast
	 
	 Does caching because date calculations are *very* expensive, especially on iPhone.
	 Will be wrong for a maximum of 30 seconds at midnight every day.*/
	
	static NSDate *tomorrow = nil;
	static NSDate *today = nil;
	static NSDate *yesterday = nil;
	static NSDate *dayBeforeYesterday = nil;
	@synchronized([NSDate class]) {
		static NSDate *lastUpdate = nil;
		NSDate *now = [NSDate date];
		if (today == nil || lastUpdate == nil || [now timeIntervalSinceDate:lastUpdate] > 30) { //update cached dates for today, yesterday, day before yesterday
			NSDateComponents *todayComponents = [rs_cachedCalendar() components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
			static NSInteger todayDay = 0;
			if (today == nil || todayDay != [todayComponents day]) {
				todayDay = [todayComponents day];
				[today release];
				today = [[rs_cachedCalendar() dateFromComponents:todayComponents] retain];
				static NSDateComponents *oneDayAgoIntervalDateComponents = nil;
				if (oneDayAgoIntervalDateComponents == nil) {
					oneDayAgoIntervalDateComponents = [[NSDateComponents alloc] init];
					[oneDayAgoIntervalDateComponents setDay:-1];
				}
				[yesterday release];
				yesterday = [[rs_cachedCalendar() dateByAddingComponents:oneDayAgoIntervalDateComponents toDate:today options:0] retain];
				[dayBeforeYesterday release];
				dayBeforeYesterday = [[rs_cachedCalendar() dateByAddingComponents:oneDayAgoIntervalDateComponents toDate:yesterday options:0] retain];
				static NSDateComponents *oneDayFutureIntervalDateComponents = nil;
				if (oneDayFutureIntervalDateComponents == nil) {
					oneDayFutureIntervalDateComponents = [[NSDateComponents alloc] init];
					[oneDayFutureIntervalDateComponents setDay:1];
				}
				[tomorrow release];
				tomorrow = [[rs_cachedCalendar() dateByAddingComponents:oneDayFutureIntervalDateComponents toDate:today options:0] retain];
			}
		}
		[lastUpdate release];
		lastUpdate = [now retain];
	}
	NSComparisonResult comparisonResult = [self compare:tomorrow];
	if (comparisonResult == NSOrderedSame || comparisonResult == NSOrderedDescending)
		return RSCalendarFuture;
	comparisonResult = [self compare:today];
	if (comparisonResult == NSOrderedSame || comparisonResult == NSOrderedDescending)
		return RSCalendarToday;
	comparisonResult = [self compare:yesterday];
	if (comparisonResult == NSOrderedSame || comparisonResult == NSOrderedDescending)
		return RSCalendarYesterday;
	comparisonResult = [self compare:dayBeforeYesterday];
	if (comparisonResult == NSOrderedSame || comparisonResult == NSOrderedDescending)
		return RSCalendarDayBeforeYesterday;
	return RSCalendarPast;
}


- (void)rs_year:(NSInteger *)year month:(NSInteger *)month {
	NSDateComponents *dateComponents = [rs_cachedCalendar() components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:self];
	*year = [dateComponents year];
	*month = [dateComponents month];
}


- (void)rs_year:(NSInteger *)year month:(NSInteger *)month dayOfMonth:(NSInteger *)dayOfMonth {
	NSDateComponents *dateComponents = [rs_cachedCalendar() components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
	*year = [dateComponents year];
	*month = [dateComponents month];
	*dayOfMonth = [dateComponents day];
}



- (NSString *)rs_w3cString {
	static NSDateFormatter *w3cDateFormatter = nil;
	@synchronized([NSDate class]) {
		if (w3cDateFormatter == nil) {
			w3cDateFormatter = [[NSDateFormatter alloc] init];
			[w3cDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
			[w3cDateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
			[w3cDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:sszzz"];
		}
	}
	return [w3cDateFormatter stringFromDate:self];
}


- (NSString *)rs_isoString {
	/*Much like rs_w3cString, but time zone is GMT.*/
	static NSDateFormatter *dateFormatter = nil;
	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
		[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
	}
	return [dateFormatter stringFromDate:self];
}


- (NSString *)rs_unixTimestampStringWithNoDecimal {
	return [NSString stringWithFormat:@"%.0f", [self timeIntervalSince1970]]; //formatting means no decimal
}


@end


#pragma mark -


@implementation NSDictionary (RSCore)

- (void)rs_addHTTPPostArgValue:(NSString *)value key:(NSString *)key index:(NSInteger *)ix toString:(NSMutableString *)s {
	if (*ix > 0)
		[s appendString:@"&"];
	*ix = *ix + 1;
	[s appendString:key];
	[s appendString:@"="];
	CFStringRef urlEncodedString = CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)value, nil, CFSTR("%=&/:+?#$,;@ "), kCFStringEncodingUTF8);
	[s appendString:(NSString *)urlEncodedString];
	CFRelease(urlEncodedString);	
}


- (void)rs_addHTTPPostArgsArray:(NSArray *)anArray key:(NSString *)key index:(NSInteger *)ix toString:(NSMutableString *)s {
	for (NSString *oneValue in anArray)
		[self rs_addHTTPPostArgValue:oneValue key:key index:ix toString:s];
}


- (NSString *)rs_httpPostArgsString {
	NSMutableString *s = [NSMutableString stringWithString:@""];
	NSInteger ix = 0;
	for (NSString *oneKey in self) {
		id obj = [self objectForKey:oneKey];
		if ([obj isKindOfClass:[NSArray class]])
			[self rs_addHTTPPostArgsArray:obj key:oneKey index:&ix toString:s];
		else
			[self rs_addHTTPPostArgValue:obj key:oneKey index:&ix toString:s];
	}
	return s;	
}

- (BOOL)rs_boolForKey:(NSString *)key {
	id obj = [self objectForKey:key];
	if (obj == nil || obj == (id)kCFBooleanFalse)
		return NO;	
	if (obj == (id)kCFBooleanTrue)
		return YES;
	
	if ([obj isKindOfClass:[NSString class]]) {
		NSString *s = [obj lowercaseString];
		if ([s isEqualToString:@"yes"] || [s isEqualToString:@"true"])
			return YES;
	}
	if ([obj respondsToSelector:@selector(integerValue)])
		return (BOOL)[obj integerValue];
	
	return NO;
}


- (NSInteger)rs_integerForKey:(NSString *)key {
	return [[self objectForKey:key] integerValue];
}


- (double)rs_doubleForKey:(NSString *)key {
	return [[self objectForKey:key] doubleValue];
}


- (NSString *)rs_stringForKey:(NSString *)key {	
	id s = [self objectForKey:key];
	if (s == nil)
		return nil;
	if ([s isKindOfClass:[NSString class]])
		return s;
	if ([s respondsToSelector:@selector(stringValue)])
		return [s stringValue];
	return nil;
}


- (BOOL)rs_writeToFile:(NSString *)f useBinaryFormat:(BOOL)useBinaryFormat {
	if (useBinaryFormat)
		return RSWriteArrayOrDictionaryToFileUsingBinaryFormat(f, self);
	return [self writeToFile:f atomically:YES];
}


- (id)rs_objectForCaseInsensitiveKey:(NSString *)key {
	/*Things like HTTP headers are often case-insensitive.*/
	id anObject = [self objectForKey:key];
	if (anObject != nil)
		return anObject;
	NSString *lowercaseKey = [key lowercaseString];
	for (NSString *oneKey in self) {
		if ([lowercaseKey isEqualToString:[oneKey lowercaseString]])
			return [self objectForKey:oneKey];
	}
	return nil;
}


@end


#pragma mark -

@implementation NSMutableArray (RSCore)

- (void)rs_safeAddObject:(id)obj {
	if (obj != nil)
		[self addObject:obj];
}


- (void)rs_safeRemoveObjectAtIndex:(NSUInteger)ix {	
	if (ix < [self count])
		[self removeObjectAtIndex:ix];	
}


- (void)rs_addObjectIfNotIdentical:(id)obj {
	if (obj != nil && [self indexOfObjectIdenticalTo:obj] == NSNotFound)
		[self addObject:obj];
}


- (void)rs_addObjectsThatAreNotIdentical:(NSArray *)objectsToAdd {
	if (RSIsEmpty(objectsToAdd))
		return;
	if ([self count] < 1) {
		[self addObjectsFromArray:objectsToAdd];
		return;
	}
	for (id oneObject in objectsToAdd) {
		if (![self rs_containsObjectIdenticalTo:oneObject])
		  [self addObject:oneObject];
	}
}


- (void)rs_addUniqueObject:(id)obj {
	if (obj != nil && ![self containsObject:obj])
		[self addObject:obj];
}


+ (NSMutableArray *)rs_mutableArrayWithArray:(NSArray *)originalArray objectsTransformedBySelector:(SEL)aSelector transformer:(id)transformer {
	if (RSIsEmpty(originalArray))
		return nil;
	NSUInteger i;
	NSUInteger ct = [originalArray count];
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:ct];
	for (i = 0; i < ct; i++)
		[tempArray rs_safeAddObject:[transformer performSelector:aSelector withObject:[originalArray objectAtIndex:i]]];
	return tempArray;	
}


@end


#pragma mark -

@implementation NSMutableDictionary (RSCore)

- (void)rs_safeSetObject:(id)obj forKey:(id)key {
	if (obj == nil || key == nil)
		return;
	[self setObject:obj forKey:key];
}


- (void)rs_setInteger:(NSInteger)anInteger forKey:(id)key {
	[self setObject:[NSNumber numberWithInteger:anInteger] forKey:key];
}


- (void)rs_setBool:(BOOL)flag forKey:(id)key {
	[self setObject:[NSNumber numberWithBool:flag] forKey:key];
}

@end


#pragma mark -

@implementation NSMutableSet (RSCore)

- (void)rs_addObject:(id)obj {
	if (obj != nil)
		[self addObject:obj];
}

@end


#pragma mark -

@implementation NSMutableString (RSCore)

+ (NSMutableString *)rs_mutableStringWithStrippedHTML:(NSString *)htmlString maxCharacters:(NSUInteger)maxCharacters {
	if (RSStringIsEmpty(htmlString))
		return nil;
	if ([htmlString rangeOfString:RSLeftCaret].location == NSNotFound) {
		if (maxCharacters > 0 && [htmlString length] > maxCharacters)
			return [[[htmlString substringToIndex:maxCharacters] mutableCopy] autorelease];
		return [[htmlString mutableCopy] autorelease];
	}
	
	NSUInteger len = [htmlString length];
	NSMutableString *s = [NSMutableString stringWithCapacity:len];
	NSUInteger i = 0, level = 0;
	BOOL flLastWasSpace = NO;
	unichar ch;
	const unichar chspace = ' ';
	NSUInteger ctCharactersAdded = 0;
	
	for (i = 0; i < len; i++) {		
		ch = [htmlString characterAtIndex:i];		
		if (ch == '<')
			level++;		
		else if (ch == '>') {			
			level--;			
			//if (level == 0)			
			//CFStringAppendCharacters((CFMutableStringRef)s, &chspace, 1);
		}		
		else if (level == 0) {			
			if (ch == ' ' || ch == '\r' || ch == '\t' || ch == '\n') {				
				if (flLastWasSpace)
					continue;
				else
					flLastWasSpace = YES;
				ch = chspace;
			}			
			else
				flLastWasSpace = NO;			
			CFStringAppendCharacters((CFMutableStringRef)s, &ch, 1);
			if (maxCharacters > 0) {
				ctCharactersAdded++;
				if (ctCharactersAdded >= maxCharacters)
					break;
			}
		}			
	}	
	return s;
}


- (void)rs_replaceEntity38WithAmpersand {
	[self replaceOccurrencesOfString:RSAmpReferenceDecimal withString:RSAmpersand options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}


- (void)rs_safeAppendString:(NSString *)stringToAppend {
	if (stringToAppend != nil)
		[self appendString:stringToAppend];
}


static NSString *RSSingleSpace = @" ";
static NSString *rs_lineFeed = @"\n";
static NSString *rs_return = @"\r";
static NSString *rs_tab = @"\t";
static NSString *rs_twoSpaces = @"  ";

- (void)rs_collapseWhitespace {
	/*There is probably a faster way to do this using NSScanner, but let's leave it as-is unless the profiler tells us we need to make it faster.*/
	[self replaceOccurrencesOfString:rs_tab withString:RSSingleSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:rs_return withString:RSSingleSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:rs_lineFeed withString:RSSingleSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	while ([self rangeOfString:rs_twoSpaces options:0].location != NSNotFound)
		[self replaceOccurrencesOfString:rs_twoSpaces withString:RSSingleSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	CFStringTrimWhitespace((CFMutableStringRef)self);	
}


- (void)rs_replaceXMLCharacterReferences {
	if ([self rangeOfString:RSAmpersand].location == NSNotFound || [self rangeOfString:RSSemicolon].location == NSNotFound)
		return;
	[self replaceOccurrencesOfString:RSLtReference withString:RSLeftCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSLtReferenceDecimal withString:RSLeftCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSLtReferenceHexUppercase withString:RSLeftCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSLtReferenceHexLowercase withString:RSLeftCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:RSGtReference withString:RSRightCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSGtReferenceHexUppercase withString:RSRightCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSGtReferenceDecimal withString:RSRightCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSGtReferenceHexLowercase withString:RSRightCaret options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:RSQuotReference withString:RSQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSQuotReferenceDecimal withString:RSQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSQuotReferenceHex withString:RSQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:RSAposReference withString:RSSingleQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSAposReferenceDecimal withString:RSSingleQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSAposReferenceHex withString:RSSingleQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:RSSpaceReference withString:RSSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSDashReference withString:RSDash options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSLeftDoubleQuote withString:RSQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSRightDoubleQuote withString:RSQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];

	[self replaceOccurrencesOfString:RSAmpReference withString:RSAmpersand options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSAmpReferenceDecimal withString:RSAmpersand options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:RSAmpReferenceHex withString:RSAmpersand options:NSLiteralSearch range:NSMakeRange(0, [self length])];	

}


- (void)rs_replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement {
	if (target && replacement)
		[self replaceOccurrencesOfString:target withString:replacement options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}


+ (NSMutableString *)rs_mutableStringByAddingThreeStrings:(NSString *)s1 s2:(NSString *)s2 s3:(NSString *)s3 {
	NSMutableString *s = [NSMutableString stringWithString:RSEmptyString];
	[s rs_safeAppendString:s1];
	[s rs_safeAppendString:s2];
	[s rs_safeAppendString:s3];
	return s;
}


@end


#pragma mark -

@implementation NSNotificationCenter (RSCore)

- (void)rs_postNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo {
	[self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:notificationName object:obj userInfo:userInfo] waitUntilDone:NO];	
}

@end

#pragma mark -

@implementation NSNotificationQueue (RSCore)

- (void)rs_enqueueIdleNotification:(NSNotification *)note {
	[self enqueueNotification:note postingStyle:NSPostWhenIdle];
}

@end


#pragma mark -

@implementation NSNumber (RSCore)


- (NSNumber *)numberIncremented {
	return [NSNumber numberWithInteger:[self integerValue] + 1];
}


@end


#pragma mark -

BOOL RSStringIsEmpty(NSString *s) {
	return s == nil || [s length] == 0;
}


BOOL RSEqualNotEmptyStrings(NSString *x, NSString *y) {
	return !RSStringIsEmpty(x) && !RSStringIsEmpty(y) && [x isEqualToString:y];
}


BOOL RSEqualStrings(NSString *x, NSString *y) {
	if ((x == nil && y == nil) || (x == y))
		return YES;
	return x != nil && y != nil && [x isEqualToString:y];
}


NSString *RSStringReplaceAll(NSString *stringToSearch, NSString *searchFor, NSString *replaceWith) {
	if (stringToSearch == nil)
		return nil;
	if (searchFor == nil || replaceWith == nil)
		return stringToSearch;
	NSMutableString *newString = [[stringToSearch mutableCopy] autorelease];
	[newString replaceOccurrencesOfString:searchFor withString:replaceWith options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
	return newString;
}


NSString *RSStringCreateLink(NSString *text, NSString *URL) {
	return [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", URL, text];
}


NSString *RSAddStrings(NSString *s1, NSString *s2) {
	if (s1 == nil)
		return s2;
	if (s2 == nil)
		return s1;
	return [NSString rs_stringByAddingStrings:s1 string2:s2];
}


NSString *RSEmptyString = @"";

NSString *RSSemicolon = @";";
NSString *RSLtReference = @"&lt;";
NSString *RSLtReferenceDecimal = @"&#60;";
NSString *RSLtReferenceHexUppercase = @"&#x3C;";
NSString *RSLtReferenceHexLowercase = @"&#x3c;";
NSString *RSLeftCaret = @"<";
NSString *RSGtReference = @"&gt;";
NSString *RSGtReferenceDecimal = @"&#62;";
NSString *RSGtReferenceHexUppercase = @"&#x3E;";
NSString *RSGtReferenceHexLowercase = @"&#x3e;";
NSString *RSRightCaret = @">";
NSString *RSQuotReference = @"&quot;";
NSString *RSQuotReferenceDecimal = @"&#34;";
NSString *RSQuotReferenceHex = @"&#x22;";
NSString *RSQuote = @"\"";
NSString *RSAposReference = @"&apos;";
NSString *RSAposReferenceDecimal = @"&#39;";
NSString *RSAposReferenceHex = @"&#x27;";
NSString *RSSingleQuote = @"'";
NSString *RSAmpReference = @"&amp;";
NSString *RSAmpReferenceDecimal = @"&#38;";
NSString *RSAmpReferenceHex = @"&#x26;";
NSString *RSSpaceReference = @"&nbsp;";
NSString *RSSpace = @" ";
NSString *RSDashReference = @"&mdash;";
NSString *RSDash = @"-";
NSString *RSLeftDoubleQuote = @"&ldquo;";
NSString *RSRightDoubleQuote = @"&rdquo;";
NSString *RSAmpersand = @"&";
NSString *RSStartHTTP = @"http://";


@implementation NSString (RSCore)

+ (NSString *)rs_stringWithContentsOfUTF8EncodedFile:(NSString *)filePath {
	/*Try to read it one way or another*/
	NSError *error = nil;
	NSStringEncoding encoding = NSUTF8StringEncoding;
	NSString *s = [NSString stringWithContentsOfFile:filePath encoding:encoding error:&error];
	if (error)
		s = [NSString stringWithContentsOfFile:filePath usedEncoding:&encoding error:&error];
	return s;
}


+ (NSString *)rs_stringWithUTF8EncodedData:(NSData *)data {
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}


- (NSString *)rs_md5HashString {
	const char *utf8String = [self UTF8String];
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	CC_MD5(utf8String, (CC_LONG)strlen(utf8String), hash);
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", hash[0], hash[1], hash[2], hash[3], hash[4], hash[5], hash[6], hash[7], hash[8], hash[9], hash[10], hash[11], hash[12], hash[13], hash[14], hash[15]];	
}


static NSString *rs_questionMark = @"?";

- (NSString *)rs_stringByStrippingURLQuery {
	if ([self rangeOfString:rs_questionMark options:0].location == NSNotFound)
		return self;
	NSArray *stringComponents = [self componentsSeparatedByString:rs_questionMark];
	NSInteger i;
	NSInteger ct = (NSInteger)[stringComponents count] - 1;
	NSMutableString *newString = [NSMutableString stringWithString:RSEmptyString];
	for (i = 0; i < ct; i++) {
		[newString appendString:[stringComponents objectAtIndex:(NSUInteger)i]];
		if (i < ct - 1)
			[newString appendString:rs_questionMark];
	}
	return newString;
}


- (NSString *)rs_stringByStrippingSuffix:(NSString *)suffix {
	if (![self hasSuffix:suffix])
		return self;
	return [self substringToIndex:[self length] - [suffix length]];
}


- (NSString *)rs_stringByStrippingCaseInsensitiveSuffix:(NSString *)suffix {
	if (![[self lowercaseString] hasSuffix:[suffix lowercaseString]])
		return self;
	return [self substringToIndex:[self length] - [suffix length]];
}


- (NSString *)rs_stringByTrimmingCharactersFromEnd:(NSUInteger)numberOfCharactersToTrim {
	NSUInteger length = [self length];
	if (length <= numberOfCharactersToTrim)
		return RSEmptyString;
	return [self substringToIndex:[self length] - 1];
}


- (NSString *)rs_stringByStrippingCaseInsensitivePrefix:(NSString *)prefix {
	if (![[self lowercaseString] hasPrefix:[prefix lowercaseString]])
		return self;
	return [self substringFromIndex:[prefix length]];
}


- (NSString *)rs_stringByStrippingPrefix:(NSString *)prefix {
	if (![self hasPrefix:prefix])
		return self;
	return [self substringFromIndex:[prefix length]];
}


- (BOOL)rs_contains:(NSString *)searchFor {
	return [self rangeOfString:searchFor].location != NSNotFound;
}


- (BOOL)rs_caseInsensitiveContains:(NSString *)searchFor {
	return [self rangeOfString:searchFor options:NSCaseInsensitiveSearch].location != NSNotFound;
}


static NSString *RSStringAddingFormat = @"%@%@";

+ (NSString *)rs_stringByAddingStrings:(NSString *)string1 string2:(NSString *)string2 {
	return [NSString stringWithFormat:RSStringAddingFormat, string1, string2];
}


static NSString *rs_2xSignifier = @"@2x";

- (NSString *)rs_stringByInserting2XSignifier {
	/*Add an @2X in the right place for a URL string*/
	if ([self length] < 10)
		return nil;
	NSRange rangeOfPeriod = [self rangeOfString:@"." options:NSBackwardsSearch range:NSMakeRange(0, [self length])];
	if (rangeOfPeriod.location == NSNotFound)
		return nil;
	NSMutableString *urlString = [[self mutableCopy] autorelease];
	[urlString insertString:rs_2xSignifier atIndex:rangeOfPeriod.location];
	return urlString;
}


static NSString *RSHTMLLeftCaret = @"<";
static NSString *RSHTMLItalicTagStart = @"<i>";
static NSString *RSHTMLItalicTagEnd = @"</i>";
static NSString *RSHTMLBoldTagStart = @"<b>";
static NSString *RSHTMLBoldTagEnd = @"</b>";
static NSString *RSHTMLBRTag = @"<br>";
static NSString *RSHTMLBRSlashTag = @"<br/>";

- (NSString *)rs_stringByMakingPlainTextTitle {
	NSString *entityDecodedString = RSStringWithDecodedEntities(self);
	NSMutableString *s = [[entityDecodedString mutableCopy] autorelease];
	if ([s rangeOfString:RSHTMLLeftCaret options:0].location != NSNotFound) {
		[s replaceOccurrencesOfString:RSHTMLItalicTagStart withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLItalicTagEnd withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBoldTagStart withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBoldTagEnd withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBRTag withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBRSlashTag withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
	}
	[s rs_replaceXMLCharacterReferences];
	[s rs_collapseWhitespace];
	return s;
}


+ (NSString *)rs_uuidString {
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	NSString *uuidString = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid) autorelease];
	CFRelease(uuid);
	CFMakeCollectable((CFStringRef)uuidString);
	return uuidString;	
}


static NSString *feedburner = @"feedburner";
static NSString *googleAdServices = @"googleadservices";
static NSString *reblog = @"reblog";
static NSString *zemanta = @"zemanta";
static NSString *pheedo = @"pheedo";
static NSString *adnxs = @"adnxs";
static NSString *tweetmeme = @"tweetmeme";
static NSString *doubleclick = @"doubleclick";
static NSString *record_view = @"record_view";
static NSString *stats_wordpress = @"stats.wordpress";
static NSString *feeds_wordpress = @"feeds.wordpress";
static NSString *rfihub = @"rfihub";
static NSString *wpDiggThis = @"wp-digg-this";
static NSString *slashdotIt = @"slashdot-it";
static NSString *facebook_icon = @"facebook_icon";
static NSString *techmeme_pml = @"pml.png";
static NSString *leading_a = @"//a.";
static NSString *leading_pixel = @"//pixel.";
static NSString *zoneid = @"ZoneID";
static NSString *hitsdot = @"//hits.";
static NSString *invitemedia = @"invitemedia";
static NSString *partnerID = @"partnerid";
static NSString *shareButton = @"share-button";


- (BOOL)rs_isIgnorableImgURLString {
	if (RSStringIsEmpty(self))
		return YES;
	NSString *lowerCaseString = [self lowercaseString];
	return [lowerCaseString rs_contains:feedburner] || [lowerCaseString rs_contains:googleAdServices] || [lowerCaseString rs_contains:reblog] || [lowerCaseString rs_contains:zemanta] || [lowerCaseString rs_contains:pheedo] || [lowerCaseString rs_contains:tweetmeme] || [lowerCaseString rs_contains:doubleclick] || [lowerCaseString rs_contains:record_view] || [lowerCaseString rs_contains:stats_wordpress] || [lowerCaseString rs_contains:rfihub] || [lowerCaseString rs_contains:wpDiggThis] || [lowerCaseString rs_contains:slashdotIt] || [lowerCaseString rs_contains:feeds_wordpress] || [lowerCaseString rs_contains:facebook_icon] || [lowerCaseString rs_contains:techmeme_pml] || [lowerCaseString rs_contains:leading_a] || [lowerCaseString rs_contains:zoneid] || [lowerCaseString rs_contains:adnxs] || [lowerCaseString rs_contains:leading_pixel] || [lowerCaseString rs_contains:hitsdot] || [lowerCaseString rs_contains:invitemedia] || [lowerCaseString rs_contains:partnerID] || [lowerCaseString rs_contains:shareButton];	
}


static NSString *startImgTag = @"<img";

+ (NSString *)rs_firstImgURLStringInHTML:(NSString *)html {
	/*Not perfect but should work for 99% of cases.*/
	while (true) {
		NSRange imgTagRange = [html rangeOfString:startImgTag options:0];
		if (imgTagRange.location == NSNotFound)
			return nil;
		if ([html length] < imgTagRange.location + 1)
			return nil;
		NSRange rangeToSearch = NSMakeRange(imgTagRange.location + 1, [html length] - (imgTagRange.location + 1));
		NSRange rangeOfClosingCaret = [html rangeOfString:RSRightCaret options:0 range:rangeToSearch];
		if (rangeOfClosingCaret.location == NSNotFound)
			return nil;
		imgTagRange.length = (rangeOfClosingCaret.location + rangeOfClosingCaret.length) - imgTagRange.location;
		NSString *imgTag = [html substringWithRange:imgTagRange];
		NSRange imgURLRange = [imgTag rangeOfString:RSStartHTTP options:0];
		if (imgURLRange.location == NSNotFound) { //may not start with http, may be relative
			imgURLRange = [imgTag rangeOfString:@" src" options:0];
			if (imgURLRange.location > rangeOfClosingCaret.location)
				return nil;
			if (imgURLRange.location == NSNotFound)
				return nil;
			imgURLRange.location = imgURLRange.location + imgURLRange.length;
		}
		NSMutableString *imgURLString = [NSMutableString stringWithCapacity:256];
		NSUInteger i = 0;
		NSUInteger lenImgTag = [imgTag length];
		unichar ch;
		BOOL skippingLeadingCharacters = YES;
		for (i = imgURLRange.location; i < lenImgTag; i++) {
			ch = [imgTag characterAtIndex:i];
			if (skippingLeadingCharacters && (ch == ' ' || ch == '\'' || ch == '"' || ch == '='))
				continue;
			skippingLeadingCharacters = NO;
			if (ch == ' ' || ch == '\r' || ch == '\t' || ch == '\n' || ch == '"' || ch == '\'' || ch == '>')
				break;
			CFStringAppendCharacters((CFMutableStringRef)imgURLString, &ch, 1);
		}
		if ([imgURLString rs_isIgnorableImgURLString]) {
			html = [html substringFromIndex:imgTagRange.location + 1];
			continue;
		}
		[imgURLString rs_replaceXMLCharacterReferences];
		return imgURLString;
	}
	return nil;
}


- (NSString *)rs_stringWithURLEncoding {
	CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)self, nil, CFSTR("`*^[]{}%=&/:+?#$,;<>@!'\" "), kCFStringEncodingUTF8);
	CFMakeCollectable(encodedString);
	return [(NSString *)encodedString autorelease];
}


+ (NSString *)rs_stringWithURLEncodedNameValuePair:(NSString *)name value:(NSString *)value {
	static NSString *nameValuePairFormat = @"%@=%@";
	return [NSString stringWithFormat:nameValuePairFormat, [name rs_stringWithURLEncoding], [value rs_stringWithURLEncoding]];	
}


+ (NSString *)rs_stringWithURLEncodedNameValuePairsFromDictionarySortedByKey:(NSDictionary *)aDictionary {
	/*OAuth wants the parameters sorted.*/
	NSMutableArray *encodedPairsArray = [NSMutableArray arrayWithCapacity:[aDictionary count]];
	NSArray *keys = [[aDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
	for (NSString *oneKey in keys)
		[encodedPairsArray addObject:[NSString rs_stringWithURLEncodedNameValuePair:oneKey value:[aDictionary objectForKey:oneKey]]]; 
	return [encodedPairsArray componentsJoinedByString:RSAmpersand];
}


- (NSString *)rs_stringByTrimmingWhitespace {
	NSMutableString *s = [[self mutableCopy] autorelease];
	CFStringTrimWhitespace((CFMutableStringRef)s);
	return s;
}


- (NSString *)rs_stringByCollapsingWhitespace {
	NSMutableString *s = [[self mutableCopy] autorelease];
	[s rs_collapseWhitespace];
	return s;
}


- (NSString *)rs_replaceAll:(NSString *)searchFor with:(NSString *)replaceWith {
	return RSStringReplaceAll(self, searchFor, replaceWith);
}


- (BOOL)rs_usernameAndPasswordFromURL:(NSString **)username password:(NSString **)password {
	
	/*From a string like http://brent:mypassword@example.com/foo/bar, get the username and password.*/
	
	if (![self rs_contains:@"@"] || ![self rs_contains:@"//"])
		return NO;
	NSArray *stringComponents = [self componentsSeparatedByString:@"//"];
	NSString *s = [stringComponents objectAtIndex:1];
	stringComponents = [s componentsSeparatedByString:@"/"];
	s = [stringComponents objectAtIndex:0];
	stringComponents = [s componentsSeparatedByString:@"@"];
	s = [stringComponents objectAtIndex:0];
	stringComponents = [s componentsSeparatedByString:@":"];
	NSString *u = [(NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[stringComponents objectAtIndex:0], (CFStringRef)@"") autorelease];
	CFMakeCollectable(u);
	NSString *p = [(NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[stringComponents rs_safeObjectAtIndex:1], (CFStringRef)@"") autorelease];
	CFMakeCollectable(p);
	*username = [[u copy] autorelease];
	*password = [[p copy] autorelease];	
	return YES;	
}


- (NSString *)rs_URLStringWithUsernameAndPasswordRemoved {
	NSString *username = nil, *password = nil;
	if (![self rs_usernameAndPasswordFromURL:&username password:&password] || RSIsEmpty(username) || RSIsEmpty(password))
		return self;	
	NSString *stringToReplace = [NSString stringWithFormat:@"%@:%@@", username, password];
	return [self rs_replaceAll:stringToReplace with:@""];	
}


- (NSString *)rs_substringAfterFirstOccurenceOfString:(NSString *)stringToFind {
	NSRange range = [self rangeOfString:stringToFind];
	if (range.location == NSNotFound || range.location == 0)
		return nil;
	NSUInteger ix = range.location + range.length;
	if (ix >= [self length])
		return nil;
	return [self substringFromIndex:ix];
}


- (NSString *)rs_ellipsizeAfterNWords:(NSUInteger)n {	
	NSArray *stringComponents = [self componentsSeparatedByString:@" "];
	NSMutableArray *componentsCopy = [[stringComponents mutableCopy] autorelease];
	NSUInteger ix = n;
	NSUInteger len = [componentsCopy count];	
	if (len < n)
		ix = len;	
	[componentsCopy removeObjectsInRange:NSMakeRange(ix, len - ix)];	
	return [componentsCopy componentsJoinedByString:@" "];
}


- (NSString *)rs_URLStringSafeForFileSystem {
	return [self rs_md5HashString];
//	NSString *urlString = self;
//	if ([urlString rs_contains:@"@"])
//		urlString = [self rs_URLStringWithUsernameAndPasswordRemoved];
//	if ([urlString hasPrefix:@"http://"] && [urlString length] > [@"http://" length])
//		urlString = [urlString substringFromIndex:[@"http://" length]];
//	else if ([urlString hasPrefix:@"https://"] && [urlString length] > [@"https://" length])
//		urlString = [urlString substringFromIndex:[@"https://" length]];
//	else if ([urlString hasPrefix:@"file://"] && [urlString length] > [@"file://" length])
//		urlString = [urlString substringFromIndex:[@"file://" length]];
//	NSMutableString *filename = [[urlString mutableCopy] autorelease];
//	[filename rs_replaceOccurrencesOfString:@"/" withString:@"_"];
//	[filename rs_replaceOccurrencesOfString:@"." withString:@"_"];
//	[filename rs_replaceOccurrencesOfString:@":" withString:@"_"];
//	[filename rs_replaceOccurrencesOfString:@"#" withString:@"_"];
//	[filename rs_replaceOccurrencesOfString:@"%" withString:@"_"];
//	[filename rs_replaceOccurrencesOfString:@" " withString:@"_"];
//	return filename;
}


- (NSString *)rs_stringByReplacingReservedXMLCharactersWithReferences {
	NSMutableString *s = [[self mutableCopy] autorelease];
	[s replaceOccurrencesOfString:RSRightCaret withString:RSGtReference options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:RSLeftCaret withString:RSLtReference options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:RSQuote withString:RSQuotReference options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:RSAmpersand withString:RSAmpReference options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	return s;	
}


+ (NSString *)rs_stringWithStrippedHTML:(NSString *)htmlString maxCharacters:(NSUInteger)maxCharacters {
	if (!htmlString || ![htmlString rs_contains:@"<"]) {
		if (maxCharacters > 0 && [htmlString length] > maxCharacters)
			return [htmlString substringToIndex:maxCharacters];
		return htmlString;
	}
	
	NSUInteger len = [htmlString length];
	NSMutableString *s = [NSMutableString stringWithCapacity:len];
	NSUInteger i = 0, level = 0;
	BOOL flLastWasSpace = NO;
	unichar ch;
	const unichar chspace = ' ';
	NSUInteger ctCharactersAdded = 0;
	
	for (i = 0; i < len; i++) {		
		ch = [htmlString characterAtIndex:i];		
		if (ch == '<')
			level++;		
		else if (ch == '>') {			
			level--;			
			//if (level == 0)			
			//CFStringAppendCharacters((CFMutableStringRef)s, &chspace, 1);
		}		
		else if (level == 0) {			
			if (ch == ' ' || ch == '\r' || ch == '\t' || ch == '\n') {				
				if (flLastWasSpace)
					continue;
				else
					flLastWasSpace = YES;
				ch = chspace;
			}			
			else
				flLastWasSpace = NO;			
			CFStringAppendCharacters((CFMutableStringRef)s, &ch, 1);
			if (maxCharacters > 0) {
				ctCharactersAdded++;
				if (ctCharactersAdded >= maxCharacters)
					break;
			}
		}			
	}	
	return s;
}


+ (NSString *)rs_stringWithCollapsedWhitespace:(NSString *)s {
	if (!s)
		return s;
	NSMutableString *dest = [[s mutableCopy] autorelease];
	CFStringTrimWhitespace((CFMutableStringRef)dest);
	[dest replaceOccurrencesOfString:@"\t" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dest length])];
	[dest replaceOccurrencesOfString:@"\r" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dest length])];
	[dest replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dest length])];
	while ([dest rangeOfString:@"  " options:0].location != NSNotFound)
		[dest replaceOccurrencesOfString:@"  " withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dest length])];
	return dest;
}

+ (NSString *)rs_stringWithCollapsedNonAlphaNumericCharacters:(NSString *)s {
	/* http://stackoverflow.com/questions/1231764/nsstring-convert-to-pure-alphabet-only-i-e-remove-accentspunctuation */
	return [[s componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

+ (NSString *)rs_stringWithCollapsedNonNumbericCharacters:(NSString *)s
{
	/* http://stackoverflow.com/questions/1231764/nsstring-convert-to-pure-alphabet-only-i-e-remove-accentspunctuation */
	return [[s componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

- (NSString *)rs_substringToFirstOccurenceOfString:(NSString *)stringToFind {
	NSRange range = [self rangeOfString:stringToFind];
	if (range.location == NSNotFound || range.location == 0)
		return nil;
	return [self substringToIndex:range.location];
}


+ (void)rs_splitFilenameWithSuffix:(NSString *)filenameWithSuffix intoFilename:(NSString **)filenameWithoutSuffix andSuffix:(NSString **)suffix {
	if (RSStringIsEmpty(filenameWithSuffix))
		return;
	*filenameWithoutSuffix = [filenameWithSuffix stringByDeletingPathExtension];
	*suffix = [filenameWithSuffix pathExtension];
}


#pragma mark Gigabyte, Megabyte, Kilobyte strings

+ (NSString *)rs_doubleStringWithOneDecimalPlace:(CGFloat)d {
	NSString *s = [NSString stringWithFormat:@"%f", d];
	NSArray *arrayComponents = [s componentsSeparatedByString:@"."];
	NSString *leftString = [arrayComponents objectAtIndex:0];
	NSString *rightString = [arrayComponents objectAtIndex:1];	
	rightString = [rightString substringToIndex:1];
	return [NSString stringWithFormat:@"%@.%@", leftString, rightString];
}


+ (NSString *)rs_byteString:(NSUInteger)numberOfBytes {
	return [NSString stringWithFormat:@"%lu bytes", (unsigned long)numberOfBytes];
}


+ (NSString *)rs_kilobyteString:(NSUInteger)numberOfBytes {
	if (numberOfBytes < 1024)
		return [NSString rs_byteString:numberOfBytes];
	CGFloat kb = (CGFloat) ((CGFloat)numberOfBytes / (CGFloat)1024);
	NSString *doubleString = [NSString rs_doubleStringWithOneDecimalPlace:kb];	
	return [NSString stringWithFormat:@"%@ KB", doubleString];
}


+ (NSString *)rs_megabyteString:(NSUInteger)numberOfBytes {
	if (numberOfBytes < 1024 * 1024)
		return [NSString rs_kilobyteString:numberOfBytes];
	CGFloat mb = (CGFloat) ((CGFloat)numberOfBytes / (CGFloat)(1024 * 1024));
	NSString *doubleString = [NSString rs_doubleStringWithOneDecimalPlace:mb];	
	return [NSString stringWithFormat:@"%@ MB", doubleString];
}


+ (NSString *)rs_gigabyteString:(NSUInteger)numberOfBytes {
	if (numberOfBytes < 1024 * (1024 * 1024))
		return [NSString rs_megabyteString:numberOfBytes];
	CGFloat gb = (CGFloat) ((CGFloat)numberOfBytes / (CGFloat)(1024 * 1024 * 1024));
	NSString *doubleString = [NSString rs_doubleStringWithOneDecimalPlace:gb];	
	return [NSString stringWithFormat:@"%@ GB", doubleString];	
}

- (NSString *)rs_stringByReplacingXMLCharacterReferences
{
	NSMutableString *mutableCopy = [NSMutableString stringWithString:self];
	[mutableCopy rs_replaceXMLCharacterReferences];
	return mutableCopy;
}

@end

NSUInteger RSStringIndexOfFirstInstanceOfCharacter(NSString *s, unichar ch) {
	if (RSIsEmpty(s))
		return NSNotFound;		
	NSUInteger ct = [s length];	
	NSUInteger i;
	for (i = 1; i < ct - 1; i++) {
		if ([s characterAtIndex:i] == ch)
			return i;
	}
	return NSNotFound;
}


NSArray *RSArraySeparatedByFirstInstanceOfCharacter(NSString *s, unichar ch) {
	/*Neither object in array contains the first instance ch. If ch appears as first or last character in s, return nil.*/
	NSUInteger ix = RSStringIndexOfFirstInstanceOfCharacter(s, ch);
	if (ix == NSNotFound)
		return nil;
	NSString *s1 = [s substringToIndex:ix];
	NSString *s2 = [s substringFromIndex:ix + 1];
	return [NSArray arrayWithObjects:s1, s2, nil];
}


NSString *RSURLDecodedString(NSString *s) {
	s = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)s, (CFStringRef) @"");
	CFMakeCollectable((CFStringRef)s);
	return [s autorelease];
}


NSDictionary *RSDictionaryFromURLParametersString(NSString *s) {
	if (!s)
		return nil;
	NSArray *components = [s componentsSeparatedByString:@"&"];
	if (RSIsEmpty(components))
		return nil;
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:10];
	NSUInteger i;
	NSUInteger ct = [components count];
	NSArray *paramComponents;
	NSString *oneName, *oneValue;
	for (i = 0; i < ct; i++) {
		paramComponents = RSArraySeparatedByFirstInstanceOfCharacter([components objectAtIndex:i], '=');
		if (RSIsEmpty(paramComponents))
			continue;
		oneName = [paramComponents objectAtIndex:0];
		if (RSIsEmpty(oneName))
			continue;
		oneValue = [paramComponents rs_safeObjectAtIndex:1];
		if (RSIsEmpty(oneValue))
			continue;
		[d rs_safeSetObject:RSURLDecodedString(oneValue) forKey:RSURLDecodedString(oneName)];
	}
	return d;
}


NSString *RSStringStartingAfterCharacter(NSString *s, unichar ch) {
	NSArray *anArray = RSArraySeparatedByFirstInstanceOfCharacter(s, ch);
	if (anArray)
		return [anArray rs_safeObjectAtIndex:1];
	return nil;
}


NSString *RSQueryStringFromURLString(NSString *s) {
	return RSStringStartingAfterCharacter(s, '?');
}


NSDictionary *RSDictionaryFromURLString(NSString *s) {
	return RSDictionaryFromURLParametersString(RSQueryStringFromURLString(s));
}


BOOL RSURLIsFeedURL(NSString *s) {
	return s != nil && [[s lowercaseString] hasPrefix:@"feed:"];
}


NSString *RSURLWithFeedURL (NSString *s) {
	if (!RSURLIsFeedURL(s))
		return s;
	if ([[s lowercaseString] isEqualToString:@"feed:"]) //well, it happened
		return nil;
	
	NSString *urlString = [s substringFromIndex:5];
	if ([urlString hasPrefix:@"//"])
		urlString = [urlString substringFromIndex:2];
	if (![urlString rs_contains:@"//"])
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	return urlString;
}


NSString *RSStringStripHTML(NSString *htmlString) {
	
	if (!htmlString || ![htmlString rs_contains:@"<"])
		return htmlString;
	
	NSUInteger len = [htmlString length];
	NSMutableString *s = [NSMutableString stringWithCapacity:len];
	NSUInteger i = 0, level = 0;
	BOOL flLastWasSpace = NO;
	unichar ch;
	const unichar chspace = ' ';
	
	for (i = 0; i < len; i++) {
		
		ch = [htmlString characterAtIndex:i];
		
		if (ch == '<')
			level++;
		
		else if (ch == '>') {
			
			level--;
			
			if (level == 0)			
				CFStringAppendCharacters((CFMutableStringRef)s, &chspace, 1);
		}
		
		else if (level == 0) {
			
			if (ch == ' ') {
				
				if (flLastWasSpace)
					continue;
				else
					flLastWasSpace = YES;
			}
			
			else
				flLastWasSpace = NO;
			
			CFStringAppendCharacters((CFMutableStringRef)s, &ch, 1);
		}			
	}
	
	return s;
}


NSString *RSStringUsefulStringWithData (NSData *d) {
	
	/*It may not be the *perfect* string encoding -- but at least a useful string encoding, so that you can actually look inside the string and find what the encoding is supposed to be.*/
	
	NSString *s = nil;
	
	if (d == nil)
		return (nil);
	
	if ([d length] > 2) { /*Check for UTF-16 BOM*/
		
		unsigned char firstChar = 0, secondChar = 0;
		BOOL flUnicode = NO;
		
		[d getBytes:&firstChar range:NSMakeRange (0, 1)];
		[d getBytes:&secondChar range:NSMakeRange (1, 1)];
		
		if ((firstChar == 0xff) && (secondChar == 0xfe))
			flUnicode = YES;
		else if ((firstChar == 0xfe) && (secondChar == 0xff))
			flUnicode = YES;
		
		if (flUnicode)
			s = [[[NSString alloc] initWithData:d encoding:NSUnicodeStringEncoding] autorelease];
		if (s != nil)
			return (s);
	}
	
	s = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSISOLatin1StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSMacOSRomanStringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSWindowsCP1251StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSWindowsCP1252StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSWindowsCP1253StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSWindowsCP1254StringEncoding] autorelease];
	if (s == nil)
		s = [[[NSString alloc] initWithData:d encoding:NSWindowsCP1250StringEncoding] autorelease];
	return (s);
}


NSString *RSStringByAddingPercentEscapes(NSString *s) {
	CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)s, nil, nil, kCFStringEncodingUTF8);
	CFMakeCollectable(encodedString);
	return [(NSString *)encodedString autorelease];
}


NSString *RSStringMailToLinkWithTitleAndBody(NSString *title, NSString *body) {
	title = RSAddStrings(@"subject=", RSStringByAddingPercentEscapes(title));
	title = RSStringReplaceAll(title, @"&", @"%26");
	body = RSAddStrings(@"body=", RSStringByAddingPercentEscapes(body));
	body = RSStringReplaceAll(body, @"&", @"%26");
	return [NSString stringWithFormat:@"mailto:?%@&%@", title, body];
}


BOOL RSStringIsWebOrFileURLString(NSString *URLString) {
	if (RSStringIsEmpty(URLString))
		return NO;
	if (![URLString hasPrefix: @"http://"] && ![URLString hasPrefix: @"https://"] && ![URLString hasPrefix: @"file://"])
		return NO;	
	return [NSURL URLWithString:URLString] != nil;
}



#pragma mark -

@implementation NSTimer (RSCore)

- (void)rs_invalidateIfValid {
	if ([self isValid])
		[self invalidate];
}


@end
