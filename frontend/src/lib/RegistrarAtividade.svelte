<script lang="ts">
  import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
  import { estimarCaloriasPorPrompt } from '../lib/estimarCaloriasPrompt';
  import { walletAddress } from '../stores/blockchainStore';
  import { get } from 'svelte/store';
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
    timestamp: gerarTimestampISO(),
    tipo: "fisica"
  };

  let resultado: string = "";
  let erro: string = "";
  let carregando = false;
  let atividades: any[] = [];

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
    const caloriasCorrigidas = atividade.tipo === "fisica"
      ? -Math.abs(atividade.calorias)
      : Math.abs(atividade.calorias);

    const payload = {
      wallet,
      descricao: atividade.descricao,
      calorias: caloriasCorrigidas,
      timestamp: atividade.timestamp ? new Date(atividade.timestamp).toISOString() : undefined
    };

    try {
      const mensagem = await sendMessageToProcess(payload, "RegistrarAtividade", processId);
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);

      resultado = mensagens?.[0]?.Data || "✅ Enviado com sucesso.";
      atividade.descricao = "";
      atividade.calorias = 0;
      atividade.timestamp = gerarTimestampISO();
      atividade.tipo = "fisica";

      await carregarGrafico(wallet);
    } catch (err) {
      erro = "❌ Erro: " + (err?.message || err);
    }

    carregando = false;
  }

  async function estimarCalorias() {
    if (!atividade.descricao) {
      erro = "❌ Forneça uma descrição para estimar as calorias.";
      return;
    }
    erro = "Estimando...";
    const estimativa = await estimarCaloriasPorPrompt(atividade.descricao);
    if (estimativa !== null) {
      atividade.calorias = Math.round(estimativa);
      erro = "✅ Estimativa atualizada.";
    } else {
      erro = "❌ Falha ao estimar calorias.";
    }
  }

  async function apagarAtividades() {
    const wallet = get(walletAddress);
    if (!wallet) return;

    const payload = { wallet };
    try {
      await sendMessageToProcess(payload, "ApagarAtividadesUsuario", processId);
      await carregarGrafico(wallet);
      resultado = "🗑️ Atividades apagadas com sucesso.";
    } catch (err) {
      erro = "❌ Erro ao apagar: " + (err?.message || err);
    }
  }

  async function carregarGrafico(wallet: string) {
    const payload = {
      wallet,
      limite: 20
    };

    const mensagem = await sendMessageToProcess(payload, "ListarPorUsuario", processId);
    const mensagens = await lerResultadoDaMensagem(processId, mensagem);
    const resposta = mensagens?.[0]?.Data;

    if (!resposta) return;

    const dados = JSON.parse(resposta);
    atividades = dados.atividades || [];

    const labels = atividades.map(a => new Date(a.timestamp).toLocaleString());
    const caloriasAlimentacao = atividades.map(a => a.calorias >= 0 ? a.calorias : 0);
    const caloriasFisica = atividades.map(a => a.calorias < 0 ? -a.calorias : 0);

    if (chartInstance) chartInstance.destroy();
    chartInstance = new Chart(chartCanvas, {
      type: 'bar',
      data: {
        labels,
        datasets: [
          {
            label: 'Alimentação (Calorias +)',
            data: caloriasAlimentacao,
            backgroundColor: 'rgba(75, 192, 192, 0.7)'
          },
          {
            label: 'Exercício (Calorias -)',
            data: caloriasFisica,
            backgroundColor: 'rgba(255, 99, 132, 0.7)'
          }
        ]
      },
      options: {
        responsive: true,
        scales: { y: { beginAtZero: true } }
      }
    });
  }

  function exportarCSV() {
    if (!atividades.length) return;

    const linhas = ["descricao,calorias,timestamp"];
    for (const a of atividades) {
      const linha = `${a.descricao},${a.calorias},${a.timestamp}`;
      linhas.push(linha);
    }

    const blob = new Blob([linhas.join("\n")], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "atividades.csv";
    a.click();
    URL.revokeObjectURL(url);
  }

  $: if ($walletAddress) {
    carregarGrafico($walletAddress);
  }
</script>

<h2>🍽️ Registrar Atividade ou Alimentação</h2>
<p>Preencha abaixo para acompanhar seus hábitos!</p>

<form on:submit|preventDefault={registrarAtividade}>
  <label>Tipo:
    <select bind:value={atividade.tipo}>
      <option value="fisica">🏃 Atividade Física</option>
      <option value="alimentacao">🍽️ Alimentação</option>
    </select>
  </label>

  <label>Descrição:
    <input type="text" bind:value={atividade.descricao} placeholder="Ex: Caminhada, Almoço..." />
  </label>

  <button type="button" on:click={estimarCalorias}>🧠 Estimar Calorias</button>

  <label>Calorias:
    <input type="number" bind:value={atividade.calorias} min="0" step="1" />
  </label>

  <label>Data e Hora:
    <input type="datetime-local" bind:value={atividade.timestamp} />
  </label>

  <button type="submit" disabled={carregando}>
    {carregando ? "Enviando..." : "Registrar"}
  </button>
</form>

<button on:click={apagarAtividades} style="margin-top: 1rem;">🗑️ Apagar todas as atividades</button>
<button on:click={exportarCSV} style="margin-left: 1rem;">📤 Exportar CSV</button>

{#if resultado}
  <div class="resultado">{resultado}</div>
{:else if erro}
  <div class="erro">{erro}</div>
{/if}

<canvas bind:this={chartCanvas}></canvas>

<style>
  input, textarea, select {
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
    margin-bottom: 0.7rem;
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