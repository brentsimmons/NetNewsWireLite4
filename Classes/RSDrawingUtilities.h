//
//  RSDrawingUtilities.h
//  nnw
//
//  Created by Brent Simmons on 12/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


void RSCGRectFillWithColor(CGRect r, CGColorRef aColor);
void RSCGRectFillWithWhite(CGRect r);

CGColorRef RSCGWhiteColor(void);

void RSDrawCGImageInRectWithBlendMode(CGImageRef cgImage, CGRect r, CGBlendMode blendMode);

