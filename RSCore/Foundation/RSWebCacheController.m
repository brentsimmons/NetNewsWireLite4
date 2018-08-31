//
//  RSWebCacheController.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/15/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSWebCacheController.h"
#import "RSFoundationExtras.h"


@interface RSWebCacheController ()
@property (nonatomic, retain, readonly) NSString *baseCacheFolder;
@property (nonatomic, retain, readonly) NSString *cacheFolderName;
@property (nonatomic, assign) BOOL didEnsureFolderExists;
@end


@implementation RSWebCacheController

@synthesize baseCacheFolder, cacheFolderName, didEnsureFolderExists;

#pragma mark Class Methods

+ (id)sharedController {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

static NSString *RSWebCacheFolderName = @"RSWebCache";

- (id)init {
	if (![super init])
		return nil;
	baseCacheFolder = [NSTemporaryDirectory() retain];
	cacheFolderName = [RSWebCacheFolderName retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[baseCacheFolder release];
	[cacheFolderName release];
	[super dealloc];
}


#pragma mark Web Cache

- (NSString *)stringRepresentationOfURL:(NSURL *)url {
	return [[url absoluteString] rs_md5HashString];
}


- (NSString *)pathForCache {
	NSString *folderPath = [self.baseCacheFolder stringByAppendingPathComponent:self.cacheFolderName];
	BOOL isDirectory = YES;
	NSError *error = nil;
	if (!self.didEnsureFolderExists) {
		@synchronized([RSWebCacheController class]) {
			self.didEnsureFolderExists = YES;
			if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory])
				[[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];		
			if (error)
				NSLog(@"Error creating web cache: %@ %@", folderPath, error);
		}		
	}
	return folderPath;
}


- (NSString *)pathForObjectAtURL:(NSURL *)url {
	return [[self pathForCache] stringByAppendingPathComponent:[self stringRepresentationOfURL:url]];
}


#pragma mark Reading

- (NSData *)cachedObjectAtPath:(NSString *)cachedObjectPath {
	NSData *data = nil;
	@synchronized([RSWebCacheController class]) {
		data = [NSData dataWithContentsOfFile:cachedObjectPath];		
	}
	return data;
}


- (NSData *)cachedObjectAtURL:(NSURL *)url {
	return [self cachedObjectAtPath:[self pathForObjectAtURL:url]];
}


- (RS_PLATFORM_IMAGE *)cachedImageAtURL:(NSURL *)URL {
	NSData *imageData = [self cachedObjectAtURL:URL];
	if (imageData == nil)
		return nil;
	return [[[RS_PLATFORM_IMAGE alloc] initWithData:imageData] autorelease];
}


#pragma mark Storing

- (void)storeObject:(NSData *)data url:(NSURL *)url {
	if (RSIsEmpty(data))
		return;
	NSError *error = nil; /*Ignored. Not a big deal.*/
	@synchronized([RSWebCacheController class]) {
		[data writeToFile:[self pathForObjectAtURL:url] options:NSAtomicWrite error:&error];
	}
	if (error)
		NSLog(@"Error storing object in web data cache: %@", error);
}


@end


#pragma mark -

@implementation RSPermanentWebCacheController

#pragma mark Class Methods

+ (id)sharedController {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

static NSString *RSPermanentWebCacheName = @"RSPermanentWebCache";

- (id)init {
	if (![super init])
		return nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	baseCacheFolder = [[paths objectAtIndex:0] retain];
	cacheFolderName = [RSPermanentWebCacheName retain];
	return self;
}


@end

