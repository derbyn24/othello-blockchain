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

    function toIndex(int8 x, int8 y) internal pure returns (uint8) {
        return uint8(y * 8 + x);
    }

    function toXY(uint8 index) internal pure returns (int8 x, int8 y) {
        return (int8(index % 8), int8(index / 8));
    }
}

