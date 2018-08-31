//
//  RSDownloadThumbnailOperation.h
//  libTapLynx
//
//  Created by Brent Simmons on 12/1/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSDownloadOperation.h"


extern NSString *RSDownloadThumbnailOperationDidCompleteNotification;

@class RSImageScalingSpecifier;

@interface RSDownloadThumbnailOperation : RSDownloadOperation {
@private
	RSImageScalingSpecifier *imageScalingSpecifier;
	UIImage *thumbnailImage;
}


- (id)initWithImageScalingSpecifier:(RSImageScalingSpecifier *)anImageScalingSpecifier delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@property (nonatomic, retain, readonly) RSImageScalingSpecifier *imageScalingSpecifier;
@property (nonatomic, retain) UIImage *thumbnailImage;


/*Deprecated. Use method with imageScalingSpecifier instead.*/

- (id)initWithURL:(NSURL *)aURL delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector targetImageSize:(CGSize)aSize roundedCorners:(BOOL)roundedCornersFlag;

/*Deprecated. Inspect imageScalingSpecifier instead.*/

@property (nonatomic, assign, readonly) CGSize targetImageSize;
@property (nonatomic, assign, readonly) BOOL roundedCorners;


@end


/*Only fetches from cache -- doesn't download*/

@interface RSFetchThumbnailFromCacheOperation : RSDownloadThumbnailOperation
@end
