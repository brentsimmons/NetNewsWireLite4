//
//  NNWRightPaneContainerView.m
//  nnw
//
//  Created by Brent Simmons on 1/19/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWRightPaneContainerView.h"


@interface NNWRightPaneContainerView ()

@property (nonatomic, strong) NSMutableArray *viewStack;
@property (nonatomic, strong, readonly) NSImageView *screenshotViewForAnimation;

- (void)animateOutView:(NSView *)aView;
- (void)animateInView:(NSView *)aView;

@end


@implementation NNWRightPaneContainerView

@synthesize viewStack;
@synthesize screenshotViewForAnimation;
@synthesize rightPaneSplitView;


#pragma mark Init

- (void)commonInit {
    viewStack = [NSMutableArray array];
}


- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self == nil)
        return nil;
    [self commonInit];
    return self;
}


- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self == nil)
        return nil;
    [self commonInit];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark AwakeFromNib

- (void)awakeFromNib {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:NSApp];
    NSNumber *splitViewLeftSubviewPercentageNum = [[NSUserDefaults standardUserDefaults] objectForKey:NNWRightPaneSplitViewPercentageKey];
    if (splitViewLeftSubviewPercentageNum != nil) {
        float leftSubviewPercentage = [splitViewLeftSubviewPercentageNum floatValue];
        if (leftSubviewPercentage > 0.05) { //if so small, assume not intentional
            CGFloat splitViewWidth = [self.rightPaneSplitView bounds].size.width;
            CGFloat widthOfLeftPane = ceil(splitViewWidth * leftSubviewPercentage);
            //CGFloat widthOfRightPane = (splitViewWidth - widthOfLeftPane) - [self.rightPaneSplitView dividerThickness];
            NSView *leftPaneView = [[self.rightPaneSplitView subviews] objectAtIndex:0];
            //NSView *rightPaneView = [[self.rightPaneSplitView subviews] objectAtIndex:1];
            NSRect rLeftPane = [leftPaneView frame];
            rLeftPane.size.width = widthOfLeftPane;
//            NSRect rRightPane = [leftPaneView frame];
//            rRightPane.size.width = 
            [leftPaneView setFrame:rLeftPane];            
        }
    }
}


#pragma mark Saving SplitView position

- (void)applicationWillTerminate:(NSNotification *)note {
    CGFloat splitViewWidth = [self.rightPaneSplitView bounds].size.width;
    if (splitViewWidth < 1.0f)
        return;
    NSView *leftPaneView = [[self.rightPaneSplitView subviews] objectAtIndex:0];
    CGFloat widthOfLeftPane = [leftPaneView frame].size.width;
    if (widthOfLeftPane < 1.0f)
        return;
    CGFloat leftPanePercentage = widthOfLeftPane / splitViewWidth;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:(float)leftPanePercentage] forKey:NNWRightPaneSplitViewPercentageKey];
}


#pragma mark Actions

- (void)closeSubview:(id)sender {
    [self popView];
}


#pragma mark API

- (NSView *)readerView { /*list plus article*/
    return [self rs_firstSubviewOfClass:[NSSplitView class]];
}


- (NSView *)topView { /*either reader view or top pushed view*/
    NSView *aView = [self.viewStack lastObject];
    if (aView != nil)
        return aView;
    return [self readerView];
}


- (void)pushViewOnTop:(NSView *)aView {
    [self animateInView:aView];
//    [[self topView] setHidden:YES];
    [self.viewStack addObject:aView];
//    [aView setFrame:[self bounds]];
//    [self addSubview:aView positioned:NSWindowAbove relativeTo:[self topView]];
    [aView setNextResponder:self];
}


- (void)popViewWithAnimation:(BOOL)animated {
    NSView *aView = [self.viewStack lastObject];
    [self.viewStack removeLastObject];
    [[self topView] setHidden:NO];
    [[self topView] setNextResponder:self];
    if (animated)
        [self animateOutView:aView];
    else
        [aView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSOverlayViewWasPoppedNotification object:self userInfo:[NSDictionary dictionaryWithObject:aView forKey:NNWViewKey]];    
}


- (void)popView {
    [self popViewWithAnimation:YES];
}


- (void)popAllViews {
    if (RSIsEmpty(self.viewStack))
        return;
    if ([self.viewStack count] == 1) {
        [self popView];
        return;
    }
    while ([self.viewStack count] > 0)
        [self popViewWithAnimation:NO];
}


- (BOOL)hasPushedView {
    return !RSIsEmpty(self.viewStack);
}


#pragma mark Animation

static const CGFloat animationDuration = 0.25f;
static const CGFloat delayBeforeRemovingTemporaryView = 0.26f;


- (void)animateScreenshotViewToZeroAlpha {
    
    [self.screenshotViewForAnimation setFrame:[self bounds]];
    [self.screenshotViewForAnimation setHidden:NO];
    [self.screenshotViewForAnimation setAlphaValue:1.0f];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:animationDuration];
    [[self.screenshotViewForAnimation animator] setAlphaValue:0.0f];
    [self performSelector:@selector(hideScreenshotView) withObject:nil afterDelay:delayBeforeRemovingTemporaryView];
    [NSAnimationContext endGrouping];    
}


- (NSImageView *)screenshotViewForAnimation {
    if (screenshotViewForAnimation == nil)
        screenshotViewForAnimation = [[NSImageView alloc] initWithFrame:[self bounds]];
    return screenshotViewForAnimation;
}


- (NSImage *)screenshotOfView:(NSView *)aView {
    
    [aView lockFocus];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[self bounds]];    
    [aView unlockFocus];
    
    NSImage *screenshot = [[NSImage alloc] initWithSize:[self bounds].size];
    [screenshot lockFocus];
    [bitmap draw];
    [screenshot unlockFocus];
    
    return screenshot;
}


- (void)animateOutView:(NSView *)aView {
    
    [self.screenshotViewForAnimation setImage:[self screenshotOfView:aView]];
    [aView removeFromSuperview];
    [self.screenshotViewForAnimation removeFromSuperview];
    [self addSubview:self.screenshotViewForAnimation positioned:NSWindowAbove relativeTo:[self topView]];
    [self animateScreenshotViewToZeroAlpha];
}

- (void)removeView:(NSView *)aView {
    [aView removeFromSuperview];
}


- (void)hideScreenshotView {
    [self.screenshotViewForAnimation setHidden:YES];
    [self.screenshotViewForAnimation setImage:nil];
}


- (void)animateInView:(NSView *)aView {
    if (![self.screenshotViewForAnimation isDescendantOf:self])
        [self addSubview:self.screenshotViewForAnimation];
    [self.screenshotViewForAnimation setImage:[self screenshotOfView:[self topView]]];
    
    [[self topView] setHidden:YES];
    
    [self addSubview:aView positioned:NSWindowBelow relativeTo:self.screenshotViewForAnimation];
    [aView setFrame:[self bounds]];
    
    [self animateScreenshotViewToZeroAlpha];
}


#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect rBounds = [self bounds];
    for (NSView *oneView in [self subviews])
        [oneView setFrame:rBounds];
}


#pragma mark Drawing

- (BOOL)isOpaque {
    return YES;
}


- (void)drawRect:(NSRect)r {
    RSCGRectFillWithWhite(r);
}


@end
