// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Othello.sol";

contract Deploy is Script {
    function run() external {
        address playerBlack = vm.envAddress("PLAYER_BLACK");
        address playerWhite = vm.envAddress("PLAYER_WHITE");

        vm.startBroadcast();

        Othello game = new Othello(playerBlack, playerWhite);

        vm.stopBroadcast();

        console.log("Othello deployed at:", address(game));
    }
}
