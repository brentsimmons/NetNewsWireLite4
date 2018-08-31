/*
	RSScriptsMenuController.m
	RancheroAppKit

	Created by Brent Simmons on Tue Jun 15 2004.
	Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import "RSScriptsMenuController.h"
#import "RSFileUtilities.h"
#import "RSFoundationExtras.h"
#import "RSAppKitUtilities.h"
#import "RSAppKitCategories.h"


NSString *RSScriptsMenuInstalledSamples = @"installedSampleScripts";
NSString *RSScriptsMenuSampleScriptsFolderName = @"SampleScripts";
NSString *RSScriptsMenuImageName = @"scriptsBW";
NSString *RSScriptsMenuFolderName = @"Scripts";
NSString *RSScriptsMenuOpenScriptsFolder =  @"Open Scripts Folder";
NSString *RSAppleScriptFileSuffix = @".scpt";


@interface RSScriptsMenuController ()

@property (nonatomic, retain) NSString *appSupportFolderName;
@property (nonatomic, retain) NSMenuItem *scriptsMenuItem;
@property (nonatomic, assign, readonly) BOOL samplesInstalled;
@property (nonatomic, retain) NSMenu *scriptsMenu;
@property (nonatomic, retain) NSArray *scriptsArray;
@property (nonatomic, retain) NSArray *lastDirectoryContents;

- (void)installSamples;
- (void)refreshMenu;

@end


@implementation RSScriptsMenuController

@synthesize appSupportFolderName = _appSupportFolderName;
@synthesize scriptsMenuItem = _scriptsMenuItem;
@synthesize scriptsMenu = _scriptsMenu;
@synthesize scriptsArray = _scriptsArray;
@synthesize lastDirectoryContents = _lastDirectoryContents;


- (id)initWithAppSupportFolderName:(NSString *)appSupportFolderName scriptsMenuItem:(NSMenuItem *)scriptsMenuItem scriptsMenu:(NSMenu *)scriptsMenu {

	self = [super init];
	if (self == nil)
		return nil;
	
	RSEnsureAppSupportSubFolderExists(RSScriptsMenuFolderName);
//
//	[RSMisc ensureApplicationSupportFolderSubfolderExists:RSScriptsMenuFolderName appName:appSupportFolderName];	
	_appSupportFolderName = [appSupportFolderName retain];
	_scriptsMenuItem = [scriptsMenuItem retain];
	_scriptsMenu = [scriptsMenu retain];
	
	[NSScriptSuiteRegistry sharedScriptSuiteRegistry];
	[_scriptsMenuItem setImage:[NSImage imageNamed:RSScriptsMenuImageName]];
	
	if (!self.samplesInstalled)
		[self installSamples];		
	[self refreshMenu];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericAppNotification:) name:NSApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericAppNotification:) name:NSApplicationDidUnhideNotification object:nil];

	return self;
	}
	

#pragma mark Accessors

- (NSString *)scriptsFolderPath {
	return [rs_app_delegate.pathToDataFolder stringByAppendingPathComponent:RSScriptMenuFolderName];
	//return RSAppSupportFilePath(RSScriptsMenuFolderName);
//	return [RSMisc applicationSupportFolderSubfolder:RSScriptsMenuFolderName appName:_appSupportFolderName ensureExists:NO];	
	}


#pragma mark Samples

- (BOOL)samplesInstalled {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:RSScriptsMenuInstalledSamples])
		return NO;
	return RSFolderHasAtLeastOneVisibleFile([self scriptsFolderPath]);
	}
	

- (void)setSamplesInstalled {
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:RSScriptsMenuInstalledSamples];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
	

- (void)installSamples {
	if (RSFileCopyFilesInFolder([[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:RSScriptsMenuSampleScriptsFolderName], [self scriptsFolderPath]))
		[self setSamplesInstalled];
	}


#pragma mark Menu

- (void)buildScriptsArray {
	[self setScriptsArray:RSFilePathArrayForFolder ([self scriptsFolderPath], NO)];
	}


- (void)populateScriptsMenu {
	
	[_scriptsMenu rs_removeAllItems];

	NSEnumerator *enumerator = [_scriptsArray objectEnumerator];
	NSString *oneScript;
	while ((oneScript = [enumerator nextObject])) {
			
		NSString *scriptTitle = [[NSFileManager defaultManager] displayNameAtPath:oneScript];
		if ([scriptTitle hasSuffix:RSAppleScriptFileSuffix])
			scriptTitle = [scriptTitle rs_stringByStrippingCaseInsensitiveSuffix:RSAppleScriptFileSuffix];
//			scriptTitle = [NSString stripSuffix:scriptTitle suffix:RSAppleScriptFileSuffix];

		[_scriptsMenu rs_addItemWithTitle:scriptTitle action:@selector(handleScript:) keyEquivalent:nil target:self representedObject:oneScript];
		}
	
	[_scriptsMenu rs_addSeparatorItem];
	
	[_scriptsMenu rs_addItemWithTitle:RSScriptsMenuOpenScriptsFolder action:@selector(openScriptsFolder:) keyEquivalent:nil target:self];		
	}


- (void)_swapOutScriptsMenuItem {
	if (!_indexOfScriptsMenuItem)
		_indexOfScriptsMenuItem = [[_scriptsMenuItem menu] indexOfItem:_scriptsMenuItem];
	[[_scriptsMenuItem menu] removeItem:_scriptsMenuItem];
	}


- (void)_swapInScriptsMenuItem {
	NSMenu *mainMenu = [NSApp mainMenu];
	if ([mainMenu indexOfItem:_scriptsMenuItem] != -1)
		return;
	if (!_indexOfScriptsMenuItem)
		_indexOfScriptsMenuItem = [mainMenu numberOfItems] - 1;
	[mainMenu insertItem:_scriptsMenuItem atIndex:_indexOfScriptsMenuItem];
	}


- (void)refreshMenu {
	[self buildScriptsArray];
	if (RSIsEmpty(_scriptsArray))
		[self _swapOutScriptsMenuItem];
	else
		[self _swapInScriptsMenuItem];
	[self populateScriptsMenu];
	}
	
	
- (void)openScriptInEditor:(NSString *)path {	
	[[NSWorkspace sharedWorkspace] openFile:path];	
	}


#pragma mark JavaScript

- (void)_runJavaScript:(NSString *)path {
//	/*Read the file to get the code. Get the current webview (description view, smashview, web page, etc.). Run the code in the context of that webview.*/
//	NSStringEncoding encoding = NSUTF8StringEncoding;
//	NSString *s = [[[NSString alloc] initWithContentsOfFile:path usedEncoding:&encoding error:nil] autorelease];
//	if (RSIsEmpty(s))
//		return;
//	s = [(NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)s, CFSTR("")) autorelease];
//	s = [s rs_replaceAll:@"\n" with:@""];
//	s = [s rs_replaceAll:@"\r" with:@""];
//	WebView *webview = [[NNWAppController sharedController] currentWebView];
//	if (!webview)
//		return;
//	BOOL didSetHostWindow = NO;
//	if (![webview hostWindow]) {
//		[webview setHostWindow:[[NSApp delegate] newsreaderWindow]];
//		didSetHostWindow = YES;
//		}
//	//id javaScriptResult = [[webview windowScriptObject] evaluateWebScript:s];
//	(void)[[webview windowScriptObject] evaluateWebScript:s];
////	NSString *javaScriptResult = [webview stringByEvaluatingJavaScriptFromString:s];
////	if (javaScriptResult)
////		NSLog(@"JavaScript result: %@", javaScriptResult);
//	if (didSetHostWindow)
//		[webview setHostWindow:nil];
	}


