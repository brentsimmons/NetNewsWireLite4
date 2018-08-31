/*
 RSDiskFileDownloadController.m
 NetNewsWire
 
 Created by Brent Simmons on 12/14/04.
 Copyright 2004 Ranchero Software. All rights reserved.
 */


#import "RSDiskFileDownloadController.h"
#import "RSDiskFileDownloadRequest.h"


const NSInteger RSDiskFileDownloadControllerMaxConcurrentDownloads = 2;


NSString *RSDiskFileDownloadControllerDidReceiveDownloadRequestNotification = @"RSDiskFileDownloadControllerDidReceiveDownloadRequestNotification";


@interface RSDiskFileDownloadController (Forward)
- (void)downloadMorePendingRequests;
- (void)addRequestToQueue:(RSDiskFileDownloadRequest *)request;
- (void)registerForNotifications;
@end


@implementation RSDiskFileDownloadController

@synthesize downloadRequests;

#pragma mark Class methods

+ (id)sharedController {	
	static id myInstance = nil;
	if (myInstance == nil)
		myInstance = [[self alloc] init];
	return myInstance;
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self) {
		[self setDownloadRequests:[NSMutableArray arrayWithCapacity:10]];
		[self registerForNotifications];
	}
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[downloadRequests release];
	[super dealloc];
}


#pragma mark Accessors

- (NSInteger)numberOfRequests {
	return [[self downloadRequests] count];
}


- (NSInteger)numberOfDeletableRequests {
	
	NSMutableArray *requests = [self downloadRequests];
	NSInteger i;
	NSInteger ct = [requests count];
	NSInteger ctCanBeDeleted = 0;
	
	for (i = 0; i < ct; i++) {
		RSDiskFileDownloadRequest *oneRequest = [requests rs_safeObjectAtIndex:i];
		RSDownloadStatus status = [oneRequest status];
		if ((status == RSDownloadComplete) || (status == RSDownloadCanceled))
			ctCanBeDeleted++;
	}
	
	return ctCanBeDeleted;
}


- (RSDiskFileDownloadRequest *)requestAtIndex:(NSInteger)ix {
	return [[self downloadRequests] rs_safeObjectAtIndex:ix];
}


- (void)removeRequestAtIndex:(NSInteger)ix {
	
	RSDiskFileDownloadRequest *request = [self requestAtIndex:ix];
	
	if (!request)
		return;
	[[request retain] autorelease];
	[[self downloadRequests] removeObjectAtIndex:ix];
	[[NSNotificationCenter defaultCenter] postNotificationName:RSDiskFileDownloadDidGetRemovedNotification object:request];
}


- (void)removeRequest:(RSDiskFileDownloadRequest *)request {
	NSInteger ix = [[self downloadRequests] indexOfObjectIdenticalTo:request];
	if (ix != NSNotFound)
		[self removeRequestAtIndex:ix];
}


#pragma mark Clearing

- (void)clearClearableDownloads {
	
	NSMutableArray *requests = [self downloadRequests];
	NSInteger i;
	NSInteger ct = [requests count];
	//int ctCanBeDeleted = 0;
	
	for (i = ct - 1; i >= 0; i--) {
		RSDiskFileDownloadRequest *oneRequest = [requests rs_safeObjectAtIndex:i];
		RSDownloadStatus status = [oneRequest status];
		if ((status == RSDownloadComplete) || (status == RSDownloadCanceled))
			[self removeRequestAtIndex:i];
	}
}


#pragma mark Download file

- (void)downloadEnclosure:(NSString *)url dataSource:(RSDataSource *)dataSource dataItem:(RSDataItem *)dataItem
		   callbackTarget:(id)target callbackSelector:(SEL)callback {
	
	/*Download an enclosure and have prefs say what to do with it.*/
	
	RSDiskFileDownloadRequest *request = [[(RSDiskFileDownloadRequest*)[RSDiskFileDownloadRequest alloc]
										initWithURL:url] autorelease];
	
	[request setDataSource:dataSource];
	[request setDataItem:dataItem];
	[request setTarget:target];
	[request setCallback:callback];
	[request setIsEnclosure:YES];
	
	[self addRequestToQueue:request];
	[self downloadMorePendingRequests];
	[[NSNotificationCenter defaultCenter] postNotificationName:RSDiskFileDownloadControllerDidReceiveDownloadRequestNotification object:self];
}


- (void)downloadEnclosure:(NSString *)url dataSource:(RSDataSource *)dataSource dataItem:(RSDataItem *)dataItem
			 sendToITunes:(BOOL)sendToITunes callbackTarget:(id)target callbackSelector:(SEL)callback {
	
	/*Download an enclosure and do what sendToITunes boolean says.*/
	
	RSDiskFileDownloadRequest *request = [[(RSDiskFileDownloadRequest*)[RSDiskFileDownloadRequest alloc]
										initWithURL:url] autorelease];
	
	[request setDataSource:dataSource];
	[request setDataItem:dataItem];
	[request setTarget:target];
	[request setCallback:callback];
	[request setSendToITunes:sendToITunes];
	[request setIgnoreITunesPrefAndUseBoolean:YES];
	[request setIsEnclosure:YES];
	
	[self addRequestToQueue:request];
	[self downloadMorePendingRequests];
	[[NSNotificationCenter defaultCenter] postNotificationName:RSDiskFileDownloadControllerDidReceiveDownloadRequestNotification object:self];
}


