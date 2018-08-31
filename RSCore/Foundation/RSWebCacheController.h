//
//  RSWebCacheController.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/15/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSPlatform.h"


@interface RSWebCacheController : NSObject {
@protected
	NSString *baseCacheFolder;
	NSString *cacheFolderName;
	BOOL didEnsureFolderExists;	
}


+ (id)sharedController;
- (NSData *)cachedObjectAtURL:(NSURL *)url;
- (void)storeObject:(NSData *)data url:(NSURL *)url;

- (RS_PLATFORM_IMAGE *)cachedImageAtURL:(NSURL *)url; //convenience. Calls cachedObjectAtURL and returns image.

@end


/*Stores things like app artwork*/

@interface RSPermanentWebCacheController : RSWebCacheController
@end
