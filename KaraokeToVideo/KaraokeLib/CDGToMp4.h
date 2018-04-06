//
//  CDGToMp4.h
//  Karaoke
//
//  Created by echo on 1/17/17.
//  Copyright © 2017 echo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CDGToMp4 : NSObject

- (instancetype)initWithMp3URL:(NSURL *)mp3URL cdgURL:(NSURL *)cdgURL mp4URL:(NSURL *)mp4URL overwrite:(BOOL)overwrite;

- (void)convertToMp4;
- (void)convertToMp4WithCompletion:(void (^)(void))completion;

@end
