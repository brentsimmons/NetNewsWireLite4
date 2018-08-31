//
//  RSThumbnailController.h
//  nnw
//
//  Created by Brent Simmons on 12/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*GC optional, modern runtime, Mac + iOS. Main thread only.
 Uses CGImageRef since it's available on Macs and iOS.
 
 Thumbnails will be images with a maximum size of 300 pixels in one direction.
 (But check the code in case that changed.)*/

extern NSString *RSThumbnailDownloadedNotification;

@class RSImageFolderCache;


@interface RSThumbnailController : NSObject {
@private
	pthread_mutex_t thumbnailControllerLock;
	NSMutableSet *checkedURLs;
	RSImageFolderCache *imageFolderCache;	
}

+ (RSThumbnailController *)sharedController;

- (CGImageRef)thumbnailForURL:(NSURL *)aURL;

@end

