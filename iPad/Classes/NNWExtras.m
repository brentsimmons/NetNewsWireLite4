//
//  NNWExtras.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#include <math.h>
#import <CommonCrypto/CommonDigest.h>
#import <MediaPlayer/MediaPlayer.h>
#import "NNWExtras.h"
#import "UIImage+Resize.h"


//NSString *RSEmptyString = @"";

static inline double radians (double degrees) {return degrees * M_PI/180;}



NSString *RSDocumentsFilePath(NSString *filename) {
	static NSString *documentsFolder = nil;
	if (!documentsFolder) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsFolder = [[paths objectAtIndex:0] retain];
	}
	return [documentsFolder stringByAppendingPathComponent:filename];
}


CGRect CGRectCenteredHorizontallyInContainingRect(CGRect rectToCenter, CGRect containingRect) {
	rectToCenter.origin.x = CGRectGetMidX(containingRect) - (rectToCenter.size.width / 2);
	return rectToCenter;
}


CGRect CGRectCenteredVerticalInContainingRect(CGRect rectToCenter, CGRect containingRect) {
	rectToCenter.origin.y = CGRectGetMidY(containingRect) - (rectToCenter.size.height / 2);
	return rectToCenter;	
}


NSString *RSApplicationDocumentsDirectory(void) {
 	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) safeObjectAtIndex:0];
}


NSString *RSApplicationSupportFile(NSString *filename) {
	return [RSApplicationDocumentsDirectory() stringByAppendingPathComponent:filename];	
}


void RSPostNotificationOnMainThread(NSString *notificationName) {
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:notificationName object:nil] waitUntilDone:NO];	
}


void RSEnqueueNotificationNameOnMainThread(NSString *notificationName) {
	[[NSNotificationQueue defaultQueue] performSelectorOnMainThread:@selector(enqueueIdleNotification:) withObject:[NSNotification notificationWithName:notificationName object:nil] waitUntilDone:NO];
}


#pragma mark -

@implementation NSObject (NNWExtras)

- (void)postNotificationOnMainThread:(NSString *)notificationName {
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:notificationName object:nil] waitUntilDone:NO];	
}


- (void)rs_postNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo {
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:notificationName object:obj userInfo:userInfo] waitUntilDone:NO];	
}


- (void)rs_enqueueNotificationOnMainThread:(NSString *)notificationName object:(id)obj userInfo:(NSDictionary *)userInfo {
	/*Uses NSNotificationQueue to post a potentially-coalesced notification.*/
	NSNotification *note = [NSNotification notificationWithName:notificationName object:obj userInfo:userInfo];
	if ([NSThread isMainThread])
		[[NSNotificationQueue defaultQueue] enqueueIdleNotification:note];
	else		
		[[NSNotificationQueue defaultQueue] performSelectorOnMainThread:@selector(enqueueIdleNotification:) withObject:note waitUntilDone:NO];
}


@end

#pragma mark -

@implementation NSString (NNWExtras)

+ (NSString *)UUIDString {	
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	NSString *s = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid) autorelease];
	CFRelease(uuid);
	return s;
}


+ (NSString *)stringWithUTF8EncodedData:(NSData *)data {
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}


+ (NSString *)onewayHashOfString:(NSString *)s {
	const char* str_utf8 = [s UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(str_utf8, strlen(str_utf8), result);
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7], result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
}


+ (NSString *)stringByStrippingSuffix:(NSString *)s suffix:(NSString *)suffix {	
	/*case insensitive*/
	if (![[s lowercaseString] hasSuffix:[suffix lowercaseString]])
		return s;	
	return [s substringToIndex:[s length] - [suffix length]];
}


