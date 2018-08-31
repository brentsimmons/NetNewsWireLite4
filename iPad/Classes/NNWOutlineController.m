//
//  NNWOutlineController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWOutlineController.h"
#import "NNWDataController.h"
#import "NNWFeed.h"
#import "NNWFeedProxy.h"
#import "NNWFolder.h"
#import "NNWFolderProxy.h"
#import "NNWAppDelegate.h"



NSString *NNWOutlineDidChangeNotification = @"NNWOutlineDidChangeNotification";

@implementation NNWOutlineNode

@synthesize nnwProxy = _nnwProxy, isFolder = _isFolder, level = _level, children = _children;

+ (id)outlineNodeWithManagedObject:(NSManagedObject *)managedObject isFolder:(BOOL)isFolder level:(NSInteger)level {
	return [[[self alloc] initWithManagedObject:managedObject isFolder:isFolder level:level] autorelease];
}


static NSString *NNWProxyKey = @"nnwProxy";
static NSString *NNWIsFolderKey = @"isFolder";
static NSString *NNWLevelKey = @"level";
static NSString *NNWChildrenKey = @"chidren";

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_nnwProxy forKey:NNWProxyKey];
	[coder encodeBool:_isFolder forKey:NNWIsFolderKey];
	[coder encodeInteger:_level forKey:NNWLevelKey];
	[coder encodeObject:_children forKey:NNWChildrenKey];
}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	_nnwProxy = [[coder decodeObjectForKey:NNWProxyKey] retain];
	_isFolder = [coder decodeBoolForKey:NNWIsFolderKey];
	_level = [coder decodeIntegerForKey:NNWLevelKey];
	_children = [[coder decodeObjectForKey:NNWChildrenKey] retain];
	return self;
}


- (id)initWithManagedObject:(NSManagedObject *)managedObject isFolder:(BOOL)isFolder level:(NSInteger)level {
	if (![super init])
		return nil;
	_isFolder = isFolder;
	NSString *googleID = [managedObject valueForKey:RSDataGoogleID];
	if (_isFolder)
		_nnwProxy = [[NNWFolderProxy folderProxyWithGoogleID:googleID] retain];
	else {
		_nnwProxy = [[NNWFeedProxy feedProxyWithGoogleID:googleID] retain];
		if (((NNWFeedProxy *)_nnwProxy).managedObjectID == nil) {
			NSManagedObjectID *objectID = [managedObject objectID];
			if (![objectID isTemporaryID]) {
				((NNWFeedProxy *)_nnwProxy).managedObjectID = objectID;
				((NNWFeedProxy *)_nnwProxy).managedObjectURI = [objectID URIRepresentation];
			}
		}
			
	}
	if (!_nnwProxy.title)
		_nnwProxy.title = [managedObject valueForKey:RSDataTitle];
	_level = level;
	return self;
}

- (void)dealloc {
	[_nnwProxy release];
	[_children release];
	[super dealloc];
}


- (NSString *)googleID {
	return self.nnwProxy.googleID;
}


- (NSString *)description {
	NSMutableString *s = [[[NSMutableString alloc] initWithString:[super description]] autorelease];
	[s appendString:@" isFolder: "];
	[s appendString: _isFolder ? @"YES " : @"NO "];
	[s appendFormat:@"Level: %d ", _level];
	NSString *title = _nnwProxy.title;
	[s appendString:title ? title : @"Unknown Title"];
	return s;
}


- (BOOL)hasAtLeastOneUnreadItem {
	if (!self.nnwProxy.unreadCountIsValid)
		[NNWFeedProxy updateUnreadCounts];
	return self.nnwProxy.unreadCount > 0;
}


@end


@interface NNWOutlineController ()
@property (nonatomic, retain) NSArray *folders;
@property (nonatomic, retain, readwrite) NSMutableArray *outline;
@property (nonatomic, retain, readwrite) NSMutableArray *flattenedOutline;
- (NSMutableArray *)_allFoldersAtLevel:(NSInteger)level withParent:(NNWFolder *)parent;
@end


@implementation NNWOutlineController

@synthesize folders = _folders, outline = _outline, flattenedOutline = _flattenedOutline, delegate = _delegate;

- (void)dealloc {
	[_folders release];
	[_outline release];
	[_flattenedOutline release];
	[super dealloc];
}


- (void)_flattenArray:(NSArray *)anArray intoArray:(NSMutableArray *)flatArray {
	for (NNWOutlineNode *oneNode in anArray) {
		[flatArray addObject:oneNode];
		[self _flattenArray:oneNode.children intoArray:flatArray];
	}
}


