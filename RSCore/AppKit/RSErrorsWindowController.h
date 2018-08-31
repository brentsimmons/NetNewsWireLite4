/*
	RSErrorsWindowController.h
	NetNewsWire

	Created by Brent Simmons on Sun Apr 04 2004.
	Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


@interface RSErrorsWindowController : NSWindowController {
@private
	IBOutlet NSTextView *_consoleTextView;	
	BOOL _flWindowShown;
	BOOL _buttonsEnabled;
	NSMutableString *_initialConsoleText;
}


- (IBAction)clearConsole:(id)sender;
//- (IBAction)saveToFile:(id)sender;


@end


@interface RSErrorsWindow : NSWindow
@end
