//
//  RSAppKitUtilities.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "RSAppKitUtilities.h"
#import "RSFoundationExtras.h"
#import "RSFileUtilities.h"


#define kKeymask_option 2048

BOOL RSOptionKeyDown(void) {
	return GetCurrentEventKeyModifiers() == kKeymask_option;
}


#pragma mark Pasteboard

NSString *WebURLsWithTitlesPboardType = @"WebURLsWithTitlesPboardType";
NSString *URLCorePboardType = @"CorePasteboardFlavorType 0x75726C20";
NSString *URLNameCorePboardType = @"CorePasteboardFlavorType 0x75726C6E";

NSString *RSRSSSourceType = @"CorePasteboardFlavorType 0x52535373";
NSString *RSRSSPboardType = @"CorePasteboardFlavorType 0x52535369";

void RSCopyStringToPasteboard(NSString *stringToCopy, NSPasteboard *pasteboard) {
	if (stringToCopy == nil)
		return;
	if (pasteboard == nil)
		pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];	
	[pasteboard setString:stringToCopy forType:NSStringPboardType];
}


void RSCopyURLStringToPasteboard(NSString *urlString, NSPasteboard *pasteboard) {
	if (RSStringIsEmpty(urlString))
		return;
	if (pasteboard == nil)
		pasteboard = [NSPasteboard generalPasteboard];
	NSURL *url = [NSURL URLWithString:urlString];
	if (url != nil) {
		[pasteboard declareTypes:[NSArray arrayWithObjects:URLCorePboardType, NSURLPboardType, NSStringPboardType, nil] owner:nil];
		[url writeToPasteboard:pasteboard];
	}
	else
		[pasteboard declareTypes:[NSArray arrayWithObjects:URLCorePboardType, NSStringPboardType, nil] owner:nil];
	[pasteboard setString:urlString forType:URLCorePboardType];
	[pasteboard setString:urlString forType:NSStringPboardType];	
}


void RSCopyURLStringAndNameToPasteboard(NSString *urlString, NSString *name, NSPasteboard *pasteboard) {
	if (RSStringIsEmpty(urlString))
		return;
	if (RSStringIsEmpty(name)) {
		RSCopyURLStringToPasteboard(urlString, pasteboard);
		return;
	}
	NSArray *urlsArray, *urlStringsArray, *urlTitlesArray;
	NSURL *url = [NSURL URLWithString: urlString];
	
	if (url != nil)
		[pasteboard declareTypes:[NSArray arrayWithObjects: WebURLsWithTitlesPboardType, URLCorePboardType, URLNameCorePboardType, NSURLPboardType, NSStringPboardType, nil] owner:nil];
	else {		
		[pasteboard declareTypes:[NSArray arrayWithObjects: WebURLsWithTitlesPboardType, URLCorePboardType, URLNameCorePboardType, NSURLPboardType, NSStringPboardType, nil] owner:nil];
		[url writeToPasteboard:pasteboard];	
	}
	
	urlStringsArray = [NSArray arrayWithObject:urlString];
	urlTitlesArray = [NSArray arrayWithObject:name];
	urlsArray = [NSArray arrayWithObjects:urlStringsArray, urlTitlesArray, nil];
	[pasteboard setPropertyList:urlsArray forType:WebURLsWithTitlesPboardType];
	
	[pasteboard setString:name forType:URLNameCorePboardType];	
	
	[pasteboard setString:urlString forType:URLCorePboardType];
	[pasteboard setString:urlString forType:NSStringPboardType];	
	
}


NSString *RSURLStringOnClipboard(BOOL translateFeedURLs) {
	NSString *stringType = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];	
	if (!stringType)
		return nil;
	NSString *s = [[NSPasteboard generalPasteboard] stringForType:stringType];
	
	if (RSIsEmpty(s))
		return nil;
	s = [s rs_stringByTrimmingWhitespace];
	if ([s hasPrefix:@"http"])
		return s;
	if (translateFeedURLs && RSURLIsFeedURL(s))
		return RSURLWithFeedURL(s);
	return nil;
}


#pragma mark Help Book

static void _registerHelpBookIfNeeded(void) {
	static BOOL didRegisterHelpBook = NO;
	if (didRegisterHelpBook)
		return;
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	FSRef fsref;
	if (FSPathMakeRef((const UInt8 *)[bundlePath fileSystemRepresentation], &fsref, nil) != noErr)
		return;
	AHRegisterHelpBook(&fsref);
	didRegisterHelpBook = YES;
}



