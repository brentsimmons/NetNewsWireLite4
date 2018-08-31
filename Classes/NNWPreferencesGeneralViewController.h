//
//  NNWPreferencesGeneralViewController.h
//  nnw
//
//  Created by Brent Simmons on 12/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SLViewControllerProtocols.h"


@interface NNWPreferencesGeneralViewController : NSViewController <SLFullContentViewControllerPlugin> {
@private
    NSButton *allowPluginsButton;
    NSButtonCell *allowPluginsButtonCell;
    NSButtonCell *openLinksButtonCell;
}


@property (nonatomic, strong) IBOutlet NSButton *allowPluginsButton;
@property (nonatomic, strong) IBOutlet NSButtonCell *allowPluginsButtonCell;
@property (nonatomic, strong) IBOutlet NSButtonCell *openLinksButtonCell;


- (IBAction)pluginsCheckboxClicked:(id)sender;

@end


