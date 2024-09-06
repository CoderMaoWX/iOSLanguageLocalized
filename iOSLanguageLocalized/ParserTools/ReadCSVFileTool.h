//
//  ReadCSVFileTool.h
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


///CSV表格解析方案
@interface ReadCSVFileTool : NSObject

#pragma mark - CSV表格专业的解析方案

/// 映射成:
/// key = en.lproj
/// value = @[ " "key1" = "value1";  ", "  "key2" = "value2";  "] //数组里面放着字符串
+ (NSDictionary *)readCSVFileToKeyAndArray:(NSString *)filePath;

/// 映射成:
/// key = en.lproj
/// value = @{ "key1" = "value1"; , "key2" = "value2"; }  //字典里面放着: 翻译key=翻译value
+ (NSDictionary *)readCSVFileToKeyAndDict:(NSString *)filePath;



#pragma mark - CSV表格手动解析备选方案

+ (NSDictionary *)backup_readCSVFileToKeyAndArray:(NSString *)filePath;

+ (NSDictionary *)backup_readCSVFileToKeyAndDict:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
