//
//  RSFeedUndoSpecifier.h
//  nnw
//
//  Created by Brent Simmons on 1/23/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RSFeed;

@interface RSFeedUndoSpecifier : NSObject {
@private
	NSArray *articleIDsMarkedForDeletion;
	NSString *folderName;
	RSFeed *feed;
}


@property (nonatomic, retain) NSArray *articleIDsMarkedForDeletion;
@property (nonatomic, retain) NSString *folderName;
@property (nonatomic, retain) RSFeed *feed;


@end
