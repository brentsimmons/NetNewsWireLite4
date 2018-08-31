/*
	RSScriptsMenuController.h
	RancheroAppKit

	Created by Brent Simmons on Tue Jun 15 2004.
	Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


@interface RSScriptsMenuController : NSObject {

	@private
		NSMenu *_scriptsMenu;
		NSMenuItem *_scriptsMenuItem;
		NSArray *_scriptsArray;
		NSString *_appSupportFolderName;
		NSArray *_lastDirectoryContents;
		NSInteger _indexOfScriptsMenuItem;
	}


- (id)initWithAppSupportFolderName:(NSString *)appSupportFolderName scriptsMenuItem:(NSMenuItem *)scriptsMenuItem scriptsMenu:(NSMenu *)scriptsMenu;
	

@end
