/*
 * Copyright (c) 2013 Kyle W. Banks
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  AsyncImageDownloader.m
//
//  Created by Kyle Banks on 2012-11-29.
//  Modified by Nicolas Schteinschraber 2013-05-30
//

#import "AsyncImageDownloader.h"

@implementation AsyncImageDownloader

@synthesize mediaURL;

-(id)initWithMediaURL:(NSString *)theMediaURL successBlock:(void (^)(UIImage *image))success failBlock:(void(^)(NSError *error))fail
{
    self = [super init];
    
    if(self)
    {
        [self setMediaURL:theMediaURL];
        successCallback = success;
        failCallback = fail;
    }
    
    return self;
}
//Perform the actual download
-(void)startDownload
{
    fileData = [[NSMutableData alloc] init];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:mediaURL]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(error) {
            self->failCallback([NSError errorWithDomain:@"Failed to create connection" code:0 userInfo:nil]);
        }
        UIImage *image = [UIImage imageWithData:data];
        self->successCallback(image);
        NSLog(@"In completionHandler");
    } ];
    [task resume];
}


@end
