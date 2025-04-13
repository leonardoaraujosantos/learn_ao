<script lang="ts">
    import {connectWallet, disconnectWallet} from '../lib/wallet'
    let isOpen = false;

    function togglePanel() {
        isOpen = !isOpen;
    }
  
    async function handleConnect() {
      
      if (!isOpen){
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