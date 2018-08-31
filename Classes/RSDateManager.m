//
//  RSDateManager.m
//  nnw
//
//  Created by Brent Simmons on 1/5/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDateManager.h"


NSString *RSDatesDidChangeNotification = @"RSDatesDidChangeNotification";

@interface RSDateManager ()

@property (nonatomic, retain) NSCalendar *userCalendar;
@property (nonatomic, retain, readwrite) NSDate *firstSecondOfToday;
@property (nonatomic, retain, readwrite) NSDate *firstSecondOfTomorrow;
@property (nonatomic, retain) NSDate *firstSecondOfYesterday;

- (void)recalculateDates;

@end


@implementation RSDateManager

@synthesize userCalendar;
@synthesize firstSecondOfToday;
@synthesize firstSecondOfTomorrow;
@synthesize firstSecondOfYesterday;


#pragma mark Class Methods

+ (RSDateManager *)sharedManager {
	static id gMyInstance = nil;
	if (gMyInstance == nil)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	[self recalculateDates];
	recalculateDatesTimer = [[NSTimer scheduledTimerWithTimeInterval:60 * 15 target:self selector:@selector(recalculateDates) userInfo:nil repeats:YES] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recalculateDates) name:NSApplicationDidBecomeActiveNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[recalculateDatesTimer rs_invalidateIfValid];
	[recalculateDatesTimer release];
	[userCalendar release];
	[firstSecondOfToday release];
	[firstSecondOfTomorrow release];
	[firstSecondOfYesterday release];
	[super dealloc];
}


#pragma mark Date Recalculating

- (void)recalculateDates {

	self.userCalendar = [NSCalendar autoupdatingCurrentCalendar];
	
	NSDateComponents *todayComponents = [self.userCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
	NSDate *updatedToday = [self.userCalendar dateFromComponents:todayComponents];
			
	static NSDateComponents *oneDayAgoIntervalDateComponents = nil;
	if (oneDayAgoIntervalDateComponents == nil) {
		oneDayAgoIntervalDateComponents = [[NSDateComponents alloc] init];
		[oneDayAgoIntervalDateComponents setDay:-1];
	}

	NSDate *updatedYesterday = [self.userCalendar dateByAddingComponents:oneDayAgoIntervalDateComponents toDate:updatedToday options:0];
	
	static NSDateComponents *oneDayFutureIntervalDateComponents = nil;
	if (oneDayFutureIntervalDateComponents == nil) {
		oneDayFutureIntervalDateComponents = [[NSDateComponents alloc] init];
		[oneDayFutureIntervalDateComponents setDay:1];
	}

	NSDate *updatedTomorrow = [self.userCalendar dateByAddingComponents:oneDayFutureIntervalDateComponents toDate:updatedToday options:0];
	
	self.firstSecondOfTomorrow = updatedTomorrow;
	self.firstSecondOfYesterday = updatedYesterday;
	self.firstSecondOfToday = updatedToday;
}


- (void)sendDatesDidRecalculateNotification {
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSDatesDidChangeNotification object:self userInfo:nil];
}


- (void)setFirstSecondOfToday:(NSDate *)aDate {
	BOOL shouldSendNotification = NO;
	if (firstSecondOfToday != nil && [aDate compare:firstSecondOfToday] != NSOrderedSame)
		shouldSendNotification = YES;
	[firstSecondOfToday autorelease];
	firstSecondOfToday = [aDate retain];
	if (shouldSendNotification)
		[self sendDatesDidRecalculateNotification];
}


#pragma mark Group for Date

- (RSDateGroup)groupForDate:(NSDate *)aDate {

	if (aDate == nil || [aDate earlierDate:self.firstSecondOfYesterday] == aDate)
		return RSDateGroupPast;
	if ([aDate earlierDate:self.firstSecondOfTomorrow] == self.firstSecondOfTomorrow || [aDate compare:self.firstSecondOfTomorrow] == NSOrderedSame)
		return RSDateGroupFuture;
	if ([aDate earlierDate:self.firstSecondOfToday] == aDate)
		return RSDateGroupYesterday;
	return RSDateGroupToday;
}


- (void)year:(NSInteger *)year andMonth:(NSInteger *)month forDate:(NSDate *)aDate {
	NSDateComponents *dateComponents = [self.userCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:aDate];
	*year = [dateComponents year];
	*month = [dateComponents month];
}


@end


