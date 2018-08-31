//
//  RSLocalAccountStreamingArticleSaver.h
//  padlynx
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSRefreshProtocols.h"


/*Saves articles as they arrive -- streamed in -- from the parser.
 Best for iOS, as part of streaming pattern which saves memory.
 Works for stand-alone feeds read from original source --
 doesn't work for Google Reader.*/


@interface RSLocalAccountStreamingArticleSaver : NSObject {
@private
	id<RSAccount> account;
	id<RSFeedSpecifier> feedSpecifier;
	NSMutableArray *heldItems;
}


- (id)initWithAccount:(id<RSAccount>)anAccount feedSpecifier:(id<RSFeedSpecifier>)aFeedSpecifier;


@end
