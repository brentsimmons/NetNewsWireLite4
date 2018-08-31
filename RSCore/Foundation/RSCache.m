//
//  RSCache.m
//  libTapLynx
//
//  Created by Brent Simmons on 7/12/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSCache.h"
#import "RSFoundationExtras.h"


static Class nsCacheClass = nil;

@interface RSCache ()
@property (nonatomic, assign, readonly) BOOL useNSCache;
@property (nonatomic, retain, readonly) NSMutableDictionary *cacheDictionary;
@property (nonatomic, retain, readonly) id nativeCache;
@end


@implementation RSCache

@synthesize useNSCache;
@synthesize cacheDictionary;
@synthesize nativeCache;


#pragma mark Class Methods

+ (id)cache {
	return [[[self alloc] init] autorelease];
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	if (nsCacheClass != nil || NSClassFromString(@"NSCache") != nil) {
		useNSCache = YES;
		if (nsCacheClass == nil)
			nsCacheClass = NSClassFromString(@"NSCache");
		nativeCache = [[nsCacheClass alloc] init];
		//[nativeCache setDelegate:self];
	}
	else {
		if (RSLockCreate(&cacheLock) != 0) {
			NSLog(@"Error creating lock in RSCache init.");
			return nil;
		}
		cacheDictionary = [[NSMutableDictionary alloc] init];
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
	}
#if !TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:NSApplicationDidResignActiveNotification object:nil];
#endif
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (useNSCache)
		[nativeCache release];
	else {
		[cacheDictionary release];
		RSLockDestroy(&cacheLock);
	}
	[super dealloc];
}


#pragma mark Getting and setting objects

- (id)objectForKey:(id)key {
	if (self.useNSCache)
		return [self.nativeCache objectForKey:key];
	RSLockLock(&cacheLock);
	id obj = [[[self.cacheDictionary objectForKey:key] retain] autorelease];
	RSLockUnlock(&cacheLock);
	return obj;
}


- (void)setObject:(id)obj forKey:(id)key {
	if (self.useNSCache) {
		[self.nativeCache setObject:obj forKey:key];
		return;
	}
	RSLockLock(&cacheLock);
	[self.cacheDictionary setObject:obj forKey:key];
	RSLockUnlock(&cacheLock);
}


- (void)setObjectIfNotNil:(id)obj forKey:(id)key {
	if (obj != nil)
		[self setObject:obj forKey:key];
}


#pragma mark Removing objects

- (void)removeObjectForKey:(id)key {
	if (self.useNSCache) {
		[self.nativeCache removeObjectForKey:key];
		return;
	}
	RSLockLock(&cacheLock);
	[self.cacheDictionary removeObjectForKey:key];
	RSLockUnlock(&cacheLock);
}


//TODO: remove all objects when app enters background - both on Mac and iOS

- (void)removeAllObjects {
	if (self.useNSCache) {
		[self.nativeCache removeAllObjects];
		return;
	}
	RSLockLock(&cacheLock);
	[self.cacheDictionary removeAllObjects];
	RSLockUnlock(&cacheLock);
}


#pragma mark Count Limit

- (NSUInteger)countLimit {
	if (self.useNSCache)
		return [self.nativeCache countLimit];
	return 0;
}


- (void)setCountLimit:(NSUInteger)aCountLimit {
	if (self.useNSCache)
		[self.nativeCache setCountLimit:aCountLimit];
}


#pragma mark Memory warning

/*Registered only if not using native NSCache, which handles memory warnings itself.*/

- (void)didReceiveMemoryWarning:(NSNotification *)note {
	[self removeAllObjects];
}


#pragma mark NSCache Delegate

//- (void)cache:(NSCache *)cache willEvictObject:(id)obj {
//	NSLog(@"Evicting: %@", obj);
//}

@end

