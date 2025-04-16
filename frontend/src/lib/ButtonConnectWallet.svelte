<script lang="ts">
  import { connectWallet, disconnectWallet } from '../lib/wallet';
  import { isConnectedWallet, walletAddress, userInfo, lastMeasurement } from '../stores/blockchainStore';
  import { get } from 'svelte/store';
  import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';

  const processId = "4z14kjJd0Pjjg1PuYA98bJd4tXKfytIcCD_-Q1z7HLQ";
  let isOpen = get(isConnectedWallet);
  let usuarioInfo: any = null;
  let erro = "";
  let ultimaMedida: any = null;

  async function carregarInformacoesUsuario(wallet: string) {
    try {
      const mensagem = await sendMessageToProcess(
        { wallet },
        "InfoUsuario",
        processId
      );
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);
      const dados = mensagens?.[0]?.Data;
      if (dados) {
        usuarioInfo = JSON.parse(dados).usuario;
        userInfo.set(usuarioInfo);
        console.log("✅ Usuário carregado:", usuarioInfo);
      } else {
        console.log("❌ Nenhum usuário encontrado");
      }
    } catch (e) {
      erro = "❌ Erro ao buscar informações do usuário";
      console.error(e);
    }
  }

  async function carregarUltimaMedida(wallet: string) {
    try {
      const mensagem = await sendMessageToProcess(
        { wallet },
        "UltimaMedida",
        processId
      );
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);
      const dados = mensagens?.[0]?.Data;
      if (dados) {
        ultimaMedida = JSON.parse(dados).ultima_medida;
        lastMeasurement.set(ultimaMedida);
        console.log("📈 Última medida carregada:", ultimaMedida);
      } else {
        console.log("⚠️ Nenhuma medida encontrada");
      }
    } catch (e) {
      console.error("❌ Erro ao buscar última medida", e);
    }
  }

  async function handleConnect() {
    const connected = get(isConnectedWallet);

    if (!connected) {
      await connectWallet();
      const wallet = get(walletAddress);
      if (wallet) {
        await carregarInformacoesUsuario(wallet);
        await carregarUltimaMedida(wallet);
      }
    } else {
      await disconnectWallet();
      usuarioInfo = null;
      ultimaMedida = null;
      userInfo.set(null);
    }

    isOpen = get(isConnectedWallet);
  }
</script>

<button on:click={handleConnect}>
  {isOpen ? "Carteira Conectada" : "Conectar Carteira"}
</button>
