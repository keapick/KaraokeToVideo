//
//  TableView.h
//  KaraokeToVideoGUI
//
//  Created by Ernest Cho on 11/23/18.
//  Copyright © 2018 echo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TableView : NSTableView

@property (nonatomic, copy, readwrite) void (^completion)(NSArray *);

@end

NS_ASSUME_NONNULL_END
