//
//  RSFoundationExtrasTests.m
//  RSCoreTests
//
//  Created by Brent Simmons on 5/25/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFoundationExtrasTests.h"
#import "RSFoundationExtras.h"


@implementation RSFoundationExtrasTests

- (void)testAppNameAndPaths {
	RSSetAppName(@"RSCoreTestApp");
	STAssertTrue([RSAppName() isEqualToString:@"RSCoreTestApp"], @"The app name should be RSCoreTestApp.");
	STAssertTrue([[@"~/Documents/" stringByExpandingTildeInPath] isEqualToString:RSUserDirectoryPath(NSDocumentDirectory)], @"");
	STAssertTrue([[@"~/Library/Application Support/RSCoreTestApp/TestFile" stringByExpandingTildeInPath] isEqualToString:RSAppSupportFilePath(@"TestFile")], @"");
}


- (void)testStringIsEmpty {
	STAssertTrue(RSStringIsEmpty(nil), @"Nil should be considered empty.");
	STAssertTrue(RSStringIsEmpty(@""), @"An empty string should be considered empty.");
	STAssertFalse(RSStringIsEmpty(@" "), @"A string with a single space should not be considered empty.");
	STAssertFalse(RSStringIsEmpty(@"some stuff"), @"This string should not be considered empty.");
}


- (void)testIsEmpty {
	STAssertTrue(RSIsEmpty(nil), @"Nil should be considered empty.");
	STAssertTrue(RSIsEmpty([NSArray array]), @"An empty array should be empty.");
	STAssertTrue(RSIsEmpty([NSDictionary dictionary]), @"An empty dictionary should be empty.");
	STAssertTrue(RSIsEmpty([NSData data]), @"An empty data object should be empty.");
	STAssertTrue(RSIsEmpty([NSSet set]), @"An empty set object should be empty.");
	STAssertTrue(RSIsEmpty([NSMutableSet set]), @"An empty mutable set object should be empty.");
	STAssertFalse(RSIsEmpty([NSArray arrayWithObject:@"test"]), @"An array with something in it should not be empty.");
	STAssertFalse(RSIsEmpty([NSSet setWithObject:@"test"]), @"A set with something in it should not be empty.");
	STAssertFalse(RSIsEmpty([NSDictionary dictionaryWithObject:@"testObject" forKey:@"testKey"]), @"A dictionary with something in it should not be empty.");
}


- (void)testRSSafeSetObject {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	STAssertNoThrow([d rs_safeSetObject:nil forKey:nil], @"Exception should not be thrown if obj or key are nil");
	STAssertTrue([d count] == 0, @"A nil obj or key should not have been added to the dictionary.");
	
	STAssertNoThrow([d rs_safeSetObject:@"testObj" forKey:nil], @"Exception should not be thrown if key is nil");
	STAssertTrue([d count] == 0, @"A nil key should not have been added to the dictionary.");
	
	STAssertNoThrow([d rs_safeSetObject:nil forKey:@"testKey"], @"Exception should not be thrown if obj is nil");
	STAssertTrue([d count] == 0, @"A nil obj should not have been added to the dictionary.");
	
	STAssertNoThrow([d rs_safeSetObject:@"testObj" forKey:@"testKey"], @"Exception should not be thrown if obj and key are both non-nil.");
	STAssertTrue([d count] == 1, @"The test object should have been added to the dictionary, to give it a count of 1.");
	
}


- (void)testIntegerForKey {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	[d rs_setInteger:10223 forKey:@"testKey"];
	STAssertTrue([d rs_integerForKey:@"testKey"] == 10223, @"The integer was not set or not retrieved properly.");
}


- (void)testMD5HashString {
	NSString *testString = @"This is a test string.";
	NSString *expectedHashedResult = @"1620d7b066531f9dbad51eee623f7635";
	NSString *actualResult = [testString rs_md5HashString];
	STAssertTrue([actualResult isEqualToString:expectedHashedResult], @"Hashed version was %@", actualResult);
}


- (void)testStripURLQuery {
	NSString *testString1 = @"http://foo?bar";
	NSString *expectedResult1 = @"http://foo";
	NSString *testString2 = @"http://foo?bar?baz";
	NSString *expectedResult2 = @"http://foo?bar";
	NSString *testString3 = @"http://example.com/foo/bar/baz.png?a=1&b=2&exampleParam=some+example%20valuelinenoise4908dhjfop78pna9fauehfn9*^&94y976";
	NSString *expectedResult3 = @"http://example.com/foo/bar/baz.png";
	STAssertTrue([[testString1 rs_stringByStrippingURLQuery] isEqualToString:expectedResult1], nil);
	STAssertTrue([[testString2 rs_stringByStrippingURLQuery] isEqualToString:expectedResult2], nil);
	STAssertTrue([[testString3 rs_stringByStrippingURLQuery] isEqualToString:expectedResult3], nil);
}


- (void)testCalendarGroups {
	STAssertTrue([[NSDate date] rs_calendarGroup] == RSCalendarToday, nil);
	STAssertTrue([[NSDate distantPast] rs_calendarGroup] == RSCalendarPast, nil);
	STAssertTrue([[NSDate distantFuture] rs_calendarGroup] == RSCalendarFuture, nil);
	NSDate *now = [NSDate date];
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
	NSDate *today = [[NSCalendar currentCalendar] dateFromComponents:components];
	STAssertTrue([today rs_calendarGroup] == RSCalendarToday, nil);
	NSDateComponents *oneDayAgoComponents = [[[NSDateComponents alloc] init] autorelease];
	[oneDayAgoComponents setDay:-1];
	NSDate *yesterday = [[NSCalendar currentCalendar] dateByAddingComponents:oneDayAgoComponents toDate:today options:0];
	STAssertTrue([yesterday rs_calendarGroup] == RSCalendarYesterday, nil);
	NSDate *dayBeforeYesterday = [[NSCalendar currentCalendar] dateByAddingComponents:oneDayAgoComponents toDate:yesterday options:0];
	STAssertTrue([dayBeforeYesterday rs_calendarGroup] == RSCalendarDayBeforeYesterday, nil);
	NSDate *aFewDaysAgo = [[NSCalendar currentCalendar] dateByAddingComponents:oneDayAgoComponents toDate:dayBeforeYesterday options:0];
	STAssertTrue([aFewDaysAgo rs_calendarGroup] == RSCalendarPast, nil);
	NSDateComponents *oneMonthAgoComponents = [[[NSDateComponents alloc] init] autorelease];
	[oneMonthAgoComponents setMonth:-1];
	NSDate *oneMonthAgo = [[NSCalendar currentCalendar] dateByAddingComponents:oneMonthAgoComponents toDate:today options:0];
	STAssertTrue([oneMonthAgo rs_calendarGroup] == RSCalendarPast, nil);
}


- (void)testUnixTimestampStringWithNoDecimal {
	NSString *timestampString = [[NSDate date] rs_unixTimestampStringWithNoDecimal];
	STAssertTrue([timestampString length] == 10, nil);
	STAssertFalse([timestampString rs_contains:@"."], nil);
	NSDate *testDate = [NSDate dateWithString:@"2010-06-22 03:57:49 +0000"];
	timestampString = [testDate rs_unixTimestampStringWithNoDecimal];
	STAssertTrue([timestampString isEqualToString:@"1277179069"], nil);
}


- (void)testDateWithNumberOfDaysInThePast {
	NSDate *pastDate = [NSDate rs_dateWithNumberOfDaysInThePast:30];
	STAssertTrue([pastDate compare:[NSDate date]] == NSOrderedAscending, nil);
}


@end
