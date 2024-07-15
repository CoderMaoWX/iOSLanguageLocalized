//
//  OuputCSVFileManager.m
//  ZFLanguageLocalized
//
//  Created by wangxin.mao on 2024/7/15.
//  Copyright © 2024 610582. All rights reserved.
//

#import "OuputCSVFileManager.h"

@implementation OuputCSVFileManager

+ (void)parseAndGenerateCSV:(NSString *)inputString outputFilePath:(NSString *)outputFilePath {
    // 创建NSScanner
    NSScanner *scanner = [NSScanner scannerWithString:inputString];
    
    // 准备一个可变字符串，用于构建CSV内容
    NSMutableString *csvContent = [NSMutableString stringWithString:@"key,value\n"];
    
    // 扫描整个字符串
    while (![scanner isAtEnd]) {
        NSString *key = nil;
        NSString *value = nil;
        
        // 尝试扫描key
        if ([scanner scanString:@"\"" intoString:NULL] &&
            [scanner scanUpToString:@"\"" intoString:&key] &&
            [scanner scanString:@"\"" intoString:NULL] &&
            [scanner scanString:@"=" intoString:NULL] &&
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
        
        // 跳过当前行的其余部分，准备扫描下一行
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
        [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
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

// printf("写入CSV文件的内容: %s", csvContent.UTF8String);
/// 测试输出csv文件
+ (void)testOuputCSVFile {
    
    // 示例字符串
    NSString *inputString = @"\"Register_Button\" = \"Register\";\n"
    "\"Register_Button_left\" = \"Register\";\n"
    "\"Register_Email\" = \"Email Address\";\n"
    "\"Register_Password\" = \"Password\";\n"
    "\"Register_FB_Connect\" = \"   Facebook\";\n"
    "\"Register_GG_Connect\" = \"   We pay great attentis is an integral part of the app and will only ever be carried out with your consent\";\n"
    "\"Register_policy\" = \"I have read and agreed to the privacy policy\";\n"
    "\"Register_GG_Connect\" = \"   We prt of the\";\n"
    "\"Register_TermsOfUser\" = \"Register_GG_Connect999\";\n"
    "\"Register_zaful.com\" = \"To complete registration, you must agree to the Zaful website Terms and Conditions.\";\n"
    "\"Register_password_less\" = \"Sorry, your password can't be less than 8 characters.\";\n"
    "\"Register_password_include\" = \"Password must include letters and numbers.\";\n"
    "\"Register_GG_Connect\" = \" is is an integral part of thecarried out with your consent\";\n"
    "\"Register_Confirm_Tip_Password\" = \"At least 8 characters & 1 number.\";";
    
    //⚠️1. 先读取项目中匹配的旧的翻译文件
    NSString *filePath = @"/Users/wangxin.mao/Documents/GitHub/ZFLanguageLocalized/ZFLanguageLocalized/en.lproj/Localizable.strings";
    NSError *error = nil;
    inputString = [NSString stringWithContentsOfFile: filePath
                                            encoding: NSUTF8StringEncoding
                                               error: &error];
    // 输出文件路径
    NSString *outputFilePath = @"/Users/wangxin.mao/Desktop/output.csv";
    
    // 调用解析和生成CSV的函数
    [OuputCSVFileManager parseAndGenerateCSV:inputString outputFilePath:outputFilePath];
}

@end
