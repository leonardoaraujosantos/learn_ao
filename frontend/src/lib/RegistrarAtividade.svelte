<script lang="ts">
    import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
    import { walletAddress } from '../stores/blockchainStore';
    import { get } from 'svelte/store';
    import { onMount } from 'svelte';
    import Chart from 'chart.js/auto';
  
    const processId = "niQZAytvrRVoKkxIOuJniZ6ZPA0d2JhXQAMjpIuubks";
  
    function gerarTimestampISO() {
      const now = new Date();
      return new Date(now.getTime() - now.getTimezoneOffset() * 60000)
        .toISOString()
        .slice(0, 16);
    }
  
    let atividade = {
      id: "",
      descricao: "",
      calorias: 0,
      timestamp: gerarTimestampISO()
    };
  
    let resultado: string = "";
    let erro: string = "";
    let carregando = false;
  
    let chartCanvas;
    let chartInstance;
  
    async function registrarAtividade() {
      carregando = true;
      resultado = "";
      erro = "";
  
      const wallet = get(walletAddress);
      if (!wallet) {
        erro = "❌ Conecte sua carteira ArConnect antes de enviar.";
        carregando = false;
        return;
      }
  
      atividade.id = String(crypto.randomUUID());
  
      const payload = {
        wallet,
        descricao: atividade.descricao,
        calorias: atividade.calorias,
        timestamp: atividade.timestamp ? new Date(atividade.timestamp).toISOString() : undefined
      };
  
      try {
        const mensagem = await sendMessageToProcess(payload, "RegistrarAtividade", processId);
        const mensagens = await lerResultadoDaMensagem(processId, mensagem);
        resultado = mensagens?.[0]?.Data || "✅ Enviado com sucesso.";
        atividade.descricao = "";
        atividade.calorias = 0;
        atividade.timestamp = gerarTimestampISO();
        await carregarGrafico(wallet); // Atualiza após envio
      } catch (err) {
        erro = "❌ Erro: " + (err?.message || err);
      }
  
      carregando = false;
    }
  
    async function carregarGrafico(wallet: string) {
      const payload = {
        wallet,
        limite: 10
      };
  
      const mensagem = await sendMessageToProcess(payload, "ListarPorUsuario", processId);
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);
      const resposta = mensagens?.[0]?.Data;
  
      if (!resposta) return;
  
      const dados = JSON.parse(resposta);
      const labels = dados.atividades.map(a => new Date(a.timestamp).toLocaleString());
      const valores = dados.atividades.map(a => a.calorias);
  
      if (chartInstance) chartInstance.destroy();
      chartInstance = new Chart(chartCanvas, {
        type: 'bar',
        data: {
          labels,
          datasets: [{
            label: 'Calorias Gastas',
            data: valores,
            backgroundColor: 'rgba(255, 99, 132, 0.6)'
          }]
        }
      });
    }
  
    // Reage à mudança da carteira conectada
    $: if ($walletAddress) {
      carregarGrafico($walletAddress);
    }
  </script>
  
  <style>
    input, textarea {
      width: 100%;
      margin-bottom: 0.7rem;
      padding: 0.5rem;
      background: #111;
      border: 1px solid #555;
      color: white;
      border-radius: 5px;
    }
  
    button {
      background-color: #1f1f1f;
      color: white;
      padding: 0.6rem 1rem;
      border-radius: 6px;
      border: 1px solid #444;
      font-weight: bold;
      cursor: pointer;
    }
  
    .resultado, .erro {
      margin-top: 1rem;
      font-weight: bold;
    }
  
    .resultado {
      background: #1a1a1a;
      color: #6afc6a;
      padding: 0.7rem;
      border-radius: 6px;
    }
  
    .erro {
      color: red;
    }
  
    canvas {
      margin-top: 2rem;
      background-color: white;
      border-radius: 10px;
    }
  </style>
  
  <h2>🏃 Registrar Atividade Física</h2>
  
  <form on:submit|preventDefault={registrarAtividade}>
    <label>Descrição:
      <input type="text" bind:value={atividade.descricao} placeholder="Ex: Caminhada, Corrida..." />
    </label>
  
    <label>Calorias Gastas:
      <input type="number" bind:value={atividade.calorias} min="0" step="1" />
    </label>
  
    <label>Data e Hora:
      <input type="datetime-local" bind:value={atividade.timestamp} />
    </label>
  
    <button type="submit" disabled={carregando}>
      {carregando ? "Enviando..." : "Registrar Atividade"}
    </button>
  </form>
  
  {#if resultado}
    <div class="resultado">{resultado}</div>
  {:else if erro}
    <div class="erro">{erro}</div>
  {/if}
  
  <canvas bind:this={chartCanvas}></canvas>