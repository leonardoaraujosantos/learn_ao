// src/lib/wallet.ts
import { walletAddress, isConnectedWallet} from "../stores/blockchainStore";

export async function connectWallet() {
    if (!window.arweaveWallet) {
      alert("Instale a extensão ArConnect.");
      return null;
    }
  
    await window.arweaveWallet.connect(["ACCESS_ADDRESS", "SIGN_TRANSACTION"]);
    const address = await window.arweaveWallet.getActiveAddress();
    walletAddress.set(address);
    isConnectedWallet.set(true)
    console.log('Endereco Carteira ArWeave: ', address)
    return address;
  }

  export async function disconnectWallet() {
    await window.arweaveWallet.disconnect();
    walletAddress.set(null);
    isConnectedWallet.set(false);
  }