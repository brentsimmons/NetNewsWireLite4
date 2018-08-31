//
//  RSDataFeedSettings.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/11/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *RSDataFeedSettingsEntityName; //@"FeedSettings";

@class RSDataFeed;

@interface RSDataFeedSettings : NSObject {
}

@property (nonatomic, retain) NSNumber *archiveItemsAsHTML;
@property (nonatomic, retain) NSNumber *automaticallyDownloadAudioEnclosures;
@property (nonatomic, retain) NSNumber *automaticallyDownloadOtherEnclosures;
@property (nonatomic, retain) NSNumber *automaticallyDownloadVideoEnclosures;
@property (nonatomic, retain) NSNumber *daysToPersistItems;
@property (nonatomic, retain) NSNumber *excludedFromDisplay;
@property (nonatomic, retain) NSNumber *excludeWhenExportingAsOPML;
@property (nonatomic, retain) NSNumber *minutesBetweenRefreshes;
@property (nonatomic, retain) NSNumber *persistItems;
@property (nonatomic, retain) NSNumber *skipDuringManualRefresh;
@property (nonatomic, retain) NSNumber *suspended;

@property (nonatomic, retain) RSDataFeed *feed;

@end
