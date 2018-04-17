//
//  DB.h
//  ZHGuidePagesView
//
//  Created by 张晓行 on 2017/11/16.
//  Copyright © 2017年 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
@class BLEModel;
@class UserinfoModel;
@class RunningDataModel;
@class StepModel;
@interface DB : NSObject

#pragma mark -  FDK do that  添加了 针对鞋垫的右脚的步数
+(void)insertPeripheralStepInfo:(StepModel *)model;

+(int)QueryStepAboutTime:(NSString *)timestr;

+(BOOL)findPeripheralInDailyTableAboutMAC:(NSString *)macstr daytime:(NSString*)dayStr;

+(BOOL)UpdatePeripheralStep:(NSString *)step   InTimeAndMac:(NSString *)macstr daytime:(NSString*)dayStr;
+(void)updatePeripheral:(NSString *)Gname revelance:(NSString *)revelence;
 
+(NSString *)FindupdatePeripheralrevelence:(NSString *)Gname;
#pragma mark -
+ (NSNumber *)getMaxGID;

+ (void)insertConnectedPeripheral:(BLEModel *)model;

+ (BOOL)findConnectPeripheral:(BLEModel *)model;

+ (void)deleteConnectedPeripheralWithGName:(BLEModel *)model;

+ (NSMutableArray *)queryAllConnectedPeripheral;

+ (void)updateConnectPeripheralGName:(BLEModel *)model newName:(NSString *)nn;

+ (void)updateConnectPeripheralLName:(BLEModel *)model newName:(NSString *)nn;

+ (void)updateConnectPeripheralRName:(BLEModel *)model newName:(NSString *)nn;

+ (void)updateConnectPeripheralOldLName:(NSString *)olname oldLMac:(NSString *)olmac gName:(BLEModel *)model;

+ (void)updateConnectPeripheralNewLName:(NSString *)nlname newLMac:(NSString *)nlmac gName:(BLEModel *)model;

+ (void)updateConnectPeripheralOldRName:(NSString *)orname oldRMac:(NSString *)ormac gName:(BLEModel *)model;

+ (void)updateConnectPeripheralNewRName:(NSString *)nrname newRMac:(NSString *)nrmac gName:(BLEModel *)model;

+ (void)updateDeletePeripheral:(BLEModel *)model withLOrR:(NSString *)str;

+ (void)insertUserUserinfo:(UserinfoModel *)model;

+ (void)updateUserUserinfoSex:(UserinfoModel *)model;

+ (void)updateUserUserinfoHeight:(UserinfoModel *)model;

+ (void)updateUserUserinfoWeight:(UserinfoModel *)model;

+ (NSMutableArray *)queryUserUserinfo;

+ (void)insertRunningData:(RunningDataModel *)model;

+ (NSMutableArray *)queryAllRunningData;

+ (NSMutableArray *)querySomedayRunningData:(NSString *)wh; //根据起始、终止时间戳查询某一天数据

+ (void)deleteRunningData:(NSString *)wh; //根据起始时间戳删除某一条数据

+ (int)sumSteps:(NSString *)c where:(NSString *)wh;

+ (double)sumDistance:(NSString *)c where:(NSString *)wh;

+ (double)sumCals:(NSString *)c where:(NSString *)wh;
@end
