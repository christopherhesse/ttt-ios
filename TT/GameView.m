//
//  GameView.m
//  TTT
//
//  Created by Christopher Hesse on 3/26/13.
//  Copyright (c) 2013 Scourcritical. All rights reserved.
//

#import "GameView.h"
#include <math.h>

const CGFloat kComputerColor[] = {0.0588, 0.3804, 0.8471, 1.0};
const CGFloat kHumanColor[] = {1.0000, 0.0000, 0.5020, 1.0};
const CGFloat kBackgroundColor[] = {0.9961, 0.9961, 0.9961, 1.0000};
const CGFloat kGridColor[] = {0.9, 0.9, 0.9, 1.0000};

const CGFloat kPieceSize = 80;
const NSInteger kBoardDimensions = 3;
const NSInteger kBoardCells = kBoardDimensions * kBoardDimensions;
const CGFloat kBoardSize = kBoardDimensions * kPieceSize;

@implementation GameView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    _backgroundQueue = dispatch_queue_create("com.scourcritical.tictactoe.bgqueue", NULL);
    [self reset];
    return self;
}

- (void)reset {
    self.board = [[GameBoard alloc] initWithDimensions:kBoardDimensions];
    self.currentPlayer = kHumanPlayer;
}

- (void)drawRect:(CGRect)rect
{
    [self drawGame];
}

- (void)drawGame
{
    _context = UIGraphicsGetCurrentContext();
    
    [self drawBackground];
    
    // easier to reference things from the top left of the board, translate there for the rest of rendering
    CGPoint center = (CGPoint){self.bounds.size.width/2, self.bounds.size.height/2};
    _boardOffset = (CGPoint){center.x-kBoardSize/2, center.y-kBoardSize/2};
    CGContextTranslateCTM(_context, _boardOffset.x, _boardOffset.y);
    
    [self drawBoard];
    for (NSArray* cell in self.board.cells) {
        [self drawPieceFor:self.board.state[cell] at:cell];
    }
}

- (void)drawBackground {
    [self setFillColor:kBackgroundColor];
    CGContextAddRect(_context, (CGRect){{0, 0}, {self.bounds.size.width, self.bounds.size.height}});
    CGContextFillPath(_context);
}

- (void)setFillColor:(const CGFloat[])components {
    CGContextSetRGBFillColor(_context, components[0], components[1], components[2], components[3]);
}

- (void)drawBoard {
    CGContextSaveGState(_context);
    
    CGContextScaleCTM(_context, kBoardSize, kBoardSize);
    
    // draw grid lines
    for (CGFloat offset = 0; offset <= 1; offset += 1.0/kBoardDimensions) {
        // vertical
        CGContextMoveToPoint(_context, 0, offset);
        CGContextAddLineToPoint(_context, 1, offset);
        
        // horizontal
        CGContextMoveToPoint(_context, offset, 0);
        CGContextAddLineToPoint(_context, offset, 1);
    }
    
    CGContextSetLineCap(_context, kCGLineCapRound);
    CGContextSetLineWidth(_context, 0.01);
    CGContextSetStrokeColor(_context, kGridColor);
    CGContextStrokePath(_context);
    
    CGContextRestoreGState(_context);
}

- (void)drawPieceFor:(NSString*)player at:(NSArray*)cell {
    int row = [cell[0] intValue], column = [cell[1] intValue];
    CGPoint point = {(column + 0.5)*kPieceSize, (row + 0.5)*kPieceSize};
    
    CGContextSaveGState(_context);
    
    CGContextTranslateCTM(_context, point.x, point.y);
    CGContextScaleCTM(_context, kPieceSize, kPieceSize);
    
    CGMutablePathRef path = CGPathCreateMutable();
    if (player == kComputerPlayer) {
        // computer plays as O
        [self setFillColor:kComputerColor];
        
        CGPathAddArc(path, NULL, 0, 0, 0.45, 0, 2*M_PI, true);
        // draw the other direction to prevent filling the center
        CGPathAddArc(path, NULL, 0, 0, 0.25, 0, 2*M_PI, false);
        CGContextAddPath(_context, path);
    } else if (player == kHumanPlayer) {
        // human plays as X
        [self setFillColor:kHumanColor];
        
        CGContextRotateCTM(_context, 45.0/180.0*M_PI);
        
        CGPathAddRect(path, NULL, (CGRect){{-0.5, -0.125}, {1, 0.25}});
        CGPathAddRect(path, NULL, (CGRect){{-0.125, -0.5}, {0.25, 1}});
        CGContextAddPath(_context, path);
    } else {
        // no player, do nothing
    }
    CGPathRelease(path);
    
    CGContextFillPath(_context);
    CGContextRestoreGState(_context);
}

- (void)computerTurn {
    // run computer's turn in a background task
    dispatch_async(_backgroundQueue, ^(void) {
        NSArray* cell = [self.board decideComputerMove];
        self.board.state[cell] = kComputerPlayer;
        self.currentPlayer = kHumanPlayer;
        [self redraw];
        
        if ([self.board evaluateOutcome] != kUnresolvedOutcome) {
            [self gameOver];
        }
    });
}

- (void)redraw {
    // always call UI methods on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
}

- (void)gameOver {
    self.currentPlayer = kNoPlayer;
    [self redraw];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for(UITouch* touch in touches) {
        [self touchedAt:[touch locationInView:self]];
    }
}

- (void)touchedAt:(CGPoint)where {
    if (self.currentPlayer == kNoPlayer) {
        [self reset];
        [self redraw];
        return;
    }
    
    CGPoint relativeWhere = (CGPoint){where.x - _boardOffset.x, where.y - _boardOffset.y};
    NSArray *cell = [self cellFromPoint:relativeWhere];
    
    if (cell != nil && self.currentPlayer == kHumanPlayer && self.board.state[cell] == kNoPlayer) {
        self.board.state[cell] = kHumanPlayer;
        self.currentPlayer = kComputerPlayer;
        [self redraw];
        
        if ([self.board evaluateOutcome] == kUnresolvedOutcome) {
            [self computerTurn];
        } else {
            [self gameOver];
        }
    }
}

- (NSArray*)cellFromPoint:(CGPoint)point {
    int column = point.x / kPieceSize;
    int row = point.y / kPieceSize;
    if (column < kBoardDimensions && row < kBoardDimensions) {
        return @[[NSNumber numberWithInt:row], [NSNumber numberWithInt:column]];
    }
    return nil;
}

@end
