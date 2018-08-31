//
//  NNWGoogleAPI.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *NNWGoogleItemIDsParameterName;
extern NSString *NNWGoogleFeedIDsParameterName;


@class NNWHTTPResponse;

@interface NNWGoogleAPI : NSObject {

}

+ (NNWHTTPResponse *)downloadSubscriptionsList;
+ (NNWHTTPResponse *)downloadUnreadCounts;

+ (NNWHTTPResponse *)markItemsRead:(NSArray *)itemIDs feedIDs:(NSArray *)feedIDs;
+ (NNWHTTPResponse *)updateNewsItem:(NSString *)googleID feedID:(NSString *)feedID starStatus:(BOOL)starStatus;

+ (NSArray *)downloadAndParseItemIDsOfReadItems;

+ (NNWHTTPResponse *)subscribeToFeed:(NSString *)urlString title:(NSString *)title folderName:(NSString *)folderName;

+ (void)addAuthTokenToRequest:(NSMutableURLRequest *)urlRequest googleAuthToken:(NSString *)googleAuthToken;

@end
