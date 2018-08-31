//
//  RSCrashReportWindowController.m
//  NetNewsWire
//
//  Created by Brent Simmons on 2/25/07.
//  Copyright 2007 Ranchero Software. All rights reserved.
//

#import "RSCrashReportWindowController.h"
#import "RSFoundationExtras.h"

//TODO: set user-agent
//TODO: get xib file in RSCore

static void _RSSendCrashReport(NSString *crashReport);

@interface RSCrashReportWindowController ()
@property (nonatomic, retain) NSString *crashReport;
@property (nonatomic, retain) NSDate *crashReportDate;
- (void)updateUI;
@end


@implementation RSCrashReportWindowController

@synthesize crashReport = _crashReport;
@synthesize crashReportDate = _crashReportDate;


#pragma mark Init

- (id)init {	
	return [super initWithWindowNibName:@"CrashReport"];
	}


#pragma mark Dealloc

- (void)dealloc {
	[_crashReport release];
	[_crashReportDate release];
	[super dealloc];
	}
	
	
#pragma mark Window

- (void)showWindow:(id)sender {
	[super showWindow:sender];
	[self updateUI];
	}
	
	
- (void)windowDidLoad {
	[self setWindowFrameAutosaveName:@"CrashReportFound"];
	[self updateUI];
	[_crashReportTextView setFont:[NSFont userFixedPitchFontOfSize:0]];
	[_crashReportTextView setTextContainerInset:NSMakeSize(5.0, 5.0)];
	}


#pragma mark Window delegate

- (void)windowWillClose:(NSNotification *)note {
	[self performSelectorOnMainThread:@selector(release) withObject:nil waitUntilDone:NO];
	}
	

#pragma mark UI

- (void)_updateTitle {
	if (self.crashReportDate == nil)
		return;
	NSString *s = [_titleTextField stringValue];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];	
	s = RSStringReplaceAll(s, @"[[timedate]]", [dateFormatter stringFromDate:self.crashReportDate]);
	[_titleTextField setStringValue:s];
	}
	

- (void)_updateTextView {
	if (self.crashReport)
		[_crashReportTextView setString:self.crashReport];
	}
	
	
- (void)updateUI {
	[self _updateTitle];
	[self _updateTextView];
	}



#pragma mark Sending	

- (void)_sendCrashReportInNewThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	_RSSendCrashReport(self.crashReport);
	[pool drain];
	}


#pragma mark Actions

- (IBAction)dontSendCrashReport:(id)sender {
	[self close];	
	}
	

- (IBAction)sendCrashReport:(id)sender {
	[_thanksTextField setHidden:NO];
	[NSThread detachNewThreadSelector:@selector(_sendCrashReportInNewThread) toTarget:self withObject:nil];
	[self performSelector:@selector(close) withObject:nil afterDelay:2.0]; /*Display Thanks*/
	}


- (void)sendAutomaticCrashReport {
	[NSThread detachNewThreadSelector:@selector(_sendCrashReportInNewThread) toTarget:self withObject:nil];
}


@end


#pragma mark C

void RSCheckForCrash(void) {

	/*Based originally on Uli Kusterer's UKCrashReporter: http://www.zathras.de/angelweb/blog-ukcrashreporter-oh-one.htm
	Expanded to put up a window that shows the crash log and shows progress while sending it.
	It also ignores crashes more than a day old, or else I'd get thousands of crashes the first
	time the build with this code is released.*/
	
	@try {	
		NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
		NSString *crashLogsFolder = [@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath];
		NSString *crashLogName = [appName stringByAppendingString:@".crash.log"];
		NSString *crashLogPath = [crashLogsFolder stringByAppendingPathComponent:crashLogName];

		/*PBS 31 Oct. 2007: find most recent crash report on Leopard, which does one file per report.*/
	
//		NSArray *filenames = [[NSFileManager defaultManager] directoryContentsAtPath:crashLogsFolder];
		NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:crashLogsFolder error:nil];
		NSUInteger i;
		if (RSIsEmpty(filenames))
			return;
		NSUInteger ct = [filenames count];
		NSString *oneFilename;
		NSDate *dateOfMostRecentFile = [NSDate distantPast];
		NSDate *oneDate;
		NSString *mostRecentFilePath = nil;
		NSString *lowerAppName = [appName lowercaseString];
		NSDictionary *oneFileAttsDict;
		NSString *oneFilePath;
		for (i = 0; i < ct; i++) {
			oneFilename = [filenames rs_safeObjectAtIndex:i];
			if ([[oneFilename lowercaseString] hasPrefix:lowerAppName]) {
				oneFilePath = [crashLogsFolder stringByAppendingPathComponent:oneFilename];
				oneFileAttsDict = [[NSFileManager defaultManager] attributesOfItemAtPath:oneFilePath error:nil];
//				oneFileAttsDict = [[NSFileManager defaultManager] fileAttributesAtPath:oneFilePath traverseLink:YES];
				oneDate = [oneFileAttsDict fileModificationDate];
				if (oneDate && [oneDate laterDate:dateOfMostRecentFile] == oneDate) {
					dateOfMostRecentFile = oneDate;
					mostRecentFilePath = [[oneFilePath copy] autorelease];
					}
				}
			}
		if (mostRecentFilePath)
			crashLogPath = [[mostRecentFilePath copy] autorelease];
		else
			return;

		NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:oneFilePath error:nil];
		//NSDictionary *fileAttrs = [[NSFileManager defaultManager] fileAttributesAtPath:crashLogPath traverseLink:YES];
		NSDate *lastTimeCrashLogged = (fileAttrs == nil) ? nil : [fileAttrs fileModificationDate];
		
		if (!lastTimeCrashLogged)
			return;

		NSTimeInterval lastCrashReportInterval = [[NSUserDefaults standardUserDefaults] floatForKey:@"lastCrashReportDate"] + 10; /*10 is slop to avoid duplicates*/
		NSDate *lastTimeCrashReported = [NSDate dateWithTimeIntervalSince1970:lastCrashReportInterval];
		NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24)];

		if (!([lastTimeCrashReported compare:lastTimeCrashLogged] == NSOrderedAscending && [yesterday compare:lastTimeCrashLogged] == NSOrderedAscending))
			return;
			
		NSString *currentReport = [NSString rs_stringWithContentsOfUTF8EncodedFile:crashLogPath];
		
		/*Use a hash to eliminate duplicates.*/
		NSData *hashOfCurrentReport = [NSData rs_md5HashWithString:currentReport];
		NSData *hashOfLastReport = [[NSUserDefaults standardUserDefaults] objectForKey:@"crashHash"];
		BOOL equalHashes = (hashOfLastReport != nil && [hashOfCurrentReport isEqualToData:hashOfLastReport]);
		[[NSUserDefaults standardUserDefaults] setObject:hashOfCurrentReport forKey:@"crashHash"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		if (equalHashes)
			return;
		
		[[NSURLCache sharedURLCache] performSelectorOnMainThread:@selector(removeAllCachedResponses) withObject:nil waitUntilDone:NO]; /*Sometimes the WebKit cache is fucked up, which causes crashes -- this fixes it*/
		
		RSCrashReportWindowController *windowController = [[RSCrashReportWindowController alloc] init]; 
		if (!windowController)
			return;
		[[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:@"lastCrashReportDate"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		windowController.crashReport = currentReport;
		windowController.crashReportDate = lastTimeCrashLogged;
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"sendCrashLogsAutomatically"]) {
			[windowController sendAutomaticCrashReport];
			return;
		}
		
		[windowController showWindow:nil];
		[[windowController window] makeKeyAndOrderFront:nil];
		}
	@catch(id obj) {
		}
	}


static void _RSSendCrashReport(NSString *crashReport) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@try {
		[[crashReport retain] autorelease];
		NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://ranchero.com/crashreportcatcher4Lite.php"]];
		NSString *boundary = @"0xKhTmLbOuNdArY";
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
		
		NSData *header = [[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"crashlog\"\r\n\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
		NSMutableData *formData = [[header mutableCopy] autorelease];
		[formData appendData:[crashReport dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
		[formData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

		[postRequest setHTTPMethod:@"POST"];
		[postRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
		//[postRequest setValue:NNWUserAgent forHTTPHeaderField:@"User-Agent"];
		[postRequest setHTTPBody:formData];
		
		NSURLResponse *response = nil;
		NSError *error = nil;
		(void)[NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response error:&error];	
		}
	@catch(id obj) {
		}
	[pool release];	
	}
	
	
