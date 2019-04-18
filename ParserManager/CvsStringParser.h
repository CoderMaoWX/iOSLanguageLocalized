//
//  CvsStringParser.h
//  CSVFileParser
//
//  Created by 610582 on 2019/4/18.
//  Copyright © 2019 610582. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CvsStringParser : NSObject

+ (CvsStringParser *)parser;

- (NSArray *)parseCSVString:(NSString *)csvString;

@end

NS_ASSUME_NONNULL_END
