//
//  NNWFeed.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataFeed.h"
#import "NGFeedSpecifier.h"
#import "RSCoreDataUtilities.h"
#import "RSDataAccount.h"
#import "RSDataManagedObjects.h"


@implementation RSDataFeed

@dynamic accountIdentifier;
@dynamic dateLastUpdated;
@dynamic faviconURL;
@dynamic feedHash;
@dynamic homePageURL;
@dynamic login;
@dynamic name;
@dynamic nameForDisplay;
@dynamic serviceFirstTrackedItemDate;
@dynamic serviceID;
@dynamic sortDescending;
@dynamic sortKey;
@dynamic URL;
@dynamic xmlBaseURL;

@dynamic articles;
@dynamic parentFolders;
@dynamic settings;


static NSString *RSDataFeedURLKey = @"URL";
static NSString *RSDataFeedAccountIdentifierKey = @"accountIdentifier";

//+ (RSDataFeed *)insertFeedWithFeedURL:(NSString *)aURL moc:(NSManagedObjectContext *)moc {
//	return (RSDataFeed *)RSInsertObjectWithValueForKey(RSDataFeedURLKey, aURL, RSDataFeedEntityName, moc);
//}
//
//
+ (RSDataFeed *)fetchFeedWithURL:(NSString *)aURL account:(RSDataAccount *)anAccount moc:(NSManagedObjectContext *)moc {
	if (anAccount == nil || RSStringIsEmpty(aURL))
		return nil;
	NSDictionary *matches = [NSDictionary dictionaryWithObjectsAndKeys:aURL, RSDataFeedURLKey, anAccount.identifier, RSDataFeedAccountIdentifierKey, nil];	
	return (RSDataFeed *)RSFetchManagedObjectWithDictionary(matches, RSDataEntityNameFeed, moc);
}


+ (RSDataFeed *)fetchFeedForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	if (account == nil || feedSpecifier.URL == nil)
		return nil;
	return [self fetchFeedWithURL:[feedSpecifier.URL absoluteString] account:account moc:moc];
}


+ (NSArray *)fetchFeedsForFeedSpecifiers:(NSArray *)feedSpecifiers account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	if (account == nil || RSIsEmpty(feedSpecifiers))
		return nil;
	NSMutableArray *someFeeds = [NSMutableArray arrayWithCapacity:[feedSpecifiers count]];
	for (NGFeedSpecifier *oneFeedSpecifier in feedSpecifiers)
		[someFeeds rs_safeAddObject:[self fetchFeedForFeedSpecifier:oneFeedSpecifier account:account moc:moc]];
	return someFeeds;
}


+ (RSDataFeed *)insertFeedWithURL:(NSString *)aURL account:(RSDataAccount *)anAccount moc:(NSManagedObjectContext *)moc {
	RSDataFeed *insertedFeed = (RSDataFeed *)RSInsertObjectWithDictionary([NSDictionary dictionaryWithObjectsAndKeys:aURL, RSDataFeedURLKey, anAccount.identifier, RSDataFeedAccountIdentifierKey, nil], RSDataEntityNameFeed, moc);
	return insertedFeed;
}


+ (RSDataFeed *)fetchOrInsertFeedWithURL:(NSString *)aURL account:(RSDataAccount *)anAccount moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate {
	if (RSStringIsEmpty(aURL) || anAccount == nil)
		return nil;
	RSDataFeed *foundFeed = [self fetchFeedWithURL:aURL account:anAccount moc:moc];
	if (foundFeed) {
		*didCreate = NO;
		return foundFeed;
	}
	*didCreate = YES;
	return [self insertFeedWithURL:aURL account:anAccount moc:moc];	
}


+ (RSDataFeedSettings *)fetchOrInsertSettingsForFeed:(RSDataFeed *)feed moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate {
	*didCreate = NO;
	RSDataFeedSettings *feedSettings = feed.settings;
	if (feedSettings != nil)
		return feedSettings;
	*didCreate = YES;
	feedSettings = (RSDataFeedSettings *)RSInsertObject(RSDataFeedSettingsEntityName, moc);
	feed.settings = feedSettings;
	return feedSettings;
}


+ (NGFeedSpecifier *)feedSpecifierForFeed:(RSDataFeed *)feed account:(RSDataAccount *)account {
	return (id)[NGFeedSpecifier feedSpecifierWithName:feed.nameForDisplay feedURL:[NSURL URLWithString:feed.URL] feedHomePageURL:[NSURL URLWithString:feed.homePageURL] account:account];
}


+ (NSArray *)feedSpecifiersForAccount:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	NSArray *feeds = RSFetchManagedObjectArrayWithValueForKey(RSDataFeedAccountIdentifierKey, account.identifier, RSDataEntityNameFeed, moc);
	if (RSIsEmpty(feeds))
		return nil;
	return [self feedSpecifiersForFeeds:feeds account:account];
//	NSMutableArray *feedSpecifiers = [NSMutableArray arrayWithCapacity:[feeds count]];
//	for (RSDataFeed *oneFeed in feeds)
//		[feedSpecifiers rs_safeAddObject:[self feedSpecifierForFeed:oneFeed account:account]]; 
//	return feedSpecifiers;
}



