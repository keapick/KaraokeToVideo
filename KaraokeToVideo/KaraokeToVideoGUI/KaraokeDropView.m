//
//  KaraokeDropView.m
//  KaraokeToVideoGUI
//
//  Created by Ernest Cho on 3/7/18.
//  Copyright © 2018 echo. All rights reserved.
//

#import "KaraokeDropView.h"
#import "CDGToMp4.h"

@interface KaraokeDropView()

@property (nonatomic, strong, readwrite) dispatch_queue_t serialQueue;

@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSURL *> *mp3s;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSURL *> *cdgs;

@end

@implementation KaraokeDropView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.serialQueue = dispatch_queue_create("com.echo.KaraokeToVideo", DISPATCH_QUEUE_SERIAL);

        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
        
        self.mp3s = [NSMutableDictionary new];
        self.cdgs = [NSMutableDictionary new];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

// prevent beachball?
- (void)mouseDown:(NSEvent *)theEvent {
    NSInteger clickCount = [theEvent clickCount];
    if (clickCount > 1) {
        NSLog(@"Click!");
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *urls = (NSArray *)[pboard readObjectsForClasses:@[[NSURL class]] options:nil];
    
    [self sortUrls:urls];
    [self convertFilesToMp4];
    
    return YES;
}

- (void)convertFilesToMp4 {
    for (NSString *key in self.mp3s.allKeys) {
        // check for matching mp3 and cdg files
        __block NSURL *mp3 = [NSURL fileURLWithPath:[self.mp3s objectForKey:key].path];
        __block NSURL *cdg = [NSURL fileURLWithPath:[self.cdgs objectForKey:key].path];
        
        if (cdg && mp3) {
            [self createMp4FromMp3:mp3 cdg:cdg];
        } else {
            NSLog(@"Failed to find matching mp3 and cdg files. %@", key);
        }
    }
    
    // empty the drag and drop list so we don't try them again
    self.mp3s = [NSMutableDictionary new];
    self.cdgs = [NSMutableDictionary new];
}

// queue up a background task to convert
- (void)createMp4FromMp3:(NSURL *)mp3 cdg:(NSURL *)cdg {
    dispatch_async(self.serialQueue, ^{
        
        // create matching mp4 url
        NSString *mp4Path = [[mp3.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"mp4"];
        NSURL *mp4 = [NSURL fileURLWithPath:mp4Path];
        
        CDGToMp4 *converter = [[CDGToMp4 alloc] initWithMp3URL:mp3 cdgURL:cdg mp4URL:mp4 overwrite:NO];
        [converter convertToMp4];
    });
}

// sort URLs by file extension
- (void)sortUrls:(NSArray *)urls {
    for (NSURL *url in urls) {
        NSString *key = [url.lastPathComponent stringByDeletingPathExtension];
        if ([[[url pathExtension] lowercaseString] isEqualToString:@"mp3"]) {
            [self.mp3s setObject:url forKey:key];
        } else if ([[[url pathExtension] lowercaseString] isEqualToString:@"cdg"]) {
            [self.cdgs setObject:url forKey:key];
        } else {
            NSLog(@"Ignoring: %@", url.path);
        }
    }
}

@end
