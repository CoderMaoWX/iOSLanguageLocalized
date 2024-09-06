//
//  ReadCSVFileTool.m
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import "ReadCSVFileTool.h"
#import "MatchLanguageTool.h"
#import "ParserManager.h"

///CSV表格解析方案
@implementation ReadCSVFileTool

#pragma mark - CSV表格专业的解析方案

/**
 * 专业的解析方案
 */
+ (NSArray *)professionalParserCsvFileWithPath:(NSString *)filePath {
    ParserManager *parser = [[ParserManager alloc] init];
    BOOL open = [parser openFileWithPath:filePath];
    if (open) {
        [parser autodetectDelimiter];
        NSArray *infoArray = [parser parseFile];
        [parser closeFile];
        //NSLog(@"readCSVData111===%@", infoArray);
        return infoArray;
    } else {
        return nil;
    }
}

/// 映射成:
/// key = en.lproj
/// value = @[ " "key1" = "value1";  ", "  "key2" = "value2";  "] //数组里面放着字符串
+ (NSDictionary *)readCSVFileToKeyAndArray:(NSString *)filePath {
    NSMutableDictionary *bigDict = [NSMutableDictionary dictionary];
    
    //解析成一行一行的数据
    NSMutableArray *paraDataArr = [NSMutableArray arrayWithArray:[ReadCSVFileTool professionalParserCsvFileWithPath:filePath]];
    
    NSArray *headerFieldArr = paraDataArr.firstObject;
    [paraDataArr removeObjectAtIndex:0];
    
    for (NSArray *fieldValueArr in paraDataArr) {
        
        NSString *firstKey = nil;
        for (NSInteger j=0; j < fieldValueArr.count; j++) {
            NSString *fieldString = [MatchLanguageTool fileFieldValue: fieldValueArr[j] ];
            
            if (j == 0) {
                firstKey = fieldString;
            } else {
                NSString *keyValue = [NSString stringWithFormat:@"\"%@\" = \"%@\";", firstKey, fieldString];
                
                if (fieldValueArr.count == headerFieldArr.count && headerFieldArr.count > j) {
                    NSString *language = [MatchLanguageTool fileFieldValue: headerFieldArr[j] ];
                    
                    NSMutableArray *bigDictArr = bigDict[ language ];
                    if (![bigDictArr isKindOfClass:[NSMutableArray class]]) {
                        bigDictArr = [NSMutableArray array];
                    }
                    
                    if (fieldString.length == 0) { // 如果没有相应的翻译, 则使用英语
                        
                        NSString *chineseKey = [MatchLanguageTool chineseCSVKey];
                        NSArray *chineseAllKeyArr = MatchLanguageTool.mappingLanguageDict[chineseKey];
                        //如果是中文的value不存在
                        if ([chineseAllKeyArr containsObject:language]) {
                            //如果是中文: 特殊设置把key和value设置成一样的, 因为项目中是直接把中文当做key的
                            keyValue = [NSString stringWithFormat:@"\"%@\" = \"%@\";", firstKey, firstKey];
                            
                        } else {
                            NSString *englishKey = [MatchLanguageTool englishCSVKey];
                            //如果没匹配到英语的key, 就找映射字典看能否再次匹配
                            if (![bigDict.allKeys containsObject:englishKey]) {
                                englishKey = [MatchLanguageTool matchLanguageKey:englishKey csvToArrayDataDict:bigDict];
                            }
                            
                            NSArray *englishKeyValueArr = bigDict[englishKey];
                            if ([englishKeyValueArr isKindOfClass:[NSArray class]]) {
                                NSString *tmpEnglishKey = [NSString stringWithFormat:@"\"%@\" =", firstKey];
                                for (NSString *englishKeyValue in englishKeyValueArr) {
                                    if ([englishKeyValue containsString:tmpEnglishKey]) {
                                        keyValue = englishKeyValue;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    
                    [bigDictArr addObject:keyValue];
                    bigDict[ language ] = bigDictArr;
                }
            }
        }
    }
    return bigDict;
}

/// 映射成:
/// key = en.lproj
/// value = @{ "key1" = "value1"; , "key2" = "value2"; }  //字典里面放着: 翻译key=翻译value
+ (NSDictionary *)readCSVFileToKeyAndDict:(NSString *)filePath {
    NSMutableDictionary *bigDict = [NSMutableDictionary dictionary];
    
    //解析成一行一行的数据
    NSMutableArray *paraDataArr = [NSMutableArray arrayWithArray:[ReadCSVFileTool professionalParserCsvFileWithPath:filePath]];
    
    NSArray *headerFieldArr = paraDataArr.firstObject;
    [paraDataArr removeObjectAtIndex:0];
    
    for (NSArray *fieldValueArr in paraDataArr) {
        
        NSString *firstKey = nil;
        for (NSInteger j=0; j < fieldValueArr.count; j++) {
            NSString *fieldString = [MatchLanguageTool fileFieldValue: fieldValueArr[j] ];
            
            if (j == 0) {
                firstKey = fieldString;
            } else {
                //NSString *keyValue = [NSString stringWithFormat:@"\"%@\" = \"%@\";", firstKey, fieldString];
                
                if (fieldValueArr.count == headerFieldArr.count && headerFieldArr.count > j) {
                    NSString *language = [MatchLanguageTool fileFieldValue: headerFieldArr[j] ];
                    
                    NSMutableDictionary *bigDictArrDict = bigDict[ language ];
                    if (![bigDictArrDict isKindOfClass:[NSMutableDictionary class]]) {
                        bigDictArrDict = [NSMutableDictionary dictionary];
                    }
                    
                    if (fieldString.length == 0) { // 如果没有相应的翻译, 则使用英语
                        
                        NSString *chineseKey = [MatchLanguageTool chineseCSVKey];
                        NSArray *chineseAllKeyArr = MatchLanguageTool.mappingLanguageDict[chineseKey];
                        //如果是中文的value不存在
                        if ([chineseAllKeyArr containsObject:language]) {
                            //如果是中文: 特殊设置把key和value设置成一样的, 因为项目中是直接把中文当做key的
                            fieldString = firstKey;
                            
                        } else {
                            NSString *englishKey = [MatchLanguageTool englishCSVKey];
                            //如果没匹配到英语的key, 就找映射英语看能否再次匹配
                            if (![bigDict.allKeys containsObject:englishKey]) {
                                englishKey = [MatchLanguageTool matchLanguageKey:englishKey csvToArrayDataDict:bigDict];
                            }
                            
                            NSDictionary *englishDict = bigDict[englishKey];
                            if ([englishDict isKindOfClass:[NSDictionary class]]) {
                                fieldString = englishDict[firstKey];
                            }
                        }
                    }
                    
                    bigDictArrDict[firstKey] = fieldString;
                    bigDict[ language ] = bigDictArrDict;
                }
            }
        }
    }
    return bigDict;
}


#pragma mark - CSV表格手动解析备选方案

/// Path to your CSV file (其中有转义换行)
/// 映射成: 
/// key = en.lproj
/// value = @[ " "key1" = "value1";  ", "  "key2" = "value2";  "] //数组里面放着字符串
+ (NSDictionary *)backup_readCSVFileToKeyAndArray:(NSString *)filePath {

    NSError *error = nil;
    NSString *csvString = [NSString stringWithContentsOfFile:filePath
                                                    encoding:NSUTF8StringEncoding
                                                       error:&error];
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
        return nil;
    }
    
    NSArray *lines = [csvString componentsSeparatedByString:@"\n"];
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    
    if ([lines count] < 2) {
        NSLog(@"CSV file does not contain enough lines.");
        return nil;
    }
    
    // Get the header row
    NSArray *header = [[lines firstObject] componentsSeparatedByString:@","];
    
    // Process each line starting from the second line
    for (NSUInteger lineIndex = 1; lineIndex < [lines count]; lineIndex++) {
        NSString *line = lines[lineIndex];
        if ([line length] == 0) {
            continue; // Skip empty lines
        }
        
        NSArray *columns = [line componentsSeparatedByString:@","];
        if ([columns count] < [header count]) {
            continue; // Skip lines with fewer columns than the header
        }
        
        for (NSUInteger col = 1; col < [header count]; col++) {
            NSString *resultKey = header[col];
            if (![resultKey isKindOfClass:[NSString class]] || resultKey.length == 0
                || [resultKey isEqualToString:@"\r"]
                || [resultKey isEqualToString:@"\n"]) {
                continue;
            }
            //去除两头的空格
            resultKey = [resultKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            //去除所有换行符
            resultKey = [resultKey stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            resultKey = [resultKey stringByReplacingOccurrencesOfString:@"\n" withString:@""];

            NSMutableArray *columnArray = resultDict[resultKey];
            if (!columnArray) {
                columnArray = [NSMutableArray array];
                resultDict[resultKey] = columnArray;
            }
            
            NSString *key = columns[0];
            NSString *value = columns[col];
            
            // If value is empty, use the value from the second column
            if ([value length] == 0) {
                value = columns[1];
            }
            
            // Trim leading and trailing whitespace characters, including newlines
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // Replace any internal double quotes in value with escaped double quotes
            value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            // Format key-value pair as "key" = "value";
            NSString *pair = [NSString stringWithFormat:@"\"%@\" = \"%@\";", key, value];
            [columnArray addObject:pair];
        }
    }
    
    return resultDict;
}

// Path to your CSV file
/// 映射成:
/// key = en.lproj
/// value = @{ "key1" = "value1"; , "key2" = "value2"; }  //字典里面放着:  翻译key=翻译value
+ (NSDictionary *)backup_readCSVFileToKeyAndDict:(NSString *)filePath {
    
    NSError *error = nil;
    NSString *csvString = [NSString stringWithContentsOfFile:filePath
                                                    encoding:NSUTF8StringEncoding
                                                       error:&error];
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
        return nil;
    }
    
    NSArray *lines = [csvString componentsSeparatedByString:@"\n"];
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    
    if ([lines count] < 2) {
        NSLog(@"CSV file does not contain enough lines.");
        return nil;
    }
    
    // Get the header row
    NSArray *header = [[lines firstObject] componentsSeparatedByString:@","];
    
    // Process each line starting from the second line
    for (NSUInteger lineIndex = 1; lineIndex < [lines count]; lineIndex++) {
        NSString *line = lines[lineIndex];
        if ([line length] == 0) {
            continue; // Skip empty lines
        }
        
        NSArray *columns = [line componentsSeparatedByString:@","];
        if ([columns count] < [header count]) {
            continue; // Skip lines with fewer columns than the header
        }
        
        for (NSUInteger col = 1; col < [header count]; col++) {
            NSString *resultKey = header[col];
            if (![resultKey isKindOfClass:[NSString class]] || resultKey.length == 0
                || [resultKey isEqualToString:@"\r"]
                || [resultKey isEqualToString:@"\n"]) {
                continue;
            }
            //去除两头的空格
            resultKey = [resultKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            //去除所有换行符
            resultKey = [resultKey stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            resultKey = [resultKey stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
            NSMutableDictionary *columnDict = resultDict[resultKey];
            if (!columnDict) {
                columnDict = [NSMutableDictionary dictionary];
                resultDict[resultKey] = columnDict;
            }
            
            NSString *key = columns[0];
            NSString *value = columns[col];
            
            // If value is empty, use the value from the second column
            if ([value length] == 0) {
                value = columns[1];
            }
            
            // Trim leading and trailing whitespace characters, including newlines
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // Replace any internal double quotes in value with escaped double quotes
            value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            // Add the key-value pair to the dictionary
            columnDict[key] = value;
        }
    }
    return resultDict;
}

@end
