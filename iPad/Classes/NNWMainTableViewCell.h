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
	BOOL _highlighted;
	BOOL _selected;
	BOOL _isAlternate;
	NSInteger _indentationLevel;
	CGFloat _indentationWidth;
	id _delegate;
	NSDictionary *_representedObject;
	UIButton *_expandCollapseButton;
	NNWMainViewController *_mainViewController;
	BOOL _collapsed;
	BOOL hasFolderShadow;
	NSInteger disclosureHighlighted;
	BOOL expandable;
	NSInteger level;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, assign) BOOL isAlternate;
@property (nonatomic) NSInteger indentationLevel;
@property (nonatomic) CGFloat indentationWidth;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSDictionary *representedObject;
@property (nonatomic, assign) NNWMainViewController *mainViewController;
@property (nonatomic, assign) BOOL collapsed;
@property (nonatomic, assign) BOOL hasFolderShadow;
@property (nonatomic, assign) NSInteger disclosureHighlighted; // Multiple taps may cause multiple animations, hence integer
@property (nonatomic, assign) BOOL expandable;
@property (nonatomic, assign) NSInteger level;

- (void)incrementDisclosureHighlights;
- (void)decrementDisclosureHighlights;

@end



@interface NNWMainTableViewCell : UITableViewCell {
@private
	NNWMainTableCellContentView *_cellView;
}


@property (nonatomic, assign) BOOL expandable;
@property (nonatomic, assign) NSInteger level;

- (void)setHasFolderShadow:(BOOL)flag;
- (void)setRepresentedObject:(NSDictionary *)dict;
- (void)setMainViewController:(NNWMainViewController *)mainViewController;
- (void)setCollapsed:(BOOL)collapsed;

- (void)turnOffDisclosureHighlight;

@end
