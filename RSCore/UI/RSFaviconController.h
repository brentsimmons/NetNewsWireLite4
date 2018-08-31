//
//  RSFaviconController.h
//  RSCoreTests
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Main thread only.
 Uses CGImageRef since it's available on Macs and iOS.*/

extern NSString *RSFaviconDownloadedNotification; //RSURLKey in userInfo


@class RSImageFolderCache;


@interface RSFaviconController : NSObject {
@private
    pthread_mutex_t faviconControllerLock;
    NSMutableSet *checkedURLs;
    RSImageFolderCache *imageFolderCache;
    NSTimer *dumpCheckedURLsCacheTimer;
}


+ (RSFaviconController *)sharedController;

/*If faviconURL is nil, uses homePageURL to calculate standard favicon path: domain/favicon.ico.
 It may return nil. Later there may be an RSFaviconDownloadedNotification for this favicon.*/

- (CGImageRef)faviconForHomePageURL:(NSURL *)homePageURL faviconURL:(NSURL *)faviconURL;

- (NSString *)filenameForFavicon:(NSURL *)homePageURL faviconURL:(NSURL *)faviconURL;

@property (nonatomic, strong, readonly) RSImageFolderCache *imageFolderCache;

@end
