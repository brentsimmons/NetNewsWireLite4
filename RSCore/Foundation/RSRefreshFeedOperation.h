//
//  RSRefreshFeedOperation.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 6/27/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSDownloadOperation.h"


/*Background thread -- NSOperation.*/

@interface RSRefreshFeedOperation : RSDownloadOperation {
@private
	NSURL *feedURL;
	NSString *accountIdentifier;
	BOOL didTryUsernameAndPassword;
}


- (id)initWithFeedURL:(NSURL *)aFeedURL accountIdentifier:(NSString *)anAccountIdentifier;


@end
