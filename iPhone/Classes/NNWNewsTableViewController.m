//
//  NNWNewsTableViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWNewsTableViewController.h"
#import "NNWAdView.h"
#import "NNWAdView.h"
#import "NNWAppDelegate.h"
#import "NNWFeed.h"
#import "NNWFeedProxy.h"
#import "NNWFolder.h"
#import "NNWFolderProxy.h"
#import "NNWTableViewCell.h"
#import "NNWWebPageViewController.h"


NSString *NNWNewsItemsListDidFetchNotification = @"NNWNewsItemsListDidFetchNotification";

@interface NNWSectionInfo : NSObject {
@private
	NSString *_title;
	NSMutableArray *_newsItemProxies;
}
+ (NNWSectionInfo *)sectionInfoWithTitle:(NSString *)title;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *newsItemProxies;
@end

@implementation NNWSectionInfo
@synthesize title = _title, newsItemProxies = _newsItemProxies;
+ (NNWSectionInfo *)sectionInfoWithTitle:(NSString *)title {
	NNWSectionInfo *sectionInfo = [[[NNWSectionInfo alloc] init] autorelease];
	sectionInfo.title = title;
	sectionInfo.newsItemProxies = [NSMutableArray array];
	return sectionInfo;
}
- (void)dealloc {
	[_title release];
	[_newsItemProxies release];
	[super dealloc];
}
@end

@interface NNWNewsTableViewController ()
- (NSFetchRequest *)createFetchRequest;
@property (nonatomic, retain) NSArray *sections;
@property (retain, readwrite) NSArray *newsItemProxies;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NNWAdView *adView;
@end


@implementation NNWNewsTableViewController

@synthesize fetchedResultsController = _fetchedResultsController, delegate = _delegate;
@synthesize nnwProxy = _nnwProxy, googleIDsOfDescendants = _googleIDsOfDescendants;
@synthesize sections = _sections, newsItemProxies = _newsItemProxies, adView = _adView;
@synthesize stateRestoredNewsItemProxy = _stateRestoredNewsItemProxy;

#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_nnwProxy release];
	[_fetchedResultsController release];
	[_googleIDsOfDescendants release];
	[_sections release];
	[_newsItemProxies release];
	[_adView release];
	[_stateRestoredNewsItemProxy release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)viewDidLoad {
	self.tableView.rowHeight = 90;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.tableView.separatorColor = [UIColor colorWithWhite:0.96 alpha:1.0];
	if (!self.sections)
		self.sections = [NSMutableArray array];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAdTouched:) name:NNWAdTouchedNotification object:nil];

#if ADS
	NSInteger adViewHeight = [NNWAdView adViewHeight];
	CGRect rTableView = self.tableView.frame;
	CGRect rAdView = CGRectMake(0, 0, rTableView.size.width, adViewHeight);
	self.adView = [NNWAdView adViewWithFrameIfConnected:rAdView];
	self.tableView.tableHeaderView = self.adView;
#endif
}


//- (void)viewDidUnload {
//	NSLog(@"newstable viewDidUnload");
//}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if (self.tableView.tableHeaderView) {
		[self.tableView.tableHeaderView setNeedsLayout];
		[self.tableView.tableHeaderView setNeedsDisplay];
	}
}


#pragma mark Unreads

- (BOOL)hasUnreadItems {
	for (NNWNewsItemProxy *oneNewsItemProxy in self.newsItemProxies) {
		if (!oneNewsItemProxy.read)
			return YES;
	}
	return NO;
}


#pragma mark Notifications

- (void)handleAdTouched:(NSNotification *)note {
	if ([note object] != self.adView)
		return;
	NSString *urlString = [[note userInfo] objectForKey:@"urlString"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	NNWWebPageViewController *webPageViewController = [[[NNWWebPageViewController alloc] initWithURLRequest:request] autorelease];
	[webPageViewController loadHTML];
	[[(UIViewController *)_delegate navigationController] pushViewController:webPageViewController animated:YES];
}



#pragma mark Core Data

- (void)runFetch {
	[self performSelector:@selector(runFetchOnBackgoundThread) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:NO];
}


- (void)runFetchIfNeeded {
	if (RSIsEmpty(self.newsItemProxies))
		[self runFetch];
}


- (void)fetchNewsItemsInBackgroundAndWait {
	[self performSelector:@selector(runFetchOnBackgoundThread) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:YES];
}


- (NNWSectionInfo *)ensureSectionInfoForTitle:(NSString *)title inSectionsArray:(NSMutableArray *)sections {
	/*Adds it to the array in case it doesn't exist*/
	for (NNWSectionInfo *oneSectionInfo in sections) {
		if ([oneSectionInfo.title isEqualToString:title])
			return oneSectionInfo;
	}
	NNWSectionInfo *sectionInfo = [NNWSectionInfo sectionInfoWithTitle:title];
	[sections addObject:sectionInfo];
	return sectionInfo;
}


- (NSArray *)buildSectionsWithNewsItemProxies:(NSArray *)newsItemProxies {
	/*newsItemProxies are already sorted in order, which tells how to sort the sections*/
	NSMutableArray *sections = [NSMutableArray array];
	for (NNWNewsItemProxy *oneNewsItemProxy in newsItemProxies) {
		NNWSectionInfo *section = [self ensureSectionInfoForTitle:oneNewsItemProxy.displaySectionName inSectionsArray:sections];
		[section.newsItemProxies addObject:oneNewsItemProxy];
	}
	return sections;
}


- (void)postDidFetchNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWNewsItemsListDidFetchNotification object:nil];
}


