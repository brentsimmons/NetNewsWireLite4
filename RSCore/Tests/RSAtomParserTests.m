//
//  RSAtomParserTests.m
//  RSCoreTests
//
//  Created by Brent Simmons on 6/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSAtomParserTests.h"
#import "RSAtomParser.h"
#import "RSFoundationExtras.h"
#import "RSParsedNewsItem.h"


static NSString *pathForFeedWithFilename(NSString *filename) {
	filename = [filename rs_stringByStrippingCaseInsensitiveSuffix:@".atom"];
	return [[NSBundle bundleForClass:[RSAtomParserTests class]] pathForResource:filename ofType:@"atom"]; 
}


static NSData *dataForFeedWithFilename(NSString *filename) {
	return [NSData dataWithContentsOfFile:pathForFeedWithFilename(filename)];
}


@implementation RSAtomParserTests

- (void)testStanleyFeld {
	NSData *feedData = dataForFeedWithFilename(@"stanleyfeld.atom");
	RSAtomParser *atomParser = [[RSAtomParser alloc] init];
	NSError *error = nil;
	[atomParser parseData:feedData error:&error];
	
	NSMutableDictionary *parserResults = [NSMutableDictionary dictionaryWithCapacity:2];
	[parserResults rs_safeSetObject:atomParser.headerItems forKey:@"headerItems"];
	NSMutableArray *newsItems = [NSMutableArray array];
	for (RSParsedNewsItem *oneNewsItem in atomParser.newsItems)
		[newsItems rs_safeAddObject:[oneNewsItem dictionaryRepresentation]];
	[parserResults rs_safeSetObject:newsItems forKey:@"newsItems"];	
	
	STAssertTrue([atomParser.newsItems count] == 25, nil);
	
	RSParsedNewsItem *newsItem = [atomParser.newsItems objectAtIndex:0];
	STAssertTrue(newsItem != nil, nil);
	STAssertEqualObjects(newsItem.author, @"stanleyfeldmdmace", nil);
	STAssertTrue([newsItem.categories count] == 5, nil);
	STAssertEqualObjects([newsItem.categories objectAtIndex:1], @"Medicine: Healthcare System", nil);
	STAssertFalse(newsItem.isGoogleReadStateLocked, nil);
	STAssertFalse(newsItem.googleSynced, nil);
	STAssertEqualObjects(newsItem.guid, @"tag:typepad.com,2003:post-6a00d83451876469e20133f19f29e3970b", nil);
	STAssertFalse(newsItem.guidIsPermalink, nil);
	STAssertEqualObjects(newsItem.permalink, @"http://feedproxy.google.com/~r/RepairingTheHealthcareSystem/~3/T4HxpXJl1Mo/president-obama-and-the-sustainable-growth-sgr-formula-for-medicare-reimbursement.html", nil);
	STAssertEqualObjects(newsItem.plainTextTitle, @"President Obama And The Sustainable Growth (SGR) Formula For Medicare Reimbursement", nil);
	//STAssertEqualObjects(newsItem.pubDateString, @"2010-06-22T18:41:12-07:00", nil);
	STAssertEqualObjects(newsItem.pubDate, [NSDate dateWithString:@"2010-06-22 18:41:12 -0700"], nil);
	STAssertFalse(newsItem.read, nil);
	STAssertFalse(newsItem.starred, nil);
	STAssertEqualObjects(newsItem.thumbnailURL, @"http://stanleyfeldmdmace.typepad.com/.a/6a00d83451876469e20133f19f25b3970b-pi", nil);
	STAssertEqualObjects(newsItem.title, @"President Obama And The Sustainable Growth (SGR) Formula For Medicare Reimbursement", nil);
	STAssertEqualObjects(newsItem.xmlBaseURL, @"http://stanleyfeldmdmace.typepad.com/repairing_the_healthcare_/", nil);
	STAssertEqualObjects(newsItem.xmlBaseURLForContent, @"http://stanleyfeldmdmace.typepad.com/repairing_the_healthcare_/", nil);
		
	[atomParser release];
}


- (void)testStackOverflowCocoa {
	NSData *feedData = dataForFeedWithFilename(@"stackoverflowcocoa.atom");
	RSAtomParser *atomParser = [[RSAtomParser alloc] init];
	NSError *error = nil;
	[atomParser parseData:feedData error:&error];
	
	NSMutableDictionary *parserResults = [NSMutableDictionary dictionaryWithCapacity:2];
	[parserResults rs_safeSetObject:atomParser.headerItems forKey:@"headerItems"];
	NSMutableArray *newsItems = [NSMutableArray array];
	for (RSParsedNewsItem *oneNewsItem in atomParser.newsItems)
		[newsItems rs_safeAddObject:[oneNewsItem dictionaryRepresentation]];
	[parserResults rs_safeSetObject:newsItems forKey:@"newsItems"];	
	
	NSDictionary *headerItems = atomParser.headerItems;
	STAssertTrue(headerItems != nil, nil);
	STAssertTrue([headerItems objectForKey:@"title"] != nil, nil);
	STAssertTrue([[headerItems objectForKey:@"title"] isEqualToString:@"active questions tagged cocoa - Stack Overflow"], nil);
	
	RSParsedNewsItem *newsItem = [atomParser.newsItems objectAtIndex:01];
	STAssertTrue(newsItem != nil, nil);
	STAssertEqualObjects(newsItem.author, @"Gordon Worley", nil);
	STAssertTrue([newsItem.categories count] == 5, nil);
	
	[atomParser release];
	
}


- (void)testAtomFeedWithSourceTag {
	NSData *feedData = dataForFeedWithFilename(@"AtomFeedWithSourceTag.atom");
	RSAtomParser *atomParser = [[RSAtomParser alloc] init];
	NSError *error = nil;
	[atomParser parseData:feedData error:&error];
	
	NSString *feedTitle = [atomParser.headerItems objectForKey:@"title"];
	STAssertTrue(feedTitle != nil, nil);
	STAssertEqualObjects(feedTitle, @"Syndication Items for Activity Stream Event", nil);
	
	RSParsedNewsItem *newsItem = [atomParser.newsItems objectAtIndex:0];
	STAssertEqualObjects(newsItem.title, @"Motorola shares fall on Q1 mobile loss forecast", nil);
	
	STAssertTrue([atomParser.newsItems count] == 1, nil);
}


@end
