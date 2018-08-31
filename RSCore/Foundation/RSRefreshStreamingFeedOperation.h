//
//  RSRefreshStreamingFeedOperation.h
//  padlynx
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RSPluginProtocols.h"
#import "RSRefreshProtocols.h"
#import "RSAbstractFeedParser.h"
#import "RSDownloadOperation.h"


/*This operation parses the feed as it comes in -- it doesn't ever have the entire feed in memory,
 unless the feed is small. This prevents large feeds from using too much memory. Good for iOS.*/


@interface RSRefreshStreamingFeedOperation : RSDownloadOperation {
@private
	id<RSFeedSpecifier> feedSpecifier;
	id<RSAccount> account;
	id<RSArticleSaver> articleSaver;
	NSManagedObjectContext *temporaryMOC;
}


- (id)initWithFeedSpecifier:(id<RSFeedSpecifier>)aFeedSpecifier account:(id<RSAccount>)anAccount;

@property (nonatomic, retain) id<RSArticleSaver> articleSaver;


@end
