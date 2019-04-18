//
//  ViewController.m
//  ZFLanguageLocalized
//
//  Created by 610582 on 2019/4/17.
//  Copyright © 2019 610582. All rights reserved.
//

#import "ViewController.h"
#import "ZafulParser.h"

@interface ViewController ()<NSTextFieldDelegate>

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
    panel.allowedFileTypes = @[@"csv"]; //只能选择xlsx文件
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isExists) {
            [self showErrorText:@"选择的csv文件不存在" excelLabel:self.excelLabel];
            return;
        }
        if (!isDirectory && ![filePath hasSuffix:@"csv"]) {
            [self showErrorText:@"仅支持csv文件!" excelLabel:self.excelLabel];
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
    self.indictorView.hidden = NO;
    [self.indictorView startAnimation:nil];
    if (!self.localizblePath || !self.excelPath) {
        [self showStatusTip:@"多语言文件替换失败, 文件路径错误" status:NO];
    } else {
        NSString *csvFilePath = self.excelPathCell.stringValue;
        
        NSArray *parseContentArray = [ZafulParser professionalParserCsvFileWithPath:csvFilePath];
        
        if (![parseContentArray isKindOfClass:[NSArray class]] || parseContentArray.count == 0) {
            parseContentArray = [ZafulParser backupParserCsvFileWithPath:csvFilePath];
        }
        
        if (![parseContentArray isKindOfClass:[NSArray class]] || parseContentArray.count == 0) {
            [self showStatusTip:@"多语言转换失败, localizable路径错误" status:NO];
        } else {
            // 解析正确
            [self parseReplaceManyLanguage:parseContentArray];
        }
    }
}

- (void)parseReplaceManyLanguage:(NSArray *)infoArray
{
    NSArray *languageFlagArr = infoArray.firstObject;
    for (NSArray *temColumnArray in infoArray) {
        if (temColumnArray.count != languageFlagArr.count) {
            [self showStatusTip:@"多语言转换失败, localizable路径错误" status:NO];
            return;
        }
    }
    NSMutableDictionary *allAppdingDict = [NSMutableDictionary dictionary];
    NSArray *allColumnArray = [infoArray subarrayWithRange:NSMakeRange(1, infoArray.count-1)];
    
    for (NSInteger j=0; j<allColumnArray.count; j++) {
        NSArray *tempRowStringArray = allColumnArray[j];
        
        NSString *languageKey = tempRowStringArray.firstObject;
        for (NSInteger i=0; i<tempRowStringArray.count; i++) {
            if (i == 0) continue;
            
            NSString *languageValue = tempRowStringArray[i];
            
            // 编译替换翻译中存在引号
            languageValue = [languageValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            NSMutableString *appdingString = [NSMutableString stringWithString:@"\n"];
            [appdingString appendFormat:@"\"%@\" = \"%@\";\n", languageKey, languageValue];
            
            NSString *language = languageFlagArr[i];
            NSString *lastValue = allAppdingDict[language];
            if (lastValue) {
                allAppdingDict[language] = [NSString stringWithFormat:@"%@%@", lastValue, appdingString];
            } else {
                allAppdingDict[language] = appdingString;
            }
        }
    }
    //NSLog(@"多语言===%@", allAppdingDict);
    
    NSFileManager *fileManger = [NSFileManager defaultManager];
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray arrayWithArray:[fileManger contentsOfDirectoryAtPath:self.localizblePath error:nil]];
    [allLanguageDirArray removeObject:@".DS_Store"];//排除异常
    
    // 获取多语言目录列表: Key（Android/iOS Key), en.lproj, de.lproj, es.lproj ...
    NSMutableDictionary *langLprojDict = [NSMutableDictionary dictionary];
    for (NSString *pathDicr in allLanguageDirArray) {
        NSLog(@"多语言文件夹子目录===%@", pathDicr);
        
        NSString *localizablePath = [NSString stringWithFormat:@"%@/%@/Localizable.strings", self.localizblePath, pathDicr];
        if ([fileManger fileExistsAtPath:localizablePath]) {
            langLprojDict[pathDicr] = localizablePath;
        }
    }
    
    // 语言替换
    for (NSString *langKey in langLprojDict.allKeys) {
        for (NSString *appdingLangKey in allAppdingDict.allKeys) {
            
            NSError *error = nil;
            if ([langKey isEqualToString:appdingLangKey]) {
                NSString *localizablePath = langLprojDict[langKey];
                
                
                NSString *allFileString = [NSString stringWithContentsOfFile:localizablePath encoding:NSUTF8StringEncoding error:&error];
                if (error || !allFileString || allFileString.length == 0) {
                    [self showStatusTip:@"多语言转换失败, localizable路径错误" status:NO];
                    continue;
                }
                
                NSString *appdingString = allAppdingDict[appdingLangKey];
                
                // 末尾追加写入
                if (self.versionFlag && self.versionFlag.length>0) {
                    NSRange range = [allFileString rangeOfString:self.versionFlag];
                    
                    //不存在版本号标识就末尾追加写入多语言
                    if (range.location == NSNotFound) {
                        NSString *replaceAllString = [allFileString stringByAppendingString:appdingString];
                        [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                        
                    } else { //存在版本号标识就替换相应版本号的多语言
                        NSString *tempAppdingString = [allFileString substringToIndex:(range.location + range.length + 1)];
                        NSString *replaceAllString = [tempAppdingString stringByAppendingString:appdingString];
                        
                        // 整体覆盖写入
                        [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                    }
                } else {
                    // 末尾追加写入
                    NSString *replaceAllString = [allFileString stringByAppendingString:appdingString];
                    [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                }
            }
        }
    }
    [self showStatusTip:@"多语言文件全部替换成功" status:YES];
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
