//
//  RSTree.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSTree.h"


@implementation RSTree

#pragma mark Attributes

- (BOOL)isGroup {
	return YES;
}


- (BOOL)isSpecialGroup {
	return NO;
}


- (RSTreeNode *)parent {
	return nil;
}


- (id<RSTreeNodeRepresentedObject>)representedObject {
	return nil;
}


@end
