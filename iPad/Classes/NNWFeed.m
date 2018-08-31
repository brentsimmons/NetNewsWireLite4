//
//  NNWFeed.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFeed.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWFeedProxy.h"
#import "NNWFolder.h"
#import "NNWFolderProxy.h"
#import "RSParsedGoogleSub.h"


NSString *NNWFeedHideShowStatusDidChangeNotification = @"NNWFeedHideShowStatusDidChangeNotification";


@implementation NNWFeed

@dynamic firstitemmsec, googleID, serverUnreadCount, title, userExcludes, folders;

#pragma mark Class Methods

+ (BOOL)_googleIDIsFeedID:(NSString *)googleID {
	return [googleID isKindOfClass:[NSString class]] && !RSStringIsEmpty(googleID) && [googleID hasPrefix:@"feed/"];
}

+ (NNWFeed *)feedWithGoogleID:(NSString *)googleID {
	if (![self _googleIDIsFeedID:googleID])
		return nil;
	NNWFeed *feed = (NNWFeed *)[[NNWDataController sharedController] objectWithUniqueGoogleID:googleID entityName:RSDataEntityFeed managedObjectContext:app_delegate.managedObjectContext];
	return feed;
}


+ (void)userSetUserExcludes:(BOOL)userExcludes forFeedWithGoogleID:(NSString *)googleID moc:(NSManagedObjectContext *)moc {
	NNWFeed *feed = (NNWFeed *)[[NNWDataController sharedController] existingFeedWithGoogleID:googleID moc:moc];
	feed.userExcludes = [NSNumber numberWithBool:userExcludes];
}


+ (void)userSetExcludedForFeedWithGoogleID:(NSString *)googleID {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSManagedObjectContext *moc = app_delegate.managedObjectContext;
	NNWFeed *feed = (NNWFeed *)[[NNWDataController sharedController] existingFeedWithGoogleID:googleID moc:moc];
	feed.userExcludes = [NSNumber numberWithBool:YES];
	[app_delegate saveManagedObjectContext];
	[pool drain];
}


+ (void)userSetNotExcludedForFeedWithGoogleID:(NSString *)googleID {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSManagedObjectContext *moc = app_delegate.managedObjectContext;
	NNWFeed *feed = (NNWFeed *)[[NNWDataController sharedController] existingFeedWithGoogleID:googleID moc:moc];
	feed.userExcludes = [NSNumber numberWithBool:NO];
	[app_delegate saveManagedObjectContext];
	[pool drain];
}


+ (void)userSetExcluded:(BOOL)flag forFeedWithGoogleID:(NSString *)googleID {
	if (flag)
		[self performSelector:@selector(userSetExcludedForFeedWithGoogleID:) onThread:app_delegate.coreDataThread withObject:googleID waitUntilDone:YES];
	else
		[self performSelector:@selector(userSetNotExcludedForFeedWithGoogleID:) onThread:app_delegate.coreDataThread withObject:googleID waitUntilDone:YES];
	[self rs_enqueueNotificationOnMainThread:NNWFeedHideShowStatusDidChangeNotification object:nil userInfo:nil];
}


+ (BOOL)feedWithGoogleIDIsUserExcluded:(NSString *)googleID {
	NNWFeed *feed = [self feedWithGoogleID:googleID];
	if (!feed)
		return NO; /*shouldn't happen*/
	return [[feed valueForKey:RSDataUserExcludes] boolValue];
}


+ (NNWFeed *)existingFeedWithGoogleID:(NSString *)googleID moc:(NSManagedObjectContext *)moc {
	if (![self _googleIDIsFeedID:googleID])
		return nil;
	return [[NNWDataController sharedController] existingFeedWithGoogleID:googleID moc:moc];
}


+ (NNWFeed *)nonExcludedFeedWithGoogleID:(NSString *)googleID moc:(NSManagedObjectContext *)moc {
	NNWFeed *feed = [self existingFeedWithGoogleID:googleID moc:moc];
	if (feed == nil || [[feed valueForKey:RSDataUserExcludes] boolValue])
		return nil;
	return feed;
}


+ (NSManagedObject *)insertOrUpdateFeedWithGoogleDictionary:(RSParsedGoogleSub *)sub firstItemMMSecDidChange:(BOOL *)firstItemMMSecDidChange managedObjectContext:(NSManagedObjectContext *)moc {
	NSString *googleID = sub.googleID;
	if (![self _googleIDIsFeedID:googleID])
		return nil;
	NSManagedObject *feed = [[NNWDataController sharedController] objectWithUniqueGoogleID:googleID entityName:RSDataEntityFeed managedObjectContext:moc];
	NSString *existingFirstItemMMSec = [(NNWFeed *)feed primitiveFirstitemmsec];//[feed valueForKey:@"firstitemmsec"];
	NSString *newFirstItemMMSec = sub.firstItemMsec;//[googleDictionary objectForKey:@"firstitemmsec"];
	if (!existingFirstItemMMSec || ![existingFirstItemMMSec isEqualToString:newFirstItemMMSec]) {
		*firstItemMMSecDidChange = YES;
		[(NNWFeed *)feed setPrimitiveFirstitemmsec:newFirstItemMMSec];
	}
	if (![sub.title isEqualToString:[(NNWFeed *)feed primitiveTitle]])
		[(NNWFeed *)feed setPrimitiveTitle:sub.title];
	NSArray *categories = sub.categories;
	if (RSIsEmpty(categories)) {
		if (!RSIsEmpty([(NNWFeed *)feed primitiveFolders]))
			((NNWFeed *)feed).folders = [NSSet set];
	}
	else {
		NSMutableSet *categoriesSet = [[[NSMutableSet alloc] init] autorelease];
		for (RSParsedGoogleCategory *oneCategory in categories) {
			if ([oneCategory isEmpty])
				continue;
			NSManagedObject *oneFolder = [NNWFolder folderWithGoogleDictionary:oneCategory managedObjectContext:moc];
			if (oneFolder)
				[categoriesSet addObject:oneFolder];
		}
		((NNWFeed *)feed).folders = categoriesSet;
	}
	return feed;
}


