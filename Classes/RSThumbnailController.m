//
//  RSThumbnailController.m
//  nnw
//
//  Created by Brent Simmons on 12/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSThumbnailController.h"
#import "RSDownloadOperation.h"
#import "RSFileUtilities.h"
#import "RSFoundationExtras.h"
#import "RSImageFolderCache.h"
#import "RSImageUtilities.h"
#import "RSOperationController.h"


NSString *RSThumbnailDownloadedNotification = @"RSThumbnailDownloadedNotification";

static NSString *RSThumbnailCacheFolderName = @"ThumbnailCache.noindex";
static const NSInteger kThumbnailMaximumPixels = 232;


@interface RSThumbnailController ()

@property (nonatomic, strong) NSMutableSet *checkedURLs; //so we don't keep re-trying unsuccessful URLs
@property (nonatomic, strong, readwrite) RSImageFolderCache *imageFolderCache;
@end


@implementation RSThumbnailController

@synthesize checkedURLs;
@synthesize imageFolderCache;

#pragma mark Class Methods

+ (RSThumbnailController *)sharedController {
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
    if (RSLockCreate(&thumbnailControllerLock) != 0)
        return nil;
    NSDate *dateCacheLastNuked = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateThumbnailCacheLastNuked"];
    if (dateCacheLastNuked == nil)
        dateCacheLastNuked = [NSDate distantPast];
    NSDate *dateOneWeekAgo = [NSDate rs_dateWithNumberOfDaysInThePast:3];
    if ([dateOneWeekAgo earlierDate:dateCacheLastNuked] == dateCacheLastNuked) {
        NSString *folder = RSSubFolderInFolder(rs_app_delegate.pathToCacheFolder, RSThumbnailCacheFolderName, NO);
        //NSString *folder = RSCacheFolderForAppSubFolder(RSThumbnailCacheFolderName, NO);
        if (RSFileExists(folder))
            RSFileDelete(folder);
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateThumbnailCacheLastNuked"];
    }
    NSString *folder = RSSubFolderInFolder(rs_app_delegate.pathToCacheFolder, RSThumbnailCacheFolderName, YES);
//    NSString *folder = RSCacheFolderForAppSubFolder(RSThumbnailCacheFolderName, YES);
    imageFolderCache = [[RSImageFolderCache alloc] initWithFolder:folder];
    imageFolderCache.inMemoryCacheCountLimit = 500;
    checkedURLs = [NSMutableSet setWithCapacity:1000];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    RSLockDestroy(&thumbnailControllerLock);
}


#pragma mark Downloading

- (void)postThumbnailDidDownloadNotificationWithURL:(NSURL *)imageURL {
    if (rs_app_delegate.appIsShuttingDown)
        return;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:imageURL forKey:RSURLKey];
    [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSThumbnailDownloadedNotification object:self userInfo:userInfo];
}


- (void)saveThumbnailWithDictionary:(NSDictionary *)thumbnailDictionary {
    if (rs_app_delegate.appIsShuttingDown)
        return;
    NSData *imageData = [thumbnailDictionary objectForKey:@"imageData"];
    NSString *filename = [thumbnailDictionary objectForKey:@"filename"];
    NSURL *URL = [thumbnailDictionary objectForKey:RSURLKey];
    CGImageRef cgImage = RSCGImageFromDataWithMaxPixelSize(imageData, kThumbnailMaximumPixels);
    if (cgImage == nil)
        return;
    NSError *error = nil;
    if (![self.imageFolderCache saveCGImage:cgImage withFilename:filename error:&error])
        return;
    [self postThumbnailDidDownloadNotificationWithURL:URL];
}


- (void)downloadOperationDidFinish:(RSDownloadOperation *)downloadOperation {
    if (!downloadOperation.okResponse || RSIsEmpty(downloadOperation.responseBody) || rs_app_delegate.appIsShuttingDown)
        return;
    NSString *filename = [RSImageFolderCache filenameForURLString:[downloadOperation.url absoluteString]];
    if (RSStringIsEmpty(filename))
        return;
    NSMutableDictionary *thumbnailDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    [thumbnailDictionary setObject:downloadOperation.responseBody forKey:@"imageData"];
    [thumbnailDictionary setObject:filename forKey:@"filename"];
    [thumbnailDictionary setObject:downloadOperation.url forKey:RSURLKey];
    NSInvocationOperation *saveThumbnailOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveThumbnailWithDictionary:) object:thumbnailDictionary];
    [saveThumbnailOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
    [[RSOperationController sharedController] addOperation:saveThumbnailOperation];    
    //    CGImageRef cgImage = RSCGImageFromDataWithMaxPixelSize(downloadOperation.responseBody, kThumbnailMaximumPixels);
//    if (cgImage == nil)
//        return;
//    NSError *error = nil;
//    if (![self.imageFolderCache saveCGImage:cgImage withFilename:filename error:&error])
//        return;
//    [self postThumbnailDidDownloadNotificationWithURL:downloadOperation.url];
}


- (void)downloadImageAtURL:(NSURL *)imageURL {
    RSDownloadOperation *downloadOperation = [[RSDownloadOperation alloc] initWithURL:imageURL delegate:self callbackSelector:@selector(downloadOperationDidFinish:) parser:nil useWebCache:YES];
    downloadOperation.operationType = RSOperationTypeDownloadThumbnail;
    downloadOperation.operationObject = imageURL;
    [[RSOperationController sharedController] addOperation:downloadOperation];
//    RSAddOperationIfNotInQueue(downloadOperation);
}


- (void)fetchThumbnail:(NSURL *)imageURL {
    
    /*Threaded, via NSInvocationOperation.*/
    
    if (rs_app_delegate.appIsShuttingDown)
        return;
    NSString *filename = [RSImageFolderCache filenameForURLString:[imageURL absoluteString]];
    CGImageRef cgImage = [self.imageFolderCache cgImageForFilename:filename];
    if (cgImage != nil) {
        [self postThumbnailDidDownloadNotificationWithURL:imageURL];
        return;
    }

    RSLockLock(&thumbnailControllerLock);
    BOOL checkedURLsContainsURL = [self.checkedURLs containsObject:imageURL];
    if (!checkedURLsContainsURL)
        [self.checkedURLs addObject:imageURL];
    RSLockUnlock(&thumbnailControllerLock);
    
    if (!checkedURLsContainsURL)
        [self downloadImageAtURL:imageURL];
}


#pragma mark Public API

- (CGImageRef)thumbnailForURL:(NSURL *)aURL {
    NSString *filename = [RSImageFolderCache filenameForURLString:[aURL absoluteString]];
    if (RSStringIsEmpty(filename))
        return nil;
    CGImageRef cgImage = [self.imageFolderCache cachedCGImageForFilename:filename];
    if (cgImage != nil)
        return cgImage;
    NSInvocationOperation *fetchThumbnailOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(fetchThumbnail:) object:aURL];
    [fetchThumbnailOperation setQueuePriority:NSOperationQueuePriorityHigh];
    [[RSOperationController sharedController] addOperation:fetchThumbnailOperation];                                                                  
    return nil;
}


@end