#pragma mark AppleScript

- (void)compileAndRunAppleScript:(NSString *)scriptPath {
	
	NSURL *scriptURL = [[[NSURL alloc] initFileURLWithPath:scriptPath] autorelease];
	NSDictionary *errorInfo = nil;
	NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorInfo] autorelease];

	if (script == nil)
		return;
	BOOL scriptDidCompile = [script compileAndReturnError:&errorInfo];	
	NSString *errorMessage = [errorInfo objectForKey:NSAppleScriptErrorMessage];
	
	if (!scriptDidCompile) {
		if (errorMessage != nil)
			NSBeginAlertSheet (@"Script Compile Error", @"Nuts", nil, nil, nil, self, nil, nil, nil, errorMessage);
		return;
	}
	
	[script executeAndReturnError:&errorInfo];	
	errorMessage = [errorInfo objectForKey:NSAppleScriptErrorMessage];	
	NSString *errorNumber = [errorInfo objectForKey:NSAppleScriptErrorNumber];
	
	if (errorMessage != nil) {
		NSInteger errorCode = noErr;		
		if (errorNumber != nil)
			errorCode = [errorNumber integerValue];		
		if (errorCode != userCanceledErr)
			NSBeginAlertSheet (@"Script Error", @"Nuts", nil, nil, nil, self, nil, nil, nil, errorMessage);		
	}
}


#pragma mark Actions

- (IBAction)handleScript:(id)sender {
	if (RSOptionKeyDown())
		[self openScriptInEditor:[sender representedObject]];
	else {
		if ([[sender representedObject] hasSuffix:@".js"])
			[self _runJavaScript:[sender representedObject]];
		else
			[self compileAndRunAppleScript:[sender representedObject]];
		}
	}


- (IBAction)openScriptsFolder:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[self scriptsFolderPath]]];
}


#pragma mark Directory Changes

- (BOOL)didDirectoryChange {
	
	NSArray *directoryContents = RSFilenameArrayForFolder([self scriptsFolderPath]);
	
	if (_lastDirectoryContents == nil) {
		[self setLastDirectoryContents:directoryContents];
		return NO;
		}
	
	if ([_lastDirectoryContents isEqualToArray:directoryContents])
		return NO;
	[self setLastDirectoryContents:directoryContents];
	return YES;
	}


- (void)checkForChangedScriptsFolder {
	if (![NSApp isActive])
		return;
	if ([self didDirectoryChange])
		[self refreshMenu];		
	}


#pragma mark Notifications

- (void)handleGenericAppNotification:(NSNotification *)note {
	[self checkForChangedScriptsFolder];
	}
	
	
@end


