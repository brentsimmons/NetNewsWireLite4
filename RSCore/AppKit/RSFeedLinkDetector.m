//
//  RSFeedLinkDetector.m
//  NetNewsWire
//
//  Created by Brent Simmons on 2/7/07.
//  Copyright 2007 Ranchero Software. All rights reserved.
//

#import "RSFeedLinkDetector.h"
#import "RSFoundationExtras.h"


static NSMutableDictionary *_linkCache = nil;


@implementation RSFeedLinkDetector


+ (void)initialize {
	_linkCache = [[NSMutableDictionary dictionaryWithCapacity:100] retain];
	}


+ (BOOL)_urlIsProbablyFeed:(NSString *)urlString {
	if ([urlString hasSuffix:@"foaf.rdf"])
		return NO;
	if ([urlString rs_contains:@"rojo.com/add-subscription?"])
		return NO;
	if ([urlString hasSuffix:@".rss"] || [urlString hasSuffix:@".xml"] || [urlString hasSuffix:@".atom"] || [urlString hasSuffix:@".rdf"] || [urlString hasSuffix:@"/feed/"] || [urlString hasSuffix:@"/feed"])
		return YES;
	if ([urlString rs_contains:@"feeds.feedburner.com"] && ![urlString rs_contains:@"~r"])
		return YES;
	return NO;
	}
	

+ (NSString *)_filterURL:(NSString *)urlString {
	/*Deal with case where URL is part of "Add to Whatever..." link*/
	if ([urlString rs_contains:@"/sub/http"]) {
		NSArray *stringComponents = [urlString componentsSeparatedByString:@"/sub/http"];
		urlString = [NSString rs_stringByAddingStrings:@"http" string2:[stringComponents objectAtIndex:1]];
		//		urlString = RSConcatenateStrings(@"http", [stringComponents objectAtIndex:1]);
	}
	else if ([urlString rs_contains:@"?"]) {
		NSDictionary *d = RSDictionaryFromURLString(urlString);
		if (!RSIsEmpty(d)) {
			NSString *tempString = [d objectForKey:@"url"];
			if (RSIsEmpty(tempString))
				tempString = [d objectForKey:@"add"];
			if (RSIsEmpty(tempString))
				tempString = [d objectForKey:@".url"];
			if (RSIsEmpty(tempString))
				tempString = [d objectForKey:@"feedurl"];
			if (RSIsEmpty(tempString))
				tempString = [d objectForKey:@"r"];
			if (!RSIsEmpty(tempString)) {
				urlString = [(NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)tempString, (CFStringRef)@"%20") autorelease];
			}
		}
	}
	return RSURLWithFeedURL(urlString);
}


+ (NSUInteger)_indexOfURL:(NSString *)oneURL before:(NSUInteger)limit inArray:(NSArray *)anArray{
	if (limit < 1 || RSIsEmpty(oneURL) || RSIsEmpty(anArray))
		return NSNotFound;
	NSUInteger i;
	NSDictionary *d;
	for (i = 0; i < limit; i++) {
		d = [anArray objectAtIndex:i];
		if ([[d objectForKey:@"url"] compare:oneURL options:NSCaseInsensitiveSearch] == NSOrderedSame)
			return i;
		}
	return NSNotFound;
	}
	

+ (void)_removeDuplicatesFromArray:(NSMutableArray *)tempArray {
	
	if (RSIsEmpty(tempArray))
		return;
	NSInteger i;
	NSUInteger ct = [tempArray count];
	NSDictionary *d;
	NSString *oneTitle;
	NSString *oneURL;
	for (i = (NSInteger)ct - 1; i >= 0; i--) {
		d = [tempArray rs_safeObjectAtIndex:(NSUInteger)i];
		if (!d)
			continue;
		oneURL = [d objectForKey:@"url"];
		oneTitle = [d objectForKey:@"title"];
		NSUInteger ix = [self _indexOfURL:oneURL before:(NSUInteger)i inArray:tempArray];
		if (ix == NSNotFound)
			continue;
		NSMutableDictionary *previousItem = [tempArray objectAtIndex:ix];
		NSString *previousTitle = [previousItem objectForKey:@"title"];
		if (RSIsEmpty(previousTitle) && !RSIsEmpty(oneTitle))
			[previousItem setObject:oneTitle forKey:@"title"];
		[tempArray rs_safeRemoveObjectAtIndex:(NSUInteger)i];
		}
	}


