//
//  OCRGlobalMacros.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/20/11.
//  Copyright 2011-2014 O'Mara Consulting Associates. All rights reserved.
//


#define kAppDelegate    (OCRAppDelegate *)[[UIApplication sharedApplication] delegate]


// =========================================================================================================
#pragma mark - Logging Macros
// =========================================================================================================

/*
 * Modified from this stackoverflow: http://stackoverflow.com/questions/969130/how-to-print-out-the-method-name-and-line-number-and-conditionally-disable-nslog
 */

/**
 Logging macros. The are 3 versions - DLog, ALog, and ELog with the first letter signifying
 Debug only, Always log, and Error (specifically NSError).
 
 All the log macros display class, method, and line. This can result in "wide" messages,
 but I find knowing the exact method and line number invaluable. If at all possible, get
 a 24" monitor - definitely worth the money.
 
 Usage:
 DLog() - I tend to pepper my code heavily with DLog's - for example, I start almost every method
 with DLog(), sometimes displaying the method's signature parameters. That has the advantage
 of leaving a detailed breadcrumb trail, but the disadvantage of filling the console with messages
 you may not be interested in at the moment. It works for me, but everybody has their own logging
 style.
 
 The key thing with DLog() is those messages are NOT compiled into your shipping product. That's
 important because NSLog writes to the console (on disk) which is an expensive operation from both
 a performance and power consumption perspective. You can use DLog() liberally and not worry about
 impacting your customer's experience.
 
 I've recently adopted Crashlytics for Crash reporting and am using it in place of my ALog() macro.
 
 ALog() - These log messages will remain in your shipping product (the Release schemes have
 DEBUG undefined). I use these for non-NSError error conditions that I hope never occur in a shipping
 product - but if they do occur I want to know about it. For example, I use ALog in didReceiveMemoryWarning,
 and in switch statements that have a case for each expected input, my default is typically:
 default: {
 ALog(@"Unexpected foo=%@", bar);
 break;
 }
 
 ELog() - These are specifically designed to handle NSError objects. These messages also remain in your
 shipping product by default. I find it extraordinarly handy to see the exact method and line displayed
 with the rest of the NSError information.
 */

//----------------------------------------------------------------------------------------------------------
#ifdef DEBUG
#   define DLog(_fmt, ...) NSLog((@"%s [Line %d] " _fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

/**
 ALog always display output regardless of the DEBUG setting. No longer used in favor of CLS_LOG()
 
 See comment above about using the Crashlytics CLS_LOG() macro.
 */
//----------------------------------------------------------------------------------------------------------
//#define ALog(_fmt, ...) NSLog((@"%s [Line %d] " _fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

// ELog always displays output regardless of the DEBUG setting.
// Elog accepts an NSError object and logs the detailed information. This may seem redundant
// for many system errors, but the macro will display the Class, method name, and line number.
//----------------------------------------------------------------------------------------------------------
#define ELog(_error, _fmt, ...)                                                                                             \
do {                                                                                                                        \
    NSLog(@"%s [Line %d] [Error %@] " _fmt, __PRETTY_FUNCTION__, __LINE__,  [_error localizedDescription], ##__VA_ARGS__);  \
    NSArray* detailedErrors = [[_error userInfo] objectForKey:NSDetailedErrorsKey];                                         \
    if (detailedErrors != nil && [detailedErrors count] > 0) {                                                              \
        for (NSError* detailedError in detailedErrors) {                                                                    \
            NSLog(@"  DetailedError: %@", [detailedError userInfo]);                                                        \
        }                                                                                                                   \
    }                                                                                                                       \
    else {                                                                                                                  \
        NSLog(@"  %@", [_error userInfo]);                                                                                  \
    }                                                                                                                       \
} while(0)

