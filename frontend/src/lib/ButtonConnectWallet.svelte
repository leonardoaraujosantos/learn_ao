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

{#if usuarioInfo}
  <div class="usuario-box">
    <p><strong>👤 Nome:</strong> {usuarioInfo.nome}</p>
    <p><strong>📏 Altura:</strong> {usuarioInfo.altura_cm} cm</p>
    <p><strong>🧬 Sexo:</strong> {usuarioInfo.sexo}</p>
    <p><strong>🧠 Biotipo:</strong> {usuarioInfo.biotipo}</p>
    <p><strong>🎂 Nascimento:</strong> {usuarioInfo.ano_nascimento}</p>
  </div>
{:else if erro}
  <div class="mensagem erro">{erro}</div>
{:else}
  <div>Debug: No user info or error</div>
{/if}

{#if ultimaMedida}
  <div class="medida-box">
    <p><strong>📏 Peso:</strong> {ultimaMedida.peso} kg</p>
    <p><strong>📊 IMC:</strong> {ultimaMedida.imc}</p>
    <p><strong>💧 Gordura Corporal:</strong> {ultimaMedida.gordura_corporal}%</p>
    <p><strong>💪 Massa Gordura:</strong> {ultimaMedida.massa_gordura} kg</p>
    <p><strong>📅 Data:</strong> {ultimaMedida.data}</p>
  </div>
{/if}

<style>
  .usuario-box {
    margin-top: 1rem;
    background: #1a1a1a;
    padding: 1rem;
    border-radius: 8px;
    border: 1px solid #333;
    color: #eee;
  }
  .mensagem.erro {
    margin-top: 1rem;
    color: red;
    font-weight: bold;
  }
  .medida-box {
    margin-top: 1rem;
    background: #1a1a1a;
    padding: 1rem;
    border-radius: 8px;
    border: 1px solid #333;
    color: #eee;
  }
</style>
