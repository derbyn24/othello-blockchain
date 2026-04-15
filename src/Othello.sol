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

    enum GameResult {
        Ongoing,
        BlackWin,
        WhiteWin,
        Draw
    }

    GameResult public result;

    event Move(address indexed player, uint8 x, uint8 y);

    constructor(address _playerBlack, address _playerWhite) {
        playerBlack = _playerBlack;
        playerWhite = _playerWhite;
        currentPlayer = BLACK;

        result = GameResult.Ongoing;

        // Initialize the board with the starting position
        board[toIndex(3, 3)] = WHITE;
        board[toIndex(4, 4)] = WHITE;
        board[toIndex(3, 4)] = BLACK;
        board[toIndex(4, 3)] = BLACK;
    }

    function makeMove(uint8 x, uint8 y) external {
        require(result == GameResult.Ongoing, "Game is over");
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
            // No valid moves for either player, game over, calculate winner
            (uint8 blackScore, uint8 whiteScore) = getScore();

            if (blackScore > whiteScore) {
                result = GameResult.BlackWin;
            } else if (whiteScore > blackScore) {
                result = GameResult.WhiteWin;
            } else {
                result = GameResult.Draw;
            }
        }

        emit Move(msg.sender, x, y);
    }

    function isValidMove(uint8 x, uint8 y, uint8 player) internal view returns (bool) {
        uint8 opponent_player = opponent(player);

        // 8 directions: right, left, down, up, down-right, down-left, up-right, up-left
        int8[8] memory dx = [int8(1), int8(-1), int8(0), int8(0), int8(1), int8(-1), int8(1), int8(-1)];
        int8[8] memory dy = [int8(0), int8(0), int8(1), int8(-1), int8(1), int8(1), int8(-1), int8(-1)];

        for (uint8 dir = 0; dir < 8; dir++) {
            int8 nx = int8(x) + dx[dir];
            int8 ny = int8(y) + dy[dir];
            bool foundOpponent = false;

            while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                uint8 piece = board[toIndex(uint8(nx), uint8(ny))];

                if (piece == opponent_player) {
                    foundOpponent = true;
                } else if (piece == player && foundOpponent) {
                    return true;
                } else {
                    break;
                }

                nx += dx[dir];
                ny += dy[dir];
            }
        }

        return false;
    }

    function flipPieces(uint8 x, uint8 y, uint8 player) internal {
        uint8 opponent_player = opponent(player);

        // 8 directions
        int8[8] memory dx = [int8(1), int8(-1), int8(0), int8(0), int8(1), int8(-1), int8(1), int8(-1)];
        int8[8] memory dy = [int8(0), int8(0), int8(1), int8(-1), int8(1), int8(1), int8(-1), int8(-1)];

        for (uint8 dir = 0; dir < 8; dir++) {
            int8 nx = int8(x) + dx[dir];
            int8 ny = int8(y) + dy[dir];

            bool foundOpponent = false;
            uint256 piecesToFlip = 0;

            // First pass: count opponent pieces
            while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                uint8 piece = board[toIndex(uint8(nx), uint8(ny))];

                if (piece == opponent_player) {
                    foundOpponent = true;
                    piecesToFlip++;
                } else if (piece == player && foundOpponent) {
                    // Valid line found, now flip
                    int8 fx = int8(x) + dx[dir];
                    int8 fy = int8(y) + dy[dir];
                    for (uint256 i = 0; i < piecesToFlip; i++) {
                        board[toIndex(uint8(fx), uint8(fy))] = player;
                        fx += dx[dir];
                        fy += dy[dir];
                    }
                    break;
                } else {
                    break;
                }

                nx += dx[dir];
                ny += dy[dir];
            }
        }
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

    function getScore() public view returns (uint8 blackScore, uint8 whiteScore) {
        for (uint8 i = 0; i < 64; i++) {
            if (board[i] == BLACK) blackScore++;
            else if (board[i] == WHITE) whiteScore++;
        }
    }

    function getWinnerAddress() public view returns (address) {
        require(result != GameResult.Ongoing, "Game is not over yet");
        if (result == GameResult.BlackWin) return playerBlack;
        if (result == GameResult.WhiteWin) return playerWhite;
        return address(0); // draw
    }

    function isGameOver() public view returns (bool) {
        return result != GameResult.Ongoing;
    }

    // BASIC HELPER FUNCTIONS

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

