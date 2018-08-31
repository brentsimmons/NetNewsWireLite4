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
extern NSString *NNWGoogleFetchItemsByIDURL;
extern NSString *NNWGoogleStarredState;
extern NSString *NNWGoogleStatesParameterName;
extern NSString *NNWGoogleExcludeParameterName;
extern NSString *NNWGoogleItemIDsLimit;
extern NSString *NNWGoogleLimitParameterName;
extern NSString *NNWGoogleItemIDsURLFormat;
extern NSString *NNWGoogleReadState;
extern NSString *NNWGoogleReadingListState;


extern NSString *NNWGoogleShortItemIDForLongItemID(NSString *itemID);
extern NSArray *NNWGoogleShortItemIDsForLongItemIDs(NSArray *longItemIDs);
extern NSSet *NNWGoogleSetOfShortItemIDsForArrayOfLongItemIDs(NSArray *longItemIDs);
extern NSArray *NNWGoogleArrayOfLongItemIDsForSetOfShortItemIDs(NSSet *shortItemIDs);
extern NSString *NNWGoogleLongItemIDForShortItemID(NSString *shortItemID);
extern NSArray *NNWGoogleLongItemIDsForShortItemIDs(NSArray *shortItemIDs);
	

@class NNWHTTPResponse;

@interface NNWGoogleAPI : NSObject {

}

+ (NSMutableDictionary *)postBodyDictionary;

+ (NNWHTTPResponse *)markItemsRead:(NSArray *)itemIDs feedIDs:(NSArray *)feedIDs;
+ (NNWHTTPResponse *)updateNewsItem:(NSString *)googleID feedID:(NSString *)feedID starStatus:(BOOL)starStatus;

+ (NNWHTTPResponse *)subscribeToFeed:(NSString *)urlString title:(NSString *)title folderName:(NSString *)folderName;

+ (void)addAuthTokenToRequest:(NSMutableURLRequest *)urlRequest googleAuthToken:(NSString *)googleAuthToken;
+ (void)addAuthTokenToRequest:(NSMutableURLRequest *)urlRequest;


@end
