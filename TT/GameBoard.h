#import <Foundation/Foundation.h>
#import "Constants.h"

@interface GameBoard : NSObject {
    int _dimensions;
}

@property NSMutableDictionary* state;
@property NSMutableArray* cells;

- (id)initWithDimensions:(int)dimensions;
- (Outcome)evaluateOutcome;
- (NSArray*)decideComputerMove;

@end