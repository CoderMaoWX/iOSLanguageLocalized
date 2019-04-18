//
//  ParserManager.h
//  CSVFileParser
//
//  Created by 610582 on 2019/4/18.
//  Copyright © 2019 610582. All rights reserved.
//
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
    #import <Foundation/Foundation.h>
#else
    #import <Cocoa/Cocoa.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ParserManager : NSObject

-(id)init;

-(BOOL)openFileWithPath:(NSString*)filePath;
-(void)closeFile;

-(char)autodetectDelimiter;

+(NSArray *)supportedDelimiters;
+(NSArray *)supportedDelimiterLocalizedNames;

+(NSArray *)supportedLineEndings;
+(NSArray *)supportedLineEndingLocalizedNames;

-(NSMutableArray*)parseFile;
-(NSMutableArray *)parseData;
-(NSMutableArray *)parseData:(NSData *)data;

@property (nonatomic, copy) NSData *data;

@property (nonatomic, assign) char delimiter;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, assign) BOOL foundQuotedCell;

@property (nonatomic, copy) NSString *delimiterString;
@property (nonatomic, copy) NSString *endOfLine;

@property (nonatomic, assign) size_t bufferSize;

@property (nonatomic, assign) BOOL verbose;

@end

NS_ASSUME_NONNULL_END