+ (NSArray *)allFeedIDs {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:RSDataEntityFeed inManagedObjectContext:app_delegate.managedObjectContext]];
	NSArray *propertiesToFetch = [[[NSArray alloc] initWithObjects:RSDataGoogleID, nil] autorelease];
	[request setPropertiesToFetch:propertiesToFetch];
	[request setResultType:NSDictionaryResultType];
	[request setReturnsDistinctResults:YES];
	NSError *error = nil;
	NSArray *result = [app_delegate.managedObjectContext executeFetchRequest:request error:&error];
	NSArray *googleIDs = [result valueForKeyPath:RSDataGoogleID];
	return googleIDs;	
}

+ (void)deleteNewsItemsForFeedWithGoogleID:(NSString *)googleID managedObjectContext:(NSManagedObjectContext *)moc {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// TODO
//	NSFetchRequest *request = [[NSFetchRequest alloc] init];
//	[request setEntity:[NSEntityDescription entityForName:RSDataEntityNewsItem inManagedObjectContext:moc]];
//	[request setPredicate:[NSPredicate predicateWithFormat:@"googleFeedID == %@", googleID]];
//	NSError *error = nil;
//	NSArray *results = [moc executeFetchRequest:request error:&error];
//	for (NNWNewsItem *oneNewsItem in results)
//		[moc deleteObject:oneNewsItem];
//	[request release];
	[pool drain];
}


+ (void)showAndHideFeeds:(NSDictionary *)showAndHideFeedsDict {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *feedsToHide = [showAndHideFeedsDict objectForKey:@"feedsToHide"];
	NSArray *feedsToShow = [showAndHideFeedsDict objectForKey:@"feedsToShow"];
	BOOL atLeastOneChange = NO;
	for (NSString *oneGoogleID in feedsToHide) {
		NNWFeed *feed = (NNWFeed *)[[NNWDataController sharedController] objectWithUniqueGoogleID:oneGoogleID entityName:RSDataEntityFeed managedObjectContext:app_delegate.managedObjectContext];
		if (!feed)
			continue;
		[feed setValue:[NSNumber numberWithBool:YES] forKey:RSDataUserExcludes];
		atLeastOneChange = YES;
		[self deleteNewsItemsForFeedWithGoogleID:oneGoogleID managedObjectContext:app_delegate.managedObjectContext];
	}
	for (NSString *oneGoogleID in feedsToShow) {
		NNWFeed *feed = (NNWFeed *)[[NNWDataController sharedController] objectWithUniqueGoogleID:oneGoogleID entityName:RSDataEntityFeed managedObjectContext:app_delegate.managedObjectContext];
		if (!feed)
			continue;
		[feed setValue:[NSNumber numberWithBool:NO] forKey:RSDataUserExcludes];
		atLeastOneChange = YES;
	}
	if (atLeastOneChange) {
		[app_delegate saveManagedObjectContext];
		RSPostNotificationOnMainThread(NNWFeedHideShowStatusDidChangeNotification);
	}
	[pool drain];
}


+ (void)deleteFeedsExceptFor:(NSArray *)feeds managedObjectContext:(NSManagedObjectContext *)moc {
	if (RSIsEmpty(feeds))
		return;
	NSArray *allFeeds = [[NNWDataController sharedController] allFeedsInManagedObjectContext:moc];
	NSMutableArray *feedsToDelete = [NSMutableArray array];
	for (NNWFeed *oneFeed in allFeeds) {
		if (![feeds containsObject:oneFeed])
			[feedsToDelete addObject:oneFeed];
	}
	if (RSIsEmpty(feedsToDelete))
		return;
	BOOL atLeastOneChange = NO;
	for (NNWFeed *oneFeed in feedsToDelete) {
		NSString *oneGoogleFeedID = [oneFeed valueForKey:RSDataGoogleID];
		if (!RSStringIsEmpty(oneGoogleFeedID))
			[self deleteNewsItemsForFeedWithGoogleID:oneGoogleFeedID managedObjectContext:moc];
		[oneFeed setValue:[NSSet set] forKey:@"folders"];
		[moc deleteObject:oneFeed];
		atLeastOneChange = YES;
	}
	if (atLeastOneChange) {
		[app_delegate saveManagedObjectContext:moc];
		RSPostNotificationOnMainThread(NNWFeedHideShowStatusDidChangeNotification);
	}	
}


@end