- (void)runFetchOnBackgoundThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	EXCEPTION_START
		NSFetchRequest *fetchRequest = [self createFetchRequest];
		if (fetchRequest) {
			NSError *error = nil;
			NSArray *newsItemDictionaries = [app_delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
			NSMutableArray *newsItemProxies = [NSMutableArray array];
			NSString *stateRestoredGoogleID = self.stateRestoredNewsItemProxy.googleID;
			for (NSDictionary *oneNewsItemDict in newsItemDictionaries) {
				if (stateRestoredGoogleID && [stateRestoredGoogleID isEqualToString:[oneNewsItemDict objectForKey:RSDataGoogleID]])
					[newsItemProxies safeAddObject:self.stateRestoredNewsItemProxy];
				else
					[newsItemProxies safeAddObject:[NNWNewsItemProxy newsItemProxyWithDictionary:oneNewsItemDict]];				
			}
			NSArray *sections = [self buildSectionsWithNewsItemProxies:newsItemProxies];
			self.newsItemProxies = newsItemProxies;
			[self performSelectorOnMainThread:@selector(reloadTable:) withObject:sections waitUntilDone:NO];
			[self performSelectorOnMainThread:@selector(postDidFetchNotification) withObject:nil waitUntilDone:NO];
		}
	EXCEPTION_END
	CATCH_EXCEPTION
	[pool release];
}


- (NSFetchRequest *)createFetchRequest {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:RSDataEntityNewsItem inManagedObjectContext:app_delegate.managedObjectContext]];
	[request setResultType:NSDictionaryResultType];
	static NSArray *propertiesToFetch = nil;
	if (!propertiesToFetch)
#if THUMBNAILS
		propertiesToFetch = [[NSArray alloc] initWithObjects:RSDataGoogleID, RSDataGoogleFeedID, RSDataGoogleFeedTitle, RSDataAudioURL, RSDataMovieURL, RSDataDatePublished, RSDataPlainTextTitle, RSDataPreview, RSDataRead, RSDataPermalink, RSDataStarred, nil];
#else
	propertiesToFetch = [[NSArray alloc] initWithObjects:RSDataGoogleID, RSDataGoogleFeedID, RSDataGoogleFeedTitle, /*RSDataAudioURL, RSDataMovieURL,*/ RSDataDatePublished, RSDataPlainTextTitle, RSDataPreview, RSDataRead, RSDataPermalink, RSDataStarred, nil];
#endif
	[request setPropertiesToFetch:propertiesToFetch];
	[request setFetchLimit:1000];
	NSPredicate *predicate = ((NNWFeedProxy *)(self.nnwProxy)).predicateForFetchRequest;
	if (!predicate) {
		NSString *googleFeedID = [self.nnwProxy.googleID copy]; /*Something about the source coming from a dictionary fetch request seems to mean we have to do this. Weird.*/
		predicate = [NSPredicate predicateWithFormat:@"googleFeedID == %@", googleFeedID];
		[googleFeedID release];
	}
	[request setPredicate:predicate];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:RSDataDatePublished ascending:app_delegate.sortNewsItemsAscending];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	return request;
}


#pragma mark Table view methods

- (void)reloadTable:(NSArray *)sections {
	NSMutableArray *allNewsItemProxies = [NSMutableArray array];
	for (NNWSectionInfo *oneSectionInfo in sections)
		[allNewsItemProxies addObjectsFromArray:oneSectionInfo.newsItemProxies];
	self.newsItemProxies = allNewsItemProxies;
	self.sections = sections;
	[self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.sections count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NNWSectionInfo *sectionInfo = [self.sections safeObjectAtIndex:section];
	if (!sectionInfo)
		return nil;
	return sectionInfo.title;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NNWSectionInfo *sectionInfo = [self.sections safeObjectAtIndex:section];
	if (!sectionInfo)
		return 0;
	return [sectionInfo.newsItemProxies count];
}


- (NNWNewsItemProxy *)newsItemProxyAtIndexPath:(NSIndexPath *)indexPath {
	NNWSectionInfo *sectionInfo = [self.sections safeObjectAtIndex:indexPath.section];
	if (!sectionInfo)
		return nil;
	return [sectionInfo.newsItemProxies safeObjectAtIndex:indexPath.row];
}


NSString *NNWNewsListCell = @"NNWNewsListCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NNWTableViewCell *cell = (NNWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NNWNewsListCell];
    if (!cell)
        cell = [[[NNWTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NNWNewsListCell] autorelease];
	NNWNewsItemProxy *newsItemProxy = [self newsItemProxyAtIndexPath:indexPath];
	NSInteger absoluteIndex = [self.newsItemProxies indexOfObjectIdenticalTo:newsItemProxy];
	[cell setIsAlternate:(absoluteIndex % 2) == 1];
	[cell setNewsItemProxy:[self newsItemProxyAtIndexPath:indexPath]];
	[cell setNeedsDisplay];
    return cell;
}


- (void)callDelegateDidSelectNewsItem:(NNWNewsItemProxy *)newsItemProxy {
	[_delegate performSelector:@selector(tableViewController:didSelectNewsItem:) withObject:self withObject:newsItemProxy];	
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([_delegate respondsToSelector:@selector(tableViewController:didSelectNewsItem:)])
		[self performSelectorOnMainThread:@selector(callDelegateDidSelectNewsItem:) withObject:[self newsItemProxyAtIndexPath:indexPath] waitUntilDone:NO];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[app_delegate sendBigUIStartNotification];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate)
		[app_delegate sendBigUIEndNotification];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[app_delegate sendBigUIEndNotification];
}


@end

