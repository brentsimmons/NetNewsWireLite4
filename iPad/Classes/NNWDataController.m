//
//  NNWDataController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWDataController.h"
#import "NNWAppDelegate.h"
#import "NNWFeed.h"


NSString *NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification = @"NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification";
NSString *NNWUserDidMarkOneOrMoreItemsInFeedAsStarredNotification = @"NNWUserDidMarkOneOrMoreItemsInFeedAsStarredNotification";
NSString *NNWUserDidMarkOneOrMoreItemsInFeedAsUnstarredNotification = @"NNWUserDidMarkOneOrMoreItemsInFeedAsUnstarredNotification";
NSString *NNWFeedDidUpdateMostRecentItemNotification = @"NNWFeedDidUpdateMostRecentItemNotification";


@interface NNWDataController ()
@property (nonatomic, retain) NSMutableDictionary *uniqueObjects;
- (NSManagedObjectID *)cachedObjectIDWithGoogleID:(NSString *)googleID entityName:(NSString *)entityName;
- (void)_cacheObject:(NSManagedObject *)obj googleID:(NSString *)googleID entityName:(NSString *)entityName moc:(NSManagedObjectContext *)moc;
@end


@implementation NNWDataController

@synthesize uniqueObjects = _uniqueObjects;

#pragma mark Class Methods

+ (id)sharedController {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	_uniqueObjects = [[NSMutableDictionary alloc] init];
	return self;
}


#pragma mark Unique Objects

- (NSManagedObject *)fetchObjectWithGoogleID:(NSString *)googleID entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext]];
	[request setFetchLimit:1];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"googleID == %@", googleID];
	[request setPredicate:predicate];
	NSError *error = nil;
	NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
	return [results safeObjectAtIndex:0];	
}


- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName moc:(NSManagedObjectContext *)moc {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
	NSError *error = nil;
	NSArray *results = [moc executeFetchRequest:request error:&error];
	for (NSManagedObject *oneObject in results) {
		NSString *oneGoogleID = [oneObject valueForKey:RSDataGoogleID];
		if (RSStringIsEmpty(oneGoogleID))
			continue;
		if (![self cachedObjectIDWithGoogleID:oneGoogleID entityName:entityName])
			[self _cacheObject:oneObject googleID:oneGoogleID entityName:entityName moc:moc];
	}	
	return results;
}


- (NSManagedObject *)createObjectWithGoogleID:(NSString *)googleID entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:managedObjectContext];
	[obj setPrimitiveValue:googleID forKey:RSDataGoogleID];
	return obj;	
}


- (NSMutableDictionary *)_cacheForEntityName:(NSString *)entityName {
	NSMutableDictionary *cache = [self.uniqueObjects objectForKey:entityName];	
	if (!cache) {
		cache = [NSMutableDictionary dictionary];
		[self.uniqueObjects setObject:cache forKey:entityName];
	}
	return cache;	
}


- (NSManagedObjectID *)cachedObjectIDWithGoogleID:(NSString *)googleID entityName:(NSString *)entityName {
	return [[self _cacheForEntityName:entityName] objectForKey:googleID];
}


- (NSManagedObject *)_cachedObjectWithGoogleID:(NSString *)googleID entityName:(NSString *)entityName moc:(NSManagedObjectContext *)moc {
	NSManagedObjectID *objectID = [self cachedObjectIDWithGoogleID:googleID entityName:entityName];
	if (objectID == nil)
		return nil;
	NSError *error = nil;
	return [moc existingObjectWithID:objectID error:&error];
}


- (void)_cacheObject:(NSManagedObject *)obj googleID:(NSString *)googleID entityName:(NSString *)entityName moc:(NSManagedObjectContext *)moc {
	NSManagedObjectID *objectID = [obj objectID];
	if ([objectID isTemporaryID]) {
		NSError *error = nil;
		[moc obtainPermanentIDsForObjects:[NSArray arrayWithObject:obj] error:&error];
		objectID = [obj objectID];
		if ([objectID isTemporaryID])
			[app_delegate saveManagedObjectContext:moc];
		objectID = [obj objectID];
	}
	[[self _cacheForEntityName:entityName] safeSetObject:objectID forKey:googleID];
}


- (NSManagedObject *)objectWithUniqueGoogleID:(NSString *)googleID entityName:(NSString *)entityName didCreate:(BOOL *)didCreate managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	*didCreate = NO;
	if (RSStringIsEmpty(googleID))
		return nil;
	NSManagedObject *obj = [self _cachedObjectWithGoogleID:googleID entityName:entityName moc:managedObjectContext];
	if (obj)
		return obj;
	obj = [self fetchObjectWithGoogleID:googleID entityName:entityName managedObjectContext:managedObjectContext];
	if (!obj) {
		*didCreate = YES;
		obj = [self createObjectWithGoogleID:googleID entityName:entityName managedObjectContext:managedObjectContext];
	}
	[self _cacheObject:obj googleID:googleID entityName:entityName moc:managedObjectContext];
	return obj;
}


- (NSManagedObject *)objectWithUniqueGoogleID:(NSString *)googleID entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	BOOL didCreate = NO;
	return [self objectWithUniqueGoogleID:googleID entityName:entityName didCreate:&didCreate managedObjectContext:managedObjectContext];
}


- (NNWFeed *)existingFeedWithGoogleID:(NSString *)googleID moc:(NSManagedObjectContext *)moc {
	if (RSStringIsEmpty(googleID))
		return nil;
	NSManagedObject *obj = [self _cachedObjectWithGoogleID:googleID entityName:@"Feed" moc:moc];
	if (obj)
		return (NNWFeed *)obj;
	return (NNWFeed *)[self fetchObjectWithGoogleID:googleID entityName:@"Feed" managedObjectContext:moc];
}


#pragma mark Folders

- (NSArray *)allFolders {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:RSDataEntityFolder inManagedObjectContext:app_delegate.managedObjectContext]];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:RSDataTitle ascending:YES] autorelease];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	NSError *error = nil;
	return [app_delegate.managedObjectContext executeFetchRequest:request error:&error];
}


#pragma mark Feeds

- (NSArray *)allFeeds {
	return [self allFeedsInManagedObjectContext:app_delegate.managedObjectContext];
}


- (NSArray *)allFeedsInManagedObjectContext:(NSManagedObjectContext *)moc {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:RSDataEntityFeed inManagedObjectContext:moc]];
	NSError *error = nil;
	return [moc executeFetchRequest:request error:&error];
}

@end
