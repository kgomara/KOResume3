#import "Resumes.h"
#import "Packages.h"
#import "Education.h"
#import "Jobs.h"


@implementation Resumes

NSString *const OCRResumesEntity      = @"Resumes";

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
    
    NSLog(@"======================= Resumes =======================");
    NSLog(@"   name              = %@", self.name);
    NSLog(@"   created_date      = %@", [dateFormatter stringFromDate: self.created_date]);
    NSLog(@"   sequence_number   = %@", [self.sequence_number stringValue]);
    NSLog(@"   in package        = %@", self.package.name);
    NSLog(@"   name              = %@", self.name);
    NSLog(@"   street1           = %@", self.street1);
    NSLog(@"   street2           = %@", self.street2);
    NSLog(@"   city              = %@", self.city);
    NSLog(@"   state             = %@", self.state);
    NSLog(@"   postal_code       = %@", self.postal_code);
    NSLog(@"   home_phone        = %@", self.home_phone);
    NSLog(@"   mobile_phone      = %@", self.mobile_phone);
    NSLog(@"   email             = %@", self.email);
    NSLog(@"   summary           = %@", first30);
    NSLog(@"   has [%d] education entities:", self.education.count);
    if (self.education.count > 0) {
        [self logEducationNames];
    }
    NSLog(@"   has [%d] job entities:", self.job.count);
    if (self.job.count > 0) {
        [self logJobNames];
    }
    NSLog(@"===================== end Resumes =====================");
    
}

-(void)logEducationNames
{
    // Omitting my customary "DLog();" here as it messes up the formatting
    
    for (Education *edu in self.education) {
        NSLog(@"      education.name    = %@", edu.name);
    }
}


-(void)logJobNames
{
    // Omitting my customary "DLog();" here as it messes up the formatting
    
    for (Jobs *job in self.job) {
        NSLog(@"      job.name          = %@", job.name);
    }
}

@end
