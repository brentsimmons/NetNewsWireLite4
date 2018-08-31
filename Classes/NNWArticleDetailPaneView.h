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


@property (nonatomic, strong) IBOutlet NSView *detailContentView; //HTML view, for instance

@property (nonatomic, strong) NSView *detailTemporaryView; //web browser, for instance. On top of content view.

@end
