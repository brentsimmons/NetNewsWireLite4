//
//  RSOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/15/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *RSOperationDidCompleteNotification;

typedef enum _RSOperationType {
	RSOperationTypeUnknown,
	RSOperationTypeDownloadFeed,
	RSOperationTypeDownloadTemporaryFeed,
	RSOperationTypeFetchImagesFromCache,
	RSOperationTypeDownloadImage,
	RSOperationTypeDownloadAd,
	RSOperationTypeDownloadAdImage,
	RSOperationTypeDownloadSearchResults,
	RSOperationTypeCreateShortenedURL,
	RSOperationTypePostToTwitter,
	RSOperationTypeDownloadThumbnail,
	RSOperationTypeFetchThumbnail, //get from cache or download
	RSOperationTypeDownloadWebConfigFile,
	RSOperationTypeDownloadAppArtwork,
	RSOperationTypeDeleteDisappearedNewsItems,
	RSOperationTypeSavingFeeds,
	RSOperationTypeDownloadFavicon,
	RSOperationTypeDownloadWebClipIcon,
	RSOperationTypeUpdateUnreadCount
} RSOperationType;

/*App-defined operation types should start at 1000*/


@interface RSOperation : NSOperation {
@protected
	id delegate;
	SEL callbackSelector;
	NSInteger operationType;
	id operationObject;
}

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) SEL callbackSelector;
@property (nonatomic, assign) NSInteger operationType;
@property (nonatomic, retain) id operationObject;

/*For subclasses*/

- (void)callDelegate;
- (void)postOperationDidCompleteNotification;
- (void)notifyObserversThatOperationIsComplete; //Calls the above two: call at end of main method (shouldn't call [super main])


@end