+ (NSString *)stringWithCollapsedWhitespace:(NSString *)s {
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


+ (NSDictionary *)_entitiesDictionary {
	static NSDictionary *entitiesDictionary = nil;
	@synchronized([NSString class]) {
		if (!entitiesDictionary)
			entitiesDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
								   @"\"", @"#034",
								   @"'", @"#039",
								   @"‘", @"#145",
								   @"’", @"#146",
								   @"“", @"#147",
								   @"”", @"#148",
								   @"•", @"#149",
								   @"-", @"#150",
								   @"—", @"#151",
								   @"™", @"#153",
								   @" ", @"#160",
								   @"¡", @"#161",
								   @"¢", @"#162",
								   @"£", @"#163",
								   @"?", @"#164",
								   @"¥", @"#165",
								   @"?", @"#166",
								   @"§", @"#167",
								   @"¨", @"#168",
								   @"©", @"#169",
								   @"©", @"#170",
								   @"«", @"#171",
								   @"¬", @"#172",
								   @"¬", @"#173",
								   @"®", @"#174",
								   @"¯", @"#175",
								   @"°", @"#176",
								   @"±", @"#177",
								   @" ", @"#178",
								   @" ", @"#179",
								   @"´", @"#180",
								   @"µ", @"#181",
								   @"µ", @"#182",
								   @"·", @"#183",
								   @"¸", @"#184",
								   @" ", @"#185",
								   @"º", @"#186",
								   @"»", @"#187",
								   @"1/4", @"#188",
								   @"1/2", @"#189",
								   @"1/2", @"#190",
								   @"¿", @"#191",
								   @"À", @"#192",
								   @"Á", @"#193",
								   @"Â", @"#194",
								   @"Ã", @"#195",
								   @"Ä", @"#196",
								   @"Å", @"#197",
								   @"Æ", @"#198",
								   @"Ç", @"#199",
								   @"È", @"#200",
								   @"É", @"#201",
								   @"Ê", @"#202",
								   @"Ë", @"#203",
								   @"Ì", @"#204",
								   @"Í", @"#205",
								   @"Î", @"#206",
								   @"Ï", @"#207",
								   @"?", @"#208",
								   @"Ñ", @"#209",
								   @"Ò", @"#210",
								   @"Ó", @"#211",
								   @"Ô", @"#212",
								   @"Õ", @"#213",
								   @"Ö", @"#214",
								   @"x", @"#215",
								   @"Ø", @"#216",
								   @"Ù", @"#217",
								   @"Ú", @"#218",
								   @"Û", @"#219",
								   @"Ü", @"#220",
								   @"Y", @"#221",
								   @"?", @"#222",
								   @"ß", @"#223",
								   @"à", @"#224",
								   @"á", @"#225",
								   @"â", @"#226",
								   @"ã", @"#227",
								   @"ä", @"#228",
								   @"å", @"#229",
								   @"æ", @"#230",
								   @"ç", @"#231",
								   @"è", @"#232",
								   @"é", @"#233",
								   @"ê", @"#234",
								   @"ë", @"#235",
								   @"ì", @"#236",
								   @"í", @"#237",
								   @"î", @"#238",
								   @"ï", @"#239",
								   @"?", @"#240",
								   @"ñ", @"#241",
								   @"ò", @"#242",
								   @"ó", @"#243",
								   @"ô", @"#244",
								   @"õ", @"#245",
								   @"ö", @"#246",
								   @"÷", @"#247",
								   @"ø", @"#248",
								   @"ù", @"#249",
								   @"ú", @"#250",
								   @"û", @"#251",
								   @"ü", @"#252",
								   @"y", @"#253",
								   @"?", @"#254",
								   @"ÿ", @"#255",
								   @" ", @"#32",
								   @"\"", @"#34",
								   @"", @"#39",
								   @" ", @"#8194",
								   @" ", @"#8195",
								   @"-", @"#8211",
								   @"—", @"#8212",
								   @"‘", @"#8216",
								   @"’", @"#8217",
								   @"“", @"#8220",
								   @"”", @"#8221",
								   @"…", @"#8230",
								   @"Æ", @"AElig",
								   @"Á", @"Aacute",
								   @"Â", @"Acirc",
								   @"À", @"Agrave",
								   @"Å", @"Aring",
								   @"Ã", @"Atilde",
								   @"Ä", @"Auml",
								   @"Ç", @"Ccedil",
								   @"?", @"Dstrok",
								   @"?", @"ETH",
								   @"É", @"Eacute",
								   @"Ê", @"Ecirc",
								   @"È", @"Egrave",
								   @"Ë", @"Euml",
								   @"Í", @"Iacute",
								   @"Î", @"Icirc",
								   @"Ì", @"Igrave",
								   @"Ï", @"Iuml",
								   @"Ñ", @"Ntilde",
								   @"Ó", @"Oacute",
								   @"Ô", @"Ocirc",
								   @"Ò", @"Ograve",
								   @"Ø", @"Oslash",
								   @"Õ", @"Otilde",
								   @"Ö", @"Ouml",
								   @"Π", @"Pi",
								   @"?", @"THORN",
								   @"Ú", @"Uacute",
								   @"Û", @"Ucirc",
								   @"Ù", @"Ugrave",
								   @"Ü", @"Uuml",
								   @"Y", @"Yacute",
								   @"á", @"aacute",
								   @"â", @"acirc",
								   @"´", @"acute",
								   @"æ", @"aelig",
								   @"à", @"agrave",
								   @"&amp;", @"amp",
								   @"'", @"apos",
								   @"å", @"aring",
								   @"ã", @"atilde",
								   @"ä", @"auml",
								   @"?", @"brkbar",
								   @"?", @"brvbar",
								   @"ç", @"ccedil",
								   @"¸", @"cedil",
								   @"¢", @"cent",
								   @"©", @"copy",
								   @"?", @"curren",
								   @"°", @"deg",
								   @"?", @"die",
								   @"÷", @"divide",
								   @"é", @"eacute",
								   @"ê", @"ecirc",
								   @"è", @"egrave",
								   @"?", @"eth",
								   @"ë", @"euml",
								   @"€", @"euro",
								   @"1/2", @"frac12",
								   @"1/4", @"frac14",
								   @"3/4", @"frac34",
								   @"&gt;", @"gt",
								   @"♥", @"hearts",
								   @"…", @"hellip",
								   @"í", @"iacute",
								   @"î", @"icirc",
								   @"¡", @"iexcl",
								   @"ì", @"igrave",
								   @"¿", @"iquest",
								   @"ï", @"iuml",
								   @"«", @"laquo",
								   @"“", @"ldquo",
								   @"‘", @"lsquo",
								   @"&lt;", @"lt",
								   @"¯", @"macr",
								   @"—", @"mdash",
								   @"µ", @"micro",
								   @"·", @"middot",
								   @" ", @"nbsp",
								   @"-", @"ndash",
								   @"¬", @"not",
								   @"ñ", @"ntilde",
								   @"ó", @"oacute",
								   @"ô", @"ocirc",
								   @"ò", @"ograve",
								   @"ª", @"ordf",
								   @"º", @"ordm",
								   @"ø", @"oslash",
								   @"õ", @"otilde",
								   @"ö", @"ouml",
								   @"¶", @"para",
								   @"π", @"pi",
								   @"±", @"plusmn",
								   @"£", @"pound",
								   @"\"", @"quot",
								   @"»", @"raquo",
								   @"”", @"rdquo",
								   @"®", @"reg",
								   @"’", @"rsquo",
								   @"§", @"sect",
								   @" ", @"shy",
								   @" ", @"sup1",
								   @" ", @"sup2",
								   @" ", @"sup3",
								   @"ß", @"szlig",
								   @"?", @"thorn",
								   @"x", @"times",
								   @"™", @"trade",
								   @"ú", @"uacute",
								   @"û", @"ucirc",
								   @"ù", @"ugrave",
								   @"¨", @"uml",
								   @"ü", @"uuml",
								   @"y", @"yacute",
								   @"¥", @"yen",
								   @"ÿ", @"yuml",
								   nil] retain];
	}
	return entitiesDictionary;
}


- (BOOL)intValueFromHexDigit:(unsigned int *)val {	
	return [[NSScanner scannerWithString:self] scanHexInt:val];  	
}


+ (NSString *)stripPrefix:(NSString *)s prefix:(NSString *)prefix {
	/*case insensitive*/	
	if ([[s lowercaseString] hasPrefix:[prefix lowercaseString]])
		return [s substringFromIndex:[prefix length]];
	return s;	
}


+ (NSString *)stripSuffix:(NSString *)s suffix:(NSString *)suffix {	
	/*case insensitive*/
	if (![[s lowercaseString] hasSuffix:[suffix lowercaseString]])
		return s;	
	return [s substringToIndex:[s length] - [suffix length]];
}


