//
//  ViewController.m
//  KaraokeToVideoGUI
//
//  Created by Ernest Cho on 2/14/18.
//  Copyright © 2018 echo. All rights reserved.
//

#import "ViewController.h"
#import "FileConversion.h"
#import "TableView.h"
#import "CDGToMp4.h"

@interface ViewController()

@property (nonatomic, strong, readwrite) dispatch_queue_t serialQueue;

@property (nonatomic, strong, readwrite) NSMutableArray<NSString *> *filenames;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, FileConversion *> *fileConversions;

@property (nonatomic, strong, readwrite) IBOutlet TableView *tableView;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        self.serialQueue = dispatch_queue_create("com.echo.KaraokeToVideo", DISPATCH_QUEUE_SERIAL);
        
        self.filenames = [NSMutableArray<NSString *> new];
        self.fileConversions = [NSMutableDictionary<NSString *, FileConversion *> new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    self.tableView.completion = ^(NSArray *urls) {
        [weakSelf handleDragAndDroppedURLs:urls];
    };
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    [self.view.window setTitle:@"MP3+CDG -> MP4"];
    
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.filenames.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSString *cellViewIdentifier = @"TableRow";
    if (row > self.filenames.count) {
        return nil;
    }
    
    FileConversion *fileConversion = [self.fileConversions objectForKey:[self.filenames objectAtIndex:row]];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:cellViewIdentifier owner:nil];
    if (tableColumn == tableView.tableColumns[0]) {
        cell.textField.stringValue = fileConversion.filename;
        
    } else if (tableColumn == tableView.tableColumns[1]) {
        switch (fileConversion.status) {
            case FileConversionStatusFinished:
                cell.textField.stringValue = @"Done! ✅";
                break;
            case FileConversionStatusInQueue:
                cell.textField.stringValue = @"In Queue. 🐌";
                break;
                
            case FileConversionStatusNull:
            default:
                cell.textField.stringValue = @"Error";
                break;
        }
    }
    return cell;
}

- (void)handleDragAndDroppedURLs:(NSArray *)urls {
    [self processURLs:urls];
    [self convertFilesToMp4];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)processURLs:(NSArray *)urls {
    
    // sort new urls by file extension
    NSMutableSet <NSString *> *keys = [NSMutableSet<NSString *> new];
    NSMutableDictionary<NSString *, NSURL *> *mp3s = [NSMutableDictionary<NSString *, NSURL *> new];
    NSMutableDictionary<NSString *, NSURL *> *cdgs = [NSMutableDictionary<NSString *, NSURL *> new];
    
    for (NSURL *url in urls) {
        NSString *key = [url.lastPathComponent stringByDeletingPathExtension];
        [keys addObject:key];
        
        if ([[[url pathExtension] lowercaseString] isEqualToString:@"mp3"]) {
            [mp3s setObject:url forKey:key];
        } else if ([[[url pathExtension] lowercaseString] isEqualToString:@"cdg"]) {
            [cdgs setObject:url forKey:key];
        } else {
            NSLog(@"Invalid file: %@", key);
        }
    }
    
    // add valid urls to the list
    for (NSString *key in keys) {
        FileConversion *fileConversion = [self.fileConversions objectForKey:key];
        
        if (!fileConversion) {
            NSURL *mp3 = [mp3s objectForKey:key];
            NSURL *cdg = [cdgs objectForKey:key];
        
            if (mp3 && cdg) {
                fileConversion = [FileConversion new];
                fileConversion.filename = key;
                fileConversion.mp3File = mp3;
                fileConversion.cdgFile = cdg;
                
                [self.filenames addObject:key];
                [self.fileConversions setObject:fileConversion forKey:key];
                
            } else {
                if (!mp3) {
                    NSLog(@"Missing mp3 file: %@", key);
                } else if (!cdg) {
                    NSLog(@"Missing cdg file: %@", key);
                }
            }
            
        } else {
            NSLog(@"Ignoring duplicate file: %@", key);
        }
    }
}

- (void)convertFilesToMp4 {
    for (NSString *filename in self.filenames) {
        FileConversion *fileConversion = [self.fileConversions objectForKey:filename];
        if (fileConversion.status == FileConversionStatusNull) {
            
            // create matching mp4 url, this gets saved in the same folder as the mp3 file
            NSString *mp4Path = [[fileConversion.mp3File.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"mp4"];
            fileConversion.mp4File = [NSURL fileURLWithPath:mp4Path];
    
            fileConversion.status = FileConversionStatusInQueue;
            dispatch_async(self.serialQueue, ^{
                
                CDGToMp4 *converter = [[CDGToMp4 alloc] initWithMp3URL:fileConversion.mp3File cdgURL:fileConversion.cdgFile mp4URL:fileConversion.mp4File overwrite:NO];
                [converter convertToMp4WithCompletion:^{
                    fileConversion.status = FileConversionStatusFinished;

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }];
            });
        }
    }
}

@end
