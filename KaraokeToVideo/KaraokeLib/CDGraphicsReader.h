//
//  CDGraphicsReader.h
//  KaraokeToVideo
//
//  Created by echo on 6/25/17.
//  Copyright © 2017 echo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>

// An iterator that goes through the CDG file one frame at a time
@interface CDGraphicsReader : NSObject

// CDG format constants
+ (int)frameRate;
+ (int)frameWidth;
+ (int)frameHeight;

// There is very little error checking!
- (instancetype)initWithCDG:(NSURL *)cdg;

// Next frame as a CoreVideo pixel buffer
- (CVPixelBufferRef)nextFrame;

// memory leak if you don't close the C objects underneath this all
- (void)close;

@end

