//
//  NNWFeedHTTPInfo.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataFeedHTTPInfo.h"
#import "NGFeedSpecifier.h"
#import "RSCoreDataUtilities.h"
#import "RSDataManagedObjects.h"
#import "RSDownloadConstants.h"


@implementation RSDataFeedHTTPInfo

@dynamic dateLastChecked;
@dynamic URL;
@dynamic httpResponseEtag;
@dynamic httpResponseLastModified;


static NSString *NNWFeedHTTPInfoEntityName = @"FeedHTTPInfo";
static NSString *NNWFeedHTTPInfoUniqueKey = @"URL";

+ (RSDataFeedHTTPInfo *)fetchOrCreateFeedHTTPInfoWithFeedURL:(NSString *)aURL moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate {
	return (RSDataFeedHTTPInfo *)RSFetchOrInsertObjectWithValueForKey(NNWFeedHTTPInfoUniqueKey, aURL, NNWFeedHTTPInfoEntityName, moc, didCreate);
}


+ (RSDataFeedHTTPInfo *)fetchHTTPInfoWithFeedURL:(NSURL *)feedURL moc:(NSManagedObjectContext *)moc {
	return (RSDataFeedHTTPInfo *)RSFetchManagedObjectWithValueForKey(NNWFeedHTTPInfoUniqueKey, [feedURL absoluteString], RSDataEntityNameFeedHTTPInfo, moc);
}


+ (void)saveHTTPInfoForFeedURL:(NSString *)aURL checkDate:(NSDate *)checkDate conditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo moc:(NSManagedObjectContext *)moc {
	BOOL didCreate = NO;
	RSDataFeedHTTPInfo *feedHTTPInfo = [self fetchOrCreateFeedHTTPInfoWithFeedURL:aURL moc:moc didCreate:&didCreate];
	feedHTTPInfo.dateLastChecked = checkDate ? checkDate : [NSDate date];
	feedHTTPInfo.httpResponseEtag = conditionalGetInfo.httpResponseEtag ? conditionalGetInfo.httpResponseEtag : nil;
	feedHTTPInfo.httpResponseLastModified = conditionalGetInfo.httpResponseLastModified ? conditionalGetInfo.httpResponseLastModified : nil;
}


+ (void)saveHTTPInfoForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier checkDate:(NSDate *)checkDate conditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo moc:(NSManagedObjectContext *)moc {
	[self saveHTTPInfoForFeedURL:[feedSpecifier.URL absoluteString] checkDate:checkDate conditionalGetInfo:conditionalGetInfo moc:moc];
}


- (RSHTTPConditionalGetInfo *)conditionalGetInfo {
	return [[[RSHTTPConditionalGetInfo alloc] initWithEtagResponse:self.httpResponseEtag lastModifiedResponse:self.httpResponseLastModified] autorelease];
}


+ (RSHTTPConditionalGetInfo *)conditionalGetInfoForFeedURL:(NSString *)aURL moc:(NSManagedObjectContext *)moc {
	BOOL didCreate = NO;
	RSDataFeedHTTPInfo *feedHTTPInfo = [self fetchOrCreateFeedHTTPInfoWithFeedURL:aURL moc:moc didCreate:&didCreate];
	return feedHTTPInfo.conditionalGetInfo;
}


+ (RSHTTPConditionalGetInfo *)conditionalGetInfoForFeedSpecifier:(id<NGFeedSpecifier>)feedSpecifier moc:(NSManagedObjectContext *)moc {
	return [self conditionalGetInfoForFeedURL:[feedSpecifier.URL absoluteString] moc:moc];
}


+ (BOOL)clearConditionalGetInfoForFeedURL:(NSURL *)feedURL moc:(NSManagedObjectContext *)moc {
	RSDataFeedHTTPInfo *feedHTTPInfo = [self fetchHTTPInfoWithFeedURL:feedURL moc:moc];
	if (feedHTTPInfo == nil)
		return NO;
	feedHTTPInfo.httpResponseEtag = nil;
	feedHTTPInfo.httpResponseLastModified = nil;
	return YES;
}


+ (BOOL)clearConditionalGetInfoForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier moc:(NSManagedObjectContext *)moc {
	return [self clearConditionalGetInfoForFeedURL:feedSpecifier.URL moc:moc];
}

@end

