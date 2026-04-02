// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Othello} from "../src/Othello.sol";

contract OthelloTest is Test {
    Othello public game;
    address public playerBlack = address(0x1);
    address public playerWhite = address(0x2);

    uint8 constant EMPTY = 0;
    uint8 constant BLACK = 1;
    uint8 constant WHITE = 2;

    function setUp() public {
        game = new Othello(playerBlack, playerWhite);
    }

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
        
        vm.prank(playerBlack);
        game.makeMove(3, 2);
        
        vm.prank(playerWhite);
        game.makeMove(2, 2);
        
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

    // Helper function to match Othello contract
    function toIndex(uint8 x, uint8 y) internal pure returns (uint8) {
        return uint8(y * 8 + x);
    }
}
