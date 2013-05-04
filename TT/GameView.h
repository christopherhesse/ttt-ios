#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import "GameBoard.h"

@interface GameView : UIView {
    CGContextRef _context;
    CGPoint _boardOffset;
    dispatch_queue_t _backgroundQueue;
}

@property GameBoard* board;
@property NSString* currentPlayer;

@end
