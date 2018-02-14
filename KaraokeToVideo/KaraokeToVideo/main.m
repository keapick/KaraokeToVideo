//
//  main.m
//  Karaoke
//
//  Created by echo on 1/17/17.
//  Copyright © 2017 echo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KaraokeLib.h"

// practice working with a binary file format, if you actually want to convert mp3+cdg to mp4 use ffmpeg!
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc == 4) {
            NSDate *startTime = NSDate.date;
            
            NSURL *cdgURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
            NSURL *mp3URL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]]];
            NSURL *mp4URL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[3]]];

            CDGToMp4 *converter = [[CDGToMp4 alloc] initWithMp3URL:mp3URL cdgURL:cdgURL mp4URL:mp4URL];
            [converter convertToMp4];
            
            NSLog(@"Duration: %f", ([startTime timeIntervalSinceNow] * -1));
        } else {
            NSLog(@"Usage: karaokeToVideo [input.cdg] [input.mp3] [output.mp4]");
        }
    }
    return 0;
}
