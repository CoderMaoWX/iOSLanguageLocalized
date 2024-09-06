//
//  OuputCSVFileTool.m
//  iOSLanguageLocalized
//
//  Created by wangxin.mao on 2024/7/15.
//  Copyright © 2024 610582. All rights reserved.
//

#import "OuputCSVFileTool.h"

///导出多语言到表格
@implementation OuputCSVFileTool

+ (void)generateCSV:(NSString *)localizbleURL
         outputPath:(NSString *)outputFilePath
        compeletion:(void (^)(BOOL status, NSString *tipStr))compeletion {
    
    NSFileManager *fileManger = [NSFileManager defaultManager];
    
    BOOL isDirectory = NO;
    BOOL isExists = [fileManger fileExistsAtPath:outputFilePath isDirectory:&isDirectory];
    if (!isExists) {
        if (compeletion) {
            compeletion(NO, @"导出路径不存在");
        }
        return;
    }
    
    NSString *outputPath = outputFilePath;
    if (!isDirectory) {
        NSString *tmpSeparated = [outputPath componentsSeparatedByString:@"/"].lastObject;
        outputPath = [outputPath componentsSeparatedByString:tmpSeparated].firstObject;
    }
    
    NSArray *allLanguageNames = [fileManger contentsOfDirectoryAtPath:localizbleURL error:nil];
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray array];
    //排除异常文件
    for (NSString *fileName in allLanguageNames) {
        if ([fileName.lowercaseString hasSuffix:@".lproj"]) {
            [allLanguageDirArray addObject:fileName];
        }
    }
    
    if (allLanguageDirArray.count == 0) {
        if (compeletion) {
            compeletion(NO, @"项目路径文件夹中不存在国际化多语言翻译文件");
        }
        return;
    }
    
    NSInteger failCount = 0;
    NSInteger allCount = 0;
    
    // 获取多语言目录列表: Key（Android/iOS Key), en.lproj, de.lproj, es.lproj ...
    for (NSString *pathDicr in allLanguageDirArray) {
        
        NSString *tmpPath = [NSString stringWithFormat:@"%@/%@", localizbleURL, pathDicr];
        NSArray *lprojSubDirectoryArr = [fileManger contentsOfDirectoryAtPath:tmpPath error:nil];
        
        for (NSString *subPath in lprojSubDirectoryArr) {
            if (![subPath.lowercaseString hasSuffix:@".strings"]) {
                continue;
            }
            allCount += 1;
            
            NSString *localizablePath = [NSString stringWithFormat:@"%@/%@", tmpPath, subPath];
            if (![fileManger fileExistsAtPath:localizablePath]) {
                failCount += 1;
                continue;
            }
            NSError *error = nil;
            //先读取项目中匹配的旧的翻译文件
            NSString *inputString = [NSString stringWithContentsOfFile: localizablePath
                                                              encoding: NSUTF8StringEncoding
                                                                 error: &error];
            
            NSArray *lines = [inputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableArray *validLines = [[NSMutableArray alloc] init];
            
            for (NSString *line in lines) {
                NSRange equalRange = [line rangeOfString:@"="];
                if (equalRange.location == NSNotFound) { continue; }
                
                NSCharacterSet *character = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                NSString *key = [[line substringToIndex:equalRange.location] stringByTrimmingCharactersInSet:character];
                NSString *value = [[line substringFromIndex:equalRange.location + 1] stringByTrimmingCharactersInSet:character];
                
                if (![key isEqualToString:@""] && ![value isEqualToString:@""]) {
                    if ([value hasSuffix:@";"]) {
                        NSString *tmpValue = [value stringByReplacingOccurrencesOfString:@";" withString:@""];
                        [validLines addObject:@[key, tmpValue]];
                    } else {
                        [validLines addObject:@[key, value]];
                    }
                }
            }
            
            NSMutableString *csvString = [NSMutableString stringWithCapacity:1000];
            [csvString appendFormat:@"key,%@\n", pathDicr];
            
            for (NSArray *pair in validLines) {
                [csvString appendFormat:@"%@,%@\n", pair[0], pair[1]];
            }
            
            if (![fileManger fileExistsAtPath:outputPath]) {
                failCount += 1;
                continue;
            }
            NSString *joinName = [subPath componentsSeparatedByString:@"."].firstObject;
            NSString *nameSuffix = [pathDicr componentsSeparatedByString:@"."].firstObject;
            NSString *outputURL = [NSString stringWithFormat:@"%@/%@-%@.csv", outputPath, joinName, nameSuffix];
            
            NSURL *fileURL = [NSURL fileURLWithPath: outputURL];
            BOOL success = [[csvString dataUsingEncoding:NSUTF8StringEncoding] writeToURL:fileURL options:NSDataWritingAtomic error:&error];
            
            if (success == NO) {
                failCount += 1;
            }
        }
    }
    
    if (!compeletion) { return; }
    
    if (failCount == 0) {
        compeletion(YES, @"💐恭喜, 多语言文件全部导出成功");
        
    } else if (failCount == allCount) {
        compeletion(NO, @"😰糟糕, 多语言文件全部导出失败,请检查文件格式");
    } else {
        compeletion(YES, @"❗️多语言部分导出成功, 部分导出失败, 请检查文件格式");
    }
}

@end
