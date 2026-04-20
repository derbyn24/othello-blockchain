# Othello Smart Contract

Created by Nick Derby & Jeremy Varghese

![UI Screenshot](images/ui_screenshot.png)

## Deployment Instructions

Before deploying, note that with the current configuration of our smart contract, you should NEVER use public/private keys for accounts that contain valuable assets. Only use accounts with testnet tokens.

To deploy our Othello Smart Contract, first get the public addresses for Player Black and Player White. Store these addresses as environment variables like so:

```sh
export PLAYER_BLACK=<player black public address>
export PLAYER_WHITE=<player white public address>
```

Then, run the following command to deploy the smart contract to the chain:

```sh
forge script Deploy \
--rpc-url <rpc url> \
--private-key <your private key> \
--broadcast
```

Upon running this command, you will be provided with the contract address, which is crucial to accessing the game in the UI.

Next, serve the UI locally. In our experience, using `python3 -m http.server 8080` works well for this purpose. Navigate to [http://localhost:8080/othello.html](http://localhost:8080/othello.html) in your browser to open the UI. Lastly, enter the RPC URL, contract address, and your private key as either player black or player white. This will allow you to make moves as the corresponding player.
