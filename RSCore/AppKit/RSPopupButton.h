/*
 RSPopupButton.h
 RancheroAppKit
 
 Created by Brent Simmons on Mon Feb 02 2004.
 Copyright (c) 2004 Ranchero Software. All rights reserved.
 */


#import <Cocoa/Cocoa.h>


@interface RSPopupButton : NSButton {
@protected
	NSMenu *_pullDownMenu;
	id _pullDownMenuDelegate;
}


@property (nonatomic, retain) NSMenu *pullDownMenu;
@property (nonatomic, assign) id pullDownMenuDelegate;

- (void)getMenuFromPullDownMenuDelegate; /*For sub-classes*/


@end
