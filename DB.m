//
//  DB.m
//  ZHGuidePagesView
//
//  Created by 张晓行 on 2017/11/16.
//  Copyright © 2017年 yourcompany. All rights reserved.
//

#import "DB.h"
#import "BLEModel.h"
#import "UserinfoModel.h"
#import "RunningDataModel.h"
#import "StepModel.h"
static FMDatabaseQueue * task_db_queue;

@implementation DB

+ (void)initialize{
    
    [DB createDatabase];
}
+ (void)createDatabase{
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(
                                                               NSDocumentDirectory,
                                                               NSUserDomainMask,
                                                               YES);
    NSString *documentFolderPath = [searchPaths objectAtIndex:0];
    //        NSLog(@"docoumentFolderPath=%@",documentFolderPath);
    NSString* dbFilePath = [documentFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",[Utils getSandbox:USER_USERNAME]]];
    
    task_db_queue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];
    
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        [db executeUpdate:@"create table if not exists ble_connectedperipherals_list (gid integer default 0, rssi integer default 0, gname text not null unique, lmac text not null, rmac text not null, lname text not null, rname text not null, relevance text not null)"];
        [db executeUpdate:@"create table if not exists user_userinfo (sex text not null, height text not null, weight text not null)"];
        [db executeUpdate:@"create table if not exists running_list (starttime bigint, pausetime bigint, activetime int, endtime bigint, distance text not null, steps text not null, speed text not null, kcal text not null, startpoint text not null, endpoint text not null, coordinate text not null)"];
        
        [db executeUpdate:@"create table if not exists daily_table (user text not null, day text not null ,mac text not null ,  step text not null)"];
        
    }];
}
#pragma mark -  FDK do that  添加了 针对鞋垫的右脚的步数
+(void)insertPeripheralStepInfo:(StepModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if (model.step == nil) {
            model.step = [NSString stringWithFormat:@"%d",0];
        }
        [db executeUpdate:@"insert into daily_table (user,day,mac,step) values (?,?,?,?)",model.user,model.day,model.mac,model.step];
       }];
}
+(int)QueryStepAboutTime:(NSString *)timestr{
    
    __block int find = 0;
    
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from daily_table"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *day = [set stringForColumn:@"day"];
            NSString *step = [set stringForColumn:@"step"];
            if ([day isEqualToString:timestr]) {
                find = find + [step intValue];
            }else {
                
            }
        }
    }];
    return find;
}
+(BOOL)findPeripheralInDailyTableAboutMAC:(NSString *)macstr daytime:(NSString*)dayStr{
    
    __block BOOL find = NO;
    
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from daily_table"];
        
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *mac = [set stringForColumn:@"mac"];
            NSString *day = [set stringForColumn:@"day"];
            if ([mac isEqualToString:macstr]&&[day isEqualToString:dayStr]) {
                find = YES;
                break;
            }else {
                find = NO;
            }
        }
    }];
    return find;
}
+(BOOL)UpdatePeripheralStep:(NSString *)step   InTimeAndMac:(NSString *)macstr daytime:(NSString*)dayStr;{
    
  __block BOOL find = NO;
    if (step == nil) {
        step = @"0";
    }
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from daily_table"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *mac = [set stringForColumn:@"mac"];
            NSString *day = [set stringForColumn:@"day"];
            if ([mac isEqualToString:macstr]&&[day isEqualToString:dayStr]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE daily_table SET step = '%@' WHERE mac = '%@'and day = '%@' ",step,macstr,dayStr];
                [db executeUpdate:sql];
                find= YES;
                break;
            }else{
                find= NO;
            }
        }
    }];
    return find;
}
#pragma mark - ---
+ (NSNumber *)getMaxGID {
    __block NSNumber *maxID = [NSNumber numberWithInteger:0];
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        //获取数据库中最大的ID
        while ([set next]) {
            if ([maxID integerValue] < [[set stringForColumn:@"gid"] integerValue]) {
                maxID = [NSNumber numberWithInteger:[[set stringForColumn:@"gid"] integerValue]];
            }
        }
        maxID = [NSNumber numberWithInteger:[maxID integerValue]+1];
    }];
    return maxID;
}
+ (BOOL)findConnectPeripheral:(BLEModel *)model {
    __block BOOL find = NO;
    
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                find = YES;
                break;
//                NSLog(@"gName = %@",gName);
            }else {
                find = NO;
            }
        }
    }];
    return find;
}
+ (void)insertConnectedPeripheral:(BLEModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if (model.gName.length < 1) {
            model.gName = @"";
        }
        if (model.rMac.length < 1) {
            model.rMac = @"";
        }
        if (model.rName.length < 1) {
            model.rName = @"";
        }
        if (model.lMac.length < 1) {
            model.lMac = @"";
        }
        if (model.lName.length < 1) {
            model.lName = @"";
        }
        [db executeUpdate:@"insert into ble_connectedperipherals_list (gid,rssi,gname,lmac,rmac,lname,rname,relevance) values (?,?,?,?,?,?,?,?)",[NSNumber numberWithInteger:model.gID],[NSNumber numberWithInteger:model.rssi],model.gName,model.lMac,model.rMac,model.lName,model.rName,model.relevance];
    }];
}
+ (void)deleteConnectedPeripheralWithGName:(BLEModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"delete from ble_connectedperipherals_list where gname = '%@'",model.gName];
        [db executeUpdate:sql];
    }];
}
+ (NSMutableArray *)queryAllConnectedPeripheral {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            BLEModel *model = [[BLEModel alloc] init];
            NSInteger gid = [set intForColumn:@"gid"];
            NSInteger rssi = [set intForColumn:@"rssi"];
            NSString *gName = [set stringForColumn:@"gname"];
            NSString *lMac = [set stringForColumn:@"lmac"];
            NSString *rMac = [set stringForColumn:@"rmac"];
            NSString *lName = [set stringForColumn:@"lname"];
            NSString *rName = [set stringForColumn:@"rname"];
             NSString *relevance = [set stringForColumn:@"relevance"];
            model.gID = gid;
            model.rssi = rssi;
            model.gName = gName;
            model.lMac = lMac;
            model.rMac = rMac;
            model.lName = lName;
            model.rName = rName;
            model.relevance =relevance;
            [array addObject:model];
        }
    }];
    return array;
}

