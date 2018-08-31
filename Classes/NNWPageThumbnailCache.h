//
//  NNWPageThumbnailCache.h
//  NetNewsWire
//
//  Created by Brent Simmons on 10/10/06.
//  Copyright 2006 Ranchero Software. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "NNWTabThumbnailCache.h"
#import "RSMacWebView.h"


#define kNNWPageThumbWidth 968
#define kNNWPageThumbHeight 600


@interface NNWPageThumbnailCache : NSObject

+ (NNWPageThumbnailCache *)sharedCache;

- (CGImageRef)thumbnailForURL:(NSURL *)aURL;


@end
