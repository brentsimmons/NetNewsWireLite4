//
//  NNWFavicon.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFavicon.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWOperationConstants.h"
#import "RSDownloadOperation.h"
#import "RSOperationController.h"


NSString *NNWFaviconDidDownloadNotification = @"NNWFaviconDidDownloadNotification";

static NSMutableDictionary *gFaviconCache = nil;
static NSMutableDictionary *gFaviconMap = nil;

@implementation NNWFavicon

static NSString *NNWFaviconMapFileName = @"faviconmap.archive";

+ (void)initialize {
	if (!gFaviconCache)
		gFaviconCache = [[NSMutableDictionary dictionary] retain];
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
	return [gFaviconCache objectForKey:googleID];
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
	RSDownloadOperation *downloadOperation = [[[RSDownloadOperation alloc] initWithURL:[NSURL URLWithString:urlString] delegate:self callbackSelector:@selector(imageDidDownload:) parser:nil useWebCache:YES] autorelease];
	downloadOperation.operationType = NNWOperationTypeFaviconDownload;
	downloadOperation.operationObject = urlString;
	[downloadOperation setQueuePriority:NSOperationQueuePriorityHigh];
	RSAddOperationIfNotInQueue(downloadOperation);
}


static NSMutableDictionary *noImageDict = nil;


+ (void)imageDidDownload:(RSDownloadOperation *)downloader {
	NSData *imageData = downloader.responseBody;
	UIImage *image = [UIImage imageWithData:imageData];
	NSURL *url = downloader.url;
	NSString *urlString = [url absoluteString];
	if (image)
		RSEnqueueNotificationNameOnMainThread(NNWFaviconDidDownloadNotification);
//		RSPostNotificationOnMainThread(NNWFaviconDidDownloadNotification);
	else if (urlString) {
		[noImageDict setBool:YES forKey:urlString];
		[gFaviconMap safeSetObject:[NSDate date] forKey:urlString];
	}
	[self _cacheFavicon:image forURLString:urlString];
}


static NSMutableSet *urlStringsAttempted = nil;

+ (UIImage *)imageForFeedWithGoogleID:(NSString *)googleID {
	if (!urlStringsAttempted)
		urlStringsAttempted = [[NSMutableSet set] retain];
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
	if ([urlStringsAttempted containsObject:faviconURLString])
		return nil;
	[urlStringsAttempted rs_addObject:faviconURLString];
	if (![self shouldDownloadFaviconForURLString:faviconURLString])
		return nil;
	[self performSelectorOnMainThread:@selector(_downloadFavicon:) withObject:faviconURLString waitUntilDone:NO];
	return nil;
}


+ (UIImage *)defaultFavicon {
	static NSString *defaultFaviconName = @"DefaultFavicon.png";
	return [UIImage imageNamed:defaultFaviconName];
}


@end
