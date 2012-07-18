//
//  XMLUtil.m
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/24/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "XMLUtil.h"

@implementation XMLUtil

+ (TBXML*) loadXML: (NSString*) url {
    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString: url]];
    TBXML *doc = [[TBXML alloc] initWithXMLData:data error:&err];
    
    if (doc == nil || err != nil) {
        doc = nil;
    }
    return doc;
}

+ (NSString*) getChildValue: (NSString*) childTag parent: (TBXMLElement*) parent {
    TBXMLElement * e = [TBXML childElementNamed:childTag parentElement:parent];
    return [TBXML textForElement:e];
}

@end