+ (BOOL)deleteFeedMatchingFeedSpecifier:(NGFeedSpecifier *)feedSpecifier account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	RSDataFeed *feed = [self fetchFeedForFeedSpecifier:feedSpecifier account:account moc:moc];
	if (feed == nil)
		return NO;
	[moc deleteObject:feed];
	return YES;
}


+ (BOOL)deleteFeedsMatchingFeedSpecifiers:(NSSet *)extraFeedsInCoreData account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	BOOL didDeleteAtLeastOne = NO;
	for (NGFeedSpecifier *oneFeedSpecifier in extraFeedsInCoreData) {
		if ([self deleteFeedMatchingFeedSpecifier:oneFeedSpecifier account:account moc:moc])
			didDeleteAtLeastOne = YES;
		oneFeedSpecifier.deleted = YES;
	}
	return didDeleteAtLeastOne;
}


+ (BOOL)addFeedForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	BOOL didCreate = NO;
	RSDataFeed *feed = [self fetchOrInsertFeedWithURL:[feedSpecifier.URL absoluteString] account:account moc:moc didCreate:&didCreate];
	if (feedSpecifier.homePageURL != nil && feed.homePageURL == nil)
		feed.homePageURL = [feedSpecifier.homePageURL absoluteString];
	if (feedSpecifier.name != nil && feed.name == nil)
		feed.name = feedSpecifier.name;
	if (feedSpecifier.name != nil && feed.nameForDisplay == nil)
		feed.nameForDisplay = feedSpecifier.name;
	return didCreate;
}


+ (BOOL)addFeedsForFeedSpecifiers:(NSSet *)setOfConfigFeeds account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	BOOL didCreateAtLeastOne = NO;
	for (NGFeedSpecifier *oneFeedSpecifier in setOfConfigFeeds) {
		if ([self addFeedForFeedSpecifier:oneFeedSpecifier account:account moc:moc])
			didCreateAtLeastOne = YES;
	}
	return didCreateAtLeastOne;
}


+ (NSArray *)notSuspendedFeedsInAccount:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	static NSPredicate *notSuspendedPredicate = nil;
	if (notSuspendedPredicate == nil)		
		notSuspendedPredicate = [[NSPredicate predicateWithFormat:@"(settings == nil) || (settings.suspended == NO)"] retain];
	return RSFetchManagedObjectArrayWithPredicate(notSuspendedPredicate, RSDataEntityNameFeed, moc);
}


+ (NSArray *)feedSpecifiersForFeeds:(NSArray *)feeds account:(RSDataAccount *)account {
	if (feeds == nil || account == nil)
		return nil;
	NSMutableArray *feedSpecifiers = [NSMutableArray arrayWithCapacity:[feeds count]];
	for (RSDataFeed *oneFeed in feeds)
		[feedSpecifiers rs_safeAddObject:[self feedSpecifierForFeed:oneFeed account:account]];
	return feedSpecifiers;
}


+ (NSArray *)notSuspendedFeedSpecifiersInAccount:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	return [self feedSpecifiersForFeeds:[self notSuspendedFeedsInAccount:account moc:moc] account:account];
}


- (NSSet *)fetchSetOfArticlesWithValue:(id)value forKey:(NSString *)key moc:(NSManagedObjectContext *)moc {
	if (RSIsEmpty(self.articles))
		return nil;
	NSPredicate *localPredicate = [RSPredicateWithEquality(key) predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:value forKey:RSDataGenericSubstitionKey]];
	return [self.articles filteredSetUsingPredicate:localPredicate];
}


- (RSDataArticle *)fetchArticleWithValue:(id)value forKey:(NSString *)key moc:(NSManagedObjectContext *)moc {
	NSSet *setOfArticles = [self fetchSetOfArticlesWithValue:value forKey:key moc:moc];
	if (RSIsEmpty(setOfArticles))
		return nil;
	return [setOfArticles anyObject];
}


//- (RSDataArticle *)fetchArticleWithGuid:(NSString *)aGuid moc:(NSManagedObjectContext *)moc {
//	return [self fetchArticleWithValue:aGuid forKey:@"guid" moc:moc];
//}


- (RSDataArticle *)insertArticleWithMOC:(NSManagedObjectContext *)moc {
	RSDataArticle *article = (RSDataArticle *)RSInsertObject(RSDataEntityNameArticle, moc);
	[self addArticlesObject:article];
	article.feedURL = self.URL;
	article.serviceIdentifier = self.serviceID;
	article.dateArrived = [NSDate date];
	return article;
}


#pragma mark Conditional Get Info

+ (RSHTTPConditionalGetInfo *)logicalConditionalGetInfoForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc {
	RSDataFeed *feed = [self fetchFeedForFeedSpecifier:feedSpecifier account:account moc:moc];
	if (feed == nil || RSIsEmpty(feed.articles))
		return nil;
	return [RSDataFeedHTTPInfo conditionalGetInfoForFeedSpecifier:feedSpecifier moc:moc];
}


@end
