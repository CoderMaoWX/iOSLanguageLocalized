//
//  ViewController.m
//  ZFLanguageLocalized
//
//  Created by 610582 on 2019/4/17.
//  Copyright © 2019 610582. All rights reserved.
//

#import "ViewController.h"
#import "LAWExcelTool.h"

@interface ViewController ()<LAWExcelParserDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField *excelPathCell;
@property (weak) IBOutlet NSTextField *excelLabel;
@property (nonatomic, copy) NSString *excelPath;

@property (weak) IBOutlet NSTextField *localizblePathCell;
@property (weak) IBOutlet NSTextField *localizbleLabel;
@property (nonatomic, copy) NSString *localizblePath;

@property (weak) IBOutlet NSTextField *versionFlagCell;
@property (weak) IBOutlet NSTextField *versionLabel;
@property (nonatomic, copy) NSString *versionFlag;

@property (weak) IBOutlet NSImageView *errorImageView;
@property (weak) IBOutlet NSProgressIndicator *indictorView;
@property (weak) IBOutlet NSTextField *errorLabel;
@property (weak) IBOutlet NSButton *executeButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSImage *image = [NSImage imageNamed:@"background"];
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    layer.contents = (__bridge id _Nullable)[self imageToCGImageRef:image];
    layer.opacity = 0.1;
    [self.view.layer addSublayer:layer];
}

#pragma mark - NSNotification

- (void)controlTextDidChange:(NSNotification *)obj {
    self.excelLabel.hidden = YES;
    self.localizbleLabel.hidden = YES;
    self.versionLabel.hidden = YES;
    self.errorImageView.hidden = YES;
    self.executeButton.enabled = (self.excelPathCell.stringValue.length >0 && self.localizblePathCell.stringValue.length >0 && self.versionFlagCell.stringValue.length >0);
    self.versionFlag = self.versionFlagCell.stringValue;
}

#pragma mark - ButtonAction

- (IBAction)excelPathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO; //是否允许多选file
    panel.canChooseDirectories = NO;   //是否允许选择文件夹
    panel.allowedFileTypes = @[@"xlsx"]; //只能选择xlsx文件
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isExists) {
            [self showErrorText:@"选择的xlsx文件不存在" excelLabel:self.excelLabel];
            return;
        }
        if (!isDirectory && ![filePath hasSuffix:@"xlsx"]) {
            [self showErrorText:@"仅支持xlsx文件!" excelLabel:self.excelLabel];
            return;
        }
        self.excelPathCell.stringValue = panel.URL.path;
        self.excelPath = panel.URL.path;
        [self controlTextDidChange:nil];
    }];
}

- (IBAction)localizblePathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES; //只允许选择文件夹
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isExists) {
            [self showErrorText:@"localizble文件夹路径不存在！" excelLabel:self.localizbleLabel];
            return;
        }
        if (!isDirectory) {
            [self showErrorText:@"localizble路径只能选择文件夹!" excelLabel:self.localizbleLabel];
            return;
        }
        self.localizblePathCell.stringValue = panel.URL.path;
        self.localizblePath = panel.URL.path;
        [self controlTextDidChange:nil];
    }];
}

- (IBAction)startConvertAction:(NSButton *)sender {
    sender.enabled = NO;
    [LAWExcelTool shareInstance].delegate = self;
    [[LAWExcelTool shareInstance] parserExcelWithPath:self.excelPathCell.stringValue];
}

#pragma mark - <LAWExcelParserDelegate>

/**
 *  解析xlsx文件,处理解析结果
 */
- (void)parser:(LAWExcelTool *)parser success:(id)responseObj {
    NSLog(@"解析xlsx文件,处理解析结果: \n%@", responseObj);
    [self startWriteReplaceCurrentLange:responseObj];
}