void RSHelpOpenAnchor(NSString *anchor) {
	_registerHelpBookIfNeeded();
	[[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]];	
}


void RSHelpGotoPage(NSString *page) {
	_registerHelpBookIfNeeded();
	AHGotoPage((CFStringRef)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"], (CFStringRef)page, nil);
}


#pragma mark Apps

void RSBringAppToFront(NSString *f) {
	
	NSString *appName = RSFileDisplayNameAtPath(f, YES);
	NSString *appNameWithAppSuffix = RSAddStrings(appName, @".app");
	
	OSStatus err = noErr;
	ProcessSerialNumber psn = {0, kNoProcess};
	CFStringRef oneAppName = nil;
	BOOL foundPSN = NO;
	
	while (true) {
		err = GetNextProcess(&psn);
		if (err != noErr)
			break;
		err = CopyProcessName(&psn, &oneAppName);
		if (err != noErr)
			break;
		if (RSEqualNotEmptyStrings(appName, (NSString *)oneAppName) || RSEqualNotEmptyStrings(appNameWithAppSuffix, (NSString *)oneAppName))
			foundPSN = YES;
		CFRelease(oneAppName);
		if (foundPSN)
			break;
	}
	
	if (foundPSN)
		SetFrontProcess(&psn);
}


BOOL RSHasAppWithName(NSString *appName) {
	NSString *f = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
	return !RSStringIsEmpty(f) && [[NSFileManager defaultManager] fileExistsAtPath:f];
}


OSStatus RSLaunchAppWithPathSync(NSString *f) {
	if (!RSFileExists(f))
		return fnfErr;
	LSLaunchURLSpec launchSpec;
	launchSpec.appURL = (CFURLRef)[NSURL fileURLWithPath:f];
	launchSpec.itemURLs = nil;
	launchSpec.passThruParams = nil;
	launchSpec.launchFlags = kLSLaunchAndDisplayErrors;
	launchSpec.asyncRefCon = nil;
	return LSOpenFromURLSpec(&launchSpec, nil);
}


NSString *RSPathToDefaultAppForURLScheme(NSString *urlScheme) {
	NSURL* appURL = nil;	
	if (![urlScheme hasSuffix:@":"])
		urlScheme = RSAddStrings(urlScheme, @":");
	LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:urlScheme], kLSRolesAll, nil, (CFURLRef *)&appURL);
	return [appURL path];
}


#pragma mark Disk Space

@implementation RSDiskSpaceChecker

+ (BOOL)isDiskSpaceLow {
	NSDictionary *volumeAtts = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
	if (volumeAtts == nil)
		return NO; //this shouldn't happen, but I have no idea what to do if it does
	NSNumber *freeSpaceNum = [volumeAtts objectForKey:NSFileSystemFreeSize];
	return freeSpaceNum && [freeSpaceNum unsignedLongLongValue] < 1024 * 1024 * 100;
}


+ (void)diskSpaceLowSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[NSApp terminate:self]; 	
}


//TODO: figure out how to deal with localized strings in framework

#define NNW_LOW_ON_DISK_SPACE_TITLE NSLocalizedString(@"Low on Disk Space!", "Disk space sheet title")
#define NNW_LOW_ON_DISK_SPACE_MESSAGE NSLocalizedString(@"Your hard drive is running out of space. It’s a good idea to quit and free up some space.", "Disk space sheet title")

+ (void)runDiskSpaceLowSheet {	
	NSBeginAlertSheet(NNW_LOW_ON_DISK_SPACE_TITLE, @"Quit", nil, nil, nil, self, @selector(diskSpaceLowSheetDidEnd:returnCode:contextInfo:), nil, nil, NNW_LOW_ON_DISK_SPACE_MESSAGE);
}

@end


@implementation RSTimeBomb

#pragma mark Time Bomb

+ (void)genericTerminateSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[NSApp terminate:self]; 	
}

#define NNW_EXPIRED_TITLE NSLocalizedString(@"This beta has expired", @"Beta expired sheet title")
#define NNW_EXPIRED_MESSAGE NSLocalizedString(@"You should be able to get the latest version on the Mac App Store. You may need to delete this copy from your hard drive first. (But you can leave your preferences and data intact.) Sorry for the inconvenience!", @"Beta expired sheet message")

+ (void)runTimeBombSheet {
	NSBeginAlertSheet(NNW_EXPIRED_TITLE, @"Quit", nil, nil, nil, self, @selector(genericTerminateSheetDidEnd:returnCode:contextInfo:), nil, nil, NNW_EXPIRED_MESSAGE);
	
}

@end