/**
 通过  组名称 在更改关联状态 （组名称唯一）

 @param Gname Gname descriptionGname
 @param revelence revelence descriptionrevelence
 */
+(void)updatePeripheral:(NSString *)Gname revelance:(NSString *)revelence {
    
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            
            if ([gName isEqualToString:gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET relevance = '%@' WHERE gname = '%@'",revelence,gName];
                [db executeUpdate:sql];
            }
        }
    }];
}

/**
  通过  组名称 查询当前的关联状态（组名称唯一）

 @param Gname Gname description
 @return return value description
 */
+(NSString *)FindupdatePeripheralrevelence:(NSString *)Gname{
    __block NSString * revelence =nil;
    
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
             NSString *Relevance = [set stringForColumn:@"relevance"];
            if ([gName isEqualToString:Gname]) {
                revelence = Relevance;
                break;
                //   NSLog(@"gName = %@",gName);
            }
        }
    }];
    return revelence;
}
+ (void)updateConnectPeripheralGName:(BLEModel *)model newName:(NSString *)nn {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET gname = '%@' WHERE gname = '%@'",nn,gName];
                [db executeUpdate:sql];
            }
        }
    }];
}
+ (void)updateConnectPeripheralLName:(BLEModel *)model newName:(NSString *)nn {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET lname = '%@' WHERE gname = '%@'",nn,gName];
                [db executeUpdate:sql];
            }
        }
    }];
}

+ (void)updateConnectPeripheralRName:(BLEModel *)model newName:(NSString *)nn {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET rname = '%@' WHERE gname = '%@'",nn,gName];
                [db executeUpdate:sql];
            }
        }
    }];
}
+ (void)updateConnectPeripheralOldLName:(NSString *)olname oldLMac:(NSString *)olmac gName:(BLEModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET lmac = '%@', lname = '%@' WHERE gname = '%@'",olmac,olname,model.gName];
                [db executeUpdate:sql];
            }
        }
    }];
}

