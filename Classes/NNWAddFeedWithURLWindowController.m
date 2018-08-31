//
//  NNWAddFeedWithURLViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedWithURLWindowController.h"
#import "NNWSourceListTreeBuilder.h"
#import "NNWSubscribeRequest.h"
#import "NNWSubscriber.h"
#import "RSDataAccount.h"
#import "RSTree.h"
#import "RSTreeNode.h"


@interface NNWAddFeedWithURLWindowController ()

@property (nonatomic, retain) NNWSubscriber *subscriber;
@property (nonatomic, retain) NSString *initialURLString;
@property (nonatomic, retain) NNWSubscribeRequest *initialSubscribeRequest;

- (void)populateFolderMenu;
- (void)syncRequestedFolderAndMenu;

@end


@implementation NNWAddFeedWithURLWindowController

@synthesize folderPopupButton;
@synthesize initialSubscribeRequest;
@synthesize initialURLString;
@synthesize subscriber;
@synthesize titleTextField;
@synthesize urlTextField;


#pragma mark Init

- (id)initWithURLString:(NSString *)aURLString {
	self = [super initWithWindowNibName:@"AddFeedWithURL"];
	if (self == nil)
		return nil;
	initialURLString = [aURLString copy];
	return self;
}


- (id)initWithSubscribeRequest:(NNWSubscribeRequest *)aSubscribeRequest {
	self = [self initWithURLString:[[aSubscribeRequest feedURL] absoluteString]];
	if (self == nil)
		return nil;
	initialSubscribeRequest = [aSubscribeRequest retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[folderPopupButton release];
	[initialSubscribeRequest release];
	[initialURLString release];
	[subscriber release];
	[titleTextField release];
	[urlTextField release];
	[super dealloc];
}


#pragma mark Actions

- (void)cancel:(id)sender {
	[NSApp stopModal];
}


- (void)addFeed:(id)sender {
	NNWSubscribeRequest *subscribeRequest = [[[NNWSubscribeRequest alloc] init] autorelease];
	NSString *urlString = [self.urlTextField stringValue];
	if (RSStringIsEmpty(urlString))
		return;
	if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"])
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	NSURL *aURL = [NSURL URLWithString:urlString];
	if (aURL == nil)
		return; //TODO: error message
	subscribeRequest.feedURL = aURL;
	id selectedFolder = [[self.folderPopupButton selectedItem] representedObject];
	RSFolder *folder = nil;
	id<RSAccount> account = nil;
	if ([selectedFolder conformsToProtocol:@protocol(RSAccount)])
		account = selectedFolder;
	else if ([selectedFolder isKindOfClass:[RSFolder class]]) {
		folder = selectedFolder;
		account = folder.account;
	}
	subscribeRequest.account = account;
	subscribeRequest.parentFolder = folder;
	subscribeRequest.title = self.titleTextField.stringValue;
	//subscribeRequest.backgroundWindow = [[self view] window];
	self.subscriber = [[[NNWSubscriber alloc] initWithSubscribeRequest:subscribeRequest] autorelease];
	[self.subscriber performSelector:@selector(subscribe) withObject:nil afterDelay:0.5f];
	[NSApp stopModal];
}


#pragma mark NSWindowController

- (void)windowDidLoad {
	[self populateFolderMenu];
	if (!RSStringIsEmpty(self.initialURLString))
		[urlTextField setStringValue:self.initialURLString];
	if (self.initialSubscribeRequest != nil) {
		if (self.initialSubscribeRequest.title != nil)
			[self.titleTextField setStringValue:self.initialSubscribeRequest.title];
		if (self.initialSubscribeRequest.parentFolder != nil)
			[self syncRequestedFolderAndMenu];
	}
	self.initialSubscribeRequest = nil; //not needed later
}


#pragma mark Folders Menu

- (void)syncRequestedFolderAndMenu {
	for (NSMenuItem *oneMenuItem in [self.folderPopupButton itemArray]) {
		if ([oneMenuItem representedObject] == self.initialSubscribeRequest.parentFolder) {
			[self.folderPopupButton selectItem:oneMenuItem];
			return;
		}			
	}
}


- (void)addAccountMenuItem:(RSTreeNode *)accountTreeNode toMenu:(NSMenu *)aMenu indentLevel:(NSInteger)indentLevel {
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:accountTreeNode.representedObject.nameForDisplay action:nil keyEquivalent:@""] autorelease];
	[menuItem setIndentationLevel:indentLevel];
	[menuItem setRepresentedObject:accountTreeNode.representedObject];
	[aMenu addItem:menuItem];
}


- (void)addFolderMenuItem:(RSTreeNode *)folderTreeNode toMenu:(NSMenu *)aMenu indentLevel:(NSInteger)indentLevel {
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:folderTreeNode.representedObject.nameForDisplay action:nil keyEquivalent:@""] autorelease];
	[menuItem setIndentationLevel:indentLevel];
	[menuItem setImage:[NSImage imageNamed:NSImageNameFolder]];
	[menuItem setRepresentedObject:folderTreeNode.representedObject];
	[aMenu addItem:menuItem];
}


- (void)addChildNodesFrom:(RSTreeNode *)aTreeNode toMenu:(NSMenu *)aMenu indentLevel:(NSInteger)indentLevel {
	for (RSTreeNode *oneTreeNode in aTreeNode.orderedChildren) {
		if (oneTreeNode.isSpecialGroup && oneTreeNode.representedObject != [RSDataAccount localAccount])
			continue;
		if (oneTreeNode.isSpecialGroup && oneTreeNode.representedObject == [RSDataAccount localAccount]) {
			[self addAccountMenuItem:oneTreeNode toMenu:aMenu indentLevel:indentLevel];
			[self addChildNodesFrom:oneTreeNode toMenu:aMenu indentLevel:indentLevel + 1];
		}
		else if (oneTreeNode.isGroup) {
			[self addFolderMenuItem:oneTreeNode toMenu:aMenu indentLevel:indentLevel];
			[self addChildNodesFrom:oneTreeNode toMenu:aMenu indentLevel:indentLevel + 1];
		}
	}
}


- (void)populateFolderMenu {
	
	NSMenu *folderMenu = [[[NSMenu alloc] initWithTitle:@"Folders"] autorelease];
	RSTree *tree = [NNWSourceListTreeBuilder sharedTreeBuilder].tree;
	
	[self addChildNodesFrom:(RSTreeNode *)tree toMenu:folderMenu indentLevel:0];
	[self.folderPopupButton setMenu:folderMenu];
}


@end
