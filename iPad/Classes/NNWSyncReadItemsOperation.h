//
//  NNWSyncReadItemsOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 1/2/10.
//  Copyright 2010 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWGoogleAPICallOperation.h"
#import "RSGoogleItemIDsParser.h"


@interface NNWSyncReadItemsOperation : NNWGoogleAPICallOperation <RSGoogleItemIDsParserDelegate> {
@private
	NSMutableArray *heldItemIDs;
}

@end
