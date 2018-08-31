//
//  RSEntityDecoder.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSEntityDecoder.h"
#import "RSFoundationExtras.h"


NSString *RSStringWithDecodedEntities(NSString *s) {
    /*To get categories to load from a static library, sometimes we have to use a C function. It's dumb, but it works.*/
    return [NSString rs_stringWithDecodedEntities:s];
}


@implementation NSString (RSEntityDecoder)


- (BOOL)rs_intValueFromHexDigit:(unsigned int *)val {
    return [[NSScanner scannerWithString:self] scanHexInt:val];      
}


+ (NSString *)rs_stringWithDecodedEntities:(NSString *)s {
    return [self rs_stringWithDecodedEntities:s convertCarets:YES convertHexEntitiesOnly:NO];
}


+ (NSString *)rs_stringWithDecodedEntities:(NSString *)s convertCarets:(BOOL)convertCarets convertHexEntitiesOnly:(BOOL)convertHexEntitiesOnly {
    
    /*TODO: make this work on bytes instead of an NSString, have it do the replacements in-place so it doesn't allocate memory.
     Since it would only ever contract, not expand, the string, in-place is totally do-able. It would be *so* fast.*/
    
    if (RSIsEmpty(s) || [s rangeOfString:@"&" options:NSLiteralSearch].location == NSNotFound)
        return s;
            
    NSUInteger len = [s length];
    if (len < 1)
        return @"";
    
    if (convertHexEntitiesOnly)
        convertCarets = NO;
    NSDictionary *entitiesDictionary = RSEntitiesDictionary();

    NSMutableString *result = [NSMutableString stringWithCapacity:len];
    NSUInteger i = 0;

    while (true) {
        
        unichar ch = [s characterAtIndex: i];
        
        if (ch == '&') {
            
            NSUInteger j = i + 1;
            NSUInteger ixRight = NSNotFound;
            
            while (true) {
                
                unichar endch;
                
                if (j >= len)
                    break;
                    
                endch = [s characterAtIndex:j];

                if (endch == ';') {                    
                    ixRight = j;
                    break;
                    }
                
                if ((endch == ' ') || (endch == '\t') || (endch == '\r') || (endch == '\n') || (endch == '&'))
                    break;
            
                j++;
                }
            
            if (ixRight != NSNotFound) {
                
                NSString *entityString = [s substringWithRange:NSMakeRange(i + 1, (ixRight - i) - 1)];
                NSString *fullEntityString = [[NSString alloc] initWithFormat:@"&%@;", entityString];
                NSString *valueString = nil;

                if (!convertHexEntitiesOnly)
                    valueString = [entitiesDictionary objectForKey:entityString];
                
                if ((valueString == nil) && ([entityString hasPrefix:@"#x"])) {
                    unsigned int val = 0;                    
                    entityString = RSStringReplaceAll(entityString, @"#x", @"0x");                    
                    [entityString rs_intValueFromHexDigit: &val];
                    if (val > 0)
                        valueString = [[NSString alloc] initWithFormat:@"%C", val];
                    }
                
                else if ((valueString == nil) && ([entityString hasPrefix:@"#"])) {
                    NSInteger val = 0;
                    entityString = [entityString rs_stringByStrippingPrefix:@"#"];
//                    entityString = [NSString stripPrefix:entityString prefix:@"#"];
                    val = [entityString integerValue];
                    if (val > 0)
                        valueString = [[NSString alloc] initWithFormat:@"%C", val];
                    }
                if (valueString && ![valueString isKindOfClass:[NSString class]])
                    NSLog(@"fooooooxxx");
                if ((!convertCarets) && ([entityString isEqualToString:@"lt"] || [entityString isEqualToString:@"gt"]))        
                    [result appendString:fullEntityString];    
                else {                
                    if (valueString)
                        [result appendString:valueString];
                    else
                        [result appendString:fullEntityString];
                    }
                
                
                i = ixRight;
                
                goto continue_loop;
                }
            }
            
        CFStringAppendCharacters((CFMutableStringRef)result, &ch, 1);
        
        continue_loop:
        
        i++;
        
        if (i >= len)
            break;
        }
    
    return result;

}


@end


