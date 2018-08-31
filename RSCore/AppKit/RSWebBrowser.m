/*
	RSWebBrowser.m
	RancheroAppKit
	
	Created by Brent Simmons on Sat Mar 15 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import "RSWebBrowser.h"
#import "RSFileUtilities.h"
#import "RSFoundationExtras.h"


@implementation RSWebBrowser


+ (void)browserOpenInFront:(NSString *)urlString {
	RSWebBrowserOpenURLInFront(urlString);
	}


+ (void)browserOpen:(NSString *)urlString inBackground:(BOOL)flBackground {
	RSWebBrowserOpenURL(urlString, flBackground);
	}

	

+ (NSArray *)pluginSuffixes {	
	static NSArray *pluginSuffixes = nil;	
	if (!pluginSuffixes)
		pluginSuffixes = [[NSArray arrayWithObjects:@".mp3", @".au", @".snd", @".mid", @".midi", @".aiff", @".avi", @".mov", nil] retain];
	return pluginSuffixes;
	}
	

+ (BOOL)urlString:(NSString *)urlString hasSuffixInArray:(NSArray *)suffixArray {
	
	NSString *oneSuffix;
	NSUInteger i = 0;
	NSUInteger ct = [suffixArray count];
	
	for (i = 0; i < ct; i++) {
		oneSuffix = [suffixArray objectAtIndex: i];
		if ([urlString hasSuffix: oneSuffix])
			return (YES);
		}
	
	return (NO);
	}


+ (BOOL)urlStringHasPluginSuffix:(NSString *)urlString {
	return [self urlString:urlString hasSuffixInArray:[self pluginSuffixes]];
	}

	
@end


#pragma mark Default Browser

NSString *RSDefaultWebBrowserName(void) {
	NSString *f = RSPathToDefaultWebBrowser();
	if (RSIsEmpty(f))
		return nil;
	return RSFileDisplayNameAtPath(f, YES);
	}
	
	
NSString *RSPathToDefaultWebBrowser(void) {
	CFURLRef appURL ;
	LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http:"], kLSRolesAll, nil, &appURL);
    NSURL *appURLARC = (__bridge_transfer NSURL *)appURL;
    
	if (!appURLARC)
		return nil;
	return [appURLARC path];	
	}
	

#pragma mark Strings

static void replaceAmpersandEntities(NSMutableString *s) {
	[s replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"&#38;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
}


static NSString *_prepareURLStringForBrowser(NSString *urlString) {
	NSMutableString *s = [[urlString mutableCopy] autorelease];
	CFStringTrimWhitespace((CFMutableStringRef)s);
	[s replaceOccurrencesOfString:@" " withString:@"%20" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	replaceAmpersandEntities(s);
	[s replaceOccurrencesOfString:@"^" withString:@"%5E" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	return s;
	}
	

#pragma mark Opening

void RSWebBrowserOpenFile(NSString *f) {
	/*Make sure a browser -- not BBEdit or whatever -- opens a local file.*/
	NSString *browserPath = RSPathToDefaultWebBrowser();
	if (RSIsEmpty(browserPath))
		return;
	[[NSWorkspace sharedWorkspace] openFile:f withApplication:browserPath];
	}


void RSWebBrowserOpenURLInFront(NSString *urlString) {
	RSWebBrowserOpenURL(urlString, NO);
	}


void RSWebBrowserOpenURL(NSString *urlString, BOOL inBackground) {	
	if (RSIsEmpty(urlString))
		return;
	NSURL *url = [NSURL URLWithString:_prepareURLStringForBrowser(urlString)];
	if (!url)
		return;
	if (inBackground) {
		NSArray *urlsArray = [NSArray arrayWithObject:url];
		LSLaunchURLSpec urlSpec;		
		urlSpec.appURL = nil;	
        urlSpec.itemURLs = (__bridge_retained CFArrayRef)urlsArray;
		urlSpec.passThruParams = nil;
		urlSpec.launchFlags = kLSLaunchDontSwitch;
		urlSpec.asyncRefCon = nil;		
		LSOpenFromURLSpec(&urlSpec, nil);			
	}
	else
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
