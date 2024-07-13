//
//  ReadCSVFileManager.h
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReadCSVFileManager : NSObject

+ (NSDictionary *)readCSVFileToArray:(NSString *)filePath;

+ (NSDictionary *)readCSVFileToDict:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
