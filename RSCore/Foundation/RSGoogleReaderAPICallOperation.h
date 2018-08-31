//
//  RSGoogleReaderAPICallOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSDownloadOperation.h"


@interface RSGoogleReaderAPICallOperation : RSDownloadOperation {
@private
	NSMutableDictionary *postBodyDict;
	BOOL didRetryWithNewGoogleToken;
}


- (id)initWithBaseURL:(NSURL *)baseURL queryDict:(NSDictionary *)aQueryDict postBodyDict:(NSDictionary *)aPostBodyDict delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector parser:(RSSAXParser *)aParser;

@end


@interface RSGoogleReaderAPICallOperation (RSConvenienceMethods)

+ (RSGoogleReaderAPICallOperation *)downloadItemIDsAPICallWithStatesToRetrieve:(NSArray *)statesToRetrieve statesToIgnore:(NSArray *)statesToIgnore itemIDsToIgnore:(NSArray *)itemIDsToIgnore delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

+ (RSGoogleReaderAPICallOperation *)downloadSubscriptionsAPICallWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@end

