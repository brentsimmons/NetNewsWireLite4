//
//  NNWOperationConstants.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum _NNWOperationType {
	NNWOperationTypeUnknown = 1000,
	NNWOperationTypeFetchNewsItems,
	NNWOperationTypeFaviconDownload,
	NNWOperationTypeCountUnread,
	NNWOperationTypeCountUnreadForAllFeeds,
	NNWOperationTypeUpdateMostRecentItem,
	NNWOperationTypeUpdateInvalidatedMostRecentItems,
	NNWOperationTypeDownloadStarredItemIDs, /*Sync operation IDs from here to end*/
	NNWOperationTypeProcessStarredItemIDs,
	NNWOperationTypeGoogleLogin,
	NNWOperationTypeDownloadSubscriptions,
	NNWOperationTypeProcessSubscriptions,
	NNWOperationTypeDownloadUnreadCounts,
	NNWOperationTypeDownloadItems,
	NNWOperationTypeDownloadReadItemIDs,
	NNWOperationTypeDownloadUnreadItemIDs,
	NNWOperationTypeProcessUnreadItemIDs,
	NNWOperationTypeProcessReadItemIDs
} NNWOperationType;
