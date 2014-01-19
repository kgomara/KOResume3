#import "Packages.h"

@implementation Packages

NSString *const OCRPackagesEntity         = @"Packages";

//----------------------------------------------------------------------------------------------------------
- (NSString *)debugDescription
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    
    NSString *first30;
    if ([self.cover_ltr length] > 30) {
        first30 = [NSString stringWithFormat:@"%@...", [self.cover_ltr substringWithRange: NSMakeRange(0, 27)]];
    } else {
        first30 = self.cover_ltr;
    }
    
    NSString *result = [NSString stringWithFormat:@"%@\n", self];
    
    result = [result stringByAppendingFormat: @"   name              = %@\n", self.name];
    result = [result stringByAppendingFormat: @"   created_date      = %@\n", [dateFormatter stringFromDate: self.created_date]];
    result = [result stringByAppendingFormat: @"   sequence_number   = %@\n", [self.sequence_number stringValue]];
    result = [result stringByAppendingFormat: @"   cover_ltr         = %@", first30];
    
    return result;
}

@end
