#import "Jobs.h"
#import "Resumes.h"
#import "Accomplishments.h"

@implementation Jobs

NSString *const KOJobsEntity         = @"Jobs";

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

    NSLog(@"======================= Jobs =======================");
    NSLog(@"   name              = %@", self.name);
    NSLog(@"   created_date      = %@", [dateFormatter stringFromDate: self.created_date]);
    NSLog(@"   sequence_number   = %@", [self.sequence_number stringValue]);
    NSLog(@"   in resume         = %@", self.resume.name);
    NSLog(@"   url               = %@", self.uri);
    NSLog(@"   city              = %@", self.city);
    NSLog(@"   state             = %@", self.state);
    NSLog(@"   title             = %@", self.title);
    NSLog(@"   start_date        = %@", [dateFormatter stringFromDate: self.start_date]);
    NSLog(@"   end_date          = %@", [dateFormatter stringFromDate: self.end_date]);
    NSLog(@"   summary           = %@", first30);
    NSLog(@"   has [%d] accomplishment entities:", self.accomplishment.count);
    if (self.accomplishment.count > 0) {
        [self logAccomplishmentNames];
    }
    NSLog(@"===================== end Jobs =====================");
    
}

-(void)logAccomplishmentNames
{
    // Omitting my customary "DLog();" here as it messes up the formatting
    
    for (Accomplishments *acc in self.accomplishment) {
        NSLog(@"      education.name    = %@", acc.name);
    }
}

@end
