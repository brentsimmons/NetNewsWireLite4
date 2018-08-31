//
//  RSFeedTypeDetectorTests.m
//  RSCoreTests
//
//  Created by Brent Simmons on 6/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeedTypeDetectorTests.h"
#import "RSFeedTypeDetector.h"
#import "RSFoundationExtras.h"


static NSString *pathForResourceFileWithFilename(NSString *filename) {
	return [[NSBundle bundleForClass:[RSFeedTypeDetectorTests class]] pathForResource:filename ofType:nil]; 
}

static NSData *dataForResourceFileWithFilename(NSString *filename) {
	return [NSData dataWithContentsOfFile:pathForResourceFileWithFilename(filename)];
}


static NSArray *allPathsWithType(NSString *fileType) {
	return [[NSBundle bundleForClass:[RSFeedTypeDetectorTests class]] pathsForResourcesOfType:fileType inDirectory:nil];	
}


@implementation RSFeedTypeDetectorTests

- (void)testDetectAtomFeeds {
	NSArray *allPaths = allPathsWithType(@"atom");
	STAssertTrue(!RSIsEmpty(allPaths), nil);
	for (NSString *onePath in allPaths) {
		RSFeedType feedType = RSFeedTypeForData([NSData dataWithContentsOfFile:onePath]);
		STAssertTrue(feedType == RSFeedTypeAtom, onePath);
	}
}


- (void)testDetectRSSFeeds {
	NSArray *allPaths = allPathsWithType(@"rss");
	STAssertTrue(!RSIsEmpty(allPaths), nil);
	for (NSString *onePath in allPaths) {
		RSFeedType feedType = RSFeedTypeForData([NSData dataWithContentsOfFile:onePath]);
		STAssertTrue(feedType == RSFeedTypeRSS, onePath);
	}
}


- (void)testDetectNotAFeed {
	NSArray *allPaths = allPathsWithType(@"html");
	STAssertTrue(!RSIsEmpty(allPaths), nil);
	for (NSString *onePath in allPaths) {
		RSFeedType feedType = RSFeedTypeForData([NSData dataWithContentsOfFile:onePath]);
		STAssertTrue(feedType == RSFeedTypeNotAFeed, onePath);
	}

	/*Test OPML -- it's not a feed*/
	STAssertTrue(RSFeedTypeForData(dataForResourceFileWithFilename(@"ng.opml")) == RSFeedTypeNotAFeed, pathForResourceFileWithFilename(@"ng.opml"));
	
	/*Test plist*/
	STAssertTrue(RSFeedTypeForData(dataForResourceFileWithFilename(@"ngopml.plist")) == RSFeedTypeNotAFeed, pathForResourceFileWithFilename(@"ngopml.plist"));
	
	/*Test png*/
	STAssertTrue(RSFeedTypeForData(dataForResourceFileWithFilename(@"notafeed.png")) == RSFeedTypeNotAFeed, pathForResourceFileWithFilename(@"notafeed.png"));

	/*Test gif*/
	STAssertTrue(RSFeedTypeForData(dataForResourceFileWithFilename(@"notafeed.gif")) == RSFeedTypeNotAFeed, pathForResourceFileWithFilename(@"notafeed.gif"));

	/*Test jpg*/
	STAssertTrue(RSFeedTypeForData(dataForResourceFileWithFilename(@"notafeed.jpg")) == RSFeedTypeNotAFeed, pathForResourceFileWithFilename(@"notafeed.jpg"));

	/*Test movie*/
	STAssertTrue(RSFeedTypeForData(dataForResourceFileWithFilename(@"notafeed.mov")) == RSFeedTypeNotAFeed, pathForResourceFileWithFilename(@"notafeed.mov"));
}


@end
