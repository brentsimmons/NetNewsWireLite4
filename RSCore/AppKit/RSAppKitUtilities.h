//
//  RSAppKitUtilities.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


BOOL RSOptionKeyDown(void);


extern NSString *WebURLsWithTitlesPboardType;
extern NSString *URLCorePboardType;
extern NSString *URLNameCorePboardType;

extern NSString *RSRSSSourceType;
extern NSString *RSRSSPboardType;


/*If pasteboard is nil, uses [NSPasteboard generalPasteboard]*/

void RSCopyStringToPasteboard(NSString *stringToCopy, NSPasteboard *pasteboard);
void RSCopyURLStringToPasteboard(NSString *urlString, NSPasteboard *pasteboard);
void RSCopyURLStringAndNameToPasteboard(NSString *urlString, NSString *name, NSPasteboard *pasteboard);

NSString *RSURLStringOnClipboard(BOOL translateFeedURLs);

void RSHelpOpenAnchor(NSString *anchor);
void RSHelpGotoPage(NSString *page);


void RSBringAppToFront(NSString *f);
BOOL RSHasAppWithName(NSString *appName);
OSStatus RSLaunchAppWithPathSync(NSString *f);
NSString *RSPathToDefaultAppForURLScheme(NSString *urlScheme);


@interface RSDiskSpaceChecker : NSObject

+ (BOOL)isDiskSpaceLow;
+ (void)runDiskSpaceLowSheet;

@end

@interface RSTimeBomb : NSObject

+ (void)runTimeBombSheet;

@end