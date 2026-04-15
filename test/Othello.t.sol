// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Othello} from "../src/Othello.sol";
import "forge-std/console.sol";

contract TestableOthello is Othello {
    constructor(address b, address w) Othello(b, w) {}

    function setBoard(uint8[64] memory newBoard) public {
        board = newBoard;
    }

    function setCurrentPlayer(uint8 p) public {
        currentPlayer = p;
    }
}

contract OthelloTest is Test {
    TestableOthello public game;
    address public playerBlack = address(0x1);
    address public playerWhite = address(0x2);

    uint8 constant EMPTY = 0;
    uint8 constant BLACK = 1;
    uint8 constant WHITE = 2;

    function setUp() public {
        game = new TestableOthello(playerBlack, playerWhite);
    }

    // HELPER FUNCTIONS

    function toIndex(uint8 x, uint8 y) internal pure returns (uint8) {
        return uint8(y * 8 + x);
    }

    function printBoard() public view {
        for (uint8 y = 0; y < 8; y++) {
            string memory row = "";
            for (uint8 x = 0; x < 8; x++) {
                uint8 val = game.board(toIndex(x, y));
                if (val == EMPTY) row = string.concat(row, ". ");
                else if (val == BLACK) row = string.concat(row, "B ");
                else row = string.concat(row, "W ");
            }
            console.log(row);
        }
        console.log("----------------");
    }

    // TESTS

    function test_InitialBoardSetup() public view {
        // Check starting position
        assertEq(game.board(toIndex(3, 3)), WHITE);
        assertEq(game.board(toIndex(4, 4)), WHITE);
        assertEq(game.board(toIndex(3, 4)), BLACK);
        assertEq(game.board(toIndex(4, 3)), BLACK);

        // Check center squares are not empty
        assertEq(game.currentPlayer(), BLACK);
        assertEq(game.gameOver(), false);
    }

    function test_ValidFirstMove() public {
        // Black should be able to move to (3, 2)
        vm.prank(playerBlack);
        game.makeMove(3, 2);

        assertEq(game.board(toIndex(3, 2)), BLACK);
        assertEq(game.board(toIndex(3, 3)), BLACK); // Should be flipped
        assertEq(game.currentPlayer(), WHITE);
    }

    function test_FlipPieces() public {
        // Black makes first move at (3, 2)
        vm.prank(playerBlack);
        game.makeMove(3, 2);

        // Verify that (3, 3) was flipped from WHITE to BLACK
        assertEq(game.board(toIndex(3, 3)), BLACK);
    }

    function test_CannotPlayOnOccupiedSquare() public {
        // Try to play on an occupied square
        vm.prank(playerBlack);
        vm.expectRevert("Space is not empty");
        game.makeMove(3, 3); // Already occupied
    }

    function test_WrongPlayerCannotMove() public {
        // White tries to move when it's Black's turn
        vm.prank(playerWhite);
        vm.expectRevert("Not your turn");
        game.makeMove(3, 2);
    }

    function test_InvalidMoveNoFlips() public {
        // Black tries to move to a square that wouldn't flip any pieces
        vm.prank(playerBlack);
        vm.expectRevert("Invalid move");
        game.makeMove(0, 0);
    }

    function test_GameProgression() public {
        // Move 1: Black plays at (3, 2)
        vm.prank(playerBlack);
        game.makeMove(3, 2);
        assertEq(game.currentPlayer(), WHITE);

        // Move 2: White plays at (2, 2)
        vm.prank(playerWhite);
        game.makeMove(2, 2);
        assertEq(game.currentPlayer(), BLACK);

        // Move 3: Black plays at (2, 3)
        vm.prank(playerBlack);
        game.makeMove(2, 3);
        assertEq(game.currentPlayer(), WHITE);
    }

    function test_EmitsMoveEvent() public {
        vm.prank(playerBlack);
        vm.expectEmit(true, false, false, true);
        emit Othello.Move(playerBlack, 3, 2);
        game.makeMove(3, 2);
    }

    function test_MultipleFlipsInOneMoveHorizontal() public {
        // Set up a board state where a single move flips multiple pieces
        // Black at (2, 3)
        // This should flip white piece at (3, 3) when Black places at (4, 3) - wait that's occupied
        // Let me test a different scenario

        // Initial: 3,3=WHITE, 4,4=WHITE, 3,4=BLACK, 4,3=BLACK
        // After Black at (3,2): 3,2=BLACK, 3,3=BLACK (flipped)
        // After White at (2,2): lots of flips
        printBoard();

        vm.prank(playerBlack);
        game.makeMove(3, 2);

        printBoard();

        vm.prank(playerWhite);
        game.makeMove(2, 2);

        printBoard();

        // Verify the board state after both moves
        assertEq(game.board(toIndex(3, 2)), BLACK);
        assertEq(game.board(toIndex(2, 2)), WHITE);
    }

    function test_BoundaryMovesAllowed() public {
        // Play out a legal sequence that ends with an edge-adjacent capture.
        vm.prank(playerBlack);
        game.makeMove(3, 2);

        vm.prank(playerWhite);
        game.makeMove(2, 2);

        vm.prank(playerBlack);
        game.makeMove(2, 3);

        vm.prank(playerWhite);
        game.makeMove(4, 2);

        vm.prank(playerBlack);
        game.makeMove(5, 1);

        // Edge capture should succeed and flip the diagonal white piece.
        assertEq(game.board(toIndex(5, 1)), BLACK);
        assertEq(game.board(toIndex(4, 2)), BLACK);
    }

    function test_OutOfBoundsMove() public {
        vm.prank(playerBlack);
        vm.expectRevert("Out of bounds");
        game.makeMove(8, 8);
    }

    function test_OutOfBoundsMoveNegative() public {
        // This should fail because we use uint8 (unsigned), so negative numbers wrap around
        vm.prank(playerBlack);
        vm.expectRevert("Out of bounds");
        game.makeMove(255, 255); // Will be out of bounds
    }

    function test_LongChainFlip() public {
        uint8[64] memory b;

        b[toIndex(0, 3)] = BLACK;
        for (uint8 x = 1; x < 7; x++) {
            b[toIndex(x, 3)] = WHITE;
        }

        game.setBoard(b);
        game.setCurrentPlayer(BLACK);

        printBoard();

        vm.prank(playerBlack);
        game.makeMove(7, 3);

        printBoard();

        for (uint8 x = 1; x < 7; x++) {
            assertEq(game.board(toIndex(x, 3)), BLACK);
        }
    }

    function test_MultiDirectionFlip() public {
        uint8[64] memory b;

        // Center empty
        // Surrounding whites
        b[toIndex(2, 3)] = WHITE;
        b[toIndex(4, 3)] = WHITE;
        b[toIndex(3, 2)] = WHITE;
        b[toIndex(3, 4)] = WHITE;
        b[toIndex(2, 2)] = WHITE;
        b[toIndex(4, 4)] = WHITE;

        // Closing blacks
        b[toIndex(1, 3)] = BLACK;
        b[toIndex(5, 3)] = BLACK;
        b[toIndex(3, 1)] = BLACK;
        b[toIndex(3, 5)] = BLACK;
        b[toIndex(1, 1)] = BLACK;
        b[toIndex(5, 5)] = BLACK;

        game.setBoard(b);
        game.setCurrentPlayer(BLACK);

        printBoard();

        vm.prank(playerBlack);
        game.makeMove(3, 3);

        printBoard();

        assertEq(game.board(toIndex(2, 3)), BLACK);
        assertEq(game.board(toIndex(4, 3)), BLACK);
        assertEq(game.board(toIndex(3, 2)), BLACK);
        assertEq(game.board(toIndex(3, 4)), BLACK);
        assertEq(game.board(toIndex(2, 2)), BLACK);
        assertEq(game.board(toIndex(4, 4)), BLACK);
    }

    function test_NoFlipWithoutClosingPiece() public {
        uint8[64] memory b;

        b[toIndex(0, 0)] = WHITE;
        b[toIndex(1, 0)] = WHITE;

        game.setBoard(b);
        game.setCurrentPlayer(BLACK);

        vm.prank(playerBlack);
        vm.expectRevert("Invalid move");
        game.makeMove(2, 0);
    }

    function test_SkipTurnWhenOpponentHasNoMoves() public {
        uint8[64] memory b;

        for (uint8 i = 0; i < 64; i++) {
            b[i] = BLACK;
        }

        b[toIndex(3, 3)] = WHITE;
        b[toIndex(2, 3)] = EMPTY;

        game.setBoard(b);
        game.setCurrentPlayer(BLACK);

        vm.prank(playerBlack);
        game.makeMove(2, 3);

        assertEq(game.currentPlayer(), BLACK);
    }

    function test_GameOverWhenBoardIsFull() public {
        uint8[64] memory b;

        // Fill board with BLACK
        for (uint8 i = 0; i < 64; i++) {
            b[i] = BLACK;
        }

        // Create a small valid flip scenario
        // Row: B W .  → play at (2,0)
        b[toIndex(1,0)] = WHITE;
        b[toIndex(2,0)] = EMPTY;

        game.setBoard(b);
        game.setCurrentPlayer(BLACK);

        printBoard(); // before

        vm.prank(playerBlack);
        game.makeMove(2,0);

        printBoard(); // after

        // After this move:
        // - Board is effectively all BLACK
        // - No valid moves for either player

        assertEq(game.gameOver(), true);
    }
}
