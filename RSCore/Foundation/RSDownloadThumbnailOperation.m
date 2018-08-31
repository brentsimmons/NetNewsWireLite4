//
//  RSDownloadThumbnailOperation.m
//  libTapLynx
//
//  Created by Brent Simmons on 12/1/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSDownloadThumbnailOperation.h"
#import "RSThumbnailCacheController.h"
#import "RSImageScalingSpecifier.h"


NSString *RSDownloadThumbnailOperationDidCompleteNotification = @"RSDownloadThumbnailOperationDidCompleteNotification";

@implementation RSDownloadThumbnailOperation

@synthesize imageScalingSpecifier;
@synthesize thumbnailImage;

#pragma mark Init

- (id)initWithImageScalingSpecifier:(RSImageScalingSpecifier *)anImageScalingSpecifier delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithURL:anImageScalingSpecifier.URL delegate:aDelegate callbackSelector:aCallbackSelector parser:nil useWebCache:YES];
	if (!self)
		return nil;
	imageScalingSpecifier = [anImageScalingSpecifier retain];
	self.operationType = RSOperationTypeDownloadThumbnail;
	self.operationObject = anImageScalingSpecifier;
	return self;
}


- (id)initWithURL:(NSURL *)aURL delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector targetImageSize:(CGSize)aSize roundedCorners:(BOOL)roundedCornersFlag {
	NSLog(@"Deprecation warning: RSDownloadThumbnailOperation - initWithURL");
	self = [super initWithURL:aURL delegate:aDelegate callbackSelector:aCallbackSelector parser:nil useWebCache:YES];
	if (!self)
		return nil;
	return [self initWithImageScalingSpecifier:imageScalingSpecifier delegate:aDelegate callbackSelector:aCallbackSelector];
}


#pragma mark Dealloc

- (void)dealloc {
	[thumbnailImage release];
	[imageScalingSpecifier release];
	[super dealloc];
}


#pragma mark Accessors - backward compatibility

- (CGSize)targetImageSize {
	NSLog(@"Deprecation warning - RSDownloadThumbnailOperation - targetImageSize");
	return self.imageScalingSpecifier.targetSize;
}


- (BOOL)roundedCorners {
	NSLog(@"Deprecation warning - RSDownloadThumbnailOperation - roundedCorners");
	return self.imageScalingSpecifier.roundedCorners;
}


#pragma mark Cache

- (BOOL)fetchCachedObject {
	self.thumbnailImage = [[RSThumbnailCacheController sharedController] cachedThumbnailForImageScalingSpecifier:self.imageScalingSpecifier];
//	self.thumbnailImage = [[RSThumbnailCacheController sharedController] cachedThumbnailAtURL:self.url targetSize:self.targetImageSize roundedCorners:self.roundedCorners];
	return self.thumbnailImage != nil;
}


#pragma mark NSOperation

- (void)main {
	if (!self.useWebCache || ![self fetchCachedObject])
		[self download];
	if (self.thumbnailImage != nil)
		[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSDownloadThumbnailOperationDidCompleteNotification object:self userInfo:nil];
	[self notifyObserversThatOperationIsComplete];
}


#pragma mark Downloading

- (void)createRequest {
	[super createRequest];
	[self.urlRequest setTimeoutInterval:20];
}


#pragma mark NSURLConnection Delegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (self.okResponse) {
		[[RSWebCacheController sharedController] storeObject:self.responseBody url:self.url];
		self.thumbnailImage = [[RSThumbnailCacheController sharedController] storeDownloadedDataAndReturnThumbnail:self.responseBody imageScalingSpecifier:self.imageScalingSpecifier];
	}
	self.finishedReading = YES;
}


@end


@implementation RSFetchThumbnailFromCacheOperation

- (void)main {
	[self fetchCachedObject];
	[self callDelegate];
	if (self.thumbnailImage != nil)
		[self rs_postNotificationOnMainThread:RSDownloadThumbnailOperationDidCompleteNotification object:self userInfo:nil];
	[self postOperationDidCompleteNotification];
}

@end
