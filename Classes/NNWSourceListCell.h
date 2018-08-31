//
//  NNWSourceListCell.h
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWSourceListCell : NSTextFieldCell {
@private
    id __unsafe_unretained smallImage;
    NSUInteger countForDisplay;
    BOOL selected;
    BOOL isFolder;
    BOOL shouldDrawSmallImage;
}


@property (nonatomic, unsafe_unretained) id smallImage; //CGImageRef
@property (nonatomic, assign) NSUInteger countForDisplay;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL isFolder;
@property (nonatomic, assign) BOOL shouldDrawSmallImage;

@end
