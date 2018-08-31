/*
	RSErrorsWindowController.h
	NetNewsWire

	Created by Brent Simmons on Sun Apr 04 2004.
	Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import "RSErrorsWindowController.h"
#import "RSAppKitCategories.h"
#import "RSErrors.h"
#import "RSFoundationExtras.h"


@interface RSErrorsWindowController (Forward)
- (void)updateButtons;
- (void)appendToConsole:(NSString *)s;
- (void)setButtonsEnabled:(BOOL)flag;
@end


@implementation RSErrorsWindowController


#pragma mark Init

- (id)init {	
	self = [super initWithWindowNibName:@"ErrorsConsoleWindow"];
	if (!self)
		return nil;
	_initialConsoleText = [[NSMutableString alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleErrorMessage:) name:RSLoggableErrorDidHappenNotification object:nil];
	return self;
	}


#pragma mark Window

- (void)showWindow:(id)sender {
	[super showWindow:sender];
	[self updateButtons];
	}
	
	
- (void)windowDidLoad {
	//[[self window] setBackgroundColor:[NSColor grayWindowBackgroundColor]];
	_flWindowShown = YES;
	[_consoleTextView setFont:[NSFont userFixedPitchFontOfSize:0]];
	[_consoleTextView setTextContainerInset:NSMakeSize(5.0, 5.0)];
	//[_consoleTextView setBackgroundColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.9]];
	//[_consoleTextView setTextColor:[NSColor colorWithCalibratedRed:0.78 green:1.0 blue:0.705 alpha:1.0]];
	[_consoleTextView setTextColor:[NSColor blackColor]];
	[self appendToConsole:_initialConsoleText];
	[_initialConsoleText release];
	_initialConsoleText = nil;
	}


#pragma mark Notifications

- (void)handleErrorMessage:(NSNotification *)note {	
	NSError *error = [note object];
	NSString *errorString = [error localizedDescription];
	NSMutableString *s = [NSMutableString stringWithString:@""];
	NSString *dateString = [[[note userInfo] objectForKey:RSErrorDateKey] description];
	[s rs_safeAppendString:dateString];
	[s appendString:@": "];
	[s rs_safeAppendString:errorString];
	[s appendString:@"\n"];
	[self appendToConsole:s];
	}

	
#pragma mark Buttons

- (void)updateButtons {
	if (![self rs_isOpen])
		return;
	[self setButtonsEnabled:_flWindowShown && !RSIsEmpty([[_consoleTextView textStorage] string])];
	}


- (void)setButtonsEnabled:(BOOL)flag {
	_buttonsEnabled = flag;
	}
	
	
#pragma mark Console
	
- (void)trimConsoleTextIfNeeded {		
	NSMutableString *s = _initialConsoleText;
	if (_flWindowShown)
		s = (NSMutableString *)[_consoleTextView textStorage];
	if ([s length] > 100 * 1024)
		[s deleteCharactersInRange:NSMakeRange (0, 20 * 1024)];
	}


- (void)appendToConsole:(NSString *)s {

	if (RSIsEmpty(s))
		return;
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(appendToConsole:) withObject:s waitUntilDone:NO];
		return;
		}
		
	s = [NSString stringWithFormat:@"%@\n", s];
	
	if (_flWindowShown) {		
		NSMutableDictionary *atts = [NSMutableDictionary dictionaryWithCapacity:2];
		[atts setObject:[NSFont userFixedPitchFontOfSize:0] forKey:NSFontAttributeName];
		[atts setObject:[_consoleTextView textColor] forKey:NSForegroundColorAttributeName];
		[[_consoleTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:s attributes:atts] autorelease]];
		}
	else
		[_initialConsoleText rs_safeAppendString:s];
		
	[self trimConsoleTextIfNeeded];
	[self updateButtons];
	}


#pragma mark Actions

- (IBAction)clearConsole:(id)sender {
	NSAttributedString *emptyString = [[[NSAttributedString alloc] initWithString:@""] autorelease];
	[[_consoleTextView textStorage] setAttributedString:emptyString];
	[self updateButtons];
	}
	
	
//- (void)saveToFilePanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {		
//	if (returnCode == NSOKButton) {	
//		NSString *s = [[_consoleTextView textStorage] string];
//		[s writeToFile:[(NSSavePanel *)sheet filename] atomically:YES encoding:NSUTF8StringEncoding error:nil];
//		}	
//	}


//- (IBAction)saveToFile:(id)sender {	
//	NSSavePanel *sp = [NSSavePanel savePanel];
//	[sp setRequiredFileType:@"txt"];	
//	[sp setTitle:RS_EXPORT_ERRORS_LIST];
//	[sp beginSheetForDirectory:NSHomeDirectory() file:@"Errors.txt" modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveToFilePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
//	}


@end

@implementation RSErrorsWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
	[self setContentBorderThickness:39.0 forEdge:NSMinYEdge];
	return self;
	}


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen];
	[self setContentBorderThickness:39.0 forEdge:NSMinYEdge];
	return self;
	}

@end
