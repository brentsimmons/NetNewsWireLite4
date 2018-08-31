//
//  RSFaviconController.m
//  RSCoreTests
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFaviconController.h"
#import "RSDownloadOperation.h"
#import "RSFileUtilities.h"
#import "RSFoundationExtras.h"
#import "RSImageFolderCache.h"
#import "RSImageUtilities.h"
#import "RSOperationController.h"


NSString *RSFaviconDownloadedNotification = @"RSFaviconDownloadedNotification";

static NSString *RSFaviconCacheFolderName = @"FaviconCache.noindex";


@interface RSFaviconController ()

@property (nonatomic, strong) NSMutableSet *checkedURLs;
@property (nonatomic, strong, readwrite) RSImageFolderCache *imageFolderCache;

@end


@implementation RSFaviconController

@synthesize checkedURLs;
@synthesize imageFolderCache;


#pragma mark Class Methods

+ (RSFaviconController *)sharedController {
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
    if (RSLockCreate(&faviconControllerLock) != 0)
        return nil;
    NSDate *dateCacheLastNuked = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateFaviconCacheLastNuked"];
    if (dateCacheLastNuked == nil)
        dateCacheLastNuked = [NSDate distantPast];
    NSDate *dateOneWeekAgo = [NSDate rs_dateWithNumberOfDaysInThePast:7];
    if ([dateOneWeekAgo earlierDate:dateCacheLastNuked] == dateCacheLastNuked) {
        NSString *folder = RSSubFolderInFolder(rs_app_delegate.pathToCacheFolder, RSFaviconCacheFolderName, NO);
//        NSString *folder = RSCacheFolderForAppSubFolder(RSFaviconCacheFolderName, NO);
        if (RSFileExists(folder))
            RSFileDelete(folder);
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateFaviconCacheLastNuked"];
    }
    NSString *folder = RSSubFolderInFolder(rs_app_delegate.pathToCacheFolder, RSFaviconCacheFolderName, YES);
    imageFolderCache = [[RSImageFolderCache alloc] initWithFolder:folder];
    checkedURLs = [NSMutableSet setWithCapacity:1000];
    dumpCheckedURLsCacheTimer = [NSTimer scheduledTimerWithTimeInterval:(60 * 60) target:self selector:@selector(dumpCheckedURLsTimerDidFire:) userInfo:nil repeats:YES];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    RSLockDestroy(&faviconControllerLock);
    [dumpCheckedURLsCacheTimer rs_invalidateIfValid];
}


#pragma mark Paths

- (NSString *)filenameForFavicon:(NSURL *)homePageURL faviconURL:(NSURL *)faviconURL {
    
    /*Return a name even if it doesn't exist.*/
    
    if (faviconURL == nil && homePageURL == nil)
        return nil;
    if (faviconURL == nil)
        faviconURL = [NSURL URLWithString:@"/favicon.ico" relativeToURL:homePageURL];
    return [RSImageFolderCache filenameForURLString:[faviconURL absoluteString]];
}


#pragma mark Downloading

- (void)saveFaviconWithDictionary:(NSDictionary *)faviconDictionary {
    NSData *imageData = [faviconDictionary objectForKey:@"imageData"];
    NSString *filename = [faviconDictionary objectForKey:@"filename"];
    CGImageRef cgImage = RSCGImageFromDataWithMaxPixelSize(imageData, 16);
    if (cgImage == nil)
        return;
    NSError *error = nil;
    if (![self.imageFolderCache saveCGImage:cgImage withFilename:filename error:&error])
        return;
    //NSDictionary *userInfo = [NSDictionary dictionaryWithObject:faviconDownloadOperation.url forKey:RSURLKey];
    [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSFaviconDownloadedNotification object:self userInfo:nil];    
}


