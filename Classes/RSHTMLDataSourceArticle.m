//
//  RSHTMLDataSourceArticle.m
//  nnw
//
//  Created by Brent Simmons on 12/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSHTMLDataSourceArticle.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSDataArticleContent.h"
#import "RSDataController.h"
#import "RSFaviconController.h"
#import "RSFeed.h"


static void NNWHTMLAddSpanToString(NSMutableString *s, NSString *value, NSString *cssClassName);
static void NNWHTMLAddSpanToStringWithTitle(NSMutableString *s, NSString *value, NSString *cssClassName, NSString *title);
static NSString *NNWHTMLSourceLink(NSString *feedHomePageURLString, NSString *feedNameForDisplay, NSURL *faviconURL);
static NSString *NNWAuthorHTML(RSDataArticle *anArticle);

@interface RSHTMLDataSourceArticle ()

@property (nonatomic, retain) RSDataArticle *article;
@property (nonatomic, retain, readonly) RSDataController *dataController;
@end


@implementation RSHTMLDataSourceArticle

@synthesize article;

#pragma mark Init

- (id)initWithArticle:(RSDataArticle *)anArticle {
	self = [super init];
	if (self == nil)
		return nil;
	article = [anArticle retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[article release];
	[super dealloc];
}


#pragma mark Macros

- (NSString *)newsitem_title {
	if (self.article == nil)
		return @"";
	NSString *title = nil;
	NSString *link = nil;
	[self.article bestSharingTitle:&title andLink:&link];
	if (RSStringIsEmpty(link))
		return title;
	return [NSString stringWithFormat:@"<a href=%@>%@</a>", link, title];
}


static NSString *NNWHTMLDateClassName = @"newsItemDate";
static NSString *NNWHTMLCreatorClassName = @"newsItemCreator";

- (NSString *)newsitem_dateline {
	
	if (self.article == nil)
		return @"";
	NSMutableString *s = [NSMutableString stringWithString:@""];
	//NNWHTMLAddSpanToString(s, NNWHTMLSourceLink(self.article.feedHome, combinedView ? NNWHTMLCVSourceClassName : NNWHTMLSourceClassName);
	
//	NSDate *date = [self.article bestDate];
	NSDate *date = self.article.dateForDisplay;
	NSString *shortDateString = [date rs_shortDateAndTimeString];
	NNWHTMLAddSpanToStringWithTitle(s, shortDateString, NNWHTMLDateClassName, [date rs_isoString]);
	
	NNWHTMLAddSpanToString(s, NNWAuthorHTML(self.article), NNWHTMLCreatorClassName);
//	NNWHTMLAddSpanToString(s, [dataItem categoriesAsString], combinedView ? NNWHTMLCVSubjectClassName : NNWHTMLSubjectClassName);
//	
//	NSString *commentsURL = [dataItem commentsURL];	
//	if (!RSIsEmpty(commentsURL))
//		NNWHTMLAddSpanToString(s, RSStringCreateLink(NNW_COMMENTS, commentsURL), combinedView ? NNWHTMLCVCommentsClassName : NNWHTMLCommentsClassName);
	
	return s;
}


- (NSString *)newsitem_description {
	if (self.article == nil)
		return @"";
	return self.article.content.htmlText ? self.article.content.htmlText : @"";
}


- (NSString *)newsitem_extralinks {
	return @"";
}


- (RSDataController *)dataController {
	return rs_app_delegate.dataController;
}


- (NSString *)faviconURLForFeed:(RSFeed *)aFeed {
	if (self.article == nil)
		return @"";
	return [[RSFaviconController sharedController] filenameForFavicon:aFeed.homePageURL faviconURL:aFeed.faviconURL];	
}


- (NSString *)faviconLinkForFeed:(RSFeed *)aFeed {
	if (self.article == nil)
		return @"";
	if (aFeed.homePageURL == nil)
		return @"";
	NSString *faviconURL = [self faviconURLForFeed:aFeed];
	if (faviconURL == nil)
		return @"";
	NSMutableString *faviconLink = [NSMutableString stringWithString:@""];
	[faviconLink appendString:@"<a href=\""];
	[faviconLink appendString:[aFeed.homePageURL absoluteString]];
	[faviconLink appendString:@"\"><img src=\"rsfavicon:"];
	[faviconLink appendString:[self faviconURLForFeed:aFeed]];
	[faviconLink appendString:@"\" height=\"16\" width=\"16\" alt=\""];
	NSString *feedName = aFeed.nameForDisplay;
	if (RSStringIsEmpty(feedName))
		return @"";
	[faviconLink appendString:@"\" title=\""];
	[faviconLink appendString:aFeed.nameForDisplay];
	[faviconLink appendString:@"\" ></a>"];
	return faviconLink;
}


- (NSString *)feedlink_nofavicon {
	if (self.article == nil)
		return @"";
	id<RSAccount> account = [self.dataController accountWithID:self.article.accountID];
	if (account == nil)
		return @"";
	NSString *feedURLString = self.article.feedURL;
	if (feedURLString == nil)
		return @"";
	RSFeed *feed = [(RSDataAccount *)account feedWithURL:[NSURL URLWithString:feedURLString]];
	if (feed == nil || feed.nameForDisplay == nil || feed.homePageURL == nil)
		return @"";
	
	return RSStringCreateLink(feed.nameForDisplay, [feed.homePageURL absoluteString]);
	
}


- (NSString *)feedlink_withfavicon {
	if (self.article == nil)
		return @"";
	id<RSAccount> account = [self.dataController accountWithID:self.article.accountID];
	if (account == nil)
		return @"";
	NSString *feedURLString = self.article.feedURL;
	if (feedURLString == nil)
		return @"";
	RSFeed *feed = [(RSDataAccount *)account feedWithURL:[NSURL URLWithString:feedURLString]];
	if (feed == nil || feed.nameForDisplay == nil || feed.homePageURL == nil)
		return @"";
	NSMutableString *s = [NSMutableString stringWithString:[self faviconLinkForFeed:feed]];
	if (RSStringIsEmpty(s))
		return [self feedlink_nofavicon];
	NSMutableString *feedLinkTable = [NSMutableString stringWithString:@""];
	[feedLinkTable appendString:@"<table border=0 cellpadding=0 cellspacing=0><tr><td valign=middle>"];
	[feedLinkTable appendString:s];
	[feedLinkTable appendString:@"</td><td>&nbsp;</td><td valign=middle>"];
	[feedLinkTable appendString:[self feedlink_nofavicon]];
	[feedLinkTable appendString:@"</td></tr></table>"];
	return feedLinkTable;
}


- (NSString *)date_long {
	if (self.article == nil)
		return @"";
	NSDate *date = self.article.dateForDisplay;
	if (date == nil)
		return @"";
	return [date rs_mediumDateAndTimeString];	
}


- (NSString *)author_link {
	if (self.article == nil)
		return @"";
	return NNWAuthorHTML(self.article);
}


@end

//static NSString *NNWHTMLSourceLink(NSString *feedHomePageURLString, NSString *feedNameForDisplay, NSURL *faviconURL) {
//	if (feedHomePageURLString == nil || RSStringIsEmpty(feedNameForDisplay))
//		return @"";
//	//TODO: favicon
//	NSString *sourceLink = RSStringCreateLink(feedNameForDisplay, feedHomePageURLString);	
//	return sourceLink;
//}

NSString *NNWHTMLMailtoLinkStart = @"<a href=\"mailto:";
NSString *NNWHTMLMailtoLinkMiddle = @"\"/>";
NSString *NNWHTMLMailtoLinkEnd = @"</a>";

static NSString *NNWAuthorHTML(RSDataArticle *anArticle) {
	
	NSMutableString *s = [NSMutableString stringWithString:@""];
	
	NSString *name = anArticle.authorName;
	if (!RSIsEmpty(name)) {
		[s rs_safeAppendString:name];
		[s appendString:@" "];
	}
	
	NSString *email = anArticle.authorEmail;
	if (!RSIsEmpty(email)) {
		[s appendString:NNWHTMLMailtoLinkStart];
		[s rs_safeAppendString:email];
		[s appendString:NNWHTMLMailtoLinkMiddle];
		[s rs_safeAppendString:email];
		[s appendString:NNWHTMLMailtoLinkEnd];
		[s appendString:@" "];
	}
	
	NSString *url = anArticle.authorURL;
	if (!RSIsEmpty(url))
		[s rs_safeAppendString:RSStringCreateLink(url, url)];
	
	return s;	
}


static NSString *NNWHTMLSpanStart = @"<span class=\"";
static NSString *NNWHTMLSpanStartTagEnd = @"\">";
static NSString *NNWHTMLSpanEnd = @"</span> ";

static void NNWHTMLAddSpanToString(NSMutableString *s, NSString *value, NSString *cssClassName) {	
	if (RSIsEmpty(value))
		return;
	[s appendString:NNWHTMLSpanStart];
	[s rs_safeAppendString:cssClassName];
	[s appendString:NNWHTMLSpanStartTagEnd];
	[s rs_safeAppendString:value];
	[s appendString:NNWHTMLSpanEnd];	
}


static void NNWHTMLAddSpanToStringWithTitle(NSMutableString *s, NSString *value, NSString *cssClassName, NSString *title) {
	if (RSIsEmpty(value))
		return;
	[s appendString:NNWHTMLSpanStart];
	[s rs_safeAppendString:cssClassName];
	[s appendString:@"\" title=\""];
	[s appendString:title];
	[s appendString:@"\">"];
	[s rs_safeAppendString:value];
	[s appendString:NNWHTMLSpanEnd];	
}