- (NSMutableArray *)_flattenedOutline {
	NSMutableArray *flatArray = [NSMutableArray arrayWithCapacity:[self.outline count] * 3];
	[self _flattenArray:self.outline intoArray:flatArray];
	return flatArray;
}


- (BOOL)_hasOrphanFolders {
	return [self.folders count] != [self.flattenedOutline count];
}


- (BOOL)_flattenedOutlineContainsFolder:(NNWFolder *)folder {
	NSString *googleID = [folder valueForKey:RSDataGoogleID];
	for (NNWOutlineNode *oneNode in self.flattenedOutline) {
		if (oneNode.isFolder && [oneNode.nnwProxy.googleID isEqualToString:googleID])
			return YES;
	}
	return NO;
}


- (void)_adoptOrphanFolders {
	/*Sometimes we know about a folder but don't know about its parent. We have to make sure the parents exist.*/
	NSMutableArray *orphans = [NSMutableArray array];
	for (NNWFolder *oneFolder in self.folders) {
		if (![self _flattenedOutlineContainsFolder:oneFolder])
			[orphans addObject:oneFolder];
	}
	for (NNWFolder *oneFolder in orphans)
		[NNWFolder ensureParent:oneFolder managedObjectContext:app_delegate.managedObjectContext];
}


- (NNWOutlineNode *)_outlineFolderNodeForManagedObject:(NSManagedObject *)managedObject {
	NSString *googleID = [managedObject valueForKey:RSDataGoogleID];
	for (NNWOutlineNode *oneOutlineNode in self.flattenedOutline) {
		if (oneOutlineNode.isFolder && [oneOutlineNode.nnwProxy.googleID isEqualToString:googleID])
			return oneOutlineNode;
	}
	return nil;
}


- (void)_addFeed:(NNWFeed *)feed toFolder:(NNWFolder *)folder {
	NNWOutlineNode *folderNode = [self _outlineFolderNodeForManagedObject:folder];
	if (!folderNode)
		return; /*Shouldn't happen*/
	NSMutableArray *children = folderNode.children;
	if (!children) {
		children = [NSMutableArray array];
		folderNode.children = children;
	}
	NNWOutlineNode *node = [NNWOutlineNode outlineNodeWithManagedObject:feed isFolder:NO level:folderNode.level + 1];
	[children addObject:node];
}


- (void)_addFeedToFolders:(NNWFeed *)feed {
	NSSet *folders = [feed valueForKey:@"folders"];
	NSInteger ctFolders = 0;
	for (NNWFolder *oneFolder in folders) {
		ctFolders++;
		[self _addFeed:feed toFolder:oneFolder];	
	}
	if (ctFolders < 1) /*[[folders allObjects] count] < 1)*/ {
		NNWOutlineNode *node = [NNWOutlineNode outlineNodeWithManagedObject:feed isFolder:NO level:0];
		[self.outline addObject:node];		
	}
}


- (void)_addFeedsToFlattenedOutline:(NSArray *)feedsThatShouldAppear {
	for (NNWFeed *oneFeed in feedsThatShouldAppear)
		[self _addFeedToFolders:oneFeed];
	self.flattenedOutline = [self _flattenedOutline]; /*Re-flatten now that it contains feeds*/
}


- (BOOL)_childrenAreLogicallyEmpty:(NSArray *)children {
	if (RSIsEmpty(children))
		return YES;
	for (NNWOutlineNode *oneNode in children) {
		if (!oneNode.isFolder)
			return NO;
		if (![self _childrenAreLogicallyEmpty:oneNode.children])
			return NO;
	}
	return YES;
}


- (void)_removeEmptyFoldersFromFlattenedOutline {
	NSInteger i = 0;
	for (i = [self.flattenedOutline count] - 1; i >= 0; i--) {
		NNWOutlineNode *oneNode = [[[self.flattenedOutline objectAtIndex:i] retain] autorelease];
		if (!oneNode.isFolder)
			continue;
//		if (RSIsEmpty(oneNode.children))
		if ([self _childrenAreLogicallyEmpty:oneNode.children])
			[self.flattenedOutline removeObjectAtIndex:i];
	}
}


