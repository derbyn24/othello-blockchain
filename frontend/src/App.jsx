// ===============================
// 1. Setup Instructions
// ===============================
// Run:
// npm create vite@latest othello-ui -- --template react
// cd othello-ui
// npm install ethers
// Replace src/App.jsx with this file
// Add your contract ABI + address below

import { useEffect, useState } from "react";
import { ethers } from "ethers";
import abiJson from "./abi/Othello.json";

const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

const ABI = abiJson.abi;

export default function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);

  const [board, setBoard] = useState(Array(64).fill(0));
  const [currentPlayer, setCurrentPlayer] = useState(1);
  const [validMoves, setValidMoves] = useState(Array(64).fill(false));

  const [account, setAccount] = useState(null);

  // -----------------------------
  // Connect wallet
  // -----------------------------
  async function connectWallet() {
    if (!window.ethereum) {
      alert("Install MetaMask");
      return;
    }

    const provider = new ethers.BrowserProvider(window.ethereum);

    // IMPORTANT: always re-request accounts
    const accounts = await provider.send("eth_requestAccounts", []);

    const signer = await provider.getSigner();
    const address = accounts[0];

    const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

    setProvider(provider);
    setSigner(signer);
    setContract(contract);
    setAccount(address);
  }

  // -----------------------------
  // Dynamically connect to active wallet
  // -----------------------------
  useEffect(() => {
    if (!window.ethereum) return;

    const handleAccountsChanged = (accounts) => {
      if (accounts.length === 0) {
        setAccount(null);
        setSigner(null);
        setContract(null);
        return;
      }

      setAccount(accounts[0]);

      // IMPORTANT: rebuild signer + contract for new account
      const newProvider = new ethers.BrowserProvider(window.ethereum);

      newProvider.getSigner().then((newSigner) => {
        setSigner(newSigner);

        const newContract = new ethers.Contract(
          CONTRACT_ADDRESS,
          ABI,
          newSigner,
        );

        setContract(newContract);
      });
    };

    window.ethereum.on("accountsChanged", handleAccountsChanged);

    return () => {
      window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
    };
  }, []);

  // -----------------------------
  // Reload game on account change
  // -----------------------------
  useEffect(() => {
    if (contract) {
      loadGame();
    }
  }, [contract, account]);

  // -----------------------------
  // Load game state
  // -----------------------------
  async function loadGame() {
    if (!contract) return;

    const [boardData, player, result] = await contract.getGameState();
    console.log("Board:", boardData);

    const parsedBoard = boardData.map((x) => Number(x));
    setBoard(parsedBoard);
    setCurrentPlayer(Number(player));

    const moves = await contract.getValidMoves(Number(player));
    setValidMoves(moves);
  }

  // -----------------------------
  // Handle move
  // -----------------------------
  async function handleClick(x, y, index) {
    if (!validMoves[index]) return;

    try {
      const tx = await contract.makeMove(x, y);
      await tx.wait();
    } catch (err) {
      console.error(err);
    }
  }

  // -----------------------------
  // Event listener
  // -----------------------------
  useEffect(() => {
    if (!contract) return;

    contract.on("Move", () => {
      loadGame();
    });

    return () => {
      contract.removeAllListeners("Move");
    };
  }, [contract]);

  // -----------------------------
  // Initial load
  // -----------------------------
  useEffect(() => {
    if (contract) loadGame();
  }, [contract]);

  // -----------------------------
  // Helpers
  // -----------------------------
  const getXY = (index) => [index % 8, Math.floor(index / 8)];

  const renderCell = (value) => {
    if (value === 1) return "⚫";
    if (value === 2) return "⚪";
    return "";
  };

  // -----------------------------
  // UI
  // -----------------------------
  return (
    <div style={{ padding: 20, fontFamily: "sans-serif" }}>
      <h1>Othello dApp</h1>

      {!account && <button onClick={connectWallet}>Connect Wallet</button>}

      {account && (
        <div>
          <p>
            <b>Connected:</b> {account}
          </p>
          <p>
            <b>Current Player:</b> {currentPlayer === 1 ? "Black" : "White"}
          </p>
        </div>
      )}

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(8, 60px)",
          gap: "4px",
          marginTop: "20px",
        }}
      >
        {board.map((cell, i) => {
          const [x, y] = getXY(i);
          const isValid = validMoves[i];

          return (
            <div
              key={i}
              onClick={() => handleClick(x, y, i)}
              style={{
                width: 60,
                height: 60,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: isValid ? "#90ee90" : "#2e7d32",
                color: "white",
                fontSize: "24px",
                cursor: isValid ? "pointer" : "not-allowed",
                borderRadius: "8px",
              }}
            >
              {renderCell(cell)}
            </div>
          );
        })}
      </div>
    </div>
  );
}
