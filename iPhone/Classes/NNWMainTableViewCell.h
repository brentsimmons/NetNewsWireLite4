//
//  NNWMainTableViewCell.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/14/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NNWMainViewController;

@interface NNWMainTableCellContentView : UIView {
@private
//	NSManagedObject *_managedObject;
	BOOL _highlighted;
	BOOL _isAlternate;
	NSInteger _indentationLevel;
	CGFloat _indentationWidth;
	id _delegate;
	NSDictionary *_representedObject;
	UIButton *_expandCollapseButton;
	NNWMainViewController *_mainViewController;
	BOOL _collapsed;
}

//@property (nonatomic, retain) NSManagedObject *managedObject;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL isAlternate;
@property (nonatomic) NSInteger indentationLevel;
@property (nonatomic) CGFloat indentationWidth;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSDictionary *representedObject;
@property (nonatomic, assign) NNWMainViewController *mainViewController;
@property (nonatomic, assign) BOOL collapsed;
@end



@interface NNWMainTableViewCell : UITableViewCell {
@private
	NNWMainTableCellContentView *_cellView;
}


//- (void)setManagedObject:(NSManagedObject *)obj;
- (void)setRepresentedObject:(NSDictionary *)dict;
- (void)setMainViewController:(NNWMainViewController *)mainViewController;
- (void)setCollapsed:(BOOL)collapsed;

@end
