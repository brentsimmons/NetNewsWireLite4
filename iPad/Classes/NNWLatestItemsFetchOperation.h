//
//  NNWLatestItemsFetchOperation.h
//  nnwipad
//
//  Created by Brent Simmons on 3/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWNewsItemsFetchOperation.h"


@interface NNWLatestItemsFetchOperation : NNWNewsItemsFetchOperation {

}


- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@end
