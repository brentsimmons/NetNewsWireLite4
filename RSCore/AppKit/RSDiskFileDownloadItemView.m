/*
	RSDiskFileDownloadItemView.m
	NetNewsWire

	Created by Brent Simmons on 12/14/04.
	Copyright 2004 Ranchero Software. All rights reserved.
*/


#import "RSDiskFileDownloadItemView.h"
#import "RSDiskFileDownloadRequest.h"
#import "RSDiskFileDownloadView.h"
#import "RSDiskFileDownloadController.h"


NSString *RSDiskFileDownloadItemViewUnknownFile = @"Unknown";
NSString *RSDiskFileDownloadItemDidChangeDownloadingStatusNotification = @"RSDiskFileDownloadItemDidChangeDownloadingStatusNotification";

/*Button images*/

NSString *RSDiskFileDownloadCancelImage = @"downloadManagerCancel";
NSString *RSDiskFileDownloadCancelMouseoverImage = @"downloadManagerCancelMouseover";
NSString *RSDiskFileDownloadCancelPressedImage = @"downloadManagerCancelPressed";
NSString *RSDiskFileDownloadRevealImage = @"downloadManagerReveal";
NSString *RSDiskFileDownloadRevealMouseoverImage = @"downloadManagerRevealMouseover";
NSString *RSDiskFileDownloadRevealPressedImage = @"downloadManagerRevealPressed";


const CGFloat RSDiskFileDownloadItemCapHeight = 17.0;
const CGFloat RSDiskFileDownloadItemCapWidth = 8.0;


@interface RSDiskFileDownloadItemView (Forward)
- (void)setupSubviews;
- (void)updateAll;
- (BOOL)isWaitingForData;
- (NSRect)rectOfOpenFileButton;
- (void)updateSubtext;
- (void)registerForNotifications;
@end


@implementation RSDiskFileDownloadItemView


#pragma mark Init

- (id)initWithFrame:(NSRect)r {
	self = [super initWithFrame:r];
	if (self)
		[self setupSubviews];
	return (self);
	}
	
	
#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[request autorelease];
	[fileIcon release];
	[super dealloc];
	}
	

- (void)removeFromSuperview {
	if (cancelOrRevealButton != nil) {
		[cancelOrRevealButton discardTrackingRects];
		[cancelOrRevealButton removeFromSuperview];
		cancelOrRevealButton = nil;
		}
	[super removeFromSuperview];
	}
	
	
#pragma mark Accessors

- (BOOL)isDownloading {
	return (downloading);
	}


- (void)setDownloading:(BOOL)fl {
	if (fl != downloading) {
		downloading = fl;
		[[NSNotificationCenter defaultCenter] postNotificationName:RSDiskFileDownloadItemDidChangeDownloadingStatusNotification object:self];
		}
	}
	

- (NSImage*)fileIcon {
	return (fileIcon);
	}


- (void)setFileIcon:(NSImage *)image {
	[fileIcon autorelease];
	fileIcon = [image retain];
	[self setNeedsDisplayInRect:[self rectOfOpenFileButton]];
	}
	

- (BOOL)mouseInsideCancelOrRevealButton {
	return (mouseInsideCancelOrRevealButton);
	}
	
	
- (void)setMouseInsideCancelOrRevealButton:(BOOL)fl {
	mouseInsideCancelOrRevealButton = fl;
	[self updateSubtext];
	}
	
	
- (RSDiskFileDownloadRequest *)request {
	return (request);
	}


- (void)setRequest:(RSDiskFileDownloadRequest *)r {
	[request autorelease];
	request = [r retain];
	_inProgress = NO;
	_lastBytesDownloaded = 0;
	[self registerForNotifications];
	[self updateAll];
	}


- (CGFloat)rowHeight {
	RSDiskFileDownloadView *sv = (RSDiskFileDownloadView*) [self superview];
	if (sv == nil) {
		if (downloading)
			return (64.0);
		return (40.0);
		}
	if (downloading)
		return [sv expandedRowHeight];
	return [sv collapsedRowHeight];
	}
	

#pragma mark Actions

- (void)removeDownloadFromList:(id)sender {
	[[RSDiskFileDownloadController sharedController] removeRequest:[self request]];
	}
	
	
- (void)cancelDownload:(id)sender {
	[request cancel];
	[[cancelOrRevealButton retain] autorelease];
	[cancelOrRevealButton removeFromSuperview];
	cancelOrRevealButton = nil;
	[self removeDownloadFromList:sender];
	}
	

- (void)copyURLOfRepresentedFile:(id)sender {
	NSString *url = [request url];
	if (!RSIsEmpty(url))
		RSCopyURLStringToPasteboard(url, [NSPasteboard generalPasteboard]);
	}
	

- (void)revealRepresentedFile:(id)sender {

	NSString *f = [request path];
	
	if (RSFileExists(f))
		[[NSWorkspace sharedWorkspace] selectFile:f inFileViewerRootedAtPath:@""];
		
	else {
		NSString *message = NNW_FILE_DOWNLOAD_CANT_SHOW_FILE_MESSAGE;
		NSString *filename = [filenameTextField stringValue];
		if (RSIsEmpty (filename))
			filename = NNW_FILE_DOWNLOAD_UNKNOWN_FILENAME;
		message = [NSString stringWithFormat:message, filename];
		NSBeginAlertSheet (NNW_FILE_DOWNLOAD_CANT_SHOW_FILE_TITLE, NNW_OK_BUTTON, nil, nil,
		[self window], self, nil, nil, nil, message);
		}		
	}
	
	
- (void)openRepresentedFile:(id)sender {

	NSString *f = [request path];
	
	if (RSFileExists(f))
		[[NSWorkspace sharedWorkspace] openFile:f];
		
	else {
		NSString *message = NNW_FILE_DOWNLOAD_CANT_OPEN_FILE_MESSAGE;
		NSString *filename = [filenameTextField stringValue];
		if (RSIsEmpty (filename))
			filename = NNW_FILE_DOWNLOAD_UNKNOWN_FILENAME;
		message = [NSString stringWithFormat:message, filename];
		NSBeginAlertSheet (NNW_FILE_DOWNLOAD_CANT_OPEN_FILE_TITLE, NNW_OK_BUTTON, nil, nil,
		[self window], self, nil, nil, nil, message);
		}		
	}
	
	
#pragma mark Events

- (void)mouseDown:(NSEvent*)event {

	if ([event clickCount] > 1) {
		NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		if (NSPointInRect (localPoint, [self rectOfOpenFileButton])) {
			[self openRepresentedFile:self];
			return;
			}
		}
		
	[(RSDiskFileDownloadView*)[self superview] mouseDownInItemView:self];		
	}
	

#pragma mark Contextual menu

- (void)addCopyURLCommandToMenu:(NSMenu *)menu {
	[menu rs_addItemWithTitle:NNW_COPY_URL action:@selector(copyURLOfRepresentedFile:) target:self];	
	}
	
	
- (void)addCancelCommandToMenu:(NSMenu *)menu {
	[menu rs_addItemWithTitle:NNW_CANCEL_DOWNLOAD action:@selector(cancelDownload:) target:self];	
	}
	
	
- (void)addRevealInFinderCommandToMenu:(NSMenu *)menu {
	[menu rs_addItemWithTitle:NNW_SHOW_IN_FINDER action:@selector(revealRepresentedFile:) target:self];	
	}
	
	
- (void)addRemoveCommandToMenu:(NSMenu *)menu {
	[menu rs_addItemWithTitle:NNW_REMOVE_FROM_LIST action:@selector(removeDownloadFromList:) target:self];	
	}
	
	
- (NSMenu *)contextualMenu {
	
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	RSDownloadStatus status = [request status];

	switch (status) {
		
		case RSDownloadPending:
			[self addCopyURLCommandToMenu:menu];
			[self addRemoveCommandToMenu:menu];
			break;
			
		case RSDownloadInProgress:
			[self addCancelCommandToMenu:menu];
			[self addCopyURLCommandToMenu:menu];
			break;
			
		case RSDownloadComplete:
			[self addRevealInFinderCommandToMenu:menu];
			[self addCopyURLCommandToMenu:menu];
			[self addRemoveCommandToMenu:menu];
			break;
		
		case RSDownloadCanceled:
			[self addRevealInFinderCommandToMenu:menu];
			[self addCopyURLCommandToMenu:menu];
			[self addRemoveCommandToMenu:menu];
			break;
		}
	
	return menu;
	}


#pragma mark Close button delegate

- (void)mouseEnteredCloseButton:(NSButton *)button {
	[self setMouseInsideCancelOrRevealButton:YES];
	}
	
	
- (void)mouseExitedCloseButton:(NSButton *)button {
	[self setMouseInsideCancelOrRevealButton:NO];
	}
	
	
#pragma mark First responder

- (BOOL)acceptsFirstResponder {
	return YES;
	}
	
	
- (BOOL)becomeFirstResponder {
	[self updateTextFields];
	return [super becomeFirstResponder];	
	}
	

- (BOOL)resignFirstResponder {
	[self updateTextFields];
	return [super resignFirstResponder];	
	}

	
#pragma mark Layout

- (BOOL)isFlipped {
	return YES;
	}


- (NSRect)rectOfOpenFileButton {

	NSRect r = [self bounds];	
	CGFloat midY = (r.size.height - r.origin.y) / 2;
	
	r.origin.x = 4;
	r.size.height = 32;
	r.origin.y = midY - (r.size.height / 2);
	r.size.width = 32;
	return r;
	}
	

- (NSRect)rectOfCancelOrRevealButton {

	NSRect r = [self bounds];
	CGFloat midY = (r.size.height - r.origin.y) / 2;
	
	r.origin.x = r.size.width - 20;
	r.origin.y = midY - 8;
	r.size.width = 16;
	r.size.height = 16;
	return r;	
	}


- (NSRect)rectOfFilenameTextField {

	NSRect r = [self bounds];
	NSRect rOpenFileButton = [self rectOfOpenFileButton];
	NSRect rCancelOrRevealButton = [self rectOfCancelOrRevealButton];
	
	r.origin.x = (rOpenFileButton.origin.x + rOpenFileButton.size.width) + 4;
	r.size.height = 15;
	r.origin.y = 2;
	r.size.width = (rCancelOrRevealButton.origin.x - r.origin.x) - 4;
	return r;
	}
	

- (NSRect)rectOfSubtextTextField {
	
	NSRect rButton = [self rectOfOpenFileButton];
	NSRect r = [self rectOfFilenameTextField];
	
	r.origin.x = rButton.origin.x + rButton.size.width + 4;
	r.size.width = ([self bounds].size.width - r.origin.x) - 4;
	r.origin.y = r.origin.y + r.size.height + 5;

	return r;	
	}
	

- (NSRect)rectOfProgressIndicator {

	NSRect rButton = [self rectOfOpenFileButton];
	NSRect r = [self rectOfFilenameTextField];
	if (!downloading)
		return (NSZeroRect);
	r.origin.y = [self rowHeight] - 15;
	r.size.height = 12;
	r.origin.x = rButton.origin.x + rButton.size.width + 5;
	r.size.width = ([self bounds].size.width - r.origin.x) - 5;
	return r;	
	}

	
- (void)tile {
	[progressIndicator setFrame:[self rectOfProgressIndicator]];
	[filenameTextField setFrame:[self rectOfFilenameTextField]];
	[subtextTextField setFrame:[self rectOfSubtextTextField]];
	[cancelOrRevealButton setFrame:[self rectOfCancelOrRevealButton]];
	}


- (void)resizeSubviewsWithOldSize:(NSSize)s {
	[self tile];
	[self setNeedsDisplay:YES];
	}
	

- (void)setFrame:(NSRect)r {
	[super setFrame:r];
	if (cancelOrRevealButton != nil)
		[cancelOrRevealButton resetTrackingRects];
	}
	
	
#pragma mark Setup

- (void)setupFilenameTextField {
	filenameTextField = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
	[filenameTextField setStringValue:@""];
	[filenameTextField setDrawsBackground:NO];
	[filenameTextField setTextColor:[NSColor darkGrayColor]];
	[filenameTextField setBordered:NO];
	[filenameTextField setBezeled:NO];
	[filenameTextField setEditable:NO];
	[filenameTextField setSelectable:NO];
	[filenameTextField setFont:[NSFont boldSystemFontOfSize:11.0]];
	[self addSubview:filenameTextField];
	}
	

- (void)setupSubtextTextField {
	subtextTextField = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
	[subtextTextField setStringValue:@"subtextTextField"];
	[subtextTextField setDrawsBackground:NO];
	[subtextTextField setTextColor:[NSColor grayColor]];
	[subtextTextField setBordered:NO];
	[subtextTextField setBezeled:NO];
	[subtextTextField setEditable:NO];
	[subtextTextField setFont:[NSFont systemFontOfSize:10.0]];
	[filenameTextField setSelectable:NO];
	[self addSubview:subtextTextField];
	}


- (void)setupCancelOrRevealButton {
	cancelOrRevealButton = [[[RSCloseButton alloc] initWithFrame:[self rectOfCancelOrRevealButton]] autorelease];
	[cancelOrRevealButton setImage:nil];
	[cancelOrRevealButton setImagePosition: NSImageOnly];
	[cancelOrRevealButton setButtonType: NSMomentaryPushInButton];
	[cancelOrRevealButton setBezelStyle: NSThickSquareBezelStyle];
	[[cancelOrRevealButton cell] setControlSize: NSSmallControlSize];
	[[cancelOrRevealButton cell] setGradientType: NSGradientNone];
	[[cancelOrRevealButton cell] setShowsStateBy: NSNoCellMask];
	[[cancelOrRevealButton cell] setHighlightsBy: NSContentsCellMask];
	[cancelOrRevealButton setBordered: NO];
	[cancelOrRevealButton setTarget:self];
	[cancelOrRevealButton setAction:@selector(cancelOrRevealButtonClicked:)];
	[cancelOrRevealButton setMouseOverDelegate:self];
	[self addSubview:cancelOrRevealButton];
	}


- (void)setupProgressIndicator {
	progressIndicator = [[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];
	[progressIndicator setUsesThreadedAnimation:NO];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator setControlSize:NSSmallControlSize];
	[self addSubview:progressIndicator];
	}
	
	
- (void)setupSubviews {
	[self setupFilenameTextField];
	[self setupSubtextTextField];
	[self setupCancelOrRevealButton];
	[self setupProgressIndicator];
	[self performSelectorOnMainThread:@selector(tile) withObject:nil waitUntilDone:NO];
	}


#pragma mark Drawing

- (NSImage *)highlightLeftImage {
	static NSImage *highlightLeftImage = nil;
	if (highlightLeftImage == nil) {
		highlightLeftImage = [[NSImage imageNamed:@"downloadHighlightLeft"] retain];
		}
	return (highlightLeftImage);
	}


- (NSImage *)highlightRightImage {
	static NSImage *highlightRightImage = nil;
	if (highlightRightImage == nil) {
		highlightRightImage = [[NSImage imageNamed:@"downloadHighlightRight"] retain];
		}
	return (highlightRightImage);
	}
	

- (NSImage *)highlightMiddleImage {
	static NSImage *highlightMiddleImage = nil;
	if (highlightMiddleImage == nil) {
		highlightMiddleImage = [[NSImage imageNamed:@"downloadHighlightMiddle"] retain];
		}
	return (highlightMiddleImage);
	}
	

- (BOOL)isOpaque {
	return (NO);
	}


- (void)drawRect:(NSRect)r {
	
	NSRect rOpenFileButton = [self rectOfOpenFileButton];
	NSPoint imagePoint = rOpenFileButton.origin;
	NSImage *image = nil;
	CGFloat alpha = 1.0;
	
	if (!NSIntersectsRect (r, rOpenFileButton))
		return;
	image = [self fileIcon];
	if (image == nil)
		return;
	
	if ([self isDownloading])
		alpha = 0.5;
	imagePoint.y += 32;
	[image dissolveToPoint:imagePoint fraction:alpha];
	}
	
	
#pragma mark Updating

- (BOOL)isSelected {
	RSDiskFileDownloadView *sv = (RSDiskFileDownloadView*) [self superview];
	if (sv == nil)
		return (NO);
	return [sv isItemViewSelected:self];
	}
	

- (BOOL)shouldUseWhiteText {
	if (![NSApp isActive])
		return (NO);
	if (![[self window] isKeyWindow])
		return (NO);
	return [self isSelected];
	}
	
	
- (NSString *)displayName {
	
	NSString *s = nil;
	//NSString *displayName = nil;
	
	if (request == nil)
		return (RSDiskFileDownloadItemViewUnknownFile);
		
	s = [request path];	
	if (!RSIsEmpty (s))
		return [s lastPathComponent];
		
	s = [request suggestedFilename];
	if (!RSIsEmpty (s))
		return (s);

	s = [request url];
	if (!RSIsEmpty (s))
		return [s lastPathComponent];

	return (RSDiskFileDownloadItemViewUnknownFile);	
	}
	
	
