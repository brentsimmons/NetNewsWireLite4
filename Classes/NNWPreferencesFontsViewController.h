//
//  NNWPreferencesFontsViewController.h
//  nnw
//
//  Created by Brent Simmons on 12/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SLViewControllerProtocols.h"


@class RSFontLabelView;

@interface NNWPreferencesFontsViewController : NSViewController <SLFullContentViewControllerPlugin> {
@private
    NSToolbarItem *toolbarItem;
    RSFontLabelView *standardFontLabelView;
    RSFontLabelView *fixedFontLabelView;
    BOOL changingStandardFont;
}


@property (nonatomic, strong) IBOutlet RSFontLabelView *standardFontLabelView;
@property (nonatomic, strong) IBOutlet RSFontLabelView *fixedFontLabelView;
@property (nonatomic, assign) int minimumFontSize;


@end
