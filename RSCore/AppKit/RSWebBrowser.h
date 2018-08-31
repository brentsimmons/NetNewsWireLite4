/*
	RSWebBrowser.h
	RancheroAppKit
	
	Created by Brent Simmons on Sat Mar 15 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


extern void RSWebBrowserOpenFile (NSString *f);

extern NSString *RSPathToDefaultWebBrowser(void);
extern NSString *RSDefaultWebBrowserName(void);

extern void RSWebBrowserOpenURLInFront(NSString *urlString);
extern void RSWebBrowserOpenURL(NSString *urlString, BOOL inBackground);


@interface RSWebBrowser : NSObject


+ (void) browserOpenInFront: (NSString *) urlString;
+ (void) browserOpen: (NSString *) urlString inBackground: (BOOL) flBackground;
+ (BOOL) urlStringHasPluginSuffix: (NSString *) urlString;


@end