- (void)updateFilename {
	[filenameTextField setStringValue:[self displayName]];
	if ([self shouldUseWhiteText])
		[filenameTextField setTextColor:[NSColor whiteColor]];
	else
		[filenameTextField setTextColor:[NSColor darkGrayColor]];
	}


- (BOOL)isWaitingForData {
		
	RSDownloadStatus status = [request status];
	long long bytesDownloaded;
	
	if (status != RSDownloadInProgress)
		return (NO);

	bytesDownloaded = [request bytesDownloaded];
	if ((bytesDownloaded == (long long)-1) || (bytesDownloaded < 100))
		return (YES);
	return (NO);
	}
	
	
- (void)updateSubtext {

	RSDownloadStatus status = [request status];
	NSString *s = nil;
	long long contentLength;
	long long bytesDownloaded;
	NSString *contentLengthString = nil;
	NSString *bytesDownloadedString = nil;
	BOOL flMouseInButton = [self mouseInsideCancelOrRevealButton];
	
	switch (status) {
			
		case RSDownloadPending:
			s = NNW_PENDING_DOWNLOAD;
			break;
		case RSDownloadComplete:
			if (flMouseInButton)
				s = NNW_SHOW_IN_FINDER;
			else
				s = [NSString rs_gigabyteString:[request sizeOfFileOnDisk]];
//				s = RSGigabyteString ((NSUInteger)[request sizeOfFileOnDisk]);
			break;
		case RSDownloadCanceled:
			if (flMouseInButton)
				s = NNW_SHOW_IN_FINDER;
			else
				s = NNW_CANCELED_DOWNLOAD;
			break;
		case RSDownloadInProgress: //Make static analyzer happy
			break;
	}
	
	if ([self shouldUseWhiteText])
		[subtextTextField setTextColor:[NSColor whiteColor]];
	else
		[subtextTextField setTextColor:[NSColor grayColor]];

	if ((status == RSDownloadInProgress) && (flMouseInButton))
		s = NNW_CANCEL_DOWNLOAD_SMALL_D;
		
	if (s != nil) {
		[subtextTextField setStringValue:s];
		return;
		}

	contentLength = [request contentLength];
	bytesDownloaded = [request bytesDownloaded];
	NSUInteger bd = (NSUInteger)bytesDownloaded;
	bytesDownloadedString = [NSString rs_gigabyteString:bd];
	
	if ((contentLength == (long long)-1) || (contentLength < 100)) {
		s = [NSString stringWithFormat:NNW_DOWNLOADED_QUOTED_ELLIPSIS, bytesDownloadedString];
		if ([self isWaitingForData])
			s = NNW_WAITING_FOR_DATA;
		}
	else {
		NSUInteger cl = (NSUInteger)contentLength;
		contentLengthString = [NSString rs_gigabyteString:cl];
		s = [NSString stringWithFormat:NNW_DOWNLOADED_O_OF_O, bytesDownloadedString, contentLengthString];
		}
	
	[subtextTextField setStringValue:s];
	}


- (void)updateProgressIndicator {
	
	RSDownloadStatus status = [request status];
	
	if (status == RSDownloadInProgress) {
		long long bytesDownloaded = [request bytesDownloaded];
		long long contentLength = [request contentLength];
		BOOL indeterminate = (contentLength == (long long)-1);
		
		if ([self isWaitingForData])
			indeterminate = YES;
			
		[progressIndicator startAnimation:self];
		[progressIndicator setIndeterminate:indeterminate];
		if (!indeterminate) {
			//double max = (double) (contentLength / 1000);
			//double curr = (double) (bytesDownloaded / 1000);
			[progressIndicator setMaxValue:(double)contentLength];
			[progressIndicator setDoubleValue:(double)bytesDownloaded];
			}
		}
	
	else {
		[progressIndicator setDisplayedWhenStopped:NO];		
		[progressIndicator setIndeterminate:NO];
		[progressIndicator stopAnimation:self];
		}
	}


- (void)updateOpenFileButton {

	NSString *f = [request path];
	NSImage *icon = nil;
	//NSArray *reps = nil;
	
	if (RSIsEmpty (f))
		return;
	icon = [[NSWorkspace sharedWorkspace] iconForFile:f];
	if (icon == nil)
		return;
	[self setFileIcon:icon];
	}


- (void)disableCancelOrRevealButton {
	[cancelOrRevealButton setEnabled:NO];
	[cancelOrRevealButton setImage:nil];
	[cancelOrRevealButton setAction:nil];	
	[cancelOrRevealButton setToolTip:nil];
	}
	

