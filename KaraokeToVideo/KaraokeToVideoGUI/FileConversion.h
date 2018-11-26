//
//  FileConversion.h
//  KaraokeToVideoGUI
//
//  Created by Ernest Cho on 11/23/18.
//  Copyright © 2018 echo. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef NS_ENUM(NSInteger, FileConversionStatus) {
    FileConversionStatusNull,
    FileConversionStatusInQueue,
    FileConversionStatusFinished
};

NS_ASSUME_NONNULL_BEGIN

@interface FileConversion : NSObject

@property (nonatomic, strong, readwrite) NSString *filename;
@property (nonatomic, strong, readwrite) NSURL *mp3File;
@property (nonatomic, strong, readwrite) NSURL *cdgFile;
@property (nonatomic, strong, readwrite) NSURL *mp4File;

@property (nonatomic, assign, readwrite) FileConversionStatus status;

@end

NS_ASSUME_NONNULL_END