+ (NSString *)stringWithDecodedEntities:(NSString *)s convertCarets:(BOOL)convertCarets convertHexEntitiesOnly:(BOOL)convertHexEntitiesOnly {
	
	if (RSIsEmpty(s) || [s rangeOfString:@"&" options:NSLiteralSearch].location == NSNotFound)
		return s;
	
	int len = [s length];
	if (convertHexEntitiesOnly)
		convertCarets = NO;
	NSDictionary *entitiesDictionary = [self _entitiesDictionary];
	
	NSMutableString *result = [NSMutableString stringWithCapacity:len];
	int i = 0;
	
	while (true) {
		
		unichar ch = [s characterAtIndex: i];
		
		if (ch == '&') {
			
			int j = i + 1;
			int ixRight = NSNotFound;
			
			while (true) {
				
				unichar endch;
				
				if (j >= len)
					break;
				
				endch = [s characterAtIndex:j];
				
				if (endch == ';') {					
					ixRight = j;
					break;
				}
				
				if ((endch == ' ') || (endch == '\t') || (endch == '\r') || (endch == '\n') || (endch == '&'))
					break;
				
				j++;
			}
			
			if (ixRight != NSNotFound) {
				
				NSString *entityString = [s substringWithRange:NSMakeRange(i + 1, (ixRight - i) - 1)];
				NSString *fullEntityString = [[NSString alloc] initWithFormat:@"&%@;", entityString];
				NSString *valueString = nil;
				
				if (!convertHexEntitiesOnly)
					valueString = [[entitiesDictionary objectForKey:entityString] retain];
				
				if ((valueString == nil) && ([entityString hasPrefix:@"#x"])) {
					unsigned int val = 0;					
					entityString = RSStringReplaceAll(entityString, @"#x", @"0x");					
					[entityString intValueFromHexDigit:&val];
					if (val > 0)
						valueString = [[NSString alloc] initWithFormat:@"%C", val];
				}
				
				else if ((valueString == nil) && ([entityString hasPrefix:@"#"])) {
					unsigned int val = 0;
					entityString = [NSString stripPrefix:entityString prefix:@"#"];
					val = [entityString intValue];
					if (val > 0)
						valueString = [[NSString alloc] initWithFormat:@"%C", val];
				}
				if ((!convertCarets) && ([entityString isEqualToString:@"lt"] || [entityString isEqualToString:@"gt"]))		
					[result appendString:fullEntityString];	
				else {				
					if (valueString)
						[result appendString:valueString];
					else
						[result appendString:fullEntityString];
				}
				
				[valueString release];
				[fullEntityString release];
				
				i = ixRight;
				
				goto continue_loop;
			}
		}
		
		CFStringAppendCharacters((CFMutableStringRef)result, &ch, 1);
		
	continue_loop:
		
		i++;
		
		if (i >= len)
			break;
	}
	
	return result;
}


+ (NSString *)stringWithDecodedEntities:(NSString *)s {
	return [self stringWithDecodedEntities:s convertCarets:YES convertHexEntitiesOnly:NO];
}


+ (NSString *)rs_stringWithStrippedHTML:(NSString *)htmlString maxCharacters:(NSInteger)maxCharacters {
	if (!htmlString || ![htmlString caseSensitiveContains:@"<"]) {
		if (maxCharacters > 0 && [htmlString length] > maxCharacters)
			return [htmlString substringToIndex:maxCharacters];
		return htmlString;
	}

	int len = [htmlString length];
	NSMutableString *s = [NSMutableString stringWithCapacity:len];
	int i = 0, level = 0;
	BOOL flLastWasSpace = NO;
	unichar ch;
	const unichar chspace = ' ';
	NSInteger ctCharactersAdded = 0;
	
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


+ (NSString *)stringWithQueryStripped:(NSString *)s {
	if (!s || ![s caseInsensitiveContains:@"?"])
		return s;
	NSArray *stringComponents = [s componentsSeparatedByString:@"?"];
	int i;
	int ct = [stringComponents count] - 1;
	NSMutableString *newString = [NSMutableString stringWithString:@""];
	for (i = 0; i < ct; i++) {
		[newString appendString:[stringComponents objectAtIndex:i]];
		if (i < ct - 1)
			[newString appendString:@"?"];
	}
	return newString;
}


- (BOOL)caseSensitiveContains:(NSString *)searchFor {
	return [self rangeOfString:searchFor options:0].location != NSNotFound;
}


- (BOOL)caseInsensitiveContains:(NSString *)searchFor {
	return [self rangeOfString:searchFor options:NSCaseInsensitiveSearch].location != NSNotFound;
}


- (NSString *)substringAfterFirstOccurenceOfString:(NSString *)stringToFind {
	NSRange range = [self rangeOfString:stringToFind];
	if (range.location == NSNotFound || range.location == 0)
		return nil;
	int ix = range.location + range.length;
	if (ix >= [self length])
		return nil;
	return [self substringFromIndex:ix];
}


- (NSUInteger)sumOfCharacterCodes {
	/*Example: for string @"sum" it returns 115 + 117 + 109*/
	NSUInteger sum = 0;
	NSInteger i = 0;
	NSInteger length = [self length];
	for (i = 0; i < length; i++)
		sum += [self characterAtIndex:i];
	return sum;
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

static NSString *startImgTag = @"<img";
static NSString *rightCaret = @">";
static NSString *startHTTP = @"http://";


BOOL RSIsIgnorableImgURLString(NSString *imgURLString) {
	return RSStringIsEmpty(imgURLString) || [imgURLString caseInsensitiveContains:feedburner] || [imgURLString caseInsensitiveContains:googleAdServices] || [imgURLString caseInsensitiveContains:reblog] || [imgURLString caseInsensitiveContains:zemanta] || [imgURLString caseInsensitiveContains:pheedo] || [imgURLString caseInsensitiveContains:tweetmeme] || [imgURLString caseInsensitiveContains:doubleclick] || [imgURLString caseInsensitiveContains:record_view] || [imgURLString caseInsensitiveContains:stats_wordpress] || [imgURLString caseInsensitiveContains:rfihub] || [imgURLString caseInsensitiveContains:wpDiggThis] || [imgURLString caseInsensitiveContains:slashdotIt] || [imgURLString caseInsensitiveContains:feeds_wordpress] || [imgURLString caseInsensitiveContains:facebook_icon] || [imgURLString caseInsensitiveContains:techmeme_pml] || [imgURLString caseInsensitiveContains:leading_a] || [imgURLString caseInsensitiveContains:zoneid] || [imgURLString caseInsensitiveContains:adnxs] || [imgURLString caseInsensitiveContains:leading_pixel];
}


NSString *RSFirstImgURLStringInHTML(NSString *html) {
	/*Not perfect but should work for 99% of cases.*/
	while (true) {
		NSRange imgTagRange = [html rangeOfString:startImgTag options:0];
		if (imgTagRange.location == NSNotFound)
			return nil;
		if ([html length] < imgTagRange.location + 1)
			return nil;
		NSRange rangeToSearch = NSMakeRange(imgTagRange.location + 1, [html length] - (imgTagRange.location + 1));
		NSRange rangeOfClosingCaret = [html rangeOfString:rightCaret options:0 range:rangeToSearch];
		if (rangeOfClosingCaret.location == NSNotFound)
			return nil;
		imgTagRange.length = (rangeOfClosingCaret.location + rangeOfClosingCaret.length) - imgTagRange.location;
		NSString *imgTag = [html substringWithRange:imgTagRange];
		NSRange imgURLRange = [imgTag rangeOfString:startHTTP options:0];
		if (imgURLRange.location == NSNotFound)
			return nil;
		NSMutableString *imgURLString = [NSMutableString stringWithCapacity:256];
		NSUInteger i = 0;
		NSUInteger lenImgTag = [imgTag length];
		unichar ch;
		for (i = imgURLRange.location; i < lenImgTag; i++) {
			ch = [imgTag characterAtIndex:i];		
			if (ch == ' ' || ch == '\r' || ch == '\t' || ch == '\n' || ch == '"' || ch == '\'' || ch == '>')
				break;
			CFStringAppendCharacters((CFMutableStringRef)imgURLString, &ch, 1);
		}
		if (RSIsIgnorableImgURLString(imgURLString)) {
			html = [html substringFromIndex:imgTagRange.location + 1];
			continue;
		}
		[imgURLString replaceXMLCharacterReferences];
		return imgURLString;
	}
	return nil;
}


@end


@implementation NSMutableString (NNWExtras)

NSString *NNWAmp38 = @"&#38;";
NSString *NNWAmpersand = @"&";

- (void)replaceEntity38WithAmpersand {
	[self replaceOccurrencesOfString:NNWAmp38 withString:NNWAmpersand options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}

NSString *NNWAmp39 = @"&#39;";
NSString *NNWSingleQuote = @"'";

- (void)replaceEntity39WithSingleQuote {
	[self replaceOccurrencesOfString:NNWAmp39 withString:NNWSingleQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
}

NSString *NNWAmpAmp = @"&amp;";

- (void)replaceEntityAmpWithAmpersand {
	[self replaceOccurrencesOfString:NNWAmpAmp withString:NNWAmpersand options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}


NSString *NNWAmpQuot = @"&quot;";
NSString *NNWDoubleQuote = @"\"";

- (void)replaceEntityQuotWithDoubleQuote {
	[self replaceOccurrencesOfString:NNWAmpQuot withString:NNWDoubleQuote options:NSLiteralSearch range:NSMakeRange(0, [self length])];	
}


- (void)replaceXMLCharacterReferences {
	if (![self caseInsensitiveContains:@"&"] || ![self caseInsensitiveContains:@";"])
		return;
	[self replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#60;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x3C;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x3c;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#62;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x3E;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x3e;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#34;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x22;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:@"&apos;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#39;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x27;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	
	[self replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#38;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x26;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [self length])];	
}


static NSString *NNWExtrasSpace = @" ";
static NSString *NNWExtrasTab = @"\t";
static NSString *NNWExtrasReturn = @"\r";
static NSString *NNWExtrasLineFeed = @"\n";
static NSString *NNWExtrasTwoSpaces = @"  ";

- (void)collapseWhitespace {
	[self replaceOccurrencesOfString:NNWExtrasTab withString:NNWExtrasSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:NNWExtrasReturn withString:NNWExtrasSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:NNWExtrasLineFeed withString:NNWExtrasSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	while ([self rangeOfString:NNWExtrasTwoSpaces options:0].location != NSNotFound)
		[self replaceOccurrencesOfString:NNWExtrasTwoSpaces withString:NNWExtrasSpace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	CFStringTrimWhitespace((CFMutableStringRef)self);
}


+ (NSMutableString *)rs_mutableStringWithStrippedHTML:(NSString *)htmlString maxCharacters:(NSInteger)maxCharacters {
	if (!htmlString || ![htmlString caseSensitiveContains:@"<"]) {
		if (maxCharacters > 0 && [htmlString length] > maxCharacters)
			return [[[htmlString substringToIndex:maxCharacters] mutableCopy] autorelease];
		return [[htmlString mutableCopy] autorelease];
	}
	
	int len = [htmlString length];
	NSMutableString *s = [NSMutableString stringWithCapacity:len];
	int i = 0, level = 0;
	BOOL flLastWasSpace = NO;
	unichar ch;
	const unichar chspace = ' ';
	NSInteger ctCharactersAdded = 0;
	
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


- (void)rs_appendString:(NSString *)stringToAppend {
	if (stringToAppend != nil)
		[self appendString:stringToAppend];
}


@end


#pragma mark -

@implementation NSData (RSExtras)


+ (NSData *)hashWithString:(NSString *)s {
	const char *utf8String = [s UTF8String];
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	CC_MD5(utf8String, strlen(utf8String), hash);
	return [NSData dataWithBytes:(const void *)hash length:CC_MD5_DIGEST_LENGTH];
}


@end


#pragma mark -

@implementation NSArray (NNWExtras)

- (id)safeObjectAtIndex:(NSUInteger)ix {
	if (ix < 0 || ix >= [self count])
		return nil;	
	return [self objectAtIndex:ix];
}


@end

@implementation NSMutableArray (NNWExtras)

- (void)safeAddObject:(id)obj {
	if (obj)
		[self addObject:obj];	
}

@end

#pragma mark -

@implementation NSDictionary (NNWExtras)

- (BOOL)boolForKey:(id)key {	
	id obj = [self objectForKey:key];
	if (!obj || obj == (id)kCFBooleanFalse)
		return NO;	
	if (obj == (id)kCFBooleanTrue)
		return YES;	
	if ([obj isKindOfClass:[NSString class]]) {
		NSString *s = [obj lowercaseString];
		if ([s isEqualToString:@"yes"] || [s isEqualToString:@"true"])
			return YES;
	}
	if ([obj respondsToSelector:@selector(intValue)])
		return (BOOL)[obj intValue];	
	return NO;
}


- (id)safeObjectForKey:(id)key {
	if (RSIsEmpty(key))
		return nil;
	return [self objectForKey:key];
}


- (NSInteger)integerForKey:(id)key {
	id obj = [self objectForKey:key];
	if (obj && [obj respondsToSelector:@selector(integerValue)])
		return [obj integerValue];
	return 0;	
}


#pragma mark HTTP POST Args

- (void)_addHTTPPostArgValue:(NSString *)value key:(NSString *)key index:(NSInteger *)ix toString:(NSMutableString *)s {
	if (*ix > 0)
		[s appendString:@"&"];
	*ix = *ix + 1;
	[s appendString:key];
	[s appendString:@"="];
	CFStringRef urlEncodedString = CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)value, nil, CFSTR("%=&/:+?#$,;@ "), kCFStringEncodingUTF8);
	[s appendString:(NSString *)urlEncodedString];
	CFRelease(urlEncodedString);	
}


- (void)_addHTTPPostArgsArray:(NSArray *)anArray key:(NSString *)key index:(NSInteger *)ix toString:(NSMutableString *)s {
	for (NSString *oneValue in anArray)
		[self _addHTTPPostArgValue:oneValue key:key index:ix toString:s];
}


- (NSString *)httpPostArgsString {
	NSMutableString *s = [NSMutableString stringWithString:@""];
	NSInteger ix = 0;
	for (NSString *oneKey in self) {
		id obj = [self objectForKey:oneKey];
		if ([obj isKindOfClass:[NSArray class]])
			[self _addHTTPPostArgsArray:obj key:oneKey index:&ix toString:s];
		else
			[self _addHTTPPostArgValue:obj key:oneKey index:&ix toString:s];
	}
	return s;
}


@end


@implementation NSMutableDictionary (NNWExtras)

- (void)safeSetObject:(id)obj forKey:(id)key {	
	if (obj)
		[self setObject:obj forKey:key];	
}


- (void)setBool:(BOOL)fl forKey:(id)key {
	[self setObject:fl ? (id)kCFBooleanTrue : (id)kCFBooleanFalse forKey:key];
}


- (void)setInteger:(NSInteger)n forKey:(id)key {
	[self setObject:[NSNumber numberWithInteger:n] forKey:key];
}


@end


#pragma mark -

NSArray *NNWSetSeparatedIntoArraysOfLength(NSSet *aSet, NSUInteger length) {
	/*Returns a container array containing arrays, each of which has a length equal to length, except that the last one may be shorter than length.*/
	if (RSIsEmpty(aSet))
		return nil;
	NSMutableArray *container = [NSMutableArray array];
	NSMutableArray *currentSubArray = [NSMutableArray array];
	[container addObject:currentSubArray];
	NSUInteger subArrayCount = 0;
	for (id oneObject in aSet) {
		if (subArrayCount < length) {
			[currentSubArray safeAddObject:oneObject];
			subArrayCount++;
		}
		else {
			currentSubArray = [NSMutableArray array];
			[container addObject:currentSubArray];
			[currentSubArray safeAddObject:oneObject];
			subArrayCount = 0;
		}
	}
	return container;
}


@implementation NSMutableSet (NNWExtras)

- (void)rs_addObject:(id)obj {
	if (obj != nil)
		[self addObject:obj];
}


@end

#pragma mark -

//int RSStringIndexOfFirstInstanceOfCharacter(NSString *s, unichar ch) {
//	if (RSIsEmpty(s))
//		return NSNotFound;		
//	int ct = [s length];	
//	int i;
//	for (i = 1; i < ct - 1; i++) {
//		if ([s characterAtIndex:i] == ch)
//			return i;
//	}
//	return NSNotFound;
//}


//NSArray *RSArraySeparatedByFirstInstanceOfCharacter(NSString *s, unichar ch) {
//	/*Neither object in array contains the first instance ch. If ch appears as first or last character in s, return nil.*/
//	int ix = RSStringIndexOfFirstInstanceOfCharacter(s, ch);
//	if (ix == NSNotFound)
//		return nil;
//	NSString *s1 = [s substringToIndex:ix];
//	NSString *s2 = [s substringFromIndex:ix + 1];
//	return [NSArray arrayWithObjects:s1, s2, nil];
//}


//NSString *RSURLDecodedString(NSString *s) {
//	return [(NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)s, (CFStringRef) @"") autorelease];
//}


#pragma mark -

@implementation NSDate (NNWExtras)

static BOOL dateComponentsInvalid = YES;

+ (void)handleSignificantDateTimeChange {
	dateComponentsInvalid = YES;
}


static void _yearMonthDayComponentsForTodayAndYesterday(NSInteger *todayYear, NSInteger *todayMonth, NSInteger *todayDay, NSInteger *yesterdayYear, NSInteger *yesterdayMonth, NSInteger *yesterdayDay) {
	static NSInteger tyear = 0, tmonth = 0, tday = 0, yyear = 0, ymonth = 0, yday = 0;
	@synchronized([NSString class]) {
		if (dateComponentsInvalid) {
			dateComponentsInvalid = NO;
			NSDateComponents *todayComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
			tyear = [todayComponents year];
			tmonth = [todayComponents month];
			tday = [todayComponents day];
			NSDateComponents *yesterdayComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24)]];
			yyear = [yesterdayComponents year];
			ymonth = [yesterdayComponents month];
			yday = [yesterdayComponents day];
		}
	}
	*todayYear = tyear;
	*todayMonth = tmonth;
	*todayDay = tday;
	*yesterdayYear = yyear;
	*yesterdayMonth = ymonth;
	*yesterdayDay = yday;
}


+ (NSString *)contextualDateStringWithDate:(NSDate *)d {
	static NSDateFormatter *gTimeFormatter = nil;
	static NSDateFormatter *gDateTimeFormatter = nil;
	@synchronized([NSString class]) {
		if (!gTimeFormatter) {
			gTimeFormatter = [[NSDateFormatter alloc] init];
			[gTimeFormatter setDateStyle:kCFDateFormatterNoStyle];
			[gTimeFormatter setTimeStyle:kCFDateFormatterShortStyle];		
		}
		if (!gDateTimeFormatter) {
			gDateTimeFormatter = [[NSDateFormatter alloc] init];
			[gDateTimeFormatter setDateStyle:kCFDateFormatterShortStyle];
			[gDateTimeFormatter setTimeStyle:kCFDateFormatterShortStyle];		
		}
	}
//	NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
//	[timeFormatter setDateStyle:kCFDateFormatterNoStyle];
//	[timeFormatter setTimeStyle:kCFDateFormatterShortStyle];		
	NSInteger year = 0, month = 0, day = 0, yesterdayYear = 0, yesterdayMonth = 0, yesterdayDay = 0;
	_yearMonthDayComponentsForTodayAndYesterday(&year, &month, &day, &yesterdayYear, &yesterdayMonth, &yesterdayDay);
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:d];
	if ([dateComponents year] == year && [dateComponents month] == month && [dateComponents day] == day)
		return [NSString stringWithFormat:@"Today, %@", [gTimeFormatter stringFromDate:d]];		
	if ([dateComponents year] == yesterdayYear && [dateComponents month] == yesterdayMonth && [dateComponents day] == yesterdayDay)
		return [NSString stringWithFormat:@"Yesterday, %@", [gTimeFormatter stringFromDate:d]];
	
//	NSDateFormatter *dateTimeFormatter = [[[NSDateFormatter alloc] init] autorelease];
//	[dateTimeFormatter setDateStyle:kCFDateFormatterShortStyle];
//	[dateTimeFormatter setTimeStyle:kCFDateFormatterShortStyle];		
	return [gDateTimeFormatter stringFromDate:d];
}


@end

#pragma mark -

@implementation NSTimer (NNWExtras)

- (void)invalidateIfValid {
	if ([self isValid])
		[self invalidate];
}

@end


#pragma mark -

@implementation NSNotificationQueue (RSExtras)

- (void)enqueueIdleNotification:(NSNotification *)note {
	[self enqueueNotification:note postingStyle:NSPostWhenIdle];
}

@end


#pragma mark -


@implementation UIButton (NNWExtras)

- (void)configureForToolbar {
	self.contentMode = UIViewContentModeCenter;
	self.imageView.contentMode = UIViewContentModeCenter;
	self.clipsToBounds = NO;
	self.imageView.clipsToBounds = NO;
}


@end

#pragma mark -

@implementation UIColor (NNWExtras)

+ (UIColor *)colorWithHexString:(NSString *)hexString {
	NSString *s = RSStringReplaceAll(hexString, @"#", @"");
	s = [NSString stringWithCollapsedWhitespace:s];
	if (RSStringIsEmpty(s))
		return [UIColor blackColor];
	NSString *redString = [s substringToIndex:2];
	NSString *greenString = [s substringWithRange:NSMakeRange(2, 2)];
	NSString *blueString = [s substringWithRange:NSMakeRange(4, 2)];
	unsigned int red = 0, green = 0, blue = 0;
	[redString intValueFromHexDigit:&red];
	[greenString intValueFromHexDigit:&green];
	[blueString intValueFromHexDigit:&blue];
	return [UIColor colorWithRed:(float)red/255.0 green:(float)green/255.0 blue:(float)blue/255.0 alpha:1.0];
}


+ (UIColor *)unreadCountBackgroundColor {
	static UIColor *unreadCountBackgroundColor = nil;
	if (!unreadCountBackgroundColor)
		unreadCountBackgroundColor = [[UIColor colorWithRed:189.0/255.0 green:199.0/255.0 blue:214.0/255.0 alpha:1.0] retain];
	return unreadCountBackgroundColor;
}


+ (UIColor *)slateBlueColor {
	static UIColor *slateBlueColor = nil;
	if (!slateBlueColor)
		slateBlueColor = [[UIColor colorWithHexString:@"#708090"] retain];
	return slateBlueColor;
}


+ (UIColor *)webViewBackgroundColor {
	static UIColor *webViewBackgroundColor = nil;
	if (!webViewBackgroundColor)
		webViewBackgroundColor = [[UIColor colorWithRed:0.359 green:0.388 blue:0.404 alpha:1.000] retain];
	return webViewBackgroundColor;
}


+ (UIColor *)coolDarkGrayColor {
	return [self webViewBackgroundColor];
}


+ (UIColor *)veryBrightBlueColor {
	static UIColor *veryBrightBlueColor = nil;
	if (!veryBrightBlueColor)
		veryBrightBlueColor = [[UIColor colorWithHexString:@"#5B85D1"] retain];
	return veryBrightBlueColor;
}


// Color algorithms from http://www.cs.rit.edu/~ncs/color/t_convert.html

#define MAX3(a,b,c) (a > b ? (a > c ? a : c) : (b > c ? b : c))
#define MIN3(a,b,c) (a < b ? (a < c ? a : c) : (b < c ? b : c))

void RGBtoHSV(float r, float g, float b, float* h, float* s, float* v) {
	float min, max, delta;
	min = MIN3(r, g, b);
	max = MAX3(r, g, b);
	*v = max;				// v
	delta = max - min;
	if( max != 0 )
		*s = delta / max;		// s
	else {
		// r = g = b = 0		// s = 0, v is undefined
		*s = 0;
		*h = -1;
		return;
	}
	if( r == max )
		*h = ( g - b ) / delta;		// between yellow & magenta
	else if( g == max )
		*h = 2 + ( b - r ) / delta;	// between cyan & yellow
	else
		*h = 4 + ( r - g ) / delta;	// between magenta & cyan
	*h *= 60;				// degrees
	if( *h < 0 )
		*h += 360;
}

void HSVtoRGB( float *r, float *g, float *b, float h, float s, float v )
{
	int i;
	float f, p, q, t;
	if( s == 0 ) {
		// achromatic (grey)
		*r = *g = *b = v;
		return;
	}
	h /= 60;			// sector 0 to 5
	i = floor( h );
	f = h - i;			// factorial part of h
	p = v * ( 1 - s );
	q = v * ( 1 - s * f );
	t = v * ( 1 - s * ( 1 - f ) );
	switch( i ) {
		case 0:
			*r = v;
			*g = t;
			*b = p;
			break;
		case 1:
			*r = q;
			*g = v;
			*b = p;
			break;
		case 2:
			*r = p;
			*g = v;
			*b = t;
			break;
		case 3:
			*r = p;
			*g = q;
			*b = v;
			break;
		case 4:
			*r = t;
			*g = p;
			*b = v;
			break;
		default:		// case 5:
			*r = v;
			*g = p;
			*b = q;
			break;
	}
}


+ (UIColor *)color:(UIColor *)color withTransformedHue:(CGFloat)hue saturation:(CGFloat)saturation value:(CGFloat)value {
	const CGFloat* rgba = CGColorGetComponents(color.CGColor);
	CGFloat r = rgba[0];
	CGFloat g = rgba[1];
	CGFloat b = rgba[2];
	CGFloat h, s, v;
	RGBtoHSV(r, g, b, &h, &s, &v);
	h*= hue;
	v*= value;
	s*= saturation;
	HSVtoRGB(&r, &g, &b, h, s, v);
	return [UIColor colorWithRed:r green:g blue:b alpha:rgba[3]];
}


- (UIColor *)lightened {
	return [UIColor color:self withTransformedHue:1 saturation:0.6 value:1.1];
}

- (UIColor *)darkened {
	return [UIColor color:self withTransformedHue:1 saturation:1.0 value:0.6];	
}



@end


#pragma mark -

@implementation UIImage (NNWExtras)

+ (UIImage *)imageInRoundRect:(UIImage *)sourceImage size:(CGSize)size radius:(CGFloat)radius frameColor:(UIColor *)frameColor {
	UIGraphicsBeginImageContext(size);
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	NSUInteger strokeWidth = 1;
	CGContextSetLineWidth(context, strokeWidth);
	
	CGRect r = CGRectMake(0, 0, size.width, size.height);
	if (radius > size.width/2.0)
		radius = size.width/2.0;
	if (radius > size.height/2.0)
		radius = size.height/2.0;    
	
	CGFloat minx = CGRectGetMinX(r);// + 0.5;
	CGFloat midx = CGRectGetMidX(r);
	CGFloat maxx = CGRectGetMaxX(r);// - 0.5;
	CGFloat miny = CGRectGetMinY(r);// + 0.5;
	CGFloat midy = CGRectGetMidY(r);
	CGFloat maxy = CGRectGetMaxY(r);// - 0.5;
	CGContextSaveGState(context);
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
	CGContextClip(context);
	
	[sourceImage drawInRect:r blendMode:kCGBlendModeNormal alpha:1.0];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRestoreGState(context);
	CGContextRelease(context);
	UIGraphicsEndImageContext();
	
	if (frameColor) {
		UIGraphicsBeginImageContext(size);
		context = CGContextRetain(UIGraphicsGetCurrentContext());
		CGContextBeginPath(context);
		CGContextSetLineWidth(context, strokeWidth);
		CGContextMoveToPoint(context, minx, midy);
		CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
		CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
		CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
		CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
		CGContextClosePath(context);
		
		[newImage drawInRect:r blendMode:kCGBlendModeNormal alpha:1.0];
		[frameColor set];
		CGContextStrokePath(context);
		newImage = UIGraphicsGetImageFromCurrentImageContext();
		CGContextRelease(context);		
		UIGraphicsEndImageContext();
	}
	//	else
	//		finalImage = newImage;
	
	return newImage;
}


+ (UIImage *)scaledImage:(UIImage *)sourceImage toSize:(CGSize)targetSize {	
	return [sourceImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:targetSize interpolationQuality:kCGInterpolationHigh];
}


+ (UIImage *)gradientImageWithStartColor:(UIColor *)startColor endColor:(UIColor *)endColor topLineColor:(UIColor *)topLineColor size:(CGSize)size {
	CGFloat components[8] = {0, 0, 0, 1.0, 0, 0, 0, 1.0};
	size_t numStartComponents = CGColorGetNumberOfComponents([startColor CGColor]);
	if (numStartComponents != 4)
		return nil;
	size_t numEndComponents = CGColorGetNumberOfComponents([endColor CGColor]);
	if (numEndComponents != 4)
		return nil;
	const CGFloat *startComponents = CGColorGetComponents([startColor CGColor]);
	const CGFloat *endComponents = CGColorGetComponents([endColor CGColor]);
	components[0] = startComponents[0];
	components[1] = startComponents[1];
	components[2] = startComponents[2];
	components[4] = endComponents[0];
	components[5] = endComponents[1];
	components[6] = endComponents[2];
	
	CGRect r = CGRectZero;
	r.origin.x = 0;
	r.origin.y = 0;
	r.size = size;
	UIGraphicsBeginImageContext(CGSizeMake(r.size.width, r.size.height));
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	
	CGGradientRef myGradient;
	CGColorSpaceRef myColorspace;
	size_t num_locations = 2;
	CGFloat locations[2] = {0.0, 1.0};
	
	myColorspace = CGColorSpaceCreateDeviceRGB();
	myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
	CGPoint myStartPoint, myEndPoint;
	myStartPoint.x = 0.0;
	myStartPoint.y = 0.0;
	myEndPoint.x = 0.0;
	myEndPoint.y = CGRectGetMaxY(r);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), myGradient, myStartPoint, myEndPoint, 0);
	CGColorSpaceRelease(myColorspace);
	CGGradientRelease(myGradient);
	
	[topLineColor set];
	CGContextSetLineWidth(context, 1.0);
	CGContextSetLineCap(context, kCGLineCapSquare);
	CGContextMoveToPoint(context, r.origin.x, r.origin.y + 0.5);
	CGContextAddLineToPoint(context, r.origin.x + r.size.width, r.origin.y + 0.5);
	CGContextStrokePath(context);
	
	UIImage *backgroundGradientImage = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRelease(context);
	UIGraphicsEndImageContext();
	return backgroundGradientImage;		
}



+ (UIImage *)gradientImageWithHexColorStrings:(NSString *)startColorString endColorString:(NSString *)endColorString topLineString:(NSString *)topLineString size:(CGSize)size {
	UIColor *startColor = [UIColor colorWithHexString:startColorString];
	UIColor *endColor = [UIColor colorWithHexString:endColorString];
	UIColor *topLineColor = [UIColor colorWithHexString:topLineString];
	return [self gradientImageWithStartColor:startColor endColor:endColor topLineColor:topLineColor size:size];
}


+ (UIImage *)grayBackgroundGradientImageWithStartGray:(CGFloat)startGray endGray:(CGFloat)endGray topLineGray:(CGFloat)topLineGray size:(CGSize)size {
	CGRect r = CGRectZero;
	r.origin.x = 0;
	r.origin.y = 0;
	r.size = size;
	UIGraphicsBeginImageContext(CGSizeMake(r.size.width, r.size.height));
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	
	CGGradientRef myGradient;
	CGColorSpaceRef myColorspace;
	size_t num_locations = 2;
	CGFloat locations[2] = {0.0, 1.0};
	CGFloat components[8] = {startGray, startGray, startGray, 1.0,  // Start color
	endGray, endGray, endGray, 1.0 }; // End color
	
	myColorspace = CGColorSpaceCreateDeviceRGB();
	myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
	CGPoint myStartPoint, myEndPoint;
	myStartPoint.x = 0.0;
	myStartPoint.y = 0.0;
	myEndPoint.x = 0.0;
	myEndPoint.y = CGRectGetMaxY(r);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), myGradient, myStartPoint, myEndPoint, 0);
	CGColorSpaceRelease(myColorspace);
	CGGradientRelease(myGradient);
	
	[[UIColor colorWithWhite:topLineGray alpha:1.0] set];
	CGContextSetLineWidth(context, 1.0);
	CGContextSetLineCap(context, kCGLineCapSquare);
	CGContextMoveToPoint(context, r.origin.x, r.origin.y);// + 0.5);
	CGContextAddLineToPoint(context, r.origin.x + r.size.width, r.origin.y);// + 0.5);
	CGContextStrokePath(context);
	
	UIImage *backgroundGradientImage = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRelease(context);
	UIGraphicsEndImageContext();
	return backgroundGradientImage;
}


+ (UIImage *)imageWithGlow:(UIImage *)sourceImage {
	
	UIImage *glowImage = [UIImage imageNamed:@"Glow.png"];
	UIGraphicsBeginImageContext(CGSizeMake(glowImage.size.width, glowImage.size.height));
	
	CGSize sourceImageSize = sourceImage.size;
	CGRect rSourceImage = CGRectMake(0, 0, sourceImageSize.width, sourceImageSize.height);
	CGRect rImageSpace = CGRectMake(0, 0, glowImage.size.width, glowImage.size.height);
	rSourceImage = CGRectCenteredHorizontallyInContainingRect(rSourceImage, rImageSpace);
	rSourceImage = CGRectCenteredVerticalInContainingRect(rSourceImage, rImageSpace);
	rSourceImage.size.width = sourceImageSize.width;
	rSourceImage.size.height = sourceImageSize.height;
	rSourceImage = CGRectIntegral(rSourceImage);
	
	[glowImage drawAtPoint:CGPointZero];
	[sourceImage drawAtPoint:CGPointMake(rSourceImage.origin.x, rSourceImage.origin.y)];
	
	UIImage *imageWithGlow = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageWithGlow;
}


+ (UIImage *)imageWithoutGlow:(UIImage *)sourceImage {
	/*Makes sure it's the same size as the image with glow, so the toolbar doesn't do weird resizing.*/
	UIImage *glowImage = [UIImage imageNamed:@"Glow.png"];
	UIGraphicsBeginImageContext(CGSizeMake(glowImage.size.width, glowImage.size.height));
	
	CGSize sourceImageSize = sourceImage.size;
	CGRect rSourceImage = CGRectMake(0, 0, sourceImageSize.width, sourceImageSize.height);
	CGRect rImageSpace = CGRectMake(0, 0, glowImage.size.width, glowImage.size.height);
	rSourceImage = CGRectCenteredHorizontallyInContainingRect(rSourceImage, rImageSpace);
	rSourceImage = CGRectCenteredVerticalInContainingRect(rSourceImage, rImageSpace);
	rSourceImage.size.width = sourceImageSize.width;
	rSourceImage.size.height = sourceImageSize.height;
	rSourceImage = CGRectIntegral(rSourceImage);
	
	//[glowImage drawAtPoint:CGPointZero];
	[sourceImage drawAtPoint:CGPointMake(rSourceImage.origin.x, rSourceImage.origin.y)];
	
	UIImage *imageWithGlow = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageWithGlow;
}


