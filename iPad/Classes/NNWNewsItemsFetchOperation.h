//
//  NNWNewsItemsFetchOperation.h
//  nnwipad
//
//  Created by Brent Simmons on 2/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"


@class FMResultSet;

@interface NNWNewsItemsFetchOperation : RSOperation {
@private
	NSMutableArray *newsItems;
	NSArray *sourceIDs;
}


@property (retain, readonly) NSMutableArray *newsItems;

- (id)initWithSourceIDs:(NSArray *)someSourceIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

/*For subclasses*/

- (FMResultSet *)fetchResultSet;

@end
