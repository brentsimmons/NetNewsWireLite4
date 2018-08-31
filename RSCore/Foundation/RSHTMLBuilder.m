//
//  RSHTMLBuilder.m
//  nnw
//
//  Created by Brent Simmons on 12/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSHTMLBuilder.h"


@interface RSHTMLBuilder ()

@property (nonatomic, strong) id dataSource;
@property (nonatomic, strong) NSString *htmlTemplate;
@property (nonatomic, strong, readwrite) NSString *renderedHTML;

- (NSString *)buildHTMLUsingTemplate:(NSString *)aTemplate;

@end


@implementation RSHTMLBuilder

@synthesize dataSource;
@synthesize htmlTemplate;
@synthesize includeHTMLFooter;
@synthesize includeHTMLHeader;
@synthesize renderedHTML;
@synthesize styleSheetPath;


#pragma mark Init

- (id)initWithDataSource:(id)aDataSource andHTMLTemplate:(NSString *)anHTMLTemplate {
    self = [super init];
    if (self == nil)
        return nil;
    dataSource = aDataSource;
    htmlTemplate = anHTMLTemplate;
    return self;
}


#pragma mark Dealloc



#pragma mark HTML

static NSString *macroStartCharacters = @"[[";
static NSString *macroEndCharacters = @"]]";
static const NSUInteger numberOfMacroStartCharacters = 2;
static const NSUInteger numberOfMacroEndCharacters = 2;


- (NSUInteger)indexOfMacroCharacters:(NSString *)macroCharacters beforeMaxIndex:(NSUInteger)maxIndex inString:(NSString *)stringToSearch {
    NSUInteger numberOfMacroCharacters = [macroCharacters length];
    if (maxIndex < numberOfMacroCharacters)
        return NSNotFound;
    NSRange macroCharactersRange = [stringToSearch rangeOfString:macroCharacters options:NSBackwardsSearch range:NSMakeRange(0, maxIndex)];
    if (macroCharactersRange.length < numberOfMacroCharacters)
        return NSNotFound;
    return macroCharactersRange.location;    
}


- (NSUInteger)indexOfMacroStartBefore:(NSUInteger)maxIndex inString:(NSString *)stringToSearch {
    return [self indexOfMacroCharacters:macroStartCharacters beforeMaxIndex:maxIndex inString:stringToSearch ];
}


- (NSUInteger)indexOfMacroEndBefore:(NSUInteger)maxIndex inString:(NSString *)stringToSearch {
    return [self indexOfMacroCharacters:macroEndCharacters beforeMaxIndex:maxIndex inString:stringToSearch ];
}


- (void)insertHTMLHeader {
    
    NSMutableString *htmlHeader = [NSMutableString stringWithString:@"<html><head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n"];
    
    if (!RSStringIsEmpty(self.styleSheetPath)) {
        [htmlHeader appendString:@"<style type=\"text/css\" media=\"screen\">@import \""];
        [htmlHeader appendString:self.styleSheetPath];
        [htmlHeader appendString:@"\";</style>\n"];
//        [htmlHeader appendString:@"<style type=\"text/css\" media=\"screen\">\n"];
//        [htmlHeader appendString:self.styleSheetPath];
//        NSString *styleSheetContents = [NSString rs_stringWithContentsOfUTF8EncodedFile:self.styleSheetPath];
//        [htmlHeader rs_safeAppendString:styleSheetContents];
//        [htmlHeader appendString:@"\n;</style>\n"];
    }
    
    [htmlHeader appendString:@"<title>[[newsitem_title]]</title>\n"];
    [htmlHeader appendString:@"<body>\n"];
    NSString *processedHTMLHeader = [self buildHTMLUsingTemplate:htmlHeader]; //replaces [[newsitem_title]]
    self.renderedHTML = [NSString stringWithFormat:@"%@%@", processedHTMLHeader, renderedHTML];
}


- (void)insertHTMLFooter {
    self.renderedHTML = [NSString stringWithFormat:@"%@%@", renderedHTML, @"\n\n</body></html>"];
}


- (NSString *)buildHTMLUsingTemplate:(NSString *)aTemplate {
    
    NSMutableString *htmlString = [[NSMutableString alloc] initWithString:aTemplate];
    
    NSUInteger indexOfMacroStart = 0;
    NSUInteger indexOfMacroEnd = 0;
    NSUInteger lastIndexOfMacroStart = [aTemplate length];
    
    /*Loop through the HTML backwards, so that replacement text that happens to contain macros doesn't get processed.*/
    while (true) {
        indexOfMacroEnd = [self indexOfMacroEndBefore:lastIndexOfMacroStart inString:htmlString];
        if (indexOfMacroEnd == NSNotFound)
            break;
        indexOfMacroStart = [self indexOfMacroStartBefore:indexOfMacroEnd inString:htmlString];
        if (indexOfMacroStart == NSNotFound)
            break;
        lastIndexOfMacroStart = indexOfMacroStart;
        NSRange rangeOfMacro = NSMakeRange(indexOfMacroStart, (indexOfMacroEnd - indexOfMacroStart) + numberOfMacroEndCharacters);
        NSRange rangeOfMacroKey = NSMakeRange(indexOfMacroStart + numberOfMacroStartCharacters, (indexOfMacroEnd - indexOfMacroStart) - numberOfMacroEndCharacters);
        NSString *macroString = [htmlString substringWithRange:rangeOfMacroKey];
        NSString *replacementString = [self.dataSource valueForKey:macroString];
        if (replacementString == nil)
            replacementString = @"";
        [htmlString replaceCharactersInRange:rangeOfMacro withString:replacementString];
    }
    
    return htmlString;
}


//static NSString *defaultHTMLTemplate = @"<div id=\"_pageContainer\">\n<div id=\"_newsItemTitle\"><h1>[[newsitem_title]]</h1></div>\n<div id=\"_newsItemContent\">\n<div id=\"_newsItemDateline\">[[newsitem_dateline]]</div>\n<div id=\"_newsItemDescription\">\n[[newsitem_description]]</div>\n<div id=\"_newsItemExtraLinks\">[[newsitem_extralinks]]</div>\n</div>\n</div>";

static NSString *defaultHTMLTemplate = @"<div class=\"newsItemContainer\">\n\
<div class=\"newsItemTitle\"><strong>[[newsitem_title]]</strong></div>\n\
<div class=\"newsItemDescription\">[[newsitem_description]]\n\
<p class=\"newsItemExtraLinks\">[[newsitem_extralinks]]</p>\n\
</div>\n\
<div class=\"newsItemDateLine\">[[newsitem_dateline]]</div>\n\
</div>";

- (NSString *)renderedHTML {
    if (RSIsEmpty(self.htmlTemplate))
        self.htmlTemplate = defaultHTMLTemplate;
    renderedHTML = [self buildHTMLUsingTemplate:self.htmlTemplate];
    if (self.includeHTMLHeader)
        [self insertHTMLHeader];
    if (self.includeHTMLFooter)
        [self insertHTMLFooter];
    return renderedHTML;
}


@end

