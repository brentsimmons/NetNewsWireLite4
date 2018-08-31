//
//  RSTree.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSTreeNode.h"


/*Common code for managing a tree of objects.
 Each item in the tree is an RSTreeNode object.
 Each RSTreeNode object has a representedObject,
 which is a real model object (like a feed, for instance).
 
 This class has some things in common with NSTreeController,
 but it works on iOS too, and it gives us more control.
 (NSTreeController is a bit too magical still.)
 
 This is the root of the tree -- all top-level objects are children
 of this node. (Yes, the tree itself is an RSTreeNode subclass.)
 
 So -- see RSTreeNode for setting the content of the tree,
 for setting children and all that.
 
 Ideally, this will be used only on the main thread, so locking won't be necessary.
 (It's not thread-safe.)
 */



@interface RSTree : RSTreeNode


@end