+ (void)_addURLToEveryTitleThatMatches:(NSString *)title array:(NSMutableArray *)tempArray {
	if (RSIsEmpty(tempArray))
		return;
	NSUInteger i;
	NSUInteger ct = [tempArray count];
	NSMutableDictionary *d;
	NSString *oneTitle;
	NSString *oneURL;
	for (i = 0; i < ct; i++) {
		d = [tempArray rs_safeObjectAtIndex:i];
		if (!d)
			continue;
		oneURL = [d objectForKey:@"url"];
		if (RSIsEmpty(oneURL))
			continue;
		oneTitle = [d objectForKey:@"title"];
		if ([oneTitle isEqualToString:title]) {
//			NSString *newTitle = RSConcatenateStrings(oneTitle, @" <");
			NSString *newTitle = [NSString rs_stringByAddingStrings:oneTitle string2:@" <"];
			newTitle = [NSString rs_stringByAddingStrings:newTitle string2:oneURL];
			newTitle = [NSString rs_stringByAddingStrings:newTitle string2:@">"];
//			newTitle = RSConcatenateStrings(newTitle, oneURL);
//			newTitle = RSConcatenateStrings(newTitle, @">");
			[d setObject:newTitle forKey:@"title"];
			}
		}
	}


+ (NSUInteger)_indexOfTitle:(NSString *)title otherThan:(NSUInteger)ixSkip inArray:(NSMutableArray *)tempArray {
	if (RSIsEmpty(tempArray) || RSIsEmpty(title))
		return NSNotFound;
	NSUInteger i;
	NSUInteger ct = [tempArray count];
	NSString *oneTitle;
	for (i = 0; i < ct; i++) {
		if (i == ixSkip)
			continue;
		oneTitle = [[tempArray objectAtIndex:i] objectForKey:@"title"];
		if (RSEqualNotEmptyStrings(title, oneTitle))
			return i;
		}
	return NSNotFound;
	}
	
	
+ (void)_addURLsToDuplicateTitlesInArray:(NSMutableArray *)tempArray {
	if (RSIsEmpty(tempArray))
		return;
	NSInteger i;
	NSUInteger ct = [tempArray count];
	NSDictionary *d;
	NSString *oneTitle;
//	NSString *oneURL;
	for (i = (NSInteger)ct - 1; i >= 0; i--) {
		d = [tempArray rs_safeObjectAtIndex:(NSUInteger)i];
		if (!d)
			continue;
	//	oneURL = [d objectForKey:@"url"];
		oneTitle = [d objectForKey:@"title"];
		NSUInteger ix = [self _indexOfTitle:oneTitle otherThan:(NSUInteger)i inArray:tempArray];
		if (ix == NSNotFound)
			continue;
		[self _addURLToEveryTitleThatMatches:oneTitle array:tempArray];
		}
	}
	
	
+ (NSDictionary *)_parsedLinkWithDOMNode:(DOMNode *)domNode pageURL:(NSURL *)pageURL {
	if (!pageURL || ![domNode respondsToSelector:@selector(href)])
		return nil;
	BOOL isLinkNode = [domNode isKindOfClass:[DOMHTMLLinkElement class]];
	if (isLinkNode) {
		NSString *rel = [(DOMHTMLLinkElement *)domNode rel];
		if (rel && ![rel rs_caseInsensitiveContains:@"alternate"])
			return nil;
		NSString *type = [(DOMHTMLLinkElement *)domNode type];
		if (!type)
			return nil;
		if (![type rs_caseInsensitiveContains:@"application/atom+xml"] && ![type rs_caseInsensitiveContains:@"application/rss+xml"] && ![type rs_caseInsensitiveContains:@"application/rdf+xml"])
			return nil;
		}
	
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:2];
	NSString *url = [(DOMHTMLLinkElement *)domNode href];
	if (RSIsEmpty(url))
		return nil;
	url = [self _filterURL:url];
	if (RSIsEmpty(url))
		return nil;
	if (!RSIsEmpty(pageURL)) {
		NSURL *resolvedURL = [NSURL URLWithString:url relativeToURL:pageURL];
		url = [resolvedURL absoluteString];
		}
	if (!isLinkNode && ![self _urlIsProbablyFeed:url])
		return nil;
	NSString *title = [(DOMHTMLElement *)domNode title];
	if (RSIsEmpty(title))
		title = [(DOMHTMLElement *)domNode innerText];
	if (RSIsEmpty(title) && [url rs_caseInsensitiveContains:@"/xml/rss/nyt/"]) {
		NSArray *stringComponents = [url componentsSeparatedByString:@"/xml/rss/nyt/"];
		title = [stringComponents objectAtIndex:1];
		}
	if (!RSIsEmpty(title))
		title = [title rs_stringByTrimmingWhitespace];
	[d rs_safeSetObject:url forKey:@"url"];
	[d rs_safeSetObject:title forKey:@"title"];
	return d;
	}


