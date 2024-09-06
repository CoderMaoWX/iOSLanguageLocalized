//
//  OuputCSVFileTool.h
//  iOSLanguageLocalized
//
//  Created by wangxin.mao on 2024/7/15.
//  Copyright © 2024 610582. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///导出多语言到表格
@interface OuputCSVFileTool : NSObject

+ (void)generateCSV:(NSString *)localizbleURL
         outputPath:(NSString *)outputFilePath
        compeletion:(void (^)(BOOL status, NSString *tipStr))compeletion;

@end

NS_ASSUME_NONNULL_END
