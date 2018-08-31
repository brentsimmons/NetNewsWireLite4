//
//  RSSDiscovery.m
//  NetNewsWire
//
//  Created by Brent Simmons on 4/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RSSDiscovery.h"
#import "RSFoundationExtras.h"


/*This code is old and insane, but it's still used.*/

@implementation RSSDiscovery

+ (NSString *) getLinkTagURL: (NSString *) xml {
    
    /*
    If there's a tag of the form...
    <link rel="alternate" type="application/rss+xml" title="RSS" href="http://ranchero.com/xml/rss.xml" />
    ...then return the URL. Otherwise return nil.
    */
    
    NSString *xmlCopy = [xml copy];
    
    while (true) {
        
        NSRange linkRange = [[xmlCopy lowercaseString] rangeOfString:@"<link"];
        if (linkRange.length < 1)
            return nil;
        NSString *linkSeparator = [xmlCopy substringWithRange:linkRange];
        NSArray *stringComponents = [xmlCopy componentsSeparatedByString:linkSeparator];
        NSString *s, *remainder, *tag, *url;
        NSUInteger ixDelete;
        
        if ([stringComponents count] < 2)
            return (nil);
        
        remainder = [stringComponents objectAtIndex: 1];
        
        s = [stringComponents objectAtIndex: 0];
        
        ixDelete = [s length] + 1;
    
        stringComponents = [remainder componentsSeparatedByString: @">"];    
        if ([stringComponents count] < 2)
            return (nil);
            
        tag = [stringComponents objectAtIndex: 0];
        NSString *lowerTag = [tag lowercaseString];
        
        if (([lowerTag rs_caseInsensitiveContains: @"alternate"]) || ([lowerTag rs_caseInsensitiveContains: @"service.feed"])) {
            
            stringComponents = [lowerTag componentsSeparatedByString:@"application/atom+xml"];
            if ([stringComponents count] < 2)
                stringComponents = [lowerTag componentsSeparatedByString:@"application/rss+xml"];
            if ([stringComponents count] < 2)
                stringComponents = [lowerTag componentsSeparatedByString:@"application/rdf+xml"];
                
            /*PBS 07/25/03: Amazon.com hack -- look for title="rss" also.*/
            
            if ([stringComponents count] > 1 || [lowerTag rs_caseInsensitiveContains:@"title=\"rss\""] || [lowerTag rs_caseInsensitiveContains:@"title=\"atom\""] || [lowerTag rs_caseInsensitiveContains:@"title='rss'"] || [lowerTag rs_caseInsensitiveContains:@"title='atom'"] || [lowerTag rs_caseInsensitiveContains:@"title=atom"] || [lowerTag rs_caseInsensitiveContains:@"title=rss"]) {

                NSRange hrefRange = [lowerTag rangeOfString:@"href"];

                if (hrefRange.length > 0) {
                    NSString *leftString = [tag substringToIndex:hrefRange.location - 1];
                    NSString *rightString = [tag substringFromIndex:hrefRange.location + hrefRange.length];
                    stringComponents = [NSArray arrayWithObjects:leftString, rightString, nil];
                    
                    url = [stringComponents objectAtIndex: 1];                
                    url = [url rs_stringByTrimmingWhitespace];
                    
                    stringComponents = [url componentsSeparatedByString: @" "];
                    
                    url = [stringComponents objectAtIndex: 0];                
                    url = [url rs_stringByTrimmingWhitespace];
                    
                    if ([url hasPrefix: @"="]) {
                    
                        url = [url substringFromIndex: 1];                
                        url = [url rs_stringByTrimmingWhitespace];
                        }
                    
                    if (([url hasPrefix: @"\""]) || ([url hasPrefix: @"'"])) {
                        
                        url = [url substringFromIndex: 1];
                        url = [url rs_stringByTrimmingWhitespace];
                        }
                    
                    if (([url hasSuffix: @"/"]) || ([url hasSuffix: @"'"])) {
                        
                        url = [url substringToIndex: [url length] - 1];                    
                        url = [url rs_stringByTrimmingWhitespace];
                        }

                    if ([url hasSuffix: @"\""]) {
                        
                        url = [url substringToIndex: [url length] - 1];                    
                        url = [url rs_stringByTrimmingWhitespace];
                        }
                    
                    return (url);
                    }
                }
            }
        xmlCopy = [xmlCopy substringFromIndex: ixDelete];
        }
            
    return nil;
    }
    

+ (NSString *)normalizeURL:(NSString *)URL {
    
    /*Trim white space and make sure it has an http:// or file:// scheme*/
    
    NSMutableString *returnedURLString;
    NSString *URLCopy = [URL rs_stringByTrimmingWhitespace];
    NSString *lowerURL = [URLCopy lowercaseString];
    
    returnedURLString = [URLCopy mutableCopy];
    
    if (![lowerURL hasPrefix: @"http://"] && ![lowerURL hasPrefix: @"https://"] && ![lowerURL hasPrefix: @"file:///"])        
        [returnedURLString insertString:@"http://" atIndex:0];
    
    return (NSString *)[returnedURLString copy];    
    }


@end