+ (NSArray *)_parsedLinksWithDOMNodes:(NSArray *)nodes pageURL:(NSURL *)pageURL {
	if (RSIsEmpty(nodes))
		return nil;
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[nodes count]];
	NSUInteger i;
	NSUInteger ct = [nodes count];
	for (i = 0; i < ct; i++)
		[tempArray rs_safeAddObject:[self _parsedLinkWithDOMNode:[nodes objectAtIndex:i] pageURL:pageURL]];
	[self _removeDuplicatesFromArray:tempArray];
	[self _addURLsToDuplicateTitlesInArray:tempArray];
	return tempArray;
	}


+ (void)_addItemsFromDOMNodeList:(DOMNodeList *)domNodeList toArray:(NSMutableArray *)anArray {
	NSUInteger ct = [domNodeList length];
	NSUInteger i;
	for (i = 0; i < ct; i++)
		[anArray rs_safeAddObject:[domNodeList item:(unsigned int)i]];
	}


+ (NSArray *)_arrayByJoiningDOMNodeLists:(NSArray *)anArray {
	if (RSIsEmpty(anArray))
		return nil;
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:200];
	NSUInteger i;
	NSUInteger ct = [anArray count];
	for (i = 0; i < ct; i++) 
		[self _addItemsFromDOMNodeList:[anArray objectAtIndex:i] toArray:tempArray];	
	return tempArray;
	}


+ (NSArray *)_parsedLinksInDOMDocument:(DOMDocument *)domDocument pageURL:(NSURL *)pageURL {
	DOMNodeList *aNodes = [domDocument getElementsByTagName:@"a"];
	DOMNodeList *linkNodes = [domDocument getElementsByTagName:@"link"];
	return [self _parsedLinksWithDOMNodes:[self _arrayByJoiningDOMNodeLists:[NSArray arrayWithObjects:aNodes, linkNodes, nil]] pageURL:pageURL];
	}


+ (NSArray *)feedLinksInDOMDocument:(DOMDocument *)domDocument pageURL:(NSURL *)pageURL {
	if (!domDocument || RSIsEmpty(pageURL))
		return nil;
	NSString *urlString = [pageURL absoluteString];
	if (RSIsEmpty(urlString))
		return nil;
	NSArray *links = [self _parsedLinksInDOMDocument:domDocument pageURL:pageURL];
	if (RSIsEmpty(links))
		[_linkCache setObject:[NSNull null] forKey:urlString];
	else
		[_linkCache setObject:links forKey:urlString];
	return links;
	}


+ (NSArray *)cachedFeedLinksForURLString:(NSString *)urlString found:(BOOL *)found {
	NSArray *links = [_linkCache objectForKey:urlString];
	if (links)
		*found = YES;
	else
		*found = NO;
	if (links == (id)[NSNull null])
		return nil;
	return links;
	}
	
	
@end

#pragma mark C

NSArray *RSCachedFeedLinks(NSString *pageURLString, BOOL *found) {
	if (RSIsEmpty(pageURLString)) {
		*found = NO;
		return nil;
		}
	return [RSFeedLinkDetector cachedFeedLinksForURLString:pageURLString found:found];
	}

