/// Tunable constants for the endless breakout sample.
///
/// Every value here is a pre-playtest initial value from the spec draft.
library;

import 'dart:math' as math;

/// Logical width of the portrait playfield.
const double breakoutWorldWidth = 360;

/// Logical height of the portrait playfield.
const double breakoutWorldHeight = 720;

/// Height of the HUD band at the top of the playfield.
const double breakoutHudHeight = 48;

/// Y coordinate of the ceiling the ball bounces off.
const double breakoutCeilingY = breakoutHudHeight;

/// Number of brick columns.
const int breakoutColumns = 8;

/// Horizontal margin between the side walls and the brick grid.
const double breakoutBoardSideMargin = 6;

/// Y coordinate of the top edge of the first brick row.
const double breakoutBoardTop = 56;

/// Height of one brick row including the gap.
const double breakoutRowHeight = 21;

/// Width of one brick cell including the gap.
const double breakoutCellWidth =
    (breakoutWorldWidth - breakoutBoardSideMargin * 2) / breakoutColumns;

/// Gap between neighbouring bricks.
const double breakoutBrickGap = 3;

/// A brick occupying this row index (or below) has reached the deadline.
const int breakoutDeadlineRow = 22;

/// Y coordinate of the deadline line.
const double breakoutDeadlineY =
    breakoutBoardTop + breakoutDeadlineRow * breakoutRowHeight;

/// Number of rows present when a new game starts.
const int breakoutInitialRows = 5;

/// Lives at the start of a game.
const int breakoutInitialLives = 3;

/// Base paddle width before the long item.
const double breakoutPaddleWidth = 72;

/// Paddle height.
const double breakoutPaddleHeight = 12;

/// Y coordinate of the paddle's top edge.
const double breakoutPaddleTop = 640;

/// Paddle width multiplier while the long item is active.
const double breakoutLongPaddleFactor = 1.5;

/// Drags only move the paddle when they start below this Y coordinate.
const double breakoutDragZoneTop = breakoutWorldHeight / 2;

/// Ball radius.
const double breakoutBallRadius = 6;

/// Ball speed at level 1 in world units per second.
const double breakoutBaseBallSpeed = 300;

/// Ball speed multiplier while the slow item is active.
const double breakoutSlowFactor = 0.65;

/// Maximum paddle bounce angle from vertical.
const double breakoutMaxPaddleAngle = 60 * math.pi / 180;

/// The ball is never allowed to tilt further than this from vertical.
const double breakoutMaxTiltAngle = 75 * math.pi / 180;

/// Angle between the original ball and each split ball for multi-ball.
const double breakoutMultiBallSpread = 20 * math.pi / 180;

/// Falling speed of item capsules.
const double breakoutCapsuleSpeed = 140;

/// Capsule size.
const double breakoutCapsuleWidth = 30;

/// Capsule height.
const double breakoutCapsuleHeight = 14;

/// Seconds between laser volleys while the laser item is active.
const double breakoutLaserInterval = 0.35;

/// Laser bolt speed.
const double breakoutLaserSpeed = 600;

/// Laser bolt size.
const double breakoutLaserWidth = 3;

/// Laser bolt height.
const double breakoutLaserHeight = 12;

/// Seconds of play per level.
const double breakoutSecondsPerLevel = 60;

/// Upper bound for a single simulation step.
///
/// Prevents a long frame (e.g. after the tab regains focus on web) from
/// collapsing several descents or level-ups into one frame.
const double breakoutMaxFrameDelta = 1 / 20;

/// Base points for one durability point of a brick.
const int breakoutPointsPerDurability = 10;

/// Bonus for clearing a row.
const int breakoutRowClearBonus = 100;

/// Bonus for clearing the whole board.
const int breakoutBoardClearBonus = 1000;

/// Broken bricks needed for each combo multiplier step.
const int breakoutComboStep = 5;

/// Multiplier added per combo step.
const double breakoutComboIncrement = 0.5;

/// Maximum combo multiplier.
const double breakoutMaxComboMultiplier = 4;

/// Default drag-to-paddle movement ratio.
const double breakoutDefaultSensitivity = 1;

/// Minimum selectable paddle sensitivity.
const double breakoutMinSensitivity = 0.5;

/// Maximum selectable paddle sensitivity.
const double breakoutMaxSensitivity = 2;
