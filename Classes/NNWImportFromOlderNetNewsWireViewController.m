//
//  NNWImportFromOlderNetNewsWireViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWImportFromOlderNetNewsWireViewController.h"


@implementation NNWImportFromOlderNetNewsWireViewController

#pragma mark Init

- (id)init {
    self = [self initWithNibName:@"ImportOPML" bundle:nil];
    if (self == nil)
        return nil;
    toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"ImportNetNewsWire"];
    [toolbarItem setLabel:NSLocalizedStringFromTable(@"Import Feeds from Older Version of NetNewsWire", @"AddFeeds", @"Item name")];
    return self;
}


#pragma mark Dealloc



#pragma mark Window Title

- (NSString *)windowTitle {
    return [toolbarItem label];
}


#pragma mark Toolbar Item

- (NSToolbarItem *)toolbarItem {
    return toolbarItem;
}


@end
