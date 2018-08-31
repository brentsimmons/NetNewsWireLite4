//
//  RSThumbnailCacheController.h
//  libTapLynx
//
//  Created by Brent Simmons on 12/1/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSWebCacheController.h"


/*Resizes the image before storing it in the cache. Uses the RSWebCacheController for reading and writing,
 but gives objects a unique ID by appending the targetSize and roundedCorners to the URL, so there aren't
 conflicts with different target sizes, or the case where the raw data is also wanted.*/

@class RSCache;
@class RSImageScalingSpecifier;

@interface RSThumbnailCacheController : RSWebCacheController {
@private
	RSCache *thumbnailMemoryCache;
}


- (UIImage *)cachedThumbnailForImageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier;
- (UIImage *)memoryCachedThumbnailForImageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier;

- (UIImage *)storeDownloadedDataAndReturnThumbnail:(NSData *)downloadedData imageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier;


/*Deprecated. Use the above methods that take an RSImageScalingSpecifier instead.*/

- (UIImage *)cachedThumbnailAtURL:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners;
- (UIImage *)memoryCachedThumbnailAtURL:(NSURL *)URL targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners;

- (UIImage *)storeDownloadedDataAndReturnThumbnail:(NSData *)downloadedData url:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners;



@end
