//
//  GlobalMacros.h
//  EMStoryboard
//
//  Created by Kevin O'Mara on 8/20/11.
//  Copyright 2011-2013 O'Mara Consulting Associates. All rights reserved.
//


#ifndef GlobalMacros_h
#define GlobalMacros_h



#endif

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

// ELog always displays output regardless of the DEBUG setting.
// Elog accepts an NSError object logs the detailed information (this may seem redundant
//      for many system errors, but the macro will display the Class, method name, and line number.
#define ELog(_error, _fmt, ...)                                                     \
do                                                                                  \
{                                                                                   \
    NSLog(@"[Error %@] " _fmt, [_error localizedDescription], ##__VA_ARGS__);       \
    NSArray* detailedErrors = [[_error userInfo] objectForKey:NSDetailedErrorsKey]; \
    if(detailedErrors != nil && [detailedErrors count] > 0) {                       \
        for(NSError* detailedError in detailedErrors) {                             \
            NSLog(@"  DetailedError: %@", [detailedError userInfo]);                \
        }                                                                           \
    }                                                                               \
    else {                                                                          \
        NSLog(@"  %@", [_error userInfo]);                                          \
    }                                                                               \
} while(0)

//RGB color macro
#define UIColorFromRGB(rgbValue) [UIColor                   \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0   \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0             \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//RGB color macro with alpha
#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor        \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0   \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0             \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

#define goldColor colorWithRed:137.0/255.0    \
                         green:103.0/255.0    \
                          blue: 18.0/255.0    \
                         alpha: 1.0



