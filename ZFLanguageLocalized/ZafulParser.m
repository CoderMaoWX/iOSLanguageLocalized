//
//  ZafulParser.m
//  ZFLanguageLocalized
//
//  Created by 610582 on 2019/4/18.
//  Copyright © 2019 610582. All rights reserved.
//

#import "ZafulParser.h"
#import "ParserManager.h"
#import "CvsStringParser.h"

@implementation ZafulParser

/**
 * 专业的解析方案, (有可能为空)
 */
+ (NSArray *)professionalParserCsvFileWithPath:(NSString *)filePath {
    ParserManager *parser = [[ParserManager alloc] init];
    BOOL open = [parser openFileWithPath:filePath];
    if (open) {
        NSArray *infoArray = [parser parseFile];
        NSLog(@"readCSVData===%@", infoArray);
        return infoArray;
    } else {
        NSLog(@"解析文件失败");
        return nil;
    }
}

/**
 * 备选解析方案, (此解析方案可能不准, 只要在上面的专业解析方法失败时才推荐调用)
 */
+ (NSArray *)backupParserCsvFileWithPath:(NSString *)filePath {
    NSString *CSVString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    if (CSVString) {
        NSArray *infoArray = [[CvsStringParser parser] parseCSVString:CSVString];
        NSLog(@"readCSVData===%@", infoArray);
        return infoArray;
    } else {
        NSLog(@"解析文件失败");
        return nil;
    }
}

@end
