//
//  NNWGoogleAPICallOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSDownloadOperation.h"


@interface NNWGoogleAPICallOperation : RSDownloadOperation {
@private
	NSMutableDictionary *postBodyDict;
	BOOL didRetryWithNewGoogleToken;
}


- (id)initWithBaseURL:(NSURL *)baseURL queryDict:(NSDictionary *)aQueryDict postBodyDict:(NSDictionary *)aPostBodyDict delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector parser:(RSSAXParser *)aParser;

@end


@interface NNWGoogleAPICallOperation (NNWConvenienceMethods)

+ (NNWGoogleAPICallOperation *)downloadItemIDsAPICallWithStatesToRetrieve:(NSArray *)statesToRetrieve statesToIgnore:(NSArray *)statesToIgnore itemIDsToIgnore:(NSArray *)itemIDsToIgnore delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

+ (NNWGoogleAPICallOperation *)downloadSubscriptionsAPICallWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

+ (NNWGoogleAPICallOperation *)downloadUnreadCounts:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@end