+ (void)updateConnectPeripheralNewLName:(NSString *)nlname newLMac:(NSString *)nlmac gName:(BLEModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET lmac = '%@', lname = '%@' WHERE gname = '%@'",nlmac,nlname,model.gName];
                [db executeUpdate:sql];
            }
        }
    }];
}

+ (void)updateConnectPeripheralOldRName:(NSString *)orname oldRMac:(NSString *)ormac gName:(BLEModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET rmac = '%@', rname = '%@' WHERE gname = '%@'",ormac,orname,model.gName];
                [db executeUpdate:sql];
            }
        }
    }];
}

+(void)updateConnectPeripheralNewRName:(NSString *)nrname newRMac:(NSString *)nrmac gName:(BLEModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET rmac = '%@', rname = '%@' WHERE gname = '%@'",nrmac,nrname,model.gName];
                [db executeUpdate:sql];
            }
        }
    }];
}

+ (void)updateDeletePeripheral:(BLEModel *)model withLOrR:(NSString *)str {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from ble_connectedperipherals_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            NSString *gName = [set stringForColumn:@"gname"];
            if ([gName isEqualToString:model.gName]) {
                NSString *sql;
                if ([str isEqualToString:@"left"]) {
                    sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET lmac = '%@', lname = '%@' WHERE gname = '%@'",@"",@"",model.gName];
                }else {
                    sql = [NSString stringWithFormat:@"UPDATE ble_connectedperipherals_list SET rmac = '%@', rname = '%@' WHERE gname = '%@'",@"",@"",model.gName];
                }
                [db executeUpdate:sql];
            }
        }
    }];
}

+ (void)insertUserUserinfo:(UserinfoModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if (model.sex.length < 1) {
            model.sex = @"";
        }
        if (model.height.length < 1) {
            model.height = @"";
        }
        if (model.weight.length < 1) {
            model.weight = @"";
        }
        [db executeUpdate:@"insert into user_userinfo (sex,height,weight) values (?,?,?)",model.sex,model.height,model.weight];
    }];
}

+ (void)updateUserUserinfoSex:(UserinfoModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"UPDATE user_userinfo SET sex = '%@'",model.sex];
        [db executeUpdate:sql];
    }];
}

+ (void)updateUserUserinfoHeight:(UserinfoModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"UPDATE user_userinfo SET height = '%@'",model.height];
        [db executeUpdate:sql];
    }];
}

+ (void)updateUserUserinfoWeight:(UserinfoModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"UPDATE user_userinfo SET weight = '%@'",model.weight];
        [db executeUpdate:sql];
    }];
}

+ (NSMutableArray *)queryUserUserinfo {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from user_userinfo"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            UserinfoModel *model = [[UserinfoModel alloc] init];
            NSString *sex = [set stringForColumn:@"sex"];
            NSString *height = [set stringForColumn:@"height"];
            NSString *weight = [set stringForColumn:@"weight"];
            model.sex = sex;
            model.height = height;
            model.weight = weight;
            [array addObject:model];
        }
    }];
    return array;
}
+ (void)insertRunningData:(RunningDataModel *)model {
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if (model.totalDistance.length < 1) {
            model.totalDistance = @"";
        }
        if (model.totalSteps.length < 1) {
            model.totalSteps = @"";
        }
        if (model.avageSpeed.length < 1) {
            model.avageSpeed = @"";
        }
        if (model.totalCals.length < 1) {
            model.totalCals = @"";
        }
        if (model.startPoint.length < 1) {
            model.startPoint = @"";
        }
        if (model.endPoint.length < 1) {
            model.endPoint = @"";
        }
        if (model.coordinates.length < 1) {
            model.coordinates = @"";
        }
        [db executeUpdate:@"insert into running_list (starttime,pausetime,activetime,endtime,distance,steps,speed,kcal,startpoint,endpoint,coordinate) values (?,?,?,?,?,?,?,?,?,?,?)",[NSString stringWithFormat:@"%lld",(long long)model.startTime],[NSString stringWithFormat:@"%lld",(long long)model.pauseTime],[NSString stringWithFormat:@"%d",model.activeTime],[NSString stringWithFormat:@"%lld",(long long)model.endTime],model.totalDistance,model.totalSteps,model.avageSpeed,model.totalCals,model.startPoint,model.endPoint,model.coordinates];
    }];
}

