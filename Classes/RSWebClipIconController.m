//
//  RSWebIconClipController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSWebClipIconController.h"
#import "RSDownloadOperation.h"
#import "RSFileUtilities.h"
#import "RSFoundationExtras.h"
#import "RSImageFolderCache.h"
#import "RSImageUtilities.h"
#import "RSOperationController.h"


NSString *RSWebClipIconDownloadedNotification = @"RSWebClipIconDownloadedNotification";
NSString *RSWebClipIconURLKey = @"url";

static NSString *RSWebClipIconCacheFolderName = @"WebClipIconCache.noindex";


@interface RSWebClipIconController ()

@property (nonatomic, retain) NSMutableSet *checkedURLs;
@property (nonatomic, retain, readwrite) RSImageFolderCache *imageFolderCache;

@end


@implementation RSWebClipIconController

@synthesize checkedURLs;
@synthesize imageFolderCache;


#pragma mark Class Methods

+ (RSWebClipIconController *)sharedController {
	static id gMyInstance = nil;
	if (gMyInstance == nil)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	if (RSLockCreate(&webclipControllerLock) != 0)
		return nil;
	NSDate *dateCacheLastNuked = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateWebClipIconCacheLastNuked"];
	if (dateCacheLastNuked == nil)
		dateCacheLastNuked = [NSDate distantPast];
	NSDate *dateOneWeekAgo = [NSDate rs_dateWithNumberOfDaysInThePast:7];
	if ([dateOneWeekAgo earlierDate:dateCacheLastNuked] == dateCacheLastNuked) {
		NSString *folder = RSSubFolderInFolder(rs_app_delegate.pathToCacheFolder, RSWebClipIconCacheFolderName, NO);
//		NSString *folder = RSCacheFolderForAppSubFolder(RSWebClipIconCacheFolderName, NO);
		if (RSFileExists(folder))
			RSFileDelete(folder);
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateWebClipIconCacheLastNuked"];
	}
//	NSString *folder = RSCacheFolderForAppSubFolder(RSWebClipIconCacheFolderName, YES);
	NSString *folder = RSSubFolderInFolder(rs_app_delegate.pathToCacheFolder, RSWebClipIconCacheFolderName, YES);
	self.imageFolderCache = [[[RSImageFolderCache alloc] initWithFolder:folder] autorelease];
	self.checkedURLs = [NSMutableSet setWithCapacity:1000];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	RSLockDestroy(&webclipControllerLock);
	[imageFolderCache release];
	[checkedURLs release];
	[super dealloc];
}


#pragma mark Downloading

- (void)webclipIconDownloadOperationDidFinish:(RSDownloadOperation *)webclipIconDownloadOperation {
	if (!webclipIconDownloadOperation.okResponse || RSIsEmpty(webclipIconDownloadOperation.responseBody) || rs_app_delegate.appIsShuttingDown)
		return;
	NSString *filename = [RSImageFolderCache filenameForURLString:[webclipIconDownloadOperation.url absoluteString]];
	if (RSStringIsEmpty(filename))
		return;
	CGImageRef cgImage = RSCGImageFromDataWithMaxPixelSize(webclipIconDownloadOperation.responseBody, 200);
	if (cgImage == nil)
		return;
	NSError *error = nil;
	if (![self.imageFolderCache saveCGImage:cgImage withFilename:filename error:&error])
		return;
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:webclipIconDownloadOperation.url forKey:RSURLKey];
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSWebClipIconDownloadedNotification object:self userInfo:userInfo];
}


- (void)downloadWebClipIconAtURL:(NSURL *)webclipIconURL {
	RSDownloadOperation *webclipIconDownloadOperation = [[[RSDownloadOperation alloc] initWithURL:webclipIconURL delegate:self callbackSelector:@selector(webclipIconDownloadOperationDidFinish:) parser:nil useWebCache:NO] autorelease];
	webclipIconDownloadOperation.operationType = RSOperationTypeDownloadWebClipIcon;
	webclipIconDownloadOperation.operationObject = webclipIconURL;
	[[RSOperationController sharedController] addOperation:webclipIconDownloadOperation];
	//RSAddOperationIfNotInQueue(webclipIconDownloadOperation);
}


#pragma mark Cache

- (void)fetchIcon:(NSURL *)imageURL {
	
	/*Threaded, via NSInvocationOperation.*/
	
	if (rs_app_delegate.appIsShuttingDown)
		return;
	NSString *filename = [RSImageFolderCache filenameForURLString:[imageURL absoluteString]];
	CGImageRef cgImage = [self.imageFolderCache cgImageForFilename:filename];
	if (cgImage != nil) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:imageURL forKey:RSURLKey];
		[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSWebClipIconDownloadedNotification object:self userInfo:userInfo];
		return;
	}
	
	RSLockLock(&webclipControllerLock);
	BOOL checkedURLsContainsURL = [self.checkedURLs containsObject:imageURL];
	if (!checkedURLsContainsURL)
		[self.checkedURLs addObject:imageURL];
	RSLockUnlock(&webclipControllerLock);
	
	if (!checkedURLsContainsURL)
		[self downloadWebClipIconAtURL:imageURL];
}


- (CGImageRef)webclipIconForURL:(NSURL *)webclipIconURL {
	if (rs_app_delegate.appIsShuttingDown)
		return nil;
	NSString *filename = [RSImageFolderCache filenameForURLString:[webclipIconURL absoluteString]];
	if (RSStringIsEmpty(filename))
		return nil;
	CGImageRef cgImage = [self.imageFolderCache cachedCGImageForFilename:filename];
	if (cgImage != nil)
		return cgImage;
	NSInvocationOperation *fetchIconOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(fetchIcon:) object:webclipIconURL] autorelease];
	[[RSOperationController sharedController] addOperation:fetchIconOperation];																  
	return nil;
//	if (![self.checkedURLs containsObject:webclipIconURL]) {
//		[self.checkedURLs addObject:webclipIconURL];
//		[self downloadWebClipIconAtURL:webclipIconURL];
//	}
//	return nil;
}


- (CGImageRef)webclipIconForHomePageURL:(NSURL *)homePageURL {
	if (homePageURL == nil)
		return nil;
	NSURL *webclipIconURL = [NSURL URLWithString:@"/apple-touch-icon.png" relativeToURL:homePageURL];
	return [self webclipIconForURL:webclipIconURL];
}


#pragma mark Public API

- (CGImageRef)webclipIconForHomePageURL:(NSURL *)homePageURL webclipIconURL:(NSURL *)webclipIconURL {
	if (webclipIconURL != nil)
		return [self webclipIconForURL:webclipIconURL];
	return [self webclipIconForHomePageURL:homePageURL];
}


@end
