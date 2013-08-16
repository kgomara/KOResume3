#import "Packages.h"

@implementation Packages

NSString *const OCRPackagesEntity         = @"Packages";

-(void)logAllFields
{
    DLog();
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];

    NSString *first30;
    if ([self.cover_ltr length] > 30) {
        first30 = [self.cover_ltr substringWithRange: NSMakeRange(0, 29)];
    } else {
        first30 = self.cover_ltr;
    }

    NSLog(@"======================= Package =======================");
    NSLog(@"   name              = %@", self.name);
    NSLog(@"   created_date      = %@", [dateFormatter stringFromDate: self.created_date]);
    NSLog(@"   sequence_number   = %@", [self.sequence_number stringValue]);
    NSLog(@"   cover_ltr         = %@", first30);
    NSLog(@"===================== end Package =====================");

}

@end
