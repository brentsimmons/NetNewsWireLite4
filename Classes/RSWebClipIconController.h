//
//  RSWebIconClipController.h
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*Main thread only.
 Uses CGImageRef since it's available on Macs and iOS.*/

/*TODO: refactor. It's basically a copy-and-paste of RSFaviconController.
 There should be a common superclass.*/

extern NSString *RSWebClipIconDownloadedNotification;
extern NSString *RSWebClipIconURLKey; //in userInfo

@class RSImageFolderCache;

@interface RSWebClipIconController : NSObject {
@private
	pthread_mutex_t webclipControllerLock;
	RSImageFolderCache *imageFolderCache;
	NSMutableSet *checkedURLs;
}

+ (RSWebClipIconController *)sharedController;

/*If webclipIconURL is nil, uses homePageURL to calculate standard favicon path: domain/apple-touch-icon.png.
 It may return nil. Later there may be an RSWebClipIconDownloadedNotification for this favicon.*/

- (CGImageRef)webclipIconForHomePageURL:(NSURL *)homePageURL webclipIconURL:(NSURL *)webclipIconURL;

@property (nonatomic, retain, readonly) RSImageFolderCache *imageFolderCache;

@end
