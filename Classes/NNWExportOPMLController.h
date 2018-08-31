//
//  NNWExportOPMLViewController.h
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSRefreshProtocols.h"


@interface NNWExportOPMLController  : NSObject {
@private
	NSWindow *backgroundWindow;
	id<RSAccount>account;
	NSMutableArray *feedsAdded;
}


@property (nonatomic, retain) NSWindow *backgroundWindow; //runs as a sheet on this window

- (void)exportOPML:(id<RSAccount>)accountToExport;

@end
