//
//  RSDateManager.h
//  nnw
//
//  Created by Brent Simmons on 1/5/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*Automatically, periodically updates dates for today and yesterday.
 Tracks changes to user calendar. Updates every 15 minutes,
 but also after coming back to the foreground.
 
 Use this to find out if a date is in today or yesterday (or some time in the future or past).
 
 Main thread only.
 
 Observe RSDatesDidChangeNotification to be notified when the dates for today
 and yesterday change. (Could be due to a new day, or change in time zone,
 or change in user setting, whatever.)
 */

extern NSString *RSDatesDidChangeNotification;


typedef enum _RSDateGroup {
    RSDateGroupFuture,
    RSDateGroupToday,
    RSDateGroupYesterday,
    RSDateGroupPast,
} RSDateGroup;


@interface RSDateManager : NSObject {
@private
    NSDate *firstSecondOfToday;
    NSDate *firstSecondOfTomorrow;
    NSDate *firstSecondOfYesterday;
    NSCalendar *userCalendar;
    NSTimer *recalculateDatesTimer;
}


+ (RSDateManager *)sharedManager;

@property (nonatomic, strong, readonly) NSDate *firstSecondOfToday;
@property (nonatomic, strong, readonly) NSDate *firstSecondOfTomorrow;

- (void)recalculateDates; //re-caches the calendar and updates today, tomorrow, yesterday

- (RSDateGroup)groupForDate:(NSDate *)aDate;

- (void)year:(NSInteger *)year andMonth:(NSInteger *)month forDate:(NSDate *)aDate;

@end
