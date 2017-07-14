//
//  main.m
//  Karaoke
//
//  Created by echo on 1/17/17.
//  Copyright © 2017 echo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDGToMp4.h"

// practice working with a binary file format, if you actually want to convert mp3+cdg to mp4 use ffmpeg!
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSDate *startTime = NSDate.date;
        
//        NSURL *mp4URL = [NSURL fileURLWithPath:@"Jay-Z & Alicia Keys - Empire State Of Mind.mp4"];
//        NSURL *cdgURL = [NSURL fileURLWithPath:@"Jay-Z & Alicia Keys - Empire State Of Mind.cdg"];
//        NSURL *mp3URL = [NSURL fileURLWithPath:@"Jay-Z & Alicia Keys - Empire State Of Mind.mp3"];

        NSURL *mp4URL = [NSURL fileURLWithPath:@"Cranberries, The - Zombie.mp4"];
        NSURL *cdgURL = [NSURL fileURLWithPath:@"Cranberries, The - Zombie.cdg"];
        NSURL *mp3URL = [NSURL fileURLWithPath:@"Cranberries, The - Zombie.mp3"];
        
        CDGToMp4 *converter = [[CDGToMp4 alloc] initWithMp3URL:mp3URL cdgURL:cdgURL mp4URL:mp4URL];
        [converter convertToMp4];
        NSLog(@"Duration: %f", ([startTime timeIntervalSinceNow] * -1));
    }
    return 0;
}
