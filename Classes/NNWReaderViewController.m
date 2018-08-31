//
//  NNWReaderViewController.m
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWReaderViewController.h"
#import "NNWArticleDetailPaneView.h"
#import "NNWArticleListPaneView.h"
#import "NNWArticleListDelegate.h"
#import "NNWReaderRightPaneContainerView.h"
#import "NNWSourceListDelegate.h"
#import "RSFaviconController.h"
#import "RSFeed.h"
#import "RSFolder.h"
#import "RSTreeNode.h"


@interface NNWReaderViewController ()

- (void)updateArticlesListWithSourceOutlineViewSelection:(NSOutlineView *)outlineView;

@end


@implementation NNWReaderViewController

@synthesize readerContentViewController;	
@synthesize rightPaneContainerView;
@synthesize sourceListDelegate;
@synthesize splitView;
@synthesize currentTreeNode;
@synthesize sourceListView;


#pragma mark Init

- (id)init {
	return [self initWithNibName:nil bundle:nil];
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[rightPaneContainerView release];
	[splitView release];
	[readerContentViewController release];
	[sourceListDelegate release];
	[sourceListView release];
	[currentTreeNode release];
	[super dealloc];
}


#pragma mark NSViewController

//- (void)loadView {
//	[super loadView];
//	self.readerContentViewController = [[[NNWReaderContentViewController alloc] init] autorelease];
//	self.rightPaneContainerView.contentViewController = self.readerContentViewController;
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSourceListSelectionDidChange:) name:RSSourceListSelectionDidChangeNotification object:nil];
//}


#pragma mark Notifications

- (void)handleSourceListSelectionDidChange:(NSNotification *)note {
	if ([[note object] isDescendantOf:self.view])
		[self updateArticlesListWithSourceOutlineViewSelection:[note object]];
}


#pragma mark Navigation

- (void)navigateToArticleInCurrentList:(RSDataArticle *)anArticle {
	[self.readerContentViewController navigateToArticleInCurrentList:anArticle];
}


- (void)navigateToFirstUnreadArticle {
	[self.readerContentViewController navigateToFirstUnreadArticle];
}


- (void)navigateToTreeNode:(RSTreeNode *)aTreeNode {
	self.currentTreeNode = aTreeNode;
	[self.sourceListDelegate selectTreeNode:aTreeNode];
}


#pragma mark Fetching Articles

- (void)updateArticlesListWithSourceOutlineViewSelection:(NSOutlineView *)outlineView {
	NSMutableArray *selectedItems = [NSMutableArray array];
	NSIndexSet *selectedRowIndexes = [outlineView selectedRowIndexes];
	NSUInteger oneIndex = [selectedRowIndexes firstIndex];
	self.currentTreeNode = nil;
	while (oneIndex != NSNotFound) {
		RSTreeNode *treeNode = (RSTreeNode *)[outlineView itemAtRow:(NSInteger)oneIndex];
		if (self.currentTreeNode == nil)
			self.currentTreeNode = treeNode;
		[selectedItems rs_safeAddObject:treeNode.representedObject];
		oneIndex = [selectedRowIndexes indexGreaterThanIndex:oneIndex];
	}
	self.readerContentViewController.feeds = selectedItems;
}


#pragma mark Split View Delegate

static const CGFloat kDividerSnapPosition = 240.0f;
static const CGFloat kDividerSnapRegion = 32.0f; //on each of both sides, so the whole region is double

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
	if (proposedPosition > kDividerSnapPosition - kDividerSnapRegion && proposedPosition < kDividerSnapPosition + kDividerSnapRegion)
		return kDividerSnapPosition;
	return proposedPosition;
}


- (BOOL)splitView:(NSSplitView *)aSplitView shouldAdjustSizeOfSubview:(NSView *)view {
	return view == [[aSplitView subviews] objectAtIndex:1];
}


#pragma mark NNWKeyDownFilter

- (NSWindow *)window {
	return [[self view] window];
}


- (BOOL)inSourceList {
	NSResponder *firstResponder = [[[self view] window] firstResponder];
	BOOL firstResponderIsAView = [firstResponder isKindOfClass:[NSView class]];
	if (!firstResponderIsAView)
		return NO;
	return [(NSView *)firstResponder isDescendantOf:[[self.splitView subviews] objectAtIndex:0]];
}


- (BOOL)inArticleList {
	NSResponder *firstResponder = [[[self view] window] firstResponder];
	return [firstResponder isKindOfClass:[NSView class]] && [(NSView *)firstResponder isDescendantOf:self.readerContentViewController.articleDetailPaneView];	
}


- (BOOL)inArticle {
	return NO;
//	NSResponder *firstResponder = [[[self view] window] firstResponder];
//	return [firstResponder isKindOfClass:[NSView class]] && [(NSView *)firstResponder isDescendantOf:self.readerContentViewController.articleListPaneView];
}


- (void)goToSourceList {
	[[self window] makeFirstResponder:self.sourceListView];
}


- (void)goToArticleList {
	[self.readerContentViewController makeArticleListFirstResponder];		
}


- (void)goToArticle {
	[self.readerContentViewController makeDetailViewFirstResponder];
}


- (void)openArticle {
	
}


