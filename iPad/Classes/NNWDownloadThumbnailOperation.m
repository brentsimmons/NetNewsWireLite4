//
//  NNWDownloadThumbnailOperation.m
//  nnwipad
//
//  Created by Brent Simmons on 3/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWDownloadThumbnailOperation.h"
#import "NNWThumbnailCacheController.h"


@implementation NNWDownloadThumbnailOperation

#pragma mark Cache

- (BOOL)fetchCachedObject {
	self.thumbnailImage = [[NNWThumbnailCacheController sharedController] cachedThumbnailAtURL:self.url targetSize:self.targetImageSize roundedCorners:self.roundedCorners];
	return self.thumbnailImage != nil;
}


#pragma mark NSURLConnection Delegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (self.statusCode == 200) {
		[[RSWebCacheController sharedController] storeObject:self.responseBody url:self.url];
		self.thumbnailImage = [[NNWThumbnailCacheController sharedController] storeDownloadedDataAndReturnThumbnail:self.responseBody url:self.url targetSize:self.targetImageSize roundedCorners:self.roundedCorners];
	}
	self.finishedReading = YES;
}


@end
