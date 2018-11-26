//
//  TableView.m
//  KaraokeToVideoGUI
//
//  Created by Ernest Cho on 11/23/18.
//  Copyright © 2018 echo. All rights reserved.
//

#import "TableView.h"

// Adds drag and drop to a tableview
@implementation TableView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
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
    
    if (self.completion) {
        self.completion(urls);
    }
    
    return YES;
}

@end
