//
//  ViewController.m
//  ZFLanguageLocalized
//
//  Created by 610582 on 2019/4/17.
//  Copyright © 2019 610582. All rights reserved.
//

#import "ViewController.h"
#import "MatchLanguageTool.h"
#import "OuputCSVFileTool.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ViewController ()<NSTextFieldDelegate>
//csv翻译文件
@property (weak) IBOutlet NSTextField *csvPathCell;
@property (weak) IBOutlet NSTextField *csvTipLabel;
//项目多语言目录
@property (weak) IBOutlet NSTextField *localizblePathCell;
@property (weak) IBOutlet NSTextField *localizbleTipLabel;
//执行提示
@property (weak) IBOutlet NSImageView *statusImageView;
@property (weak) IBOutlet NSTextField *statusTipLabel;
@property (weak) IBOutlet NSProgressIndicator *loadingView;
//导出按钮
@property (weak) IBOutlet NSButton *exportButton;
//导入按钮
@property (weak) IBOutlet NSButton *importButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSImage *image = [NSImage imageNamed:@"background"];
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    layer.contents = (__bridge id _Nullable)[self imageToCGImageRef:image];
    layer.opacity = 1.0;
    [self.view.layer addSublayer:layer];
}

//NSImage 转为 CGImageRef
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

- (void)viewDidAppear {
    [super viewDidAppear];
    NSString *filePath = [[NSUserDefaults standardUserDefaults] objectForKey:kLanguageLocalized];
    if ([filePath isKindOfClass:[NSString class]] && filePath.length > 0) {
        self.localizblePathCell.stringValue = filePath;
        [self refreshUI];
    }
}

#pragma mark - refreshUI

- (void)controlTextDidChange:(NSNotification *)obj {
    [self refreshUI];
}

- (void)refreshUI {
    self.csvTipLabel.hidden = YES;
    self.localizbleTipLabel.hidden = YES;
    self.statusImageView.hidden = YES;
    self.statusTipLabel.hidden = YES;
    
    self.importButton.enabled = (self.csvPathCell.stringValue.length > 0 &&
                                  self.localizblePathCell.stringValue.length > 0);
    
    self.exportButton.enabled = self.importButton.enabled;
}

- (void)showCheckTip:(NSString *)tipText tipLabel:(NSTextField *)tipLabel {
    tipLabel.hidden = NO;
    tipLabel.stringValue = tipText;
    self.loadingView.hidden = YES;
}

- (void)showResultTip:(NSString *)tipText status:(BOOL)status {
    self.csvPathCell.enabled = YES;
    self.localizblePathCell.enabled = YES;
    
    self.loadingView.hidden = YES;
    
    self.statusImageView.image = [NSImage imageNamed:(status ? @"success" : @"fail")];
    self.statusImageView.hidden = NO;
    
    self.statusTipLabel.hidden = NO;
    self.statusTipLabel.stringValue = tipText;

    self.importButton.enabled = !status;
    self.exportButton.enabled = !status;
}

- (BOOL)checkTipInputPath:(NSString *)filePath
                 tipLabel:(NSTextField *)tipLabel {
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    BOOL isCSV = (tipLabel == self.csvTipLabel);
    BOOL isLocalizble = (tipLabel == self.localizbleTipLabel);
    NSString *tipStr = nil;
    if (!isExists) {
        if (isCSV) {
            tipStr = @"选择的csv文件不存在!";
        } else if (isLocalizble) {
            tipStr = @"localizble文件夹目录不存在！";
        }
    }
    if (tipStr == nil && !isDirectory) {
        if (isCSV && ![filePath hasSuffix:@"csv"]) {
            tipStr = @"仅支持csv文件!";
        } else if (isLocalizble) {
            tipStr = @"localizble目录只能选择文件夹!";
        }
    }
    if (tipStr != nil) {
        [self showCheckTip:tipStr tipLabel:tipLabel];
    }
    return tipStr == nil;
}

#pragma mark - 处理添加多语言

/// 选择需要追加翻译的CSV文件路径
- (IBAction)excelPathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO; //是否允许多选file
    panel.canChooseDirectories = NO;   //是否允许选择文件夹
    //panel.allowedFileTypes = @[@"csv"]; //方法过期了
    // 设置只允许选择csv文件
    panel.allowedContentTypes = @[
        [UTType typeWithFilenameExtension:@"csv"],
    ];
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        if ([self checkTipInputPath:filePath tipLabel:self.csvTipLabel]) {
            self.csvPathCell.stringValue = panel.URL.path;
            [self refreshUI];
        }
    }];
}

/// 选择项目国际化文件夹路径: 每个翻译文件的父文件夹
- (IBAction)localizblePathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES; //只允许选择文件夹
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        if ([self checkTipInputPath:filePath tipLabel:self.localizbleTipLabel]) {
            self.localizblePathCell.stringValue = panel.URL.path;
            [self refreshUI];
        }
    }];
}

/// 开始导出翻译
- (IBAction)exportBtnAction:(NSButton *)sender {
    if (![self checkTipInputPath:self.localizblePathCell.stringValue tipLabel:self.localizbleTipLabel]) return;
    
    self.csvTipLabel.hidden = YES;
    self.csvPathCell.enabled = NO;
    self.localizblePathCell.enabled = NO;
    self.loadingView.hidden = NO;
    [self.loadingView startAnimation:nil];
    self.importButton.enabled = NO;
    self.exportButton.enabled = NO;

    // 需要导出的翻译文件
    NSString *localizbleURL = self.localizblePathCell.stringValue;
    // 导出文件路径
    NSString *outputFilePath = self.csvPathCell.stringValue;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 调用解析和生成CSV的函数
        [OuputCSVFileTool generateCSV:localizbleURL
                           outputPath:outputFilePath
                          compeletion:^(BOOL status, NSString *tipStr) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showResultTip:tipStr status:status];
                
                [[NSUserDefaults standardUserDefaults] setObject:localizbleURL forKey:kLanguageLocalized];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }];
    });
}


/// 开始导入翻译
- (IBAction)importBtnAction:(NSButton *)sender {
    if (![self checkTipInputPath:self.csvPathCell.stringValue tipLabel:self.csvTipLabel]) return;
    if (![self checkTipInputPath:self.localizblePathCell.stringValue tipLabel:self.localizbleTipLabel]) return;
    
    self.csvPathCell.enabled = NO;
    self.localizblePathCell.enabled = NO;
    self.loadingView.hidden = NO;
    [self.loadingView startAnimation:nil];
    self.importButton.enabled = NO;
    self.exportButton.enabled = NO;
    
    // 开始添加CSV表格中的多语言翻译
    NSString *csvFileURL = self.csvPathCell.stringValue;
    NSString *localizbleURL = self.localizblePathCell.stringValue;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [MatchLanguageTool mappingLanguage:csvFileURL
                            localizblePath:localizbleURL
                               compeletion:^(BOOL checkSuccess, NSString * _Nonnull tipString, BOOL tipStatus) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (checkSuccess) {
                    [self showResultTip:tipString status:tipStatus];
                } else {
                    [self showCheckTip:tipString tipLabel:self.localizbleTipLabel];
                }
                [[NSUserDefaults standardUserDefaults] setObject:localizbleURL forKey:kLanguageLocalized];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }];
    });
}

@end