- (CGSize)bestSizeForTargetSize:(CGSize)targetSize {
	CGSize imageSize = self.size;
	if (CGSizeEqualToSize(imageSize, targetSize))
		return imageSize;
	
	//	CGFloat width = imageSize.width;
	//	CGFloat height = imageSize.height;
	
	//	CGFloat targetWidth = targetSize.width;
	//	CGFloat targetHeight = targetSize.height;
	
	//	CGFloat scaleFactor = 0.0;
	//	CGFloat scaledWidth = targetWidth;
	//	CGFloat scaledHeight = targetHeight;	
	
	//	CGFloat widthFactor = targetWidth / width;
	//	CGFloat heightFactor = targetHeight / height;
	CGFloat scaleFactor = MIN(targetSize.width / imageSize.width, targetSize.height / imageSize.height);
	//	if (widthFactor < heightFactor) 
	//		scaleFactor = widthFactor;
	//	else
	//		scaleFactor = heightFactor;
	
	//	scaledWidth  = width * scaleFactor;
	//	scaledHeight = height * scaleFactor;
	CGRect r = CGRectMake(0, 0, imageSize.width * scaleFactor, imageSize.height * scaleFactor);
	return CGRectIntegral(r).size;
	//	return CGSizeMake(imageSize.width * scaleFactor, imageSize.height * scaleFactor);
}


