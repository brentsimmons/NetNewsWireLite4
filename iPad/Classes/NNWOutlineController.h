//
//  NNWOutlineController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *NNWOutlineDidChangeNotification;

@class NNWProxy, NNWFolderProxy;

@interface NNWOutlineNode : NSObject <NSCoding> {
@private
	NNWProxy *_nnwProxy;
	NSMutableArray *_children;
	BOOL _isFolder;
	NSInteger _level;
}

- (id)initWithManagedObject:(NSManagedObject *)managedObject isFolder:(BOOL)isFolder level:(NSInteger)level;

@property (nonatomic, retain) NNWProxy *nnwProxy;
@property (nonatomic, assign) BOOL isFolder;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, retain, readonly) NSString *googleID;

- (BOOL)hasAtLeastOneUnreadItem;

@end

@interface NNWOutlineController : NSObject {
@private
	NSArray *_folders;
	NSMutableArray *_outline;
	NSMutableArray *_flattenedOutline;
	id _delegate;
}

@property (nonatomic, retain, readonly) NSMutableArray *outline;
@property (nonatomic, retain, readonly) NSMutableArray *flattenedOutline;
@property (nonatomic, assign) id delegate;

- (void)rebuildOutline:(NSArray *)feedsThatShouldAppear;
- (void)rebuildOutline:(NSArray *)feedIDsThatShouldAppear includeExcludedFeeds:(BOOL)includeExcludedFeeds;

- (NSInteger)numberOfObjects;
- (NNWProxy *)objectAtIndex:(NSInteger)index;
- (NSInteger)indentationLevelForIndex:(NSInteger)index;	

- (NSArray *)googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)folder;


@end


