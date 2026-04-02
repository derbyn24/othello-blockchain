// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Othello {
    uint8 constant EMPTY = 0;
    uint8 constant BLACK = 1;
    uint8 constant WHITE = 2;

    uint8[64] public board; // 0 for empty, 1 for black, 2 for white

    address public playerBlack;
    address public playerWhite;
    uint8 public currentPlayer; // 1 for black, 2 for white

    bool public gameOver;

    event Move(address indexed player, uint8 x, uint8 y);

    constructor(address _playerBlack, address _playerWhite) {
        playerBlack = _playerBlack;
        playerWhite = _playerWhite;
        currentPlayer = BLACK;

        // Initialize the board with the starting position
        board[toIndex(3, 3)] = WHITE;
        board[toIndex(4, 4)] = WHITE;
        board[toIndex(3, 4)] = BLACK;
        board[toIndex(4, 3)] = BLACK;
    }

    function makeMove(uint8 x, uint8 y) external {
        require(x < 8 && y < 8, "Out of bounds");
        require(board[toIndex(x, y)] == EMPTY, "Space is not empty");
        require(
            (currentPlayer == BLACK && msg.sender == playerBlack)
                || (currentPlayer == WHITE && msg.sender == playerWhite),
            "Not your turn"
        );

        require(isValidMove(x, y, currentPlayer), "Invalid move");

        board[toIndex(x, y)] = currentPlayer;
        flipPieces(x, y, currentPlayer);

        uint8 nextPlayer = opponent(currentPlayer);

        if (hasValidMove(nextPlayer)) {
            currentPlayer = nextPlayer;
        } else if (hasValidMove(currentPlayer)) {
            // Opponent has no valid moves, current player goes again
        } else {
            // No valid moves for either player, game over
            gameOver = true;
        }

        emit Move(msg.sender, x, y);
    }

    function isValidMove(uint8 x, uint8 y, uint8 player) internal view returns (bool) {
        // TODO
    }

    function flipPieces(uint8 x, uint8 y, uint8 player) internal {
        // TODO
    }

    function hasValidMove(uint8 player) internal view returns (bool) {
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                if (board[toIndex(x, y)] == EMPTY && isValidMove(x, y, player)) {
                    return true;
                }
            }
        }
        return false;
    }

    function toIndex(uint8 x, uint8 y) internal pure returns (uint8) {
        return uint8(y * 8 + x);
    }

    function toXY(uint8 index) internal pure returns (uint8 x, uint8 y) {
        return (uint8(index % 8), uint8(index / 8));
    }

    function opponent(uint8 player) internal pure returns (uint8) {
        return (player == BLACK) ? WHITE : BLACK;
    }
}

