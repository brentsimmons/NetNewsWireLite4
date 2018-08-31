//
//  RSLocalAccountCoreDataArticleSaverOperation.h
//  padlynx
//
//  Created by Brent Simmons on 9/6/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"


/*Background thread -- NSOperation.
 
 It also has to mark-as-deleted articles that no longer appear in the feed.*/

@interface RSLocalAccountCoreDataArticleSaverOperation : RSOperation {
@private
	NSArray *existingArticles;
	NSArray *parsedArticles;
	NSManagedObjectContext *temporaryMOC;
	NSString *accountIdentifier;
	NSURL *feedURL;
	NSMutableSet *managedObjectIDsOfItemsInFeed;
	NSUInteger unreadCount;
}


- (id)initWithParsedArticles:(NSArray *)someParsedArticles feedURL:(NSURL *)aFeedURL accountIdentifier:(NSString *)anAccountIdentifier;

@property (nonatomic, assign, readonly) NSUInteger unreadCount;

@end
