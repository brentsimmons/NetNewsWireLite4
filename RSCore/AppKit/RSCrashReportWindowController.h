//
//  RSCrashReportWindowController.h
//  NetNewsWire
//
//  Created by Brent Simmons on 2/25/07.
//  Copyright 2007 Ranchero Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


void RSCheckForCrash(void);


@interface RSCrashReportWindowController : NSWindowController {
@private
	IBOutlet NSTextView *_crashReportTextView;
	IBOutlet NSTextField *_titleTextField;
	IBOutlet NSTextField *_thanksTextField;
	
	NSString *_crashReport;
	NSDate *_crashReportDate;
}


- (IBAction)dontSendCrashReport:(id)sender;
- (IBAction)sendCrashReport:(id)sender;


@end