- (void)rebuildOutline:(NSArray *)feedIDsThatShouldAppear includeExcludedFeeds:(BOOL)includeExcludedFeeds {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray *feedsThatShouldAppear = [[[NSMutableArray alloc] init] autorelease];
	for (NSString *oneGoogleFeedID in feedIDsThatShouldAppear) {
		if (includeExcludedFeeds)
			[feedsThatShouldAppear safeAddObject:[NNWFeed existingFeedWithGoogleID:oneGoogleFeedID moc:app_delegate.managedObjectContext]];
		else
			[feedsThatShouldAppear safeAddObject:[NNWFeed nonExcludedFeedWithGoogleID:oneGoogleFeedID moc:app_delegate.managedObjectContext]];
	}
		
	static NSArray *sortDescriptors = nil;
	if (!sortDescriptors)
		sortDescriptors = [[NSArray alloc] initWithObjects:[[[NSSortDescriptor alloc] initWithKey:RSDataTitle ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease], nil];
	[feedsThatShouldAppear sortUsingDescriptors:sortDescriptors]; 
	if (RSIsEmpty(feedsThatShouldAppear)) {
		self.folders = nil;
		self.outline = nil;
		self.flattenedOutline = nil;
		goto rebuildOutline_exit;
	}
	self.folders = [[NNWDataController sharedController] allFolders]; /*Sorted by title already*/
	self.outline = [self _allFoldersAtLevel:0 withParent:nil];
	self.flattenedOutline = [self _flattenedOutline];
	if ([self _hasOrphanFolders]) {
		[self _adoptOrphanFolders];
		self.outline = [self _allFoldersAtLevel:0 withParent:nil];
		self.flattenedOutline = [self _flattenedOutline];
	}
	[self _addFeedsToFlattenedOutline:feedsThatShouldAppear];
	[self _removeEmptyFoldersFromFlattenedOutline];
rebuildOutline_exit:
	if (_delegate)
		[_delegate performSelectorOnMainThread:@selector(outlineDidRebuild:) withObject:self waitUntilDone:NO];
	[pool drain];
}


- (void)rebuildOutline:(NSArray *)feedsThatShouldAppear {
	[self rebuildOutline:feedsThatShouldAppear includeExcludedFeeds:NO];
}


- (NSMutableArray *)_allFoldersAtLevel:(NSInteger)level withParent:(NNWFolder *)parent {
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[self.folders count]];
	NSMutableString *prefix = [[[NSMutableString alloc] initWithString:@""] autorelease];
	if (parent) {
		[prefix appendString:[parent valueForKey:@"label"]];
		[prefix appendString:@" — "];
	}
	for (NNWFolder *oneFolder in self.folders) {
		if ([[oneFolder valueForKey:@"level"] integerValue] != level)
			continue;
		if (parent && ![[oneFolder valueForKey:@"label"] hasPrefix:prefix])
			continue;
		NNWOutlineNode *outlineNode = [NNWOutlineNode outlineNodeWithManagedObject:oneFolder isFolder:YES level:level];
		outlineNode.children = [self _allFoldersAtLevel:level + 1 withParent:oneFolder];
		[tempArray addObject:outlineNode];
	}
	return tempArray;
}


#pragma mark -
#pragma mark Data Source - Main Thread

- (NSInteger)numberOfObjects {
	if (!self.flattenedOutline)
		return 0;
	return [self.flattenedOutline count];
}


- (NNWProxy *)objectAtIndex:(NSInteger)index {
	return [[self.flattenedOutline safeObjectAtIndex:index] nnwProxy];
}


- (NSInteger)indentationLevelForIndex:(NSInteger)index {
	NNWOutlineNode *outlineNode = [self.flattenedOutline safeObjectAtIndex:index];
	return outlineNode ? outlineNode.level : 0;
}


#pragma mark Folders - Fetch Requests / News Items

- (NSInteger)indexOfProxy:(NNWProxy *)proxy {
	NSInteger ix = 0;
	for (NNWOutlineNode *oneNode in self.flattenedOutline) {
		if (oneNode.nnwProxy == proxy)
			return ix;
		ix++;
	}
	return NSNotFound;
}


- (NSArray *)googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)folder {
	NSInteger ix = [self indexOfProxy:folder];
	if (ix == NSNotFound)
		return nil;
	NNWOutlineNode *folderNode = [self.flattenedOutline objectAtIndex:ix];
	NSInteger folderLevel = folderNode.level;
	NSMutableArray *googleIDs = [NSMutableArray array];
	while (true) {
		ix++;
		NNWOutlineNode *oneNode = [self.flattenedOutline safeObjectAtIndex:ix];
		if (!oneNode || oneNode.level <= folderLevel)
			break;
		if (oneNode.level > folderLevel && !oneNode.isFolder)
			[googleIDs safeAddObject:oneNode.nnwProxy.googleID];
	}
	return googleIDs;
}


@end

