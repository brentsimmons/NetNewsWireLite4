//
//  NNWFolderProxy.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFolderProxy.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWMainViewController.h"


@implementation NNWFolderProxy

@synthesize googleIDsOfDescendants = _googleIDsOfDescendants;

static NSMutableDictionary *gFolderProxyCache = nil;

+ (void)initialize {
	if (!gFolderProxyCache)
		gFolderProxyCache = [[NSMutableDictionary alloc] init];
}

+ (NNWFolderProxy *)folderProxyWithGoogleID:(NSString *)googleID {
	if (RSStringIsEmpty(googleID))
		return nil;
	if ([gFolderProxyCache objectForKey:googleID])
		return [gFolderProxyCache objectForKey:googleID];
	NNWFolderProxy *folderProxy = [[[NNWFolderProxy alloc] initWithGoogleID:googleID] autorelease];
	[gFolderProxyCache setObject:folderProxy forKey:googleID];
	return folderProxy;
}


+ (NSArray *)folderProxies {
	NSMutableArray *folderProxies = [NSMutableArray array];
	for (NSString *oneKey in gFolderProxyCache)
		[folderProxies safeAddObject:[gFolderProxyCache objectForKey:oneKey]];
	return folderProxies;
}


+ (void)updateUnreadCountsForAllFolders {
	NSArray *folderProxies = [self folderProxies];
	[folderProxies makeObjectsPerformSelector:@selector(updateUnreadCountFromDescendants)];
}


static NSString *NNWGoogleIDsOfDescendantsKey = @"googleIDsOfDescendants";

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:_googleIDsOfDescendants forKey:NNWGoogleIDsOfDescendantsKey];
}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	_googleIDsOfDescendants = [[coder decodeObjectForKey:NNWGoogleIDsOfDescendantsKey] retain];
	[gFolderProxyCache setObject:self forKey:_googleID];
	return self;
}


- (void)dealloc {
	[_googleIDsOfDescendants release];
	[super dealloc];
}


- (BOOL)isFolder {
	return YES;
}


- (NSArray *)googleIDsOfDescendants {
	// TODO
	if (!_googleIDsOfDescendants) /*TODO: not get this from main view controller. Ugh.*/
		self.googleIDsOfDescendants = [[NNWMainViewController sharedViewController] googleIDsOfDescendantsOfFolder:self];
	return _googleIDsOfDescendants;
}


- (void)updateGoogleIDsOfDescendants {
	self.googleIDsOfDescendants = [[NNWMainViewController sharedViewController] googleIDsOfDescendantsOfFolder:self];
}


- (void)updateUnreadCountFromDescendants {
	[self updateGoogleIDsOfDescendants];
	NSArray *googleIDsOfDescendants = self.googleIDsOfDescendants;
	NSInteger unreadCount = 0;
	for (NSString *oneGoogleID in googleIDsOfDescendants) {
		NNWFeedProxy *oneFeedProxy = [NNWFeedProxy feedProxyWithGoogleID:oneGoogleID];
		if (!oneFeedProxy)
			continue;
		unreadCount += oneFeedProxy.unreadCount;
	}
	self.unreadCount = unreadCount;
}


@end
