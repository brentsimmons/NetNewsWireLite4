/*
 RSDiskFileDownloadController.h
 NetNewsWire
 
 Created by Brent Simmons on 12/14/04.
 Copyright 2004 Ranchero Software. All rights reserved.
 */


#import <Cocoa/Cocoa.h>


extern NSString *RSDiskFileDownloadControllerDidReceiveDownloadRequestNotification;


@class RSDiskFileDownloadRequest;
@class RSDataSource;
@class RSDataItem;


@interface RSDiskFileDownloadController : NSObject {
	
@private
	NSMutableArray *downloadRequests;
}


@property (nonatomic, retain) NSMutableArray *downloadRequests;

+ (id)sharedController;

- (void)downloadEnclosure:(NSString *)url dataSource:(RSDataSource *)dataSource dataItem:(RSDataItem *)dataItem
		   callbackTarget:(id)target callbackSelector:(SEL)callback;
- (void)downloadEnclosure:(NSString *)url dataSource:(RSDataSource *)dataSource dataItem:(RSDataItem *)dataItem
			 sendToITunes:(BOOL)sendToITunes callbackTarget:(id)target callbackSelector:(SEL)callback;
- (void)downloadURL:(NSString *)url referer:(NSString *)referer;
- (void)downloadURL:(NSString*)url;

- (void)removeRequest:(RSDiskFileDownloadRequest *)request;

- (void)clearClearableDownloads;

- (NSInteger)numberOfRequests;
- (NSInteger)numberOfDeletableRequests;
- (RSDiskFileDownloadRequest *)requestAtIndex:(NSInteger)ix;

- (NSInteger)numberOfCurrentDownloads;
- (NSInteger)numberOfPendingDownloads;
- (BOOL)hasCurrentOrPendingDownloads;

- (BOOL)urlStringIsBeingDownloadedOrIsPending:(NSString *)urlString;


@end