- (void)faviconDownloadOperationDidFinish:(RSDownloadOperation *)faviconDownloadOperation {
    if (rs_app_delegate.appIsShuttingDown)
        return;
    if (!faviconDownloadOperation.okResponse || RSIsEmpty(faviconDownloadOperation.responseBody))
        return;
    NSString *filename = [RSImageFolderCache filenameForURLString:[faviconDownloadOperation.url absoluteString]];
    if (RSStringIsEmpty(filename))
        return;
    NSMutableDictionary *faviconDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    [faviconDictionary setObject:faviconDownloadOperation.responseBody forKey:@"imageData"];
    [faviconDictionary setObject:filename forKey:@"filename"];
    NSInvocationOperation *saveFaviconOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveFaviconWithDictionary:) object:faviconDictionary];
    [saveFaviconOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
    [[RSOperationController sharedController] addOperation:saveFaviconOperation];    
}


- (void)downloadFaviconAtURL:(NSURL *)faviconURL {
    RSDownloadOperation *faviconDownloadOperation = [[RSDownloadOperation alloc] initWithURL:faviconURL delegate:self callbackSelector:@selector(faviconDownloadOperationDidFinish:) parser:nil useWebCache:NO];
    faviconDownloadOperation.operationType = RSOperationTypeDownloadFavicon;
    faviconDownloadOperation.operationObject = faviconURL;
    [[RSOperationController sharedController] addOperation:faviconDownloadOperation];
//    RSAddOperationIfNotInQueue(faviconDownloadOperation);
}


#pragma mark Timer

- (void)dumpCheckedURLsTimerDidFire:(NSTimer *)aTimer {
    [self.checkedURLs removeAllObjects];
}


#pragma mark Cache

- (void)fetchfavicon:(NSURL *)imageURL {
    
    /*Threaded, via NSInvocationOperation.*/
    
    if (rs_app_delegate.appIsShuttingDown)
        return;
    NSString *filename = [RSImageFolderCache filenameForURLString:[imageURL absoluteString]];
    CGImageRef cgImage = [self.imageFolderCache cgImageForFilename:filename];
    if (cgImage != nil) {
        [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSFaviconDownloadedNotification object:self userInfo:nil];
        return;
    }
    
    RSLockLock(&faviconControllerLock);
    BOOL checkedURLsContainsURL = [self.checkedURLs containsObject:imageURL];
    if (!checkedURLsContainsURL)
        [self.checkedURLs addObject:imageURL];
    RSLockUnlock(&faviconControllerLock);
    
    if (!checkedURLsContainsURL)
        [self downloadFaviconAtURL:imageURL];
}


- (CGImageRef)faviconForURL:(NSURL *)faviconURL {
    if (rs_app_delegate.appIsShuttingDown)
        return nil;
    NSString *filename = [RSImageFolderCache filenameForURLString:[faviconURL absoluteString]];
    if (RSStringIsEmpty(filename))
        return nil;
    CGImageRef cgImage = [self.imageFolderCache cachedCGImageForFilename:filename];
    if (cgImage != nil)
        return cgImage;
    NSInvocationOperation *fetchFaviconOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(fetchfavicon:) object:faviconURL];
    [[RSOperationController sharedController] addOperation:fetchFaviconOperation];                                                                  
    return nil;
//    if (![self.checkedURLs containsObject:faviconURL]) {
//        [self.checkedURLs addObject:faviconURL];
//        [self downloadFaviconAtURL:faviconURL];
//    }
//    return nil;
}


- (CGImageRef)faviconForHomePageURL:(NSURL *)homePageURL {
    if (homePageURL == nil)
        return nil;
    NSURL *faviconURL = [NSURL URLWithString:@"/favicon.ico" relativeToURL:homePageURL];
    return [self faviconForURL:faviconURL];
}


#pragma mark Public API

- (CGImageRef)faviconForHomePageURL:(NSURL *)homePageURL faviconURL:(NSURL *)faviconURL {
    if (faviconURL != nil)
        return [self faviconForURL:faviconURL];
    return [self faviconForHomePageURL:homePageURL];
}


@end
