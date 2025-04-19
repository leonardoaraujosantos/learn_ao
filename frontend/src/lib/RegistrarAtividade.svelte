<script lang="ts">
  import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
  import { estimarCaloriasPorPrompt } from '../lib/estimarCaloriasPrompt';
  import { walletAddress, lastMeasurement } from '../stores/blockchainStore';
  import { fly } from 'svelte/transition';
  import Chart from 'chart.js/auto';
  import { onMount, tick } from 'svelte';

  const processId = "niQZAytvrRVoKkxIOuJniZ6ZPA0d2JhXQAMjpIuubks";

  // Reactive declarations for form data
  $: caloriasBasal = $lastMeasurement?.calorias_basal || 0;
  
  // State with default values
  let atividade = {
    id: "",
    descricao: "",
    calorias: 0,
    timestamp: gerarTimestampISO(),
    tipo: "fisica"
  };
  
  let resultado = "";
  let erro = "";
  let carregando = false;
  let estimandoCalorias = false;
  let atividades = [];
  let chartResumo;
  
  // Helper function to generate ISO timestamp
  function gerarTimestampISO() {
    const now = new Date();
    return new Date(now.getTime() - now.getTimezoneOffset() * 60000)
      .toISOString()
      .slice(0, 16);
  }

  // Register activity with validation
  async function registrarAtividade() {
    carregando = true;
    resultado = "";
    erro = "";

    if (!$walletAddress) {
      erro = "❌ Conecte sua carteira ArConnect antes de enviar.";
      carregando = false;
      return;
    }

    try {
      // Format data for submission
      const caloriasCorrigidas = atividade.tipo === "fisica"
        ? -Math.abs(atividade.calorias)
        : Math.abs(atividade.calorias);
      
      const payload = {
        wallet: $walletAddress,
        descricao: atividade.descricao,
        calorias: caloriasCorrigidas,
        timestamp: atividade.timestamp ? new Date(atividade.timestamp).toISOString() : undefined,
        id: crypto.randomUUID()
      };

      const mensagem = await sendMessageToProcess(payload, "RegistrarAtividade", processId);
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);

      // Reset form and show success
      resultado = mensagens?.[0]?.Data || "✅ Enviado com sucesso.";
      resetarFormulario();
      await carregarGrafico($walletAddress);
    } catch (err) {
      erro = "❌ Erro: " + (err?.message || err);
    } finally {
      carregando = false;
    }
  }

  // Reset form to default values
  function resetarFormulario() {
    atividade = {
      id: "",
      descricao: "",
      calorias: 0,
      timestamp: gerarTimestampISO(),
      tipo: "fisica"
    };
  }

  // Estimate calories via AI
  async function estimarCalorias() {
    if (!atividade.descricao) {
      erro = "❌ Forneça uma descrição para estimar as calorias.";
      return;
    }
    
    estimandoCalorias = true;
    erro = "Estimando...";
    
    try {
      const estimativa = await estimarCaloriasPorPrompt(atividade.descricao);
      if (estimativa !== null) {
        atividade.calorias = Math.round(estimativa);
        erro = "✅ Estimativa atualizada.";
      } else {
        erro = "❌ Falha ao estimar calorias.";
      }
    } catch (error) {
      erro = "❌ Erro na estimativa: " + error.message;
    } finally {
      estimandoCalorias = false;
    }
  }

  // Delete all activities with confirmation
  async function apagarAtividades() {
    if (!confirm("Tem certeza que deseja apagar todas as atividades? Esta ação não pode ser desfeita.")) {
      return;
    }
    
    if (!$walletAddress) {
      erro = "❌ Conecte sua carteira ArConnect antes de apagar.";
      return;
    }
    
    carregando = true;
    erro = "";
    resultado = "";
    
    try {
      await sendMessageToProcess({ wallet: $walletAddress }, "ApagarPorUsuario", processId);
      await carregarGrafico($walletAddress);
      resultado = "🗑️ Atividades apagadas com sucesso.";
    } catch (err) {
      erro = "❌ Erro ao apagar: " + (err?.message || err);
    } finally {
      carregando = false;
    }
  }

  // Load activities and render chart
  async function carregarGrafico(wallet) {
    if (!wallet) return;
    
    try {
      const mensagem = await sendMessageToProcess(
        { wallet, limite: 100 }, 
        "ListarPorUsuario", 
        processId
      );
      
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);
      const resposta = mensagens?.[0]?.Data;

      if (resposta) {
        const dados = JSON.parse(resposta);
        atividades = dados.atividades || [];
        
        // Wait for DOM to update
        await tick();
        renderizarGraficoResumoDiario();
      }
    } catch (error) {
      console.error("Erro ao carregar gráficos:", error);
    }
  }
  
  // Render daily summary chart
  function renderizarGraficoResumoDiario() {
    const resumoCanvas = document.getElementById('resumoCalorias');
    if (!resumoCanvas) return;
    
    // Calculate data for today
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
    
    // Destroy previous chart if exists
    if (chartResumo) chartResumo.destroy();
    
    // Create new chart
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

    // Update deficit display
    atualizarDeficitDisplay(resumoCanvas, deficitCalorico);
  }
  
  // Ensure chart is properly initialized even when no data is available
  function inicializarGraficoVazio() {
    const resumoCanvas = document.getElementById('resumoCalorias');
    if (!resumoCanvas) return;
    
    // Destroy previous chart if exists
    if (chartResumo) chartResumo.destroy();
    
    // Create empty chart to maintain layout
    chartResumo = new Chart(resumoCanvas, {
      type: 'bar',
      data: {
        labels: ['Alimentação', 'Exercício'],
        datasets: [{
          label: 'Resumo do Dia',
          data: [0, 0],
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
    
    // Show connection message
    const deficitText = document.createElement('div');
    deficitText.className = 'deficit-display';
    deficitText.textContent = 'Conecte sua carteira para ver dados';
    deficitText.style.fontSize = '0.8rem';
    deficitText.style.maxWidth = '300px';
    deficitText.style.margin = '1rem auto';
    deficitText.style.padding = '0.5rem';
    deficitText.style.textAlign = 'center';
    deficitText.style.fontWeight = 'bold';
    deficitText.style.color = '#666';
    deficitText.style.borderRadius = '0.5rem';
    deficitText.style.backgroundColor = 'rgba(0, 0, 0, 0.05)';
    deficitText.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.1)';
    
    // Remove any existing deficit display first
    const existingDisplay = resumoCanvas.parentElement?.querySelector('.deficit-display');
    if (existingDisplay) {
      existingDisplay.remove();
    }
    
    resumoCanvas.parentElement?.appendChild(deficitText);
  }

  // Update the deficit display element
  function atualizarDeficitDisplay(canvas, deficitCalorico) {
    // Remove existing deficit display if present
    const existingDisplay = canvas.parentElement?.querySelector('.deficit-display');
    if (existingDisplay) {
      existingDisplay.remove();
    }
    
    // Create new deficit display
    const deficitText = document.createElement('div');
    deficitText.className = 'deficit-display';
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
    
    canvas.parentElement?.appendChild(deficitText);
  }

  // Export activities to JSON file
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

  // Import activities from JSON file
  async function importarAtividades(event) {
    const input = event.target;
    if (!input.files || input.files.length === 0) return;
    
    const file = input.files[0];
    carregando = true;
    erro = "";
    resultado = "";
    
    try {
      // Validate wallet connection
      if (!$walletAddress) {
        throw new Error("Conecte sua carteira ArConnect antes de importar.");
      }
      
      // Read file
      const text = await file.text();
      const json = JSON.parse(text);
      
      if (!Array.isArray(json)) {
        throw new Error("O arquivo JSON deve ser uma lista de atividades.");
      }
      
      // Import each activity
      for (const item of json) {
        await sendMessageToProcess({
          wallet: $walletAddress,
          descricao: item.descricao,
          calorias: item.calorias,
          timestamp: new Date(item.timestamp).toISOString()
        }, "RegistrarAtividade", processId);
      }
      
      resultado = "✅ Atividades importadas com sucesso.";
      await carregarGrafico($walletAddress);
      
    } catch (err) {
      erro = "❌ Erro: " + (err?.message || err);
    } finally {
      carregando = false;
      input.value = ""; // Reset file input
    }
  }

  // Load data when wallet changes (reactive)
  $: if ($walletAddress) {
    carregarGrafico($walletAddress);
  } else {
    // If no wallet is connected, initialize an empty chart
    tick().then(() => inicializarGraficoVazio());
  }

  // Initial setup when component mounts
  onMount(() => {
    if ($walletAddress) {
      carregarGrafico($walletAddress);
    } else {
      // Initialize empty chart if wallet not connected on mount
      inicializarGraficoVazio();
    }
    
    return () => {
      // Cleanup on unmount
      if (chartResumo) {
        chartResumo.destroy();
      }
    };
  });
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
            required
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
              required
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
            required
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
    
    <label class="btn-action" class:disabled={carregando}>
      <span class="action-icon">📥</span> Importar Atividades
      <input 
        type="file" 
        accept=".json" 
        style="display: none;" 
        on:change={importarAtividades}
        disabled={carregando} 
      />
    </label>
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
  
  .form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }

  .full-width {
    grid-column: 1 / -1;
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
  .btn-action:disabled, .btn-danger:disabled,
  .disabled {
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
    .form-grid {
      grid-template-columns: 1fr;
    }
    
    .actions-panel {
      flex-direction: column;
    }
    
    .input-with-button {
      flex-direction: column;
    }
    
    .form-panel {
      padding: 1rem;
    }
  }

  @media (max-width: 640px) {
    .input-with-button {
      flex-direction: column;
    }
  }
</style>