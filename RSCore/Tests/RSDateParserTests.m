//
//  RSDateParserTests.m
//  RSCoreTests
//
//  Created by Brent Simmons on 5/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDateParserTests.h"
#import "RSDateParser.h"
#import "RSFoundationExtras.h"


@implementation RSDateParserTests

- (void)testDateWithString {
	NSDate *expectedDateResult = [NSDate dateWithString:@"2010-05-28 14:03:38 -0700"];
	STAssertTrue(expectedDateResult != nil, nil);

	STAssertTrue(RSDateWithString(@"Fri, 28 May 2010 21:03:38 +0000") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"Fri, 28 May 2010 21:03:38 +0000")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"Fri, 28 May 2010 21:03:38 +00:00") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"Fri, 28 May 2010 21:03:38 +00:00")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"Fri, 28 May 2010 21:03:38 -00:00") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"Fri, 28 May 2010 21:03:38 -00:00")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"Fri, 28 May 2010 21:03:38 -0000") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"Fri, 28 May 2010 21:03:38 -0000")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"Fri, 28 May 2010 21:03:38 GMT") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"Fri, 28 May 2010 21:03:38 GMT")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"2010-05-28T21:03:38+00:00") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-05-28T21:03:38+00:00")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"2010-05-28T21:03:38+0000") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-05-28T21:03:38+0000")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"2010-05-28T21:03:38-0000") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-05-28T21:03:38-0000")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"2010-05-28T21:03:38-00:00") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-05-28T21:03:38-00:00")] == NSOrderedSame, nil);
	
	STAssertTrue(RSDateWithString(@"2010-05-28T21:03:38Z") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-05-28T21:03:38Z")] == NSOrderedSame, nil);
	
	expectedDateResult = [NSDate dateWithString:@"2010-07-13 17:06:40 +0000"];
	STAssertTrue(RSDateWithString(@"2010-07-13T17:06:40+00:00") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-07-13T17:06:40+00:00")] == NSOrderedSame, nil);

	expectedDateResult = [NSDate dateWithString:@"2010-04-30 05:00:00 -0700"];
	STAssertTrue(RSDateWithString(@"30 Apr 2010 5:00 PDT") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"30 Apr 2010 5:00 PDT")] == NSOrderedSame, nil);
	
	expectedDateResult = [NSDate dateWithString:@"2010-05-21 21:22:53 -0000"];
	STAssertTrue(RSDateWithString(@"21 May 2010 21:22:53 GMT") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"21 May 2010 21:22:53 GMT")] == NSOrderedSame, nil);
	
	expectedDateResult = [NSDate dateWithString:@"2010-06-09 05:00:00 +0000"];
	STAssertTrue(RSDateWithString(@"Wed, 09 Jun 2010 00:00 EST") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"Wed, 09 Jun 2010 00:00 EST")] == NSOrderedSame, nil);
	
	expectedDateResult = [NSDate dateWithString:@"2010-06-23 03:43:50 +0000"];
	STAssertTrue(RSDateWithString(@"Wed, 23 Jun 2010 03:43:50 Z") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"Wed, 23 Jun 2010 03:43:50 Z")] == NSOrderedSame, nil);
	
	expectedDateResult = [NSDate dateWithString:@"2010-06-22 03:57:49 +0000"];
	STAssertTrue(RSDateWithString(@"2010-06-22T03:57:49+00:00") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-06-22T03:57:49+00:00")] == NSOrderedSame, nil);

	expectedDateResult = [NSDate dateWithString:@"2010-11-17 08:40:07 -0500"];
	STAssertTrue(RSDateWithString(@"2010-11-17T08:40:07-05:00") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSDateWithString(@"2010-11-17T08:40:07-05:00")] == NSOrderedSame, nil);
}


- (void)testTwitterTimelineDateWithString {	
	NSDate *expectedDateResult = [NSDate dateWithString:@"2010-07-16 16:58:46 +0000"];
	STAssertTrue(expectedDateResult != nil, nil);

	STAssertTrue(RSTwitterTimelineDateWithString(@"Fri Jul 16 16:58:46 +0000 2010") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSTwitterTimelineDateWithString(@"Fri Jul 16 16:58:46 +0000 2010")] == NSOrderedSame, nil);

	expectedDateResult = [NSDate dateWithString:@"2006-11-29 06:08:08 +0000"];
	STAssertTrue(expectedDateResult != nil, nil);
	
	STAssertTrue(RSTwitterTimelineDateWithString(@"Wed Nov 29 06:08:08 +0000 2006") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSTwitterTimelineDateWithString(@"Wed Nov 29 06:08:08 +0000 2006")] == NSOrderedSame, nil);

	expectedDateResult = [NSDate dateWithString:@"2007-01-15 15:22:14 +0000"];
	STAssertTrue(expectedDateResult != nil, nil);
	
	STAssertTrue(RSTwitterTimelineDateWithString(@"Mon Jan 15 15:22:14 +0000 2007") != nil, nil);
	STAssertTrue([expectedDateResult compare:RSTwitterTimelineDateWithString(@"Mon Jan 15 15:22:14 +0000 2007")] == NSOrderedSame, nil);
}


@end
