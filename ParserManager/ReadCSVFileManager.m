//
//  ReadCSVFileManager.m
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import "ReadCSVFileManager.h"

@implementation ReadCSVFileManager

/// Path to your CSV file (其中有转义换行)
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
            NSMutableArray *columnArray = resultDict[header[col]];
            if (!columnArray) {
                columnArray = [NSMutableArray array];
                resultDict[header[col]] = columnArray;
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
    
    // Print or use resultDict as needed
//    NSDictionary *tmpDict = [NSDictionary dictionaryWithDictionary:resultDict];
//    NSLog(@"Processed results: %@", tmpDict);
//    for (NSString *columnKey in resultDict) {
//        NSLog(@"%@: %@", columnKey, resultDict[columnKey]);
//        NSLog(@"\n");
//    }
}

// Path to your CSV file
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
            NSMutableDictionary *columnDict = resultDict[header[col]];
            if (!columnDict) {
                columnDict = [NSMutableDictionary dictionary];
                resultDict[header[col]] = columnDict;
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
    
//    // Print or use resultDict as needed
//    NSLog(@"Processed results:");
//    for (NSString *columnKey in resultDict) {
//        NSLog(@"%@: %@", columnKey, resultDict[columnKey]);
//        NSLog(@"\n");
//    }
}


@end
