//
//  NNWImportOPMLViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWImportOPMLController.h"
#import "RSOPMLParser.h"


@interface NNWImportOPMLController ()

@property (nonatomic, retain) NSString *errorTitle;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, assign) id callbackTarget;
@property (nonatomic, assign) SEL callbackSelector;
@property (nonatomic, retain, readwrite) NSArray *outlineItems;
@end


@implementation NNWImportOPMLController

@synthesize backgroundWindow;
@synthesize errorTitle;
@synthesize errorMessage;
@synthesize callbackTarget;
@synthesize callbackSelector;
@synthesize outlineItems;


#pragma mark Dealloc

- (void)dealloc {
	[backgroundWindow release];
	[errorTitle release];
	[errorMessage release];
	[outlineItems release];
	[super dealloc];
}


#pragma mark Error Sheet

- (void)displayAlertSheet {
	[rs_app_delegate showAlertSheetWithTitle:self.errorTitle andMessage:self.errorMessage];
}


#pragma mark Run Sheet

#define NNW_CHOOSE_OPML_FILE NSLocalizedString(@"Choose an OPML file:", @"Prompt for open-file sheet")
#define NNW_IMPORT_ERROR_TITLE NSLocalizedString(@"Import Error", @"Title for error importing subscriptions")
#define NNW_EXPORT_SUBSCRIPTIONS_FILE NSLocalizedString(@"Export subscriptions file", @"Title for exporting subscriptions")
#define NNW_IMPORT_DATA_EMPTY NSLocalizedString(@"OPML file is empty", @"OPML Import Error")
#define NNW_CANT_PARSE_OPML_IMPORT NSLocalizedString(@"Can’t parse the OPML file.", @"OPML Import Error")


- (void)doCallback {
	if (self.callbackTarget != nil)
		[self.callbackTarget performSelector:self.callbackSelector withObject:self];
	self.callbackTarget = nil;
	self.callbackSelector = nil;
}


- (void)chooseOPMLSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo {
	
	if (returnCode != NSOKButton)
		return;
	
	NSData *opmlData = [NSData dataWithContentsOfURL:[[(NSOpenPanel *)sheet URLs] rs_safeObjectAtIndex:0]];
	
	if (RSIsEmpty(opmlData)) {
		self.errorTitle = NNW_IMPORT_ERROR_TITLE;
		self.errorMessage = NNW_IMPORT_DATA_EMPTY;
		[self performSelector:@selector(displayAlertSheet) withObject:nil afterDelay:1.0]; //give time to dismiss choose-file sheet
		[self doCallback];
		return;
	}
	
	RSOPMLParser *opmlParser = [RSOPMLParser xmlParser];
	[opmlParser parseData:opmlData error:nil];
	
	if (!RSIsEmpty([opmlParser outlineItems]))
		self.outlineItems = opmlParser.outlineItems;
	else {
		self.errorTitle = NNW_IMPORT_ERROR_TITLE;
		self.errorMessage = NNW_CANT_PARSE_OPML_IMPORT;
		[self performSelector:@selector(displayAlertSheet) withObject:nil afterDelay:1.0]; //give time to dismiss choose-file sheet
	}
	
	[self doCallback];
}


- (void)runChooseOPMLFileSheet:(id)aCallbackTarget callbackSelector:(SEL)aCallbackSelector {
	
	self.callbackTarget = aCallbackTarget;
	self.callbackSelector = aCallbackSelector;
	
	self.outlineItems = nil;
	self.errorTitle = nil; //because this object gets re-used
	self.errorMessage = nil;
	
	NSOpenPanel *op = [NSOpenPanel openPanel];	
	[op setAllowsMultipleSelection:NO];	
	[op setCanChooseDirectories:NO];	
	[op setCanChooseFiles:YES];
	[op setMessage:NNW_CHOOSE_OPML_FILE];	
	[op beginSheetForDirectory:nil file:nil types:nil modalForWindow:self.backgroundWindow modalDelegate:self didEndSelector:@selector(chooseOPMLSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


@end