NSDictionary *RSEntitiesDictionary(void) {
    static NSDictionary *entitiesDictionary = nil;
    @synchronized([NSString class]) {
        if (entitiesDictionary == nil)
            entitiesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"\"", @"#034",
                                   @"'", @"#039",
                                   @"‘", @"#145",
                                   @"’", @"#146",
                                   @"“", @"#147",
                                   @"”", @"#148",
                                   @"•", @"#149",
                                   @"-", @"#150",
                                   @"—", @"#151",
                                   @"™", @"#153",
                                   @" ", @"#160",
                                   @"¡", @"#161",
                                   @"¢", @"#162",
                                   @"£", @"#163",
                                   @"?", @"#164",
                                   @"¥", @"#165",
                                   @"?", @"#166",
                                   @"§", @"#167",
                                   @"¨", @"#168",
                                   @"©", @"#169",
                                   @"©", @"#170",
                                   @"«", @"#171",
                                   @"¬", @"#172",
                                   @"¬", @"#173",
                                   @"®", @"#174",
                                   @"¯", @"#175",
                                   @"°", @"#176",
                                   @"±", @"#177",
                                   @" ", @"#178",
                                   @" ", @"#179",
                                   @"´", @"#180",
                                   @"µ", @"#181",
                                   @"µ", @"#182",
                                   @"·", @"#183",
                                   @"¸", @"#184",
                                   @" ", @"#185",
                                   @"º", @"#186",
                                   @"»", @"#187",
                                   @"1/4", @"#188",
                                   @"1/2", @"#189",
                                   @"1/2", @"#190",
                                   @"¿", @"#191",
                                   @"À", @"#192",
                                   @"Á", @"#193",
                                   @"Â", @"#194",
                                   @"Ã", @"#195",
                                   @"Ä", @"#196",
                                   @"Å", @"#197",
                                   @"Æ", @"#198",
                                   @"Ç", @"#199",
                                   @"È", @"#200",
                                   @"É", @"#201",
                                   @"Ê", @"#202",
                                   @"Ë", @"#203",
                                   @"Ì", @"#204",
                                   @"Í", @"#205",
                                   @"Î", @"#206",
                                   @"Ï", @"#207",
                                   @"?", @"#208",
                                   @"Ñ", @"#209",
                                   @"Ò", @"#210",
                                   @"Ó", @"#211",
                                   @"Ô", @"#212",
                                   @"Õ", @"#213",
                                   @"Ö", @"#214",
                                   @"x", @"#215",
                                   @"Ø", @"#216",
                                   @"Ù", @"#217",
                                   @"Ú", @"#218",
                                   @"Û", @"#219",
                                   @"Ü", @"#220",
                                   @"Y", @"#221",
                                   @"?", @"#222",
                                   @"ß", @"#223",
                                   @"à", @"#224",
                                   @"á", @"#225",
                                   @"â", @"#226",
                                   @"ã", @"#227",
                                   @"ä", @"#228",
                                   @"å", @"#229",
                                   @"æ", @"#230",
                                   @"ç", @"#231",
                                   @"è", @"#232",
                                   @"é", @"#233",
                                   @"ê", @"#234",
                                   @"ë", @"#235",
                                   @"ì", @"#236",
                                   @"í", @"#237",
                                   @"î", @"#238",
                                   @"ï", @"#239",
                                   @"?", @"#240",
                                   @"ñ", @"#241",
                                   @"ò", @"#242",
                                   @"ó", @"#243",
                                   @"ô", @"#244",
                                   @"õ", @"#245",
                                   @"ö", @"#246",
                                   @"÷", @"#247",
                                   @"ø", @"#248",
                                   @"ù", @"#249",
                                   @"ú", @"#250",
                                   @"û", @"#251",
                                   @"ü", @"#252",
                                   @"y", @"#253",
                                   @"?", @"#254",
                                   @"ÿ", @"#255",
                                   @" ", @"#32",
                                   @"\"", @"#34",
                                   @"", @"#39",
                                   @" ", @"#8194",
                                   @" ", @"#8195",
                                   @"-", @"#8211",
                                   @"—", @"#8212",
                                   @"‘", @"#8216",
                                   @"’", @"#8217",
                                   @"“", @"#8220",
                                   @"”", @"#8221",
                                   @"…", @"#8230",
                                   @"Æ", @"AElig",
                                   @"Á", @"Aacute",
                                   @"Â", @"Acirc",
                                   @"À", @"Agrave",
                                   @"Å", @"Aring",
                                   @"Ã", @"Atilde",
                                   @"Ä", @"Auml",
                                   @"Ç", @"Ccedil",
                                   @"?", @"Dstrok",
                                   @"?", @"ETH",
                                   @"É", @"Eacute",
                                   @"Ê", @"Ecirc",
                                   @"È", @"Egrave",
                                   @"Ë", @"Euml",
                                   @"Í", @"Iacute",
                                   @"Î", @"Icirc",
                                   @"Ì", @"Igrave",
                                   @"Ï", @"Iuml",
                                   @"Ñ", @"Ntilde",
                                   @"Ó", @"Oacute",
                                   @"Ô", @"Ocirc",
                                   @"Ò", @"Ograve",
                                   @"Ø", @"Oslash",
                                   @"Õ", @"Otilde",
                                   @"Ö", @"Ouml",
                                   @"Π", @"Pi",
                                   @"?", @"THORN",
                                   @"Ú", @"Uacute",
                                   @"Û", @"Ucirc",
                                   @"Ù", @"Ugrave",
                                   @"Ü", @"Uuml",
                                   @"Y", @"Yacute",
                                   @"á", @"aacute",
                                   @"â", @"acirc",
                                   @"´", @"acute",
                                   @"æ", @"aelig",
                                   @"à", @"agrave",
                                   @"&amp;", @"amp",
                                   @"'", @"apos",
                                   @"å", @"aring",
                                   @"ã", @"atilde",
                                   @"ä", @"auml",
                                   @"?", @"brkbar",
                                   @"?", @"brvbar",
                                   @"ç", @"ccedil",
                                   @"¸", @"cedil",
                                   @"¢", @"cent",
                                   @"©", @"copy",
                                   @"?", @"curren",
                                   @"°", @"deg",
                                   @"?", @"die",
                                   @"÷", @"divide",
                                   @"é", @"eacute",
                                   @"ê", @"ecirc",
                                   @"è", @"egrave",
                                   @"?", @"eth",
                                   @"ë", @"euml",
                                   @"€", @"euro",
                                   @"1/2", @"frac12",
                                   @"1/4", @"frac14",
                                   @"3/4", @"frac34",
                                   @"&gt;", @"gt",
                                   @"♥", @"hearts",
                                   @"…", @"hellip",
                                   @"í", @"iacute",
                                   @"î", @"icirc",
                                   @"¡", @"iexcl",
                                   @"ì", @"igrave",
                                   @"¿", @"iquest",
                                   @"ï", @"iuml",
                                   @"«", @"laquo",
                                   @"“", @"ldquo",
                                   @"‘", @"lsquo",
                                   @"&lt;", @"lt",
                                   @"¯", @"macr",
                                   @"—", @"mdash",
                                   @"µ", @"micro",
                                   @"·", @"middot",
                                   @" ", @"nbsp",
                                   @"-", @"ndash",
                                   @"¬", @"not",
                                   @"ñ", @"ntilde",
                                   @"ó", @"oacute",
                                   @"ô", @"ocirc",
                                   @"ò", @"ograve",
                                   @"ª", @"ordf",
                                   @"º", @"ordm",
                                   @"ø", @"oslash",
                                   @"õ", @"otilde",
                                   @"ö", @"ouml",
                                   @"¶", @"para",
                                   @"π", @"pi",
                                   @"±", @"plusmn",
                                   @"£", @"pound",
                                   @"\"", @"quot",
                                   @"»", @"raquo",
                                   @"”", @"rdquo",
                                   @"®", @"reg",
                                   @"’", @"rsquo",
                                   @"§", @"sect",
                                   @" ", @"shy",
                                   @" ", @"sup1",
                                   @" ", @"sup2",
                                   @" ", @"sup3",
                                   @"ß", @"szlig",
                                   @"?", @"thorn",
                                   @"x", @"times",
                                   @"™", @"trade",
                                   @"ú", @"uacute",
                                   @"û", @"ucirc",
                                   @"ù", @"ugrave",
                                   @"¨", @"uml",
                                   @"ü", @"uuml",
                                   @"y", @"yacute",
                                   @"¥", @"yen",
                                   @"ÿ", @"yuml",
                                   nil];
    }
    return entitiesDictionary;
}
