//
//  NNWLastUpdateContainerView.m
//  nnwipad
//
//  Created by Brent Simmons on 3/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWLastUpdateContainerView.h"
#import "NNWRefreshController.h"


@interface NNWLastUpdateContainerView ()
@property (nonatomic, retain) UILabel *refreshLabel;
@property (nonatomic, assign) CGSize refreshLabelSize;
@property (nonatomic, retain) UILabel *dateLabel;
@property (nonatomic, retain) NSDate *lastUpdateDate;
@property (nonatomic, retain, readonly) NSString *lastUpdateKeyPath;
@property (nonatomic, assign) CGFloat dateLabelTextWidth;
@end

@implementation NNWLastUpdateContainerView

@synthesize refreshLabel, refreshLabelSize, dateLabel, dateLabelTextWidth;
@synthesize lastUpdateDate, lastUpdateKeyPath;

#pragma mark Init

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	lastUpdateDate = [[[NSUserDefaults standardUserDefaults] objectForKey:NNWLastRefreshDateKey] retain];
	lastUpdateKeyPath = [[NSString stringWithFormat:@"values.%@", NNWLastRefreshDateKey] retain];
	displayDateFormatter = [[NSDateFormatter alloc] init];
	[displayDateFormatter setDateStyle:kCFDateFormatterShortStyle];
	[displayDateFormatter setTimeStyle:kCFDateFormatterShortStyle];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSessionDidEnd:) name:NNWRefreshSessionDidEndNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[refreshLabel release];
	[dateLabel release];
	[lastUpdateDate release];
	[lastUpdateKeyPath release];
	[displayDateFormatter release];
    [super dealloc];
}


#pragma mark Subviews

static const CGFloat labelFontSize = 14.0f;

- (UILabel *)createLabel {
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	label.userInteractionEnabled = NO;
	label.adjustsFontSizeToFitWidth = NO;
	label.shadowOffset = CGSizeMake(0, -1);
	label.shadowColor = [UIColor colorWithWhite:0.2 alpha:0.4];
	label.autoresizingMask = UIViewAutoresizingNone;
	label.numberOfLines = 1;
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.font = [UIFont systemFontOfSize:labelFontSize];
	label.textAlignment = UITextAlignmentLeft;
	label.lineBreakMode = UILineBreakModeTailTruncation;
	return label;
}


static NSString *NNWRefreshLabelTitle = @"Updated:";

- (void)createRefreshLabel {
	self.refreshLabel = [self createLabel];
	self.refreshLabel.font = [UIFont boldSystemFontOfSize:labelFontSize];
	[self addSubview:self.refreshLabel];
	self.refreshLabel.text = NNWRefreshLabelTitle;
	self.refreshLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	//self.refreshLabel.backgroundColor = [UIColor greenColor];
	self.refreshLabel.textAlignment = UITextAlignmentRight;
	[self.refreshLabel sizeToFit];
	self.refreshLabelSize = self.refreshLabel.frame.size;
}


- (void)updateLabelText {
	if (self.lastUpdateDate == nil) {
		self.dateLabel.text = RSEmptyString;
		self.refreshLabel.text = RSEmptyString;
		self.dateLabelTextWidth = 0;
		return;
	}
	self.refreshLabel.text = NNWRefreshLabelTitle;
	self.dateLabel.text = [displayDateFormatter stringFromDate:self.lastUpdateDate];
	[self.dateLabel sizeToFit];
	self.dateLabelTextWidth = [self.dateLabel.text sizeWithFont:self.dateLabel.font].width;
}


- (void)createDateLabel {
	self.dateLabel = [self createLabel];
	//self.dateLabel.backgroundColor = [UIColor redColor];
	[self addSubview:self.dateLabel];
	[self updateLabelText];
}


#pragma mark UIView

- (CGRect)refreshLabelRect {
	CGRect r = self.refreshLabel.frame;
	r.origin = CGPointZero;
	return r;
}


static const CGFloat kLabelSeparationWidth = 4.0f;

- (CGRect)dateLabelRect {
	CGRect r = self.dateLabel.frame;
	r.origin.x = self.refreshLabelSize.width + kLabelSeparationWidth;
	r.origin.y = 0;
//	r.size.width = CGRectGetWidth(self.bounds) - r.origin.x;
	r.size.width = self.dateLabelTextWidth;
	r.size.height = self.refreshLabelSize.height;
	return r;	
}


- (void)layoutSubviews {
	if (self.refreshLabel == nil)
		[self createRefreshLabel];
	if (self.dateLabel == nil)
		[self createDateLabel];
	CGRect rRefreshLabel = [self refreshLabelRect];
	CGRect rDateLabel = [self dateLabelRect];
//	self.refreshLabel.frame = rRefreshLabel;
//	self.dateLabel.frame = rDateLabel;
	/*Make the whole thing appear to be centered in the containing toolbar*/
	CGFloat totalWidth = rRefreshLabel.size.width + kLabelSeparationWidth + rDateLabel.size.width;
	CGFloat toolbarX = (320 / 2) - (totalWidth / 2.0f);
	CGRect rFrame = self.frame;
	CGFloat containerX = toolbarX - rFrame.origin.x;
	rRefreshLabel.origin.x = containerX;
	rDateLabel.origin.x = CGRectGetMaxX(rRefreshLabel) + kLabelSeparationWidth;
	self.refreshLabel.frame = CGRectIntegral(rRefreshLabel);
	self.dateLabel.frame = CGRectIntegral(rDateLabel);
}


#pragma mark Accessors

- (void)setLastUpdateDate:(NSDate *)aDate {
	[lastUpdateDate autorelease];
	lastUpdateDate = [aDate retain];
	[self updateLabelText];
}


#pragma mark Notifications

- (void)refreshSessionDidEnd:(NSNotification *)note {
	self.lastUpdateDate = [[NSUserDefaults standardUserDefaults] objectForKey:NNWLastRefreshDateKey];
}

@end
