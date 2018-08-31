//
//  NNWFavicon.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFavicon.h"
#import "BCDownloadImageRequest.h"
#import "BCDownloadRequest.h"
#import "BCThreadSafeCache.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"


NSString *NNWFaviconDidDownloadNotification = @"NNWFaviconDidDownloadNotification";

static NSMutableDictionary *gFaviconCache = nil;
static NSMutableDictionary *gFaviconMap = nil;

@implementation NNWFavicon

static NSString *NNWFaviconMapFileName = @"faviconmap.archive";

+ (void)initialize {
	if (!gFaviconCache)
		gFaviconCache = [[NSMutableDictionary dictionary] retain];
	static BOOL didRegisterForNotifications = NO;
	if (!didRegisterForNotifications) {
		didRegisterForNotifications = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDownloadDidComplete:) name:BCDownloadDidCompleteNotification object:nil];
	}
	static BOOL didLoadFaviconMap = NO;
	if (!didLoadFaviconMap) {
		didLoadFaviconMap = YES;
		gFaviconMap = [[NSKeyedUnarchiver unarchiveObjectWithFile:[NSTemporaryDirectory() stringByAppendingPathComponent:NNWFaviconMapFileName]] retain];
		if (!gFaviconMap)
			gFaviconMap = [[NSMutableDictionary dictionary] retain];
	}
}


+ (void)saveFaviconMap {
	if (!RSIsEmpty(gFaviconMap))
		[NSKeyedArchiver archiveRootObject:gFaviconMap toFile:[NSTemporaryDirectory() stringByAppendingPathComponent:NNWFaviconMapFileName]];
}


+ (BOOL)shouldDownloadFaviconForURLString:(NSString *)urlString {
	NSDate *dateLastAttempted = [gFaviconMap objectForKey:urlString];
	if (!dateLastAttempted)
		return YES;
	static NSDate *dateYesterday = nil;
	if (!dateYesterday)
		dateYesterday = [[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24)] retain];
	if ([dateYesterday earlierDate:dateLastAttempted] == dateLastAttempted)
		return YES;
	return NO;
}


+ (NSString *)_faviconURLStringForGoogleID:(NSString *)googleID {
	if (RSStringIsEmpty(googleID) || ![googleID hasPrefix:@"feed/"])
		return nil;
	NSString *feedURLString = [NSString stripPrefix:googleID prefix:@"feed/"];
	NSString *host = [[NSURL URLWithString:feedURLString] host];
	if (RSStringIsEmpty(host))
		return nil;
	NSMutableString *faviconURLString = [[[NSMutableString alloc] initWithString:@"http://"] autorelease];
	[faviconURLString appendString:host];
	[faviconURLString appendString:@"/favicon.ico"];
	return faviconURLString;
}


+ (UIImage *)_cachedFaviconForGoogleFeedID:(NSString *)googleID {
//	if ([gFaviconCache objectForKey:googleID])
		return [gFaviconCache objectForKey:googleID];
//	NSString *urlString = [self _faviconURLStringForGoogleID:googleID];
//	if (RSStringIsEmpty(urlString))
//		return nil;
//	UIImage *image = [gFaviconCache objectForKey:urlString];
//	if (image)
//		[gFaviconCache setObject:image forKey:googleID];
//	return image;
}


+ (UIImage *)_cachedFaviconForURLString:(NSString *)urlString googleID:(NSString *)googleID {
	UIImage *image = [gFaviconCache objectForKey:urlString];
	if (image && ![gFaviconCache objectForKey:googleID])
		[gFaviconCache setObject:image forKey:googleID];
	return image;
}


+ (void)_cacheFavicon:(UIImage *)favicon forURLString:(NSString *)urlString {
	if (!RSStringIsEmpty(urlString)) {
		[gFaviconCache safeSetObject:favicon forKey:urlString];
		if (favicon) /*It must be good, so also make sure it's not bad-map*/
			[gFaviconMap removeObjectForKey:urlString];
	}
}


+ (void)_cacheFavicon:(UIImage *)favicon forGoogleFeedID:(NSString *)googleID {
	[self _cacheFavicon:favicon forURLString:[self _faviconURLStringForGoogleID:googleID]];
	[self _cacheFavicon:favicon forURLString:googleID];
}


+ (void)_downloadFavicon:(NSString *)urlString {
	BCDownloadImageRequest *downloadRequest = [[[BCDownloadImageRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
	downloadRequest.downloadPriority = BCDownloadImmediately;
	downloadRequest.downloadType = BCDownloadTypeFavicon;
	downloadRequest.storagePolicy = NSURLCacheStorageAllowed;
	//downloadRequest.nameForStatusMessage = [NSString stringWithFormat:@"favicon for %@", [[NSURL URLWithString:urlString] host]];
	[downloadRequest addToDownloadQueue];
}


static NSMutableDictionary *noImageDict = nil;

+ (void)_handleDownloadDidComplete:(NSNotification *)note {
	BCDownloadImageRequest *downloadRequest = [[(BCDownloadImageRequest *)[note object] retain] autorelease];
	if (![downloadRequest isKindOfClass:[BCDownloadImageRequest class]] || downloadRequest.downloadType != BCDownloadTypeFavicon)
		return;
	UIImage *image = downloadRequest.image;
	if (image) {
		if (image.size.height != 16 || image.size.width != 16)
			image = [UIImage scaledImage:image toSize:CGSizeMake(16, 16)];
		RSPostNotificationOnMainThread(NNWFaviconDidDownloadNotification);
	}
	else {
		[noImageDict setBool:YES forKey:[downloadRequest.url absoluteString]];
		[gFaviconMap safeSetObject:[NSDate date] forKey:[downloadRequest.url absoluteString]];
	}
	[self _cacheFavicon:image forURLString:[downloadRequest.url absoluteString]];
}


static NSMutableArray *arrayOfURLStringsAttempted = nil;

+ (UIImage *)imageForFeedWithGoogleID:(NSString *)googleID {
	if (!arrayOfURLStringsAttempted)
		arrayOfURLStringsAttempted = [[NSMutableArray array] retain];
	if (!noImageDict)
		noImageDict = [[NSMutableDictionary dictionary] retain];
	if ([noImageDict boolForKey:googleID])
		return nil;
	UIImage *image = [self _cachedFaviconForGoogleFeedID:googleID];
	if (image)
		return image;
	if (RSStringIsEmpty(googleID) || ![googleID hasPrefix:@"feed/"])
		return nil;
	NSString *faviconURLString = [self _faviconURLStringForGoogleID:googleID];
	if (RSStringIsEmpty(faviconURLString))
		return nil;
	image = [self _cachedFaviconForURLString:faviconURLString googleID:googleID];
	if (image)
		return image;
	if ([noImageDict boolForKey:faviconURLString]) {
		[noImageDict setBool:YES forKey:googleID];
		return nil;
	}
	if ([arrayOfURLStringsAttempted containsObject:faviconURLString])
		return nil;
	[arrayOfURLStringsAttempted safeAddObject:faviconURLString];
	if (![self shouldDownloadFaviconForURLString:faviconURLString])
		return nil;
	[self performSelector:@selector(_downloadFavicon:) withObject:faviconURLString afterDelay:3.0];
	return nil;
}


@end
