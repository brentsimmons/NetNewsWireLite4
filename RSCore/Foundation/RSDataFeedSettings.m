//
//  RSDataFeedSettings.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/11/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataFeedSettings.h"



NSString *RSDataFeedSettingsEntityName = @"FeedSettings";

@implementation RSDataFeedSettings

@dynamic archiveItemsAsHTML;
@dynamic automaticallyDownloadAudioEnclosures;
@dynamic automaticallyDownloadOtherEnclosures;
@dynamic automaticallyDownloadVideoEnclosures;
@dynamic daysToPersistItems;
@dynamic excludedFromDisplay;
@dynamic excludeWhenExportingAsOPML;
@dynamic minutesBetweenRefreshes;
@dynamic persistItems;
@dynamic skipDuringManualRefresh;
@dynamic suspended;

@dynamic feed;

@end