- (void)startWriteReplaceCurrentLange:(NSArray *)infoArray {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.indictorView.hidden = NO;
        [self.indictorView startAnimation:nil];
    });

    if (!self.localizblePath || !self.excelPath) {
        [self showStatusTip:@"多语言文件替换失败" status:NO];
        return;
    }
    NSFileManager *fileManger = [NSFileManager defaultManager];
    NSMutableDictionary *langDict = [NSMutableDictionary dictionary];
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray arrayWithArray:[fileManger contentsOfDirectoryAtPath:self.localizblePath error:nil]];
    [allLanguageDirArray removeObject:@".DS_Store"];//排除异常
    
    for (NSString *pathDicr in allLanguageDirArray) {
        NSLog(@"多语言文件夹子目录===%@", pathDicr);
        
        NSString *langFlag = [pathDicr componentsSeparatedByString:@"."].firstObject;
        if ([langFlag isEqualToString:@"en"]) {
            
            NSString *localizablePath = [NSString stringWithFormat:@"%@/%@/Localizable.strings", self.localizblePath, pathDicr];
            if ([fileManger fileExistsAtPath:localizablePath]) {
                langDict[@"en"] = localizablePath;
            }
        }
    }
    
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"keyName" ascending:YES]];
    NSMutableArray *excelInfoArray = [NSMutableArray arrayWithArray:infoArray];
    [excelInfoArray sortUsingDescriptors:sortDescriptors];
    NSLog(@"排序后的数组====%@",excelInfoArray);
    
    NSArray *firstArray = [excelInfoArray subarrayWithRange:NSMakeRange(0, excelInfoArray.count/2)];
    NSArray *lastArray = [excelInfoArray subarrayWithRange:NSMakeRange(excelInfoArray.count/2, excelInfoArray.count/2)];
    
    // 遍历替换多语言文件
    [langDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull langFlag, id  _Nonnull localizablePath, BOOL * _Nonnull stop) {
       
        NSError *error = nil;
        NSString *allFileString = [NSString stringWithContentsOfFile:localizablePath encoding:NSUTF8StringEncoding error:&error];
        if (error || !allFileString || allFileString.length == 0) {
            [self showStatusTip:@"多语言文件替换失败" status:NO];
            return;
        }
        
        NSMutableString *appdingString = [NSMutableString stringWithString:@"\n"];
        if (firstArray.count == lastArray.count) {
            for (NSInteger i=0; i<firstArray.count; i++) {
                NSDictionary *keyDict = firstArray[i];
                NSString *key = keyDict[@"value"];
                
                NSDictionary *valueDict = lastArray[i];
                NSString *value = valueDict[@"value"];
                if ([value containsString:@"\n"]) {
                    value = [value stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                }
                [appdingString appendFormat:@"\"%@\" = \"%@\";\n", key, value];
            }
        }
        
        // 末尾追加写入
        NSError *err = nil;
        if (self.versionFlag && self.versionFlag.length>0) { //存在版本号就替换相应版本号的多语言
            NSRange range = [allFileString rangeOfString:self.versionFlag];
            if (range.location == NSNotFound) {
                
                // 末尾追加写入
                NSString *replaceAllString = [allFileString stringByAppendingString:appdingString];
                [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
            } else {
                NSString *tempAppdingString = [allFileString substringToIndex:(range.location + range.length + 1)];
                NSString *replaceAllString = [tempAppdingString stringByAppendingString:appdingString];
                
                // 整体覆盖写入
                [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
            }
        } else {
            // 末尾追加写入
            NSString *replaceAllString = [allFileString stringByAppendingString:appdingString];
            [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
        }
        [self showStatusTip:@"多语言文件全部替换成功" status:YES];
        return;
    }];
}

#pragma mark - <Other deal with>

- (void)showStatusTip:(NSString *)statusText status:(BOOL)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.errorImageView.image = [NSImage imageNamed:(status ? @"success" : @"fail")];
        self.errorLabel.hidden = NO;
        self.errorImageView.hidden = NO;
        self.indictorView.hidden = YES;
        self.errorLabel.stringValue = statusText;
        self.executeButton.enabled = YES;
    });
}

- (void)showErrorText:(NSString *)errorText excelLabel:(NSTextField *)excelLabel
{
    excelLabel.hidden = NO;
    excelLabel.stringValue = errorText;
}

//NSImage 转换为 CGImageRef
- (CGImageRef)imageToCGImageRef:(NSImage*)image {
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef = nil;
    if(imageData){
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
    return imageRef;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
