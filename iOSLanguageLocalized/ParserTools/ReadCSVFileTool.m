//
//  ReadCSVFileTool.m
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import "ReadCSVFileTool.h"

@implementation ReadCSVFileTool

/// Path to your CSV file (其中有转义换行)
/// 映射成: 
/// key = es.lproj
/// value = @[ " "key1" = "value1";  ", "  "key2" = "value2";  "] //数组里面放着字符串
+ (NSDictionary *)readCSVFileToArray:(NSString *)filePath {

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
/// key = es.lproj
/// value = @{ "key1" = "value1"; , "key2" = "value2"; }  //字典里面放着key=value
+ (NSDictionary *)readCSVFileToDict:(NSString *)filePath {
    
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