- (void)goRight {
	
	//NSResponder *firstResponder = [[[self view] window] firstResponder];
	//BOOL firstResponderIsAView = [firstResponder isKindOfClass:[NSView class]];
	
	BOOL inSourceList = [self inSourceList];
	BOOL inArticleList = [self inArticleList];
	BOOL inArticle = [self inArticle];
	
	/*If not in source-list/article-list/article, go to source list.
	 If is source list, go to article list.
	 If article list, go to webview.
	 If webview, open article.*/
	
	if (!inSourceList && !inArticleList && !inArticle)
		[self goToSourceList];
	else if (inSourceList)
		[self goToArticleList];
	else if (inArticleList)
		[self goToArticle];
	else if (inArticle)
		[self openArticle];
}


- (void)goLeft {
	
}


- (BOOL)didHandleKeyDown:(NSEvent *)event {

	NSString *s = [event characters];
	if (RSIsEmpty(s))
		return NO;
	
	unichar ch = [s characterAtIndex: 0];
	BOOL shiftKeyDown = (([event modifierFlags] & NSShiftKeyMask) != 0);
	BOOL optionKeyDown = (([event modifierFlags] & NSAlternateKeyMask) != 0);
	BOOL commandKeyDown = (([event modifierFlags] & NSCommandKeyMask) != 0);
	BOOL controlKeyDown = (([event modifierFlags] & NSControlKeyMask) != 0);
	BOOL anyModifierKeyDown = shiftKeyDown || optionKeyDown || commandKeyDown || controlKeyDown;

	if (ch == ' ')
		return [(id<NNWKeyDownFilter>)(self.readerContentViewController) didHandleKeyDown:event];
	
	switch (ch) {
			
		case NSRightArrowFunctionKey:
			if (anyModifierKeyDown)
				return NO;
			[self goRight];
			return YES;
			
		case '\t':
			if (!anyModifierKeyDown) {
				[self goRight];
				return YES;
			}
				
	}
//	if (ch == NSRightArrowFunctionKey && !anyModifierKeyDown)
//		[self goRight];
//	else if (ch == '\t' && !anyModifierKeyDown)
//		[self goRight];
//	else if (ch == NSLeftArrowFunctionKey && !anyModifierKeyDown)
//		[self goLeft];
//	else if (ch == '\t' && shiftKeyDown && !optionKeyDown && !commandKeyDown && !controlKeyDown)
//		[self goLeft];
	
	
//	switch (ch) {
//			
//		case ' ':
//			if (shiftKey
//			if ((flShiftKey) || ([_webView canScrollDown])) {			
//				[[[_webView mainFrame] frameView] keyDown: event];			
//				return YES;
//			}
//			
//			return [[NSApp delegate] handleKeyStroke: event inView: view];
//		case '\t':
//			return [[NSApp delegate] handleKeyStroke: event inView: view];
//		case NSLeftArrowFunctionKey: 
//		case NSRightArrowFunctionKey:
//		case NSUpArrowFunctionKey:
//		case NSDownArrowFunctionKey:
//		case NSHomeFunctionKey:
//		case NSBeginFunctionKey:
//		case NSEndFunctionKey:
//		case NSPageUpFunctionKey:
//		case NSPageDownFunctionKey:
//			
//			if (flShiftKey)
//				return NO;
//			[[[_webView mainFrame] frameView] keyDown: event];			
//			return YES;
//			
//	}

	
	return NO;
}


@end


static CGImageRef NNWImageForFolder(RSFolder *aFolder) {
	static CGImageRef folderImage = nil;
	if (folderImage == nil) {
		NSImage *standardFolderImage = [NSImage imageNamed:NSImageNameFolder];
		if (standardFolderImage != nil) {
			NSRect rFolderImage = NSMakeRect(0.0f, 0.0f, 16.0f, 16.0f);
			folderImage = CGImageRetain([standardFolderImage CGImageForProposedRect:&rFolderImage context:nil hints:nil]);
		}
	}
	return folderImage;
}


static CGImageRef NNWImageForFeed(RSFeed *aFeed) {

	static NSMutableDictionary *faviconCache = nil;
	if (faviconCache == nil)
		faviconCache = [[NSMutableDictionary alloc] init];
	
	id smallImage = nil;
	if (aFeed.faviconURL != nil)
		smallImage = [faviconCache objectForKey:aFeed.faviconURL];
	if (smallImage == nil && aFeed.homePageURL != nil)
		smallImage = [faviconCache objectForKey:aFeed.homePageURL];
	if (smallImage == nil) {
		smallImage = (id)[[RSFaviconController sharedController] faviconForHomePageURL:aFeed.homePageURL faviconURL:aFeed.faviconURL];
		if (smallImage != nil)
			[faviconCache setObject:smallImage forKey:aFeed.faviconURL ? aFeed.faviconURL : aFeed.homePageURL];
	}
	if (smallImage != nil)
		return (CGImageRef)smallImage;

	static CGImageRef defaultFavicon = nil;
	if (defaultFavicon == nil) {
		NSImage *favicon = [NSImage imageNamed:@"DefaultFavicon"];
		if (favicon != nil) {
			defaultFavicon = [favicon CGImageForProposedRect:NULL context:nil hints:nil];
			if (defaultFavicon != nil)
				CGImageRetain(defaultFavicon);
		}
	}
	return defaultFavicon;
}


CGImageRef NNWImageForFeedOrFolder(id feedOrFolder) {
	if ([feedOrFolder isKindOfClass:[RSFolder class]])
		return NNWImageForFolder(feedOrFolder);
	else if ([feedOrFolder isKindOfClass:[RSFeed class]])
		return NNWImageForFeed(feedOrFolder);
	return nil;
}

