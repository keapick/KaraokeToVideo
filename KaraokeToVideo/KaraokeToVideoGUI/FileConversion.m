//
//  FileConversion.m
//  KaraokeToVideoGUI
//
//  Created by Ernest Cho on 11/23/18.
//  Copyright © 2018 echo. All rights reserved.
//

#import "FileConversion.h"

@implementation FileConversion

- (instancetype)init {
    self = [super init];
    if (self) {
        self.status = FileConversionStatusNull;
    }
    return self;
}

@end