- (void)downloadURL:(NSString*)url toFolder:(NSString*)folder sendToITunes:(BOOL)sendToITunes callbackTarget:(id)target callbackSelector:(SEL)callback referer:(NSString *)referer {
	
	RSDiskFileDownloadRequest *request = [[(RSDiskFileDownloadRequest*)[RSDiskFileDownloadRequest alloc]
										initWithURL:url] autorelease];
	
	[request setDestinationFolder:folder];
	[request setTarget:target];
	[request setCallback:callback];
	[request setSendToITunes:sendToITunes];
	[request setReferer:referer];
	
	[self addRequestToQueue:request];
	[self downloadMorePendingRequests];
	[[NSNotificationCenter defaultCenter] postNotificationName:RSDiskFileDownloadControllerDidReceiveDownloadRequestNotification object:self];
}


- (void)downloadURL:(NSString *)url referer:(NSString *)referer {
	[self downloadURL:url toFolder:nil sendToITunes:NO callbackTarget:nil callbackSelector:nil referer:referer];
}


- (void)downloadURL:(NSString *)url {
	[self downloadURL:url toFolder:nil sendToITunes:NO callbackTarget:nil callbackSelector:nil referer:nil];
}


#pragma mark Requests array

- (void)addRequestToQueue:(RSDiskFileDownloadRequest *)request {
	[[self downloadRequests] rs_safeAddObject:request];	
}


#pragma mark Downloading

- (NSInteger)numberOfCurrentDownloads {
	
	NSMutableArray *requests = [self downloadRequests];
	NSInteger i;
	NSInteger ct = [requests count];
	NSInteger currentDownloads = 0;
	
	for (i = 0; i < ct; i++) {
		RSDiskFileDownloadRequest *oneRequest = [requests rs_safeObjectAtIndex:i];
		if ([oneRequest status] == RSDownloadInProgress)
			currentDownloads++;
	}
	
	return (currentDownloads);
}


- (NSInteger)numberOfPendingDownloads {
	
	NSMutableArray *requests = [self downloadRequests];
	NSInteger i;
	NSInteger ct = [requests count];
	NSInteger ctPending = 0;
	
	for (i = 0; i < ct; i++) {
		RSDiskFileDownloadRequest *oneRequest = [requests rs_safeObjectAtIndex:i];
		if ([oneRequest status] == RSDownloadPending)
			ctPending++;
	}
	
	return (ctPending);
}


- (BOOL)hasCurrentOrPendingDownloads {
	
	NSMutableArray *requests = [self downloadRequests];
	NSInteger i;
	NSInteger ct = [requests count];
	
	for (i = 0; i < ct; i++) {
		RSDiskFileDownloadRequest *oneRequest = [requests rs_safeObjectAtIndex:i];
		NSInteger status = [oneRequest status];
		if ((status == RSDownloadInProgress) || (status == RSDownloadPending))
			return YES;
	}
	
	return NO;
}


- (void)downloadRequest:(RSDiskFileDownloadRequest *)request {
	[request setStatus:RSDownloadInProgress];
}


- (void)downloadMorePendingRequests {
	
	NSInteger currentDownloads = [self numberOfCurrentDownloads];
	NSMutableArray *requests = [self downloadRequests];
	NSInteger i;
	NSInteger ct = [requests count];
	
	for (i = 0; i < ct; i++) {
		if (currentDownloads >= RSDiskFileDownloadControllerMaxConcurrentDownloads)
			break;
		RSDiskFileDownloadRequest *oneRequest = [requests rs_safeObjectAtIndex:i];
		if ([oneRequest status] == RSDownloadPending) {
			currentDownloads++;
			[oneRequest download];
		}
	}
}


- (BOOL)urlStringIsBeingDownloadedOrIsPending:(NSString *)urlString {
	if (RSIsEmpty(urlString))
		return NO;
	NSMutableArray *requests = [self downloadRequests];
	if (RSIsEmpty(requests))
		return NO;
	NSInteger i;
	NSInteger ct = [requests count];	
	for (i = 0; i < ct; i++) {
		if ([urlString isEqualToString:(NSString *)[[requests rs_safeObjectAtIndex:i] url]])
			return YES;
	}	
	return NO;
}


#pragma mark Notifications

- (void)handleRequestStatusDidChange:(NSNotification*)note {
	[self downloadMorePendingRequests];
}


- (void)registerForNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRequestStatusDidChange:) name:RSDiskFileDownloadStatusDidChangeNotification object:nil];
}



@end