+ (NSMutableArray *)queryAllRunningData
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from running_list"];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            RunningDataModel *model = [[RunningDataModel alloc] init];
            model.startTime = [set longLongIntForColumn:@"starttime"];
            model.pauseTime = [set longLongIntForColumn:@"pausetime"];
            int activeTime = [set intForColumn:@"activetime"];
            model.endTime = [set longLongIntForColumn:@"endtime"];
            NSString *totalDistance = [set stringForColumn:@"distance"];
            NSString *totalSteps = [set stringForColumn:@"steps"];
            NSString *avageSpeed = [set stringForColumn:@"speed"];
            NSString *totalCals = [set stringForColumn:@"kcal"];
            NSString *startPoint = [set stringForColumn:@"startpoint"];
            NSString *endPoint = [set stringForColumn:@"endpoint"];
            NSString *coordinates = [set stringForColumn:@"coordinate"];
            model.activeTime = activeTime;
            model.totalDistance = totalDistance;
            model.totalSteps = totalSteps;
            model.avageSpeed = avageSpeed;
            model.totalCals = totalCals;
            model.startPoint = startPoint;
            model.endPoint = endPoint;
            model.coordinates = coordinates;
            
            [array addObject:model];
        }
    }];
    return array;
}

+ (NSMutableArray *)querySomedayRunningData:(NSString *)wh
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from running_list %@",wh];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            RunningDataModel *model = [[RunningDataModel alloc] init];
            model.startTime = [set longLongIntForColumn:@"starttime"];
            model.pauseTime = [set longLongIntForColumn:@"pausetime"];
            int activeTime = [set intForColumn:@"activetime"];
            model.endTime = [set longLongIntForColumn:@"endtime"];
            NSString *totalDistance = [set stringForColumn:@"distance"];
            NSString *totalSteps = [set stringForColumn:@"steps"];
            NSString *avageSpeed = [set stringForColumn:@"speed"];
            NSString *totalCals = [set stringForColumn:@"kcal"];
            NSString *startPoint = [set stringForColumn:@"startpoint"];
            NSString *endPoint = [set stringForColumn:@"endpoint"];
            NSString *coordinates = [set stringForColumn:@"coordinate"];
            model.activeTime = activeTime;
            model.totalDistance = totalDistance;
            model.totalSteps = totalSteps;
            model.avageSpeed = avageSpeed;
            model.totalCals = totalCals;
            model.startPoint = startPoint;
            model.endPoint = endPoint;
            model.coordinates = coordinates;
            
            [array addObject:model];
        }
    }];
    return array;
}

+ (void)deleteRunningData:(NSString *)wh
{
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"delete from running_list %@",wh];
        [db executeUpdate:sql];
    }];
}
+ (int)sumSteps:(NSString *)c where:(NSString *)wh
{
    __block int totalSteps = 0;
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from running_list %@",wh];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            totalSteps += [[set stringForColumn:@"steps"] intValue];
        }
    }];
    
    return totalSteps;
}

+ (double)sumDistance:(NSString *)c where:(NSString *)wh
{
    __block double distance = 0;
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from running_list %@",wh];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            distance += [[set stringForColumn:@"distance"] doubleValue];
        }
    }];
    
    return distance;
}

+ (double)sumCals:(NSString *)c where:(NSString *)wh
{
    __block double cals = 0;
    [task_db_queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT *from running_list %@",wh];
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            cals += [[set stringForColumn:@"kcal"] doubleValue];
        }
    }];
    
    return cals;
}
@end
