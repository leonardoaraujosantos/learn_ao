<script lang="ts">
  import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
  import { estimarCaloriasPorPrompt } from '../lib/estimarCaloriasPrompt';
  import { walletAddress, lastMeasurement } from '../stores/blockchainStore';
  import { get } from 'svelte/store';
  import { fly } from 'svelte/transition';
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
  let estimandoCalorias = false;
  let atividades: any[] = [];

  let chartCanvas: HTMLCanvasElement;
  let chartResumo: Chart;
  let chartInstance: Chart;

  let caloriasBasal = 0;

  $: if ($lastMeasurement) {
    caloriasBasal = $lastMeasurement.calorias_basal;
  }

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
    } catch (err: any) {
      erro = "❌ Erro: " + (err?.message || err);
    }

    carregando = false;
  }

  async function estimarCalorias() {
    if (!atividade.descricao) {
      erro = "❌ Forneça uma descrição para estimar as calorias.";
      return;
    }
    estimandoCalorias = true;
    erro = "Estimando...";
    const estimativa = await estimarCaloriasPorPrompt(atividade.descricao);
    if (estimativa !== null) {
      atividade.calorias = Math.round(estimativa);
      erro = "✅ Estimativa atualizada.";
    } else {
      erro = "❌ Falha ao estimar calorias.";
    }
    estimandoCalorias = false;
  }

  async function apagarAtividades() {
    if (!confirm("Tem certeza que deseja apagar todas as atividades? Esta ação não pode ser desfeita.")) {
      return;
    }
    
    carregando = true;
    const wallet = get(walletAddress);
    if (!wallet) {
      erro = "❌ Conecte sua carteira ArConnect antes de apagar.";
      carregando = false;
      return;
    }

    const payload = { wallet };
    try {
      await sendMessageToProcess(payload, "ApagarPorUsuario", processId);
      await carregarGrafico(wallet);
      resultado = "🗑️ Atividades apagadas com sucesso.";
    } catch (err: any) {
      erro = "❌ Erro ao apagar: " + (err?.message || err);
    }
    carregando = false;
  }

  async function carregarGrafico(wallet: string) {
    const payload = {
      wallet,
      limite: 100
    };

    try {
      const mensagem = await sendMessageToProcess(payload, "ListarPorUsuario", processId);
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);
      const resposta = mensagens?.[0]?.Data;

      if (!resposta) return;

      const dados = JSON.parse(resposta);
      atividades = dados.atividades || [];
      
      // Only render the 'Resumo Diário' chart
      renderizarGraficoResumoDiario();
    } catch (error) {
      console.error("Erro ao carregar gráficos:", error);
    }
  }
  
  function renderizarGraficoResumoDiario() {
    const resumoCanvas = document.getElementById('resumoCalorias') as HTMLCanvasElement;
    if (!resumoCanvas) return;
    
    // Calcular dados para hoje
    const hoje = new Date();
    const diaInicio = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate());
    const diaFim = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate() + 1);

    const doDia = atividades.filter(a => {
      const data = new Date(a.timestamp);
      return data >= diaInicio && data < diaFim;
    });
    
    const totalAlimento = doDia.filter(a => a.calorias > 0).reduce((s, a) => s + a.calorias, 0);
    const totalGasto = doDia.filter(a => a.calorias < 0).reduce((s, a) => s - a.calorias, 0);
    const deficitCalorico = totalAlimento - caloriasBasal - totalGasto;
    
    if (chartResumo) chartResumo.destroy();
    
    chartResumo = new Chart(resumoCanvas, {
      type: 'bar',
      data: {
        labels: ['Alimentação', 'Exercício'],
        datasets: [{
          label: 'Resumo do Dia',
          data: [totalAlimento, totalGasto],
          backgroundColor: ['rgba(91, 192, 190, 0.7)', 'rgba(255, 99, 132, 0.7)'],
          borderColor: ['rgba(91, 192, 190, 1)', 'rgba(255, 99, 132, 1)'],
          borderWidth: 0,
          borderRadius: 3,
          barThickness: 25
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        scales: { 
          x: { 
            beginAtZero: true,
            grid: {
              color: 'rgba(200, 200, 200, 0.2)',
              drawOnChartArea: true,
              drawTicks: false,
              lineWidth: 1
            },
            ticks: {
              font: {
                size: 10
              }
            }
          },
          y: {
            grid: {
              display: false
            },
            ticks: {
              font: {
                size: 11,
                weight: 'bold'
              }
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          title: {
            display: true,
            text: 'Resumo do Dia',
            position: 'top',
            font: {
              size: 12
            },
            color: '#666',
            padding: {
              bottom: 5
            }
          }
        }
      }
    });

    // Add a text element to display the deficit calórico
    const deficitText = document.createElement('div');
    deficitText.textContent = `Déficit Calórico: ${deficitCalorico}`;
    deficitText.style.fontSize = '0.8rem';
    deficitText.style.maxWidth = '300px';
    deficitText.style.margin = '1rem auto';
    deficitText.style.padding = '0.5rem';
    deficitText.style.textAlign = 'center';
    deficitText.style.fontWeight = 'bold';
    deficitText.style.color = deficitCalorico > 0 ? 'red' : 'green';
    deficitText.style.borderRadius = '0.5rem';
    deficitText.style.backgroundColor = 'rgba(0, 0, 0, 0.05)';
    deficitText.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.1)';
    resumoCanvas.parentElement?.appendChild(deficitText);
  }

  function exportarAtividadesComoJSON() {
    if (atividades.length === 0) {
      erro = "❌ Não há atividades para exportar.";
      return;
    }
    
    const dataStr = JSON.stringify(atividades, null, 2);
    const blob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'atividades.json';
    a.click();
    URL.revokeObjectURL(url);
    
    resultado = "✅ Atividades exportadas com sucesso.";
  }

  async function importarAtividades(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    const reader = new FileReader();
    carregando = true;
    erro = "";
    resultado = "";

    reader.onload = async (e) => {
      try {
        const json = JSON.parse(e.target?.result as string);
        if (!Array.isArray(json)) {
          erro = "❌ O arquivo JSON deve ser uma lista de atividades.";
          carregando = false;
          return;
        }

        const wallet = get(walletAddress);
        if (!wallet) {
          erro = "❌ Conecte sua carteira ArConnect antes de importar.";
          carregando = false;
          return;
        }

        for (const atividade of json) {
          const payload = {
            wallet,
            descricao: atividade.descricao,
            calorias: atividade.calorias,
            timestamp: new Date(atividade.timestamp).toISOString()
          };

          try {
            await sendMessageToProcess(payload, "RegistrarAtividade", processId);
          } catch (err: any) {
            erro = "❌ Erro ao registrar atividade: " + (err?.message || err);
            carregando = false;
            return;
          }
        }

        resultado = "✅ Atividades importadas com sucesso.";
        await carregarGrafico(wallet);
      } catch (err: unknown) {
        erro = "❌ Erro ao ler o arquivo JSON: " + (err instanceof Error ? err.message : String(err));
      } finally {
        carregando = false;
      }
    };

    reader.readAsText(file);
  }

  $: if ($walletAddress) {
    carregarGrafico($walletAddress);
  }
</script>

<div class="registrar-atividade-container">
  <div class="section-header">
    <div class="icon-badge">📌</div>
    <h2>Registrar Atividade ou Alimentação</h2>
  </div>
  
  <p class="description">Preencha abaixo para acompanhar seus hábitos!</p>

  <div class="form-panel">
    <form on:submit|preventDefault={registrarAtividade}>
      <div class="form-grid">
        <div class="form-group full-width">
          <label for="tipo">Tipo:</label>
          <select id="tipo" class="form-control" bind:value={atividade.tipo}>
            <option value="fisica">🏃 Atividade Física</option>
            <option value="alimentacao">🍽️ Alimentação</option>
          </select>
        </div>

        <div class="form-group full-width">
          <label for="descricao">Descrição:</label>
          <input 
            type="text" 
            id="descricao" 
            class="form-control" 
            bind:value={atividade.descricao} 
            placeholder="Ex: Caminhada, Almoço..." 
          />
        </div>

        <div class="form-group full-width">
          <label for="calorias">Calorias:</label>
          <div class="input-with-button">
            <input 
              type="number" 
              id="calorias" 
              class="form-control" 
              bind:value={atividade.calorias} 
              min="0" 
              step="1" 
              placeholder="0"
            />
            <button 
              type="button" 
              class="btn-secondary" 
              on:click={estimarCalorias}
              disabled={estimandoCalorias || !atividade.descricao}
            >
              {#if estimandoCalorias}
                <span class="spinner"></span>
              {:else}
                🧠
              {/if}
              Estimar Calorias
            </button>
          </div>
        </div>

        <div class="form-group full-width">
          <label for="datetime">Data e Hora:</label>
          <input 
            type="datetime-local" 
            id="datetime" 
            class="form-control" 
            bind:value={atividade.timestamp} 
          />
        </div>
      </div>

      <button 
        type="submit" 
        class="btn-primary" 
        disabled={carregando || !atividade.descricao || atividade.calorias <= 0}
      >
        {#if carregando}
          <span class="spinner"></span> Enviando...
        {:else}
          Registrar
        {/if}
      </button>
    </form>
  </div>

  <div class="actions-panel">
    <button 
      class="btn-danger" 
      on:click={apagarAtividades}
      disabled={carregando || atividades.length === 0}
    >
      <span class="action-icon">🗑️</span> Apagar todas as atividades
    </button>
    
    <button 
      class="btn-action" 
      on:click={exportarAtividadesComoJSON}
      disabled={carregando || atividades.length === 0}
    >
      <span class="action-icon">📤</span> Exportar Atividades
    </button>
    
    <button 
      class="btn-action" 
      on:click={() => {
        const input = document.getElementById('importarAtividadesInput');
        if (input) input.click();
      }}
      disabled={carregando}
    >
      <span class="action-icon">📥</span> Importar Atividades
    </button>
    
    <input 
      id="importarAtividadesInput" 
      type="file" 
      accept=".json" 
      style="display: none;" 
      on:change={importarAtividades} 
    />
  </div>

  {#if resultado}
    <div class="notification success" in:fly={{ y: 20, duration: 200 }}>
      <div class="notification-icon">✅</div>
      <div class="notification-text">{resultado}</div>
    </div>
  {/if}

  {#if erro}
    <div class="notification {erro.startsWith('✅') ? 'info' : 'error'}" in:fly={{ y: 20, duration: 200 }}>
      <div class="notification-icon">{erro.startsWith('✅') ? '📝' : '❌'}</div>
      <div class="notification-text">{erro}</div>
    </div>
  {/if}

  <div class="chart-container">
    <div class="resumo-section">
      <div class="section-header small">
        <div class="icon-badge small">📊</div>
        <h3>Resumo Diário</h3>
      </div>
      
      <div class="chart-small-container">
        <canvas id="resumoCalorias" height="150"></canvas>
      </div>
    </div>
  </div>
</div>

<style>
  .registrar-atividade-container {
    width: 100%;
    max-width: 1000px;
    margin: 0 auto;
  }

  .section-header {
    display: flex;
    align-items: center;
    margin-bottom: 0.25rem;
    gap: 0.5rem;
  }

  .section-header.small {
    margin-top: 1.5rem;
    margin-bottom: 0.5rem;
  }

  .icon-badge {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2.5rem;
    height: 2.5rem;
    background: linear-gradient(135deg, #ff0080, #7928ca);
    border-radius: 0.75rem;
    font-size: 1.25rem;
    color: white;
    box-shadow: 0 2px 8px rgba(255, 0, 128, 0.2);
  }

  .icon-badge.small {
    width: 2rem;
    height: 2rem;
    font-size: 1rem;
    border-radius: 0.5rem;
  }

  h2, h3 {
    margin: 0;
    color: #333;
    font-weight: 700;
  }

  .description {
    margin: 0 0 0.75rem 0;
    color: #666;
    font-size: 0.95rem;
  }

  .form-panel {
    background: white;
    border-radius: 1rem;
    padding: 1rem;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
    margin-bottom: 1rem;
  }
  
  @media (max-width: 768px) {
    .form-panel {
      padding: 1rem;
    }
  }

  .form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }

  .full-width {
    grid-column: 1 / -1;
  }

  @media (max-width: 768px) {
    .form-grid {
      grid-template-columns: 1fr;
    }
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  label {
    font-size: 0.875rem;
    font-weight: 600;
    color: #555;
    margin-bottom: 0.25rem;
  }

  .input-with-button {
    display: flex;
    gap: 0.75rem;
  }
  
  @media (max-width: 640px) {
    .input-with-button {
      flex-direction: column;
    }
  }

  .form-control {
    padding: 0.3rem;
    border: 1px solid #e0e0e0;
    border-radius: 0.5rem;
    font-size: 1rem;
    transition: border-color 0.2s ease, box-shadow 0.2s ease;
    height: 38px;
    box-sizing: border-box;
    flex: 1;
  }

  .form-control:focus {
    border-color: #ff0080;
    box-shadow: 0 0 0 3px rgba(255, 0, 128, 0.1);
    outline: none;
  }

  /* Buttons */
  .btn-primary, .btn-secondary, .btn-action, .btn-danger {
    padding: 0.75rem 1.5rem;
    border-radius: 0.5rem;
    font-size: 0.95rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    border: none;
    height: 48px;
  }

  .btn-primary {
    background: linear-gradient(90deg, #ff0080, #7928ca);
    color: white;
    width: 100%;
    margin-top: 1rem;
  }

  .btn-secondary {
    background: #fff;
    color: #ff69b4;
    border: 1px solid #ffcee6;
    height: 48px;
    padding: 0 1.25rem;
    white-space: nowrap;
    border-radius: 0.5rem;
  }

  .btn-primary:hover:not(:disabled), .btn-secondary:hover:not(:disabled), 
  .btn-action:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  }

  .btn-primary:disabled, .btn-secondary:disabled, 
  .btn-action:disabled, .btn-danger:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .actions-panel {
    display: flex;
    gap: 0.5rem;
    margin-top: 0.75rem;
    margin-bottom: 1rem;
    flex-wrap: wrap;
  }

  .btn-action {
    background: white;
    color: #2196f3;
    border: 1px solid #e3f2fd;
    font-size: 0.9rem;
    padding: 0 1.25rem;
    height: 40px;
  }

  .btn-danger {
    background: white;
    color: #e53935;
    border: 1px solid #ffcfcf;
    font-size: 0.9rem;
    padding: 0 1.25rem;
    height: 40px;
  }

  .btn-danger:hover:not(:disabled) {
    background: #ffebee;
    color: #e53935;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(229, 57, 53, 0.15);
  }

  .action-icon {
    font-size: 1.1rem;
  }

  /* Spinner */
  .spinner {
    width: 1rem;
    height: 1rem;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    border-top-color: white;
    animation: spin 1s ease-in-out infinite;
  }

  .btn-secondary .spinner {
    border: 2px solid rgba(0, 0, 0, 0.1);
    border-top-color: #333;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  /* Notifications */
  .notification {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem;
    border-radius: 0.5rem;
    margin-bottom: 1rem;
    font-size: 0.9rem;
  }

  .notification.success {
    background-color: #e8f5e9;
    border-left: 4px solid #4caf50;
  }

  .notification.error {
    background-color: #ffebee;
    border-left: 4px solid #e53935;
  }

  .notification.info {
    background-color: #e3f2fd;
    border-left: 4px solid #2196f3;
  }

  .notification-icon {
    font-size: 1.25rem;
  }

  .notification-text {
    color: #333;
  }

  /* Charts */
  .chart-container {
    margin-top: 1.5rem;
  }

  .chart-container canvas {
    width: 100%;
    background: white;
    border-radius: 0.5rem;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
    padding: 1rem;
    box-sizing: border-box;
    max-height: 500px;
  }

  .chart-small-container {
    height: 150px;
    position: relative;
    margin-top: 0.5rem;
  }

  .resumo-section {
    margin-top: 1.5rem;
    margin-bottom: 0.5rem;
  }

  @media (max-width: 768px) {
    .actions-panel {
      flex-direction: column;
    }
    
    .input-with-button {
      flex-direction: column;
    }
  }
</style>