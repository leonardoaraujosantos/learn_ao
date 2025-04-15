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
  let chartResumo;
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
      limite: 100
    };

    const mensagem = await sendMessageToProcess(payload, "ListarPorUsuario", processId);
    const mensagens = await lerResultadoDaMensagem(processId, mensagem);
    const resposta = mensagens?.[0]?.Data;

    if (!resposta) return;

    const dados = JSON.parse(resposta);
    atividades = dados.atividades || [];
    console.log(atividades);

    const labels = atividades.map(a => new Date(a.timestamp).toLocaleString());
    const caloriasAlimentacao = atividades.map(a => a.calorias >= 0 ? a.calorias : 0);
    const caloriasFisica = atividades.map(a => a.calorias < 0 ? -a.calorias : 0);
    console.log("caloriasAlimentacao:", caloriasAlimentacao);
    console.log("caloriasFisica:", caloriasFisica);

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

    // Gráfico de resumo
    const hoje = new Date();
    const diaInicio = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate());
    const diaFim = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate() + 1);

    const doDia = atividades.filter(a => {
      const data = new Date(a.timestamp);
      return data >= diaInicio && data < diaFim;
    });
    const totalAlimento = doDia.filter(a => a.calorias > 0).reduce((s, a) => s + a.calorias, 0);
    const totalGasto = doDia.filter(a => a.calorias < 0).reduce((s, a) => s - a.calorias, 0);
    console.log("Hoje:", hoje);
    console.log("totalAlimento:", totalAlimento);
    console.log("totalGasto:", totalGasto);

    if (chartResumo) chartResumo.destroy();
    chartResumo = new Chart(document.getElementById('resumoCalorias') as HTMLCanvasElement, {
      type: 'bar',
      data: {
        labels: ['Alimentação', 'Exercício'],
        datasets: [{
          label: 'Resumo do Dia',
          data: [totalAlimento, totalGasto],
          backgroundColor: ['rgba(75, 192, 192, 0.7)', 'rgba(255, 99, 132, 0.7)']
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        scales: { x: { beginAtZero: true } }
      }
    });
  }

  function exportarAtividadesComoJSON() {
    const dataStr = JSON.stringify(atividades, null, 2);
    const blob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'atividades.json';
    a.click();
    URL.revokeObjectURL(url);
  }

  $: if ($walletAddress) {
    carregarGrafico($walletAddress);
  }
</script>

<h2 style="margin-bottom: 0.5rem;">📌 Registrar Atividade ou Alimentação</h2>
<p class="subtexto">Preencha abaixo para acompanhar seus hábitos!</p>

<form on:submit|preventDefault={registrarAtividade}>
  <label>Tipo:</label>
  <select bind:value={atividade.tipo}>
    <option value="fisica">🏃 Atividade Física</option>
    <option value="alimentacao">🍽️ Alimentação</option>
  </select>

  <label>Descrição:</label>
  <input type="text" bind:value={atividade.descricao} placeholder="Ex: Caminhada, Almoço..." />

  <label>Calorias:</label>
  <div class="calorias-linha">
    <input type="number" bind:value={atividade.calorias} min="0" step="1" />
    <button type="button" on:click={estimarCalorias}>🧠 Estimar Calorias</button>
  </div>

  <label>Data e Hora:</label>
  <input type="datetime-local" bind:value={atividade.timestamp} />

  <button class="btn-principal" type="submit" disabled={carregando}>
    {carregando ? "Enviando..." : "Registrar"}
  </button>
</form>

<div class="botoes-secundarios">
  <button on:click={apagarAtividades}>🗑️ Apagar todas as atividades</button>
  <button on:click={exportarAtividadesComoJSON}>📤 Exportar Atividades</button>
</div>

{#if resultado}
  <div class="mensagem sucesso">{resultado}</div>
{:else if erro}
  <div class="mensagem erro">{erro}</div>
{/if}

<canvas bind:this={chartCanvas}></canvas>
<h3 style="margin-top: 2rem;">📊 Resumo Diário</h3>
<canvas id="resumoCalorias"></canvas>

<style>
  form {
    margin-top: 1rem;
    text-align: left;
  }

  label {
    margin: 0.6rem 0 0.3rem;
    display: block;
    font-weight: 500;
  }

  .calorias-linha {
    display: flex;
    gap: 0.5rem;
    align-items: center;
  }

  input, select {
    width: 100%;
    padding: 0.5rem;
    background: #111;
    border: 1px solid #444;
    border-radius: 6px;
    color: white;
    margin-bottom: 0.8rem;
  }

  .btn-principal {
    width: 100%;
    margin-top: 1rem;
    background: #222;
    border: 1px solid #444;
    padding: 0.7rem;
    font-weight: bold;
    border-radius: 6px;
    color: #fff;
    cursor: pointer;
  }

  .botoes-secundarios {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    margin-top: 1rem;
  }

  .botoes-secundarios button {
    flex: 1;
    padding: 0.6rem;
    border-radius: 6px;
    border: 1px solid #555;
    background: #1f1f1f;
    color: white;
    font-weight: bold;
    cursor: pointer;
  }

  .mensagem {
    margin-top: 1rem;
    padding: 0.8rem;
    border-radius: 6px;
    font-weight: bold;
    text-align: center;
  }

  .sucesso {
    background: #1c3321;
    color: #6afc6a;
    border: 1px solid #3d6344;
  }

  .erro {
    background: #331c1c;
    color: #f86;
    border: 1px solid #633d3d;
  }

  .subtexto {
    font-size: 0.95rem;
    color: #aaa;
    margin-bottom: 1rem;
  }
</style>