//
//  RSTwitterCallSendStatus.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperationTwitterCall.h"


@class RSOAuthInfo;

@interface RSTwitterCallSendStatus : RSOperationTwitterCall {
@private
	NSString *status;
}


- (id)initWithStatus:(NSString *)aStatus oauthInfo:(RSOAuthInfo *)oaInfo delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;


@end
