//
//  MRProgressView.m
//  MRProgress
//
//  Created by Marius Rackwitz on 31.05.14.
//  Copyright (c) 2014 Marius Rackwitz. All rights reserved.
//

#import "MRProgressView.h"


@implementation MRProgressView

- (void) __attribute__((noreturn)) setProgress:(float)progress animated:(BOOL)animated  {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override selector '%@' in %@ or a intermediate class!",
                                           NSStringFromSelector(_cmd), NSStringFromClass(self.class)]
                                 userInfo:nil];
}

@end