@end

#pragma mark -

@implementation UITableView (BCExtras)

- (void)deselectCurrentRow {
	NSIndexPath *indexPath = [self indexPathForSelectedRow];
	if (indexPath)
		[self deselectRowAtIndexPath:indexPath animated:YES];
}

@end

#pragma mark -

@implementation UIView (RSExtras)

- (BOOL)rs_inPopover {
	UIView *nomad = self;
	while (nomad != nil) {
		NSString *className = NSStringFromClass([nomad class]);
		if ([className caseInsensitiveContains:@"popover"])
			return YES;
		nomad = nomad.superview;
	}
	return NO;	
}

@end


#pragma mark -

@implementation UIViewController (BCExtras)

#pragma mark Movies

- (void)playMediaAtURL:(NSURL *)url {
    MPMoviePlayerController *moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:url];
    moviePlayerController.scalingMode = MPMovieScalingModeAspectFit;
//    moviePlayerController.movieControlMode = MPMovieControlModeDefault;
	moviePlayerController.controlStyle = MPMovieControlStyleFullscreen;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_movieDidFinishCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayerController];
    [moviePlayerController play];
}


- (void)_movieDidFinishCallback:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:[notification object]];
	[self.view setNeedsLayout];
	[self viewWillAppear:NO];
	[self viewDidAppear:NO];
	[self.view setNeedsDisplay];
	[self.view performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];	
	[[notification object] release];
}


- (BOOL)orientationIsPortrait {
	return UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
}


- (float)navigationBarHeight {
	return [self orientationIsPortrait] ? 44.0f : 32.0f;
}


- (float)tabBarHeight {
	return 49.0f;
}


- (float)appFrameHeight {
	return [self appFrame].size.height;
}


- (float)appFrameWidth {
	return [self appFrame].size.width;
}


- (CGRect)appFrame {
	/*Flips if needed*/
	CGRect r = [UIScreen mainScreen].applicationFrame;
	if (![self orientationIsPortrait])
		r = CGRectMake(r.origin.y, r.origin.x, r.size.height, r.size.width);
	return r;
}

@end


#pragma mark -

@implementation UIWebView (NNWExtras)

- (void)releaseSafelyToWorkAroundOddWebKitCrashes {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(releaseSafelyToWorkAroundOddWebKitCrashes) withObject:nil waitUntilDone:NO];
		return;
	}
	self.delegate = nil;
	[self stopLoading];
	[self performSelector:@selector(autorelease) withObject:nil afterDelay:4.0];
}


@end