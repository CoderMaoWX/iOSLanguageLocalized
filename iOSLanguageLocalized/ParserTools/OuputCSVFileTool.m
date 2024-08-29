//
//  OuputCSVFileTool.m
//  iOSLanguageLocalized
//
//  Created by wangxin.mao on 2024/7/15.
//  Copyright © 2024 610582. All rights reserved.
//

#import "OuputCSVFileTool.h"

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
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray arrayWithArray:[fileManger contentsOfDirectoryAtPath:localizbleURL error:nil]];
    [allLanguageDirArray removeObject:@".DS_Store"];//排除异常文件
    
    NSInteger count = 0;
    
    // 获取多语言目录列表: Key（Android/iOS Key), en.lproj, de.lproj, es.lproj ...
    for (NSString *pathDicr in allLanguageDirArray) {
        //NSLog(@"多语言文件夹子目录===%@", pathDicr);
        
        NSString *localizablePath = [NSString stringWithFormat:@"%@/%@/Localizable.strings", localizbleURL, pathDicr];
        if ([fileManger fileExistsAtPath:localizablePath]) {
            
            NSError *error = nil;
            //先读取项目中匹配的旧的翻译文件
            NSString *inputString = [NSString stringWithContentsOfFile: localizablePath
                                                              encoding: NSUTF8StringEncoding
                                                                 error: &error];
            
            NSArray *lines = [inputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableArray *validLines = [[NSMutableArray alloc] init];
            
            for (NSString *line in lines) {
                NSRange equalRange = [line rangeOfString:@"="];
                if (equalRange.location != NSNotFound) {
                    NSString *key = [[line substringToIndex:equalRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *value = [[line substringFromIndex:equalRange.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if (![key isEqualToString:@""] && ![value isEqualToString:@""]) {
                        if ([value hasSuffix:@";"]) {
                            NSString *tmpValue = [value stringByReplacingOccurrencesOfString:@";" withString:@""];
                            [validLines addObject:@[key, tmpValue]];
                        } else {
                            [validLines addObject:@[key, value]];
                        }
                    }
                }
            }
            
            NSMutableString *csvString = [NSMutableString stringWithCapacity:1000];
            [csvString appendFormat:@"key,%@\n", pathDicr];

            for (NSArray *pair in validLines) {
                [csvString appendFormat:@"%@,%@\n", pair[0], pair[1]];
            }
            
            if ([fileManger fileExistsAtPath:outputPath]) {
                NSString *outputURL = [NSString stringWithFormat:@"%@/%@.csv", outputPath, pathDicr];
                
                NSURL *fileURL = [NSURL fileURLWithPath: outputURL];
                [[csvString dataUsingEncoding:NSUTF8StringEncoding] writeToURL:fileURL options:NSDataWritingAtomic error:&error];
                
                if (error == nil) {
                    count += 1;
                }
            }
            
        //    if (error) {
        //        NSLog(@"Error writing to file: %@", error);
        //    } else {
        //        NSLog(@"CSV file successfully created!");
        //    }
        }
    }
    BOOL isSuccess = count == allLanguageDirArray.count;
    
    NSString *tipStr = @"💐恭喜, 多语言文件导出成功";
    if (!isSuccess) {
        tipStr = @"部分多语言文件导出成功, 请检查文件夹中是否存在其他文件";
    }
    if (compeletion) {
        compeletion(isSuccess, tipStr);
    }
}

// 测试逐行读取字符串方案
+ (void)testGenerateCSV:(NSString *)inputString
             outputPath:(NSString *)outputFilePath {

    // 准备一个可变字符串，用于构建CSV内容
    NSMutableString *csvContent = [NSMutableString stringWithString:@"key,value\n"];
    
    // 分割字符串为每一行
    NSArray *lines = [inputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *line in lines) {
        NSString *key = nil;
        NSString *value = nil;
        
        // 创建NSScanner
        NSScanner *scanner = [NSScanner scannerWithString:line];
        
        // 尝试扫描key
        if ([scanner scanString:@"\"" intoString:NULL] &&
            [scanner scanUpToString:@"\"" intoString:&key] &&
            [scanner scanString:@"\"" intoString:NULL] &&
            [scanner scanString:@"=" intoString:NULL] &&
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL] &&
            [scanner scanString:@"\"" intoString:NULL] &&
            [scanner scanUpToString:@"\"" intoString:&value] &&
            [scanner scanString:@"\"" intoString:NULL] &&
            [scanner scanString:@";" intoString:NULL]) {
            
            // 检查key和value是否为空白
            if (key.length > 0 && value.length > 0) {
                // 添加到CSV内容
                [csvContent appendFormat:@"%@,%@\n", key, value];
            }
        }
    }
    printf("写入CSV文件的内容: %s", csvContent.UTF8String);
    
    // 将CSV内容写入文件
    NSError *error = nil;
    BOOL success = [csvContent writeToFile:outputFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!success) {
        NSLog(@"写入CSV文件失败: %@", error);
    } else {
        NSLog(@"CSV文件写入成功: %@", outputFilePath);
    }
}

@end
