//
//  RSGoogleUtilities.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSGoogleReaderUtilities.h"
#import "RSGoogleReaderConstants.h"


static NSString *RSGoogleReaderURLStringWithClientAppended(NSString *urlString) {
	NSMutableString *urlStringWithClientAppended = [NSMutableString stringWithString:urlString];
	if ([urlString rs_contains:@"?"])
		[urlStringWithClientAppended appendString:@"&"];
	else
		[urlStringWithClientAppended appendString:@"?"];
	[urlStringWithClientAppended appendString:@"client="];
	[urlStringWithClientAppended appendString:RSGoogleReaderClientName];
	return urlStringWithClientAppended;
}


NSURL *RSGoogleReaderURLWithClientAppended(NSString *urlString) {
	return [NSURL URLWithString:RSGoogleReaderURLStringWithClientAppended(urlString)];
}


#pragma mark IDs

static const NSUInteger kLongGoogleItemIDLength = 32;

BOOL RSGoogleReaderItemIDIsLong(NSString *itemID) {
	return [itemID length] == kLongGoogleItemIDLength && [itemID hasPrefix:RSGoogleReaderItemIDPrefix];
}


NSString *RSGoogleReaderShortItemIDForLongItemID(NSString *itemID) {
	if (RSStringIsEmpty(itemID))
		return itemID;
	NSUInteger lengthOfID = [itemID length];
	if (lengthOfID == 16)
		return itemID;
	if (lengthOfID > 32)
		return [itemID substringFromIndex:kLongGoogleItemIDLength];
	if (![itemID rs_contains:@"/"]) /*Shouldn't get here*/
		return itemID;
	return [[itemID componentsSeparatedByString:@"/"] lastObject];
}


NSArray *RSGoogleReaderShortItemIDsForLongItemIDs(NSArray *longItemIDs) {
	if (RSIsEmpty(longItemIDs))
		return longItemIDs;
	NSMutableArray *shortItemIDs = [NSMutableArray arrayWithCapacity:[longItemIDs count]];
	for (NSString *oneLongItemID in longItemIDs)
		[shortItemIDs rs_safeAddObject:RSGoogleReaderShortItemIDForLongItemID(oneLongItemID)];
	return shortItemIDs;
}


NSArray *RSGoogleReaderArrayOfLongItemIDsForSetOfShortItemIDs(NSSet *shortItemIDs) {
	if (RSIsEmpty(shortItemIDs))
		return nil;
	NSMutableArray *longItemIDs = [NSMutableArray arrayWithCapacity:[shortItemIDs count]];
	for (NSString *oneShortItemID in shortItemIDs)
		[longItemIDs rs_safeAddObject:RSGoogleReaderLongItemIDForShortItemID(oneShortItemID)];
	return longItemIDs;
}


NSSet *RSGoogleReaderSetOfShortItemIDsForArrayOfLongItemIDs(NSArray *longItemIDs) {
	if (RSIsEmpty(longItemIDs))
		return nil;
	NSMutableSet *shortItemIDs = [NSMutableSet setWithCapacity:[longItemIDs count]];
	for (NSString *oneLongItemID in longItemIDs)
		[shortItemIDs rs_addObject:RSGoogleReaderShortItemIDForLongItemID(oneLongItemID)];
	return shortItemIDs;	
}


NSString *RSGoogleReaderLongItemIDForShortItemID(NSString *shortItemID) {
	if (shortItemID == nil)
		return nil;
	NSUInteger lengthOfID = [shortItemID length];
	if (lengthOfID == 48)
		return shortItemID;
	if (lengthOfID < 33) 
		return [NSString stringWithFormat:RSGoogleReaderItemIDPrefixFormat, shortItemID];
	if ([shortItemID hasPrefix:RSGoogleReaderItemIDPrefix]) /*Shouldn't get here*/
		return shortItemID;
	return [NSString stringWithFormat:RSGoogleReaderItemIDPrefixFormat, shortItemID];
}

NSArray *RSGoogleReaderLongItemIDsForShortItemIDs(NSArray *shortItemIDs) {
	if (RSIsEmpty(shortItemIDs))
		return shortItemIDs;
	NSMutableArray *longItemIDs = [NSMutableArray arrayWithCapacity:[shortItemIDs count]];
	for (NSString *oneShortItemID in shortItemIDs)
		[longItemIDs rs_safeAddObject:RSGoogleReaderLongItemIDForShortItemID(oneShortItemID)];
	return longItemIDs;
	
}


BOOL SLGoogleReaderGuidIsFromGoogleReader(NSString *guid) {
	return [guid hasPrefix:@"tag:google.com,"] && [guid rs_contains:@"reader/item/"];	
}


static NSString *SLGoogleReaderCalculatedIDWithNameAndPrefix(NSString *name, NSString *prefix) {
	if (RSStringIsEmpty(name))
		return nil;
	if ([name hasPrefix:prefix])
		return name;
	NSMutableString *s = [NSMutableString stringWithString:prefix];
	[s appendString:name];
	return s;	
}


NSString *SLGoogleReaderCalculatedIDForFeedURLString(NSString *feedURLString) {
	return SLGoogleReaderCalculatedIDWithNameAndPrefix(feedURLString, @"feed/");
}


NSString *SLGoogleReaderCalculatedIDForFolderName(NSString *folderName) {
	return SLGoogleReaderCalculatedIDWithNameAndPrefix(SLGoogleReaderNameForFolderName(folderName), @"user/-/label/");
}


NSString *SLGoogleReaderNameForFolderName(NSString *folderName) {
	/*Illegal characters in Google names: " < > ? & / \ ^
	 Translate to: _ [ ] _ + | | _*/
	if (RSStringIsEmpty(folderName))
		return folderName;
	NSMutableString *googleName = [NSMutableString stringWithString:folderName];
	[googleName replaceOccurrencesOfString:@"\"" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"<" withString:@"[" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@">" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"?" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"&" withString:@"+" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"/" withString:@"|" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"\\" withString:@"|" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"^" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"," withString:@"." options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	return googleName;	
}


