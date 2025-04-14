<script lang="ts">
    import {connectWallet, disconnectWallet} from '../lib/wallet'
    import { isConnectedWallet } from '../stores/blockchainStore';
    import { get } from 'svelte/store';
    let isOpen = get(isConnectedWallet);

    function togglePanel() {
        isOpen = !isOpen;
    }
  
    async function handleConnect() {
      const connected = get(isConnectedWallet);
      
      if (!connected){
        await connectWallet();
      } else {
        await disconnectWallet();
      }
      togglePanel();
    }
  </script>
  
  <button on:click={handleConnect}>
    {isOpen ? "Carteira Connectada" : "Conectar Carteira"}
</button>