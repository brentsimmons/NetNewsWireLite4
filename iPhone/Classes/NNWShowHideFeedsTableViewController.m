//
//  NNWShowHideFeedsTableViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 9/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWShowHideFeedsTableViewController.h"
#import "NNWAppDelegate.h"
#import "NNWFavicon.h"
#import "NNWFeed.h"


@interface NNWShowHideFeedProxy : NSObject {
	@private
	NSString *_googleID;
	BOOL _userExcludes;
	BOOL _originalUserExcludes;
	NSString *_title;
}

@property (nonatomic, retain) NSString *googleID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, assign) BOOL userExcludes;
@property (nonatomic, assign) BOOL originalUserExcludes;
@end

@implementation NNWShowHideFeedProxy

@synthesize googleID = _googleID, title = _title, userExcludes = _userExcludes, originalUserExcludes = _originalUserExcludes;

+ (NNWShowHideFeedProxy *)showHideFeedProxyWithManagedObject:(NSManagedObject *)managedObject {
	NNWShowHideFeedProxy *feedProxy = [[[NNWShowHideFeedProxy alloc] init] autorelease];
	feedProxy.googleID = [managedObject valueForKey:RSDataGoogleID];
	feedProxy.title = [managedObject valueForKey:RSDataTitle];
	feedProxy.userExcludes = [[managedObject valueForKey:RSDataUserExcludes] boolValue];
	feedProxy.originalUserExcludes = [[managedObject valueForKey:RSDataUserExcludes] boolValue];
	return feedProxy;
}


- (void)dealloc {
	[_googleID release];
	[_title release];
	[super dealloc];
}

@end

@interface NNWInstructionsBackgroundView : UIView
@end

@implementation NNWInstructionsBackgroundView
//- (UIImage *)gradientBackgroundImage {
//	static UIImage *backgroundImage = nil;
//	if (backgroundImage)
//		return backgroundImage;
//	backgroundImage = [[UIImage gradientImageWithStartColor:[[UIColor colorWithRed:0.183 green:0.311 blue:0.525 alpha:1.000] lightened] endColor:[UIColor colorWithRed:0.183 green:0.311 blue:0.525 alpha:1.000] topLineColor:[[[UIColor colorWithRed:0.183 green:0.311 blue:0.525 alpha:1.000] lightened] lightened] size:self.bounds.size] retain];
//	return backgroundImage;			
//}
//- (void)drawRect:(CGRect)r {
//	[super drawRect:r];
////	[[self gradientBackgroundImage] drawInRect:self.bounds];
//	CGContextRef context = UIGraphicsGetCurrentContext();
//	CGContextBeginPath(context);
//	CGContextSetLineWidth(context, 1.0);
//	CGContextMoveToPoint(context, CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - 0.5);
//	CGContextAddLineToPoint(context, CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) - 0.5);
//	CGContextClosePath(context);
//	[[UIColor darkGrayColor] set];
//	[[UIColor colorWithWhite:0.55 alpha:1.0] set];
//	CGContextStrokePath(context);
//}
@end

@interface NNWShowHideFeedsTableViewController ()
@property (nonatomic, retain) NSArray *feedProxies;
@end

@implementation NNWShowHideFeedsTableViewController

@synthesize feedProxies = _feedProxies;


#pragma mark Class Methods

