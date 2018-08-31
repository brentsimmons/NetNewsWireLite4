//
//  NNWArticleDetailPaneView.h
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWArticleDetailPaneView : NSView {
@private	
	NSView *detailContentView;
	NSView *detailTemporaryView;
	NSImageView *screenshotViewForAnimation;
}


@property (nonatomic, retain) IBOutlet NSView *detailContentView; //HTML view, for instance

@property (nonatomic, retain) NSView *detailTemporaryView; //web browser, for instance. On top of content view.

@end
