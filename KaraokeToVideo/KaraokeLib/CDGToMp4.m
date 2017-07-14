//
//  CDGToMp4.m
//  Karaoke
//
//  Created by echo on 1/17/17.
//  Copyright © 2017 echo. All rights reserved.
//

#import "CDGToMp4.h"
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CDGraphicsReader.h"


@interface CDGToMp4()

@property (nonatomic, strong, readwrite) NSURL *mp3URL;
@property (nonatomic, strong, readwrite) NSURL *cdgURL;
@property (nonatomic, strong, readwrite) NSURL *mp4URL;

// AV classes
@property (nonatomic, strong, readwrite) AVAssetWriter *videoWriter;
@property (nonatomic, strong, readwrite) AVAssetWriterInputPixelBufferAdaptor *videoAdaptor;

@end

@implementation CDGToMp4

- (instancetype)initWithMp3URL:(NSURL *)mp3URL cdgURL:(NSURL *)cdgURL mp4URL:(NSURL *)mp4URL{
    self = [super init];
    if (self) {
        self.mp3URL = mp3URL;
        self.cdgURL = cdgURL;
        self.mp4URL = mp4URL;
        
        // TODO: make this more reasonable, maybe move to backup version or only delete when force flag is set
        [self cleanUpFiles];
    }
    return self;
}

- (void)cleanUpFiles {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:[self tmpFile] error:&error];
    [[NSFileManager defaultManager] removeItemAtURL:self.mp4URL error:&error];
}

- (NSURL *)tmpFile {
    return [NSURL fileURLWithPath:@"tmp.mp4"];
}

// blocking convert method
- (void)convertToMp4 {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self convertToMp4WithCompletion:^{
        dispatch_semaphore_signal(semaphore);
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    }
}

- (void)convertToMp4WithCompletion:(void (^)())completion {
    
    // CDG -> MP4 with no audio
    [self convertCDGToMp4WithCompletion:^{
        
        // MP4 + MP3 -> MP4 with audio
        [self addMp3ToMp4WithCompletion:completion];
    }];
}

// fast conversion from MP4 + MP3 -> MP4
- (void)addMp3ToMp4WithCompletion:(void (^)())completion {
    
    AVAsset *video = [AVAsset assetWithURL:[self tmpFile]];
    AVAsset *audio = [AVAsset assetWithURL:self.mp3URL];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, video.duration)
                        ofTrack:[[video tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audio.duration)
                        ofTrack:[[audio tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];

    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset640x480];
    exporter.outputURL = self.mp4URL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        if (completion) {
            completion();
        }
    }];
}

// slow conversion from CDG -> MP4
// ffmpeg is also pretty slow. CDG is just a crappy video format.
- (void)convertCDGToMp4WithCompletion:(void (^)())completion {
    CDGraphicsReader *reader = [[CDGraphicsReader alloc] initWithCDG:self.cdgURL];
    
    [self setupVideo];
    
    CMTime frameRate = CMTimeMake(1, 15);
    __block CMTime next = frameRate;
    
    // pull style buffer, it asks for data as it's ready
    // https://developer.apple.com/documentation/avfoundation/avassetwriterinput/1387508-requestmediadatawhenreadyonqueue
    [self.videoAdaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:dispatch_get_main_queue() usingBlock:^{
        while ([self.videoAdaptor.assetWriterInput isReadyForMoreMediaData]) {
            CVPixelBufferRef buffer = [reader nextFrame];
            if (buffer) {
                [self.videoAdaptor appendPixelBuffer:buffer withPresentationTime:next];
                CVBufferRelease(buffer);
                next = CMTimeAdd(next, frameRate);
            } else {
                [reader close];
                [self closeVideoWithCompletion:completion];
                break;
            }
        }
    }];
}

// setup video
- (void)setupVideo {
    NSURL *tmpFile = [self tmpFile];
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:tmpFile fileType:AVFileTypeMPEG4 error:nil];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:CDGFrameWidth], AVVideoWidthKey,
                                   [NSNumber numberWithInt:CDGFrameHeight], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    self.videoAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    
    [self.videoWriter addInput:videoWriterInput];
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
}

// close video
- (void)closeVideoWithCompletion:(void (^)())completion {
    [self.videoAdaptor.assetWriterInput markAsFinished];
    [self.videoWriter finishWritingWithCompletionHandler:^{
        if (completion) {
            completion();
        }
    }];
}

@end
