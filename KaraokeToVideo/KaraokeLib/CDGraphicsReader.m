//
//  CDGraphicsReader.m
//  KaraokeToVideo
//
//  Created by echo on 6/25/17.
//  Copyright © 2017 echo. All rights reserved.
//

#import "CDGraphicsReader.h"

// cdg data packets are 24 bytes
static int const CDGDataPacketSize = 24;

// data stream rate
static int const CDGPacketsPerSecond = 300;

// command byte marks the start of a command
static int const CDGMask = '\x3F';
static int const CDGCommandByte = '\x09';

// instructions
static int const CDGMemoryPreset = 1;
static int const CDGBorderPreset = 2;
static int const CDGColorsLow = 30;
static int const CDGColorsHigh = 31;
static int const CDGTileBlock = 6;
static int const CDGTileBlockXOR = 38;

// number of colors
static int const CDGColorCount = 16;

// color masks
static const char maskArray[] = {
    0x20, 0x10, 0x08, 0x04, 0x02, 0x01
};

// start of data skipping the command, instruction and parity bytes
static int const dataStart = 4;

// start of the color bitmap
static int const colorStart = 8;

@interface CDGraphicsReader() {
    // C file handle.  I cannot figure out how to get NSFileHandle to stop mangling binary files.
    FILE *file;
    char buffer[CDGDataPacketSize];
    
    // bitmap containing color index values
    int bitmap[CDGFrameWidth][CDGFrameHeight];
}

@property (nonatomic, strong, readwrite) NSMutableArray *colors;

// working frame
@property (nonatomic, assign, readwrite) CVPixelBufferRef frame;

// a lot of frames are exact duplicates of the previous frame
@property (nonatomic, assign, readwrite) BOOL frameHasChanged;
@end

@implementation CDGraphicsReader

- (instancetype)initWithCDG:(NSURL *)cdg {
    self = [super init];
    if (self) {
        [self openCDGFile:cdg];
        self.colors = [[NSMutableArray alloc] initWithCapacity:CDGColorCount];
        self.frameHasChanged = NO;
        self.frame = [self createFrame];
    }
    return self;
}

- (void)openCDGFile:(NSURL *)cdg {
    file = fopen(cdg.path.UTF8String, "rb");
}

- (void)close {
    fclose(file);
}

// create a new frame
- (CVPixelBufferRef)createFrame {
    CVPixelBufferRef frame = nil;
    
    // https://developer.apple.com/documentation/corevideo/1456758-cvpixelbuffercreate
    // https://developer.apple.com/library/content/qa/qa1501/_index.html
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CDGFrameWidth, CDGFrameHeight, kCVPixelFormatType_32BGRA, nil, &frame);
    NSParameterAssert(status == kCVReturnSuccess && frame != nil);
    
    return frame;
}

// update the working frame
- (void)updateFrame:(CVPixelBufferRef)frame {
    CVPixelBufferLockBaseAddress(frame, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(frame);
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(frame);
    
    for (int i = 0; i < CDGFrameHeight; i++) {
        uint8_t *pixel = baseAddress + (i * bytesPerRow);
        for (int j = 0; j < CDGFrameWidth; j++) {
            NSColor *color = [self colorAtIndex:bitmap[j][i]];
            pixel[0] = (int)(color.blueComponent * 255.0);
            pixel[1] = (int)(color.greenComponent * 255.0);
            pixel[2] = (int)(color.redComponent * 255.0);
            pixel[4] = 1;
            
            pixel = pixel + 4;
        }
    }
    
    CVPixelBufferUnlockBaseAddress(frame, 0);
}

// return a copy of the working frame
- (CVPixelBufferRef)copyFrame:(CVPixelBufferRef)frame {
    CVPixelBufferRef copy = [self createFrame];
    CVPixelBufferLockBaseAddress(frame, 0);
    CVPixelBufferLockBaseAddress(copy, 0);
    
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(frame);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(frame);

    uint8_t *copyBaseAddress = CVPixelBufferGetBaseAddress(copy);
    memcpy(copyBaseAddress, baseAddress, CDGFrameHeight * bytesPerRow);
    
    CVPixelBufferUnlockBaseAddress(frame, 0);
    CVPixelBufferUnlockBaseAddress(copy, 0);
    return copy;
}

- (CVPixelBufferRef)nextFrame {
    if (!feof(file)) {
        [self parseToNextFrame];
        if (self.frameHasChanged) {
            [self updateFrame:self.frame];
        }
        return [self copyFrame:self.frame];
    }
    return nil;
}

- (void)parseToNextFrame {
    self.frameHasChanged = NO;
    for (int i=0; i<(CDGPacketsPerSecond/CDGFramesPerSecond) && !feof(file); i++) {
        fread(buffer, CDGDataPacketSize, 1, file);

        char command = buffer[0] & CDGMask;
        char instruction = buffer[1] & CDGMask;
        
        if (command == CDGCommandByte) {
            switch (instruction) {
                case CDGColorsLow:
                    [self updateColorsIsLowBlock:YES];
                    self.frameHasChanged = YES;
                    break;
                case CDGColorsHigh:
                    [self updateColorsIsLowBlock:NO];
                    self.frameHasChanged = YES;
                    break;
                case CDGMemoryPreset:
                    [self writeMemoryPreset];
                    break;
                case CDGBorderPreset:
                    [self writeBorderPreset];
                    break;
                case CDGTileBlockXOR:
                    [self writeTileBlockIsXOR:YES];
                    break;
                case CDGTileBlock:
                    [self writeTileBlockIsXOR:NO];
                    break;
                default:
                    // screen unchanged pause for audio
                    break;
            }
        }
    }
}

// colors come in two blocks of 8 colors each
- (void)updateColorsIsLowBlock:(BOOL)isLowBlock {
    
    // are we updating the first 8 colors or last 8 colors?
    int colorIndex = isLowBlock ? 0 : 8;
    
    for (int i = 0; i < 16; i = i + 2, colorIndex = colorIndex + 1) {
        
        // cdg files have 16 bit color, and omits an alpha.  only 12 bits of data
        int red = 0, green = 0, blue = 0;
        
        // grab two bytes at a time
        int lowbyte = buffer[dataStart+i];
        int highbyte = buffer[dataStart+i+1];
        
        // 4 bits for red
        if ((lowbyte & 0x20) > 0) {
            red = 8;
        }
        if ((lowbyte & 0x10) > 0) {
            red = red + 4;
        }
        if ((lowbyte & 0x08) > 0) {
            red = red + 2;
        }
        if ((lowbyte & 0x04) > 0) {
            red = red + 1;
        }
        
        // 4 bits for green
        if ((lowbyte & 0x02) > 0) {
            green = 8;
        }
        if ((lowbyte & 0x01) > 0) {
            green = green + 4;
        }
        if ((highbyte & 0x20) > 0) {
            green = green + 2;
        }
        if ((highbyte & 0x10) > 0) {
            green = green + 1;
        }
        
        // 4 bits for blue
        if ((highbyte & 0x08) > 0) {
            blue = 8;
        }
        if ((highbyte & 0x04) > 0) {
            blue = blue + 4;
        }
        if ((highbyte & 0x02) > 0) {
            blue = blue + 2;
        }
        if ((highbyte & 0x01) > 0) {
            blue = blue + 1;
        }
        
        // convert 4 bit color to 8 bit color
        blue = blue * 17;
        red = red * 17;
        green = green * 17;
        
        // save as a 32 bit color
        NSColor *color = [NSColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:1.0f];
        self.colors[colorIndex] = color;
    }
}

- (NSColor *)colorAtIndex:(int)index {
    if (index > -1 && index < self.colors.count) {
        NSColor *tmp = [self.colors objectAtIndex:index];
        if (tmp) {
            return tmp;
        }
    }
    
    // default color is white. should never get here.
    return [NSColor colorWithRed:1.0f green:1.0f blue:0.0f alpha:1.0f];
}

// paint a tile on the frame
- (void)paintFrame:(int)colorIndex rowStart:(int)rowStart rowEnd:(int)rowEnd colStart:(int)colStart colEnd:(int)colEnd {
    for (int i = rowStart; i < rowEnd; i++) {
        for (int j = colStart; j < colEnd; j++) {
            if (bitmap[j][i] != colorIndex) {
                self.frameHasChanged = YES;
                bitmap[j][i] = colorIndex;
            }
        }
    }
}

// paints background color
- (void)writeMemoryPreset {
    int colorIndex = buffer[dataStart] & 0x0F;
    [self paintFrame:colorIndex rowStart:0 rowEnd:CDGFrameHeight colStart:0 colEnd:CDGFrameWidth];
}

// paints a border
- (void)writeBorderPreset {
    int colorIndex = buffer[dataStart] & 0x0F;
    
    // top
    [self paintFrame:colorIndex rowStart:0 rowEnd:12 colStart:0 colEnd:CDGFrameWidth];
    
    // bottom
    [self paintFrame:colorIndex rowStart:202 rowEnd:CDGFrameHeight colStart:0 colEnd:CDGFrameWidth];
    
    // left
    [self paintFrame:colorIndex rowStart:11 rowEnd:204 colStart:0 colEnd:6];
    
    // right
    [self paintFrame:colorIndex rowStart:11 rowEnd:204 colStart:294 colEnd:CDGFrameWidth];
}

// paints tiles
- (void)writeTileBlockIsXOR:(BOOL)isXOR {
    
    // reference colors
    int colorIndexA = buffer[dataStart] & 0x0F;
    int colorIndexB = buffer[dataStart+1] & 0x0F;
    
    // tile position
    int top = (buffer[dataStart + 2] & 0x1F) * 12;
    int left = (buffer[dataStart + 3] & 0x3F) * 6;

    for (int i=0; i<12; i++) {
        for (int j=0; j<6; j++) {
            
            // find out which color goes in this pixel
            int colorIndex = (buffer[colorStart + i] & maskArray[j]) ? colorIndexB : colorIndexA;
            if (isXOR) {
                if (bitmap[left+j][top+i] != (bitmap[left+j][top+i] ^ colorIndex)) {
                    self.frameHasChanged = YES;
                    bitmap[left+j][top+i] = bitmap[left+j][top+i] ^ colorIndex;
                }
            } else {
                if (bitmap[left+j][top+i] != colorIndex) {
                    self.frameHasChanged = YES;
                    bitmap[left+j][top+i] = colorIndex;
                }
            }
        }
    }
}

@end
