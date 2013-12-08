#import "Accomplishments.h"
#import "Jobs.h"

@implementation Accomplishments

NSString *const OCRAccomplishmentsEntity      = @"Accomplishments";

-(void)logAllFields
{
    DLog();
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    
    NSString *first30;
    if ([self.summary length] > 30) {
        first30 = [self.summary substringWithRange: NSMakeRange(0, 29)];
    } else {
        first30 = self.summary;
    }
    
    NSLog(@"======================= Accomplishments =======================");
    NSLog(@"   name              = %@", self.name);
    NSLog(@"   created_date      = %@", [dateFormatter stringFromDate: self.created_date]);
    NSLog(@"   sequence_number   = %@", [self.sequence_number stringValue]);
    NSLog(@"   in job            = %@", self.job.name);
    NSLog(@"   summary           = %@", first30);
    NSLog(@"===================== end Accomplishments =====================");
    
}

@end
