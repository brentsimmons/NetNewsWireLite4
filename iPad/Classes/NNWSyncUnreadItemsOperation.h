//
//  NNWSyncUnreadItemsOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 1/2/10.
//  Copyright 2010 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWGoogleAPICallOperation.h"
#import "RSGoogleItemIDsParser.h"


@class NNWSyncUnreadItemsOperation;

@protocol NNWSyncUnreadItemsOperationDelegate
@required
- (void)syncUnreadItemsOperation:(NNWSyncUnreadItemsOperation *)operation didParseUnreadItemIDs:(NSSet *)itemIDs;
@end


@interface NNWSyncUnreadItemsOperation : NNWGoogleAPICallOperation <RSGoogleItemIDsParserDelegate> {
@private
	NSMutableSet *heldItemIDs;
	id<NNWSyncUnreadItemsOperationDelegate> didParseItemsDelegate;
}


@property (nonatomic, assign) id<NNWSyncUnreadItemsOperationDelegate> didParseItemsDelegate;


@end



