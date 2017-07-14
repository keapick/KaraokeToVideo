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

// frame size
static int const CDGFrameWidth = 300;
static int const CDGFrameHeight = 216;

// frame rate
static int const CDGFramesPerSecond = 15;

// An iterator that goes through the CDG file one frame at a time
@interface CDGraphicsReader : NSObject

// URL to source cdg file.  There is very little error checking!
- (instancetype)initWithCDG:(NSURL *)cdg;

// Next frame as a CoreVideo pixel buffer
- (CVPixelBufferRef)nextFrame;

// memory leak if you don't close the C objects underneath this all
- (void)close;

@end

