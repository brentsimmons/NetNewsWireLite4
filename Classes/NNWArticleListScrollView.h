//
//  NNWArticleListScrollView.h
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*This is modeled after UITableView.*/

@protocol NNWArticleListDelegate <NSObject>

@required

- (NSView *)listView:(id)listView viewForRow:(NSUInteger)row;
- (CGFloat)listView:(id)listView heightForRow:(NSUInteger)row;
- (NSUInteger)numberOfRowsInListView:(id)listView;

@optional
- (BOOL)listView:(id)listView shouldSelectRow:(NSUInteger)row;
- (void)listViewSelectionDidChange:(id)listView;
- (id)itemInListView:(id)listView atRow:(NSUInteger)row;
- (void)listView:(id)listView rowWasDoubleClicked:(NSUInteger)row;
- (void)listViewUserDidSwipeRight:(id)listView;

@end


#pragma mark -


@protocol NNWArticleListRowView <NSObject>

@required
- (NSString *)reuseIdentifier;
- (void)prepareForReuse;

@property (nonatomic, assign) BOOL selected;

@end


#pragma mark -


@interface NNWArticleListScrollView : NSScrollView {
@private
    CGFloat *cachedViewYOrigins;
    NSMutableArray *enqueuedViews;
    NSMutableArray *visibleViews;
    NSMutableDictionary *rowToViewMap;
    NSUInteger numberOfRows;
    NSIndexSet *selectedRowIndexes;
    CGFloat heightOfAllRows;
    NSUInteger indexOfFirstVisibleRow;
    id<NNWArticleListDelegate> __unsafe_unretained delegate;
    BOOL selected;
}


@property (nonatomic, unsafe_unretained) IBOutlet id<NNWArticleListDelegate> delegate;
@property (nonatomic, strong, readonly) NSIndexSet *selectedRowIndexes;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) CGFloat heightOfAllRows;

- (NSView<NNWArticleListRowView> *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (void)reloadData;
- (void)reloadDataWithoutResettingSelectedRowIndexes;

- (void)selectTopRow;
- (void)selectTopRowIfNoneSelected;
- (BOOL)selectRow:(NSUInteger)aRow;
- (void)selectRow:(NSUInteger)aRow scrollToVisibleIfNeeded:(BOOL)scrollToVisibleIfNeeded;

- (void)scrollRowToVisible:(NSUInteger)row;
- (BOOL)scrollRowToMiddleIfNotVisible:(NSUInteger)row; //returns YES if view visible, NO if had to scroll

@end
