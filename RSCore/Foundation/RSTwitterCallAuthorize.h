//
//  RSTwitterCallAuthorize.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperationTwitterCall.h"


@interface RSTwitterCallAuthorize : RSOperationTwitterCall {
}


- (id)initWithOAuthInfo:(RSOAuthInfo *)oaInfo username:(NSString *)aUsername password:(NSString *)aPassword delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;


@end