- (void)makeCancelButton {
	[cancelOrRevealButton setEnabled:YES];
	[cancelOrRevealButton setImage:[NSImage imageNamed:RSDiskFileDownloadCancelImage]];
	[cancelOrRevealButton setRealImage:[NSImage imageNamed:RSDiskFileDownloadCancelImage]];
	[cancelOrRevealButton setAlternateImage:[NSImage imageNamed:RSDiskFileDownloadCancelPressedImage]];
	[cancelOrRevealButton setMouseOverImage:[NSImage imageNamed:RSDiskFileDownloadCancelMouseoverImage]];
	[cancelOrRevealButton setAction:@selector(cancelDownload:)];	
	[cancelOrRevealButton setToolTip:NNW_CANCEL_DOWNLOAD_SMALL_D];
	}
	

- (void)makeRevealButton {

	[cancelOrRevealButton setEnabled:YES];
	[cancelOrRevealButton setImage:[NSImage imageNamed:RSDiskFileDownloadRevealImage]];
	[cancelOrRevealButton setRealImage:[NSImage imageNamed:RSDiskFileDownloadRevealImage]];
	[cancelOrRevealButton setAlternateImage:[NSImage imageNamed:RSDiskFileDownloadRevealPressedImage]];
	[cancelOrRevealButton setMouseOverImage:[NSImage imageNamed:RSDiskFileDownloadRevealMouseoverImage]];
	[cancelOrRevealButton setAction:@selector(revealRepresentedFile:)];	
	[cancelOrRevealButton setToolTip:NNW_SHOW_IN_FINDER];
	}
	
	
- (void)updateCancelOrRevealButton {
	
	RSDownloadStatus status = [request status];
	
	switch (status) {
		
		case RSDownloadPending:
			[self disableCancelOrRevealButton];
			return;
		
		case RSDownloadInProgress:
			[self makeCancelButton];
			return;
			
		case RSDownloadComplete:
		case RSDownloadCanceled:
			if ([request fileExists])
				[self makeRevealButton];
			else
				[self disableCancelOrRevealButton];
		}
	}
	

- (void)updateDownloadingStatus {
	[self setDownloading:([request status] == RSDownloadInProgress)];
	}
	

- (void)updateAll {
	[self updateDownloadingStatus];
	[self updateFilename];
	[self updateSubtext];
	[self updateProgressIndicator];
	[self updateOpenFileButton];
	[self updateCancelOrRevealButton];		
	}


- (void)updateTextFields {
	[self updateDownloadingStatus];
	[self updateFilename];
	[self updateSubtext];
	}
	
	
#pragma mark Notifications

- (void)handleGenericFileDownloadNotification:(NSNotification *)note {
	[self updateAll];
	}
	

- (void)handleFileDownloadDidSetPathNotification:(NSNotification *)note {
	[self updateDownloadingStatus];
	[self updateFilename];
	[self updateCancelOrRevealButton];
	[self updateOpenFileButton];
	}
	
	
- (void)handleBytesDownloadedDidChangeNotification:(NSNotification *)note {
	if (_inProgress && [request status] == RSDownloadInProgress) {
		if ([request bytesDownloaded] - _lastBytesDownloaded < 99 * 1024) /*performance: skip some events*/
			return;
		}
	_lastBytesDownloaded = [request bytesDownloaded];
	_inProgress = ([request status] == RSDownloadInProgress);
	[self updateDownloadingStatus];
	[self updateSubtext];
	[self updateProgressIndicator];
	}


- (void)handleFileDownloadDidSuggestFilenameNotification:(NSNotification *)note {
	[self updateDownloadingStatus];
	[self updateFilename];
	}
	
	
- (void)registerForNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBytesDownloadedDidChangeNotification:) name:RSDiskFileDownloadBytesDownloadedDidChangeNotification object:request];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBytesDownloadedDidChangeNotification:) name:RSDiskFileDownloadContentLengthDidChangeNotification object:request];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFileDownloadNotification:) name:RSDiskFileDownloadDidSetPathNotification object:request];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFileDownloadNotification:) name:RSDiskFileDownloadStatusDidChangeNotification object:request];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFileDownloadNotification:) name:RSDiskFileDownloadDidSuggestFilenameNotification object:request];
	}
	
	
@end

