//
//  RSSAXOPMLParserTests.m
//  RSCoreTests
//
//  Created by Brent Simmons on 6/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSSAXOPMLParserTests.h"
#import "RSOPMLParser.h"


static NSString *pathForResourceFileWithFilename(NSString *filename) {
	return [[NSBundle bundleForClass:[RSSAXOPMLParserTests class]] pathForResource:filename ofType:nil]; 
}


static NSData *dataForResourceFileWithFilename(NSString *filename) {
	return [NSData dataWithContentsOfFile:pathForResourceFileWithFilename(filename)];
}


static NSArray *arrayForResourceFileWithFilename(NSString *filename) {
	return [NSArray arrayWithContentsOfFile:pathForResourceFileWithFilename(filename)];
}


@implementation RSSAXOPMLParserTests

- (void)testNGOPMLParsing {
	/* Not that we sync with NG anymore, but this stuff might appear in Social Sites or whatever, so it's worth testing.*/
	NSData *opmlData = dataForResourceFileWithFilename(@"ng.opml");
	STAssertNotNil(opmlData, nil);
	RSOPMLParser *opmlParser = [[[RSOPMLParser alloc] init] autorelease];
	NSError *error = nil;
	[opmlParser parseData:opmlData error:&error];
	NSArray *opmlOutline = opmlParser.outlineItems;
	STAssertNotNil(opmlOutline, nil);
//	[opmlOutline writeToFile:@"/Users/brent/Desktop/ng.opml.plist" atomically:YES];
	NSArray *expectedResult = arrayForResourceFileWithFilename(@"ngopml.plist");
	STAssertEqualObjects(opmlOutline, expectedResult, nil);
}


@end
