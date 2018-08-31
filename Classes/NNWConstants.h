//
//  NNWConstants.h
//  nnw
//
//  Created by Brent Simmons on 12/22/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*Keys*/

extern NSString *NNWWidthKey; //@"width"
extern NSString *NNWViewKey; //@"view"
extern NSString *NNWFeedKey;
extern NSString *NNWSharableItemKey;
extern NSString *NNWWindowKey; //@"window"

/*Notifications*/

extern NSString *NNWSelectedURLDidUpdateNotification;
extern NSString *NNWMouseOverURLDidUpdateNotification;


extern NSString *NNWFeedAddedNotification; //posted when a feed is added manually (or via import)
/*userInfo: RSURLKey: feedURL NNWFeedKey: RSFeed*/ 

extern NSString *NNWFolderAddedNotification; //when added manually or via import
/*userInfo: RSNameKey : folder name*/

extern NSString *NNWPresentedSharableItemDidChangeNotification; //posted when detail pane changes
/*userInfo: NNWSharableItemKey : the item*/

extern NSString *NNWOPMLImportDidSucceedNotification;

extern NSString *NNWFeedsAndFoldersDidReorganizeNotification;

extern NSString *NNWFeedsSelectedNotification;

extern NSString *NNWMainWindowDidResizeNotification;

extern NSString *RSOverlayViewWasPoppedNotification;

extern NSString *NNWCurrentWebViewDidChangeNotification;
extern NSString *RSMainResponderDidChangeNotification;


/*Defaults*/

extern NSString *NNWOpenInBrowserInBackgroundDefaultsKey;

extern NSString *NNWRightPaneSplitViewPercentageKey;

/*Common Localized Strings*/

#define NNW_OK NSLocalizedString(@"OK", @"Button")
#define NNW_CANCEL NSLocalizedString(@"Cancel", @"Button")

