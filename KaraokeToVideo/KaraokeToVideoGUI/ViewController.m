//
//  ViewController.m
//  KaraokeToVideoGUI
//
//  Created by Ernest Cho on 2/14/18.
//  Copyright © 2018 echo. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    [self.view.window setTitle:@"MP3+CDG -> MP4"];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