+ (NNWShowHideFeedsTableViewController *)showHideFeedsTableViewController {
	return [[[NNWShowHideFeedsTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
}


#pragma mark Dealloc

- (void)dealloc {
	[_feedProxies release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)viewDidLoad {
	self.title = @"Show/Hide Feeds";
	self.navigationController.toolbarHidden = YES;
	self.tableView.rowHeight = 48;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	UILabel *instructionsView = [[[UILabel alloc] initWithFrame:CGRectMake(12, 0, 320 - 24, 70)] autorelease];
	instructionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	instructionsView.text = @"Feeds with checkmarks will be shown.\nTo hide a feed, tap it to remove the checkmark.";
	instructionsView.backgroundColor = [UIColor clearColor];//[UIColor slateBlueColor];
	instructionsView.textColor = [UIColor whiteColor];
	instructionsView.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
//	instructionsView.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
//	instructionsView.shadowOffset = CGSizeMake(0, 1);
	instructionsView.font = [UIFont systemFontOfSize:14.0];
	instructionsView.numberOfLines = 0;
	instructionsView.contentMode = UIViewContentModeRedraw;
	//UIView *instructionsBackgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)] autorelease];
	NNWInstructionsBackgroundView *instructionsBackgroundView = [[[NNWInstructionsBackgroundView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)] autorelease];
	instructionsBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	instructionsBackgroundView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
	[instructionsBackgroundView addSubview:instructionsView];
	self.tableView.tableHeaderView = instructionsBackgroundView;
	[self performSelector:@selector(fetchFeeds) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:NO];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NSMutableArray *feedsToHide = [NSMutableArray array];
	NSMutableArray *feedsToShow = [NSMutableArray array];
	for (NNWShowHideFeedProxy *oneFeedProxy in self.feedProxies) {
		if (oneFeedProxy.userExcludes && !oneFeedProxy.originalUserExcludes)
			[feedsToHide safeAddObject:oneFeedProxy.googleID];
		if (!oneFeedProxy.userExcludes && oneFeedProxy.originalUserExcludes)
			[feedsToShow safeAddObject:oneFeedProxy.googleID];
	}
	NSMutableDictionary *showHideChangesDict = [NSMutableDictionary dictionary];
	[showHideChangesDict setObject:feedsToHide forKey:@"feedsToHide"];
	[showHideChangesDict setObject:feedsToShow forKey:@"feedsToShow"];
	[NNWFeed performSelector:@selector(showAndHideFeeds:) onThread:app_delegate.coreDataThread withObject:showHideChangesDict waitUntilDone:NO];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return RSIsEmpty(self.feedProxies) ? 0 : [self.feedProxies count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ShowHideFeedsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }

	NNWShowHideFeedProxy *feedProxy = [self.feedProxies objectAtIndex:indexPath.row];
	BOOL userExcludes = feedProxy.userExcludes;
	cell.textLabel.text = feedProxy.title;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
	cell.textLabel.shadowColor = userExcludes ? nil : [UIColor colorWithWhite:0.3 alpha:0.1];
	cell.textLabel.shadowOffset = userExcludes ? CGSizeMake(0, 0) :  CGSizeMake(0, 1);
	cell.textLabel.textColor = userExcludes ? [UIColor slateBlueColor] : [UIColor blackColor];
	cell.accessoryType = userExcludes ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	UIImage *favicon = [NNWFavicon imageForFeedWithGoogleID:feedProxy.googleID];
	cell.imageView.image = favicon;
	cell.imageView.alpha = userExcludes ? 0.3 : 1.0;
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NNWShowHideFeedProxy *feedProxy = [self.feedProxies objectAtIndex:indexPath.row];
	feedProxy.userExcludes = !feedProxy.userExcludes;
	[self.tableView reloadData];
}


#pragma mark Feeds

- (void)fetchFeeds {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	EXCEPTION_START
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:[NSEntityDescription entityForName:RSDataEntityFeed inManagedObjectContext:app_delegate.managedObjectContext]];
		NSError *error = nil;
		NSArray *sortDescriptors = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:RSDataTitle ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease]];
		[request setSortDescriptors:sortDescriptors];
		NSArray *result = [app_delegate.managedObjectContext executeFetchRequest:request error:&error];
		NSMutableArray *feedProxies = [NSMutableArray array];
		for (NSManagedObject *oneManagedObject in result)
			[feedProxies addObject:[NNWShowHideFeedProxy showHideFeedProxyWithManagedObject:oneManagedObject]];
		self.feedProxies = feedProxies;
		[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	EXCEPTION_END
	CATCH_EXCEPTION
	[pool drain];
}


@end

