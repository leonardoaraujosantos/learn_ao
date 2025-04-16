<script lang="ts">
  import { walletAddress } from '../stores/blockchainStore';
  import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
  import { get } from 'svelte/store';
  import { fly } from 'svelte/transition';

  const processId = "4z14kjJd0Pjjg1PuYA98bJd4tXKfytIcCD_-Q1z7HLQ";

  // User registration data
  let nome = "";
  let anoNascimento = 1990;
  let altura = 175;
  let sexo = "masculino";
  let biotipo = "mesomorfo";

  // Measurement data
  let peso = 70;
  let imc = 23.5;
  let gordura = 15;
  let massaGordura = 12;
  let dataMedicao = new Date().toISOString().slice(0, 16);
  let caloriasBasal = 0;

  // State variables
  let resultado = "";
  let erro = "";
  let medidas: any[] = [];
  let isUserRegistering = false;
  let isMeasurementRegistering = false;
  let activeTab = "register";

  async function registrarUsuario() {
    erro = resultado = "";
    isUserRegistering = true;
    const wallet = get(walletAddress);
    if (!wallet) {
      erro = "Conecte a carteira";
      isUserRegistering = false;
      return;
    }

    const payload = { wallet, nome, ano_nascimento: anoNascimento, altura_cm: altura, sexo, biotipo };
    console.log("Payload:", payload);

    try {
      const msg = await sendMessageToProcess(payload, "RegistrarUsuario", processId);
      const resposta = await lerResultadoDaMensagem(processId, msg);
      resultado = resposta?.[0]?.Data || "✅ Usuário registrado com sucesso.";
    } catch (error: any) {
      erro = `❌ Erro ao registrar: ${error.message || error}`;
    } finally {
      isUserRegistering = false;
    }
  }

  async function registrarMedida() {
    erro = resultado = "";
    isMeasurementRegistering = true;
    const wallet = get(walletAddress);
    if (!wallet) {
      erro = "Conecte a carteira";
      isMeasurementRegistering = false;
      return;
    }

    const payload = {
      wallet,
      peso,
      imc,
      gordura_corporal: gordura,
      massa_gordura: massaGordura,
      calorias_basal: caloriasBasal,
      data: new Date(dataMedicao).toISOString()
    };

    try {
      const msg = await sendMessageToProcess(payload, "RegistrarMedida", processId);
      const resposta = await lerResultadoDaMensagem(processId, msg);
      resultado = resposta?.[0]?.Data || "✅ Medida registrada com sucesso.";
      await listarMedidas();
    } catch (error: any) {
      erro = `❌ Erro ao registrar medida: ${error.message || error}`;
    } finally {
      isMeasurementRegistering = false;
    }
  }

  async function listarMedidas() {
    erro = resultado = "";
    const wallet = get(walletAddress);
    if (!wallet) {
      erro = "Conecte a carteira";
      return;
    }

    try {
      const msg = await sendMessageToProcess({ wallet }, "ListarMedidas", processId);
      const res = await lerResultadoDaMensagem(processId, msg);
      medidas = JSON.parse(res?.[0]?.Data || "[]").medidas;
    } catch (error: any) {
      erro = `❌ Erro ao listar medidas: ${error.message || error}`;
    }
  }

  async function apagarMedidas() {
    if (!confirm("Tem certeza que deseja apagar todas as medidas?")) return;
    
    erro = resultado = "";
    const wallet = get(walletAddress);
    if (!wallet) {
      erro = "Conecte a carteira";
      return;
    }

    try {
      await sendMessageToProcess({ wallet }, "ApagarMedidas", processId);
      medidas = [];
      resultado = "🗑️ Medidas apagadas com sucesso";
    } catch (error: any) {
      erro = `❌ Erro ao apagar medidas: ${error.message || error}`;
    }
  }

  async function apagarUsuario() {
    if (!confirm("Tem certeza que deseja apagar seu usuário? Esta ação não pode ser desfeita.")) return;
    
    erro = resultado = "";
    const wallet = get(walletAddress);
    if (!wallet) {
      erro = "Conecte a carteira";
      return;
    }

    try {
      await sendMessageToProcess({ wallet }, "ApagarUsuario", processId);
      resultado = "🗑️ Usuário apagado com sucesso";
    } catch (error: any) {
      erro = `❌ Erro ao apagar usuário: ${error.message || error}`;
    }
  }

  async function exportarMedidas() {
    if (medidas.length === 0) {
      erro = "❌ Não há medidas para exportar";
      return;
    }
    
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify({ medidas }));
    const downloadAnchorNode = document.createElement('a');
    downloadAnchorNode.setAttribute("href", dataStr);
    downloadAnchorNode.setAttribute("download", "medidas.json");
    document.body.appendChild(downloadAnchorNode);
    downloadAnchorNode.click();
    downloadAnchorNode.remove();
    
    resultado = "✅ Medidas exportadas com sucesso";
    erro = "";
  }

  async function importarMedidas(event: Event) {
    erro = resultado = "";
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = function(e) {
      const result = e.target?.result;
      if (typeof result === 'string') {
        try {
          const importedData = JSON.parse(result);
          if (Array.isArray(importedData.medidas)) {
            medidas = importedData.medidas;
            resultado = "✅ Medidas importadas com sucesso.";
          } else {
            erro = "❌ Formato de arquivo inválido.";
          }
        } catch (error) {
          erro = "❌ Erro ao importar medidas. Verifique o formato do arquivo.";
        }
      } else {
        erro = "❌ Erro ao ler o arquivo.";
      }
    };
    reader.readAsText(file);
  }

  function setTab(tab: string) {
    activeTab = tab;
  }

  function formatDate(dateString: string) {
    const date = new Date(dateString);
    return date.toLocaleString('pt-BR', { 
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  $: if ($walletAddress) listarMedidas();
</script>

<div class="registro-medidas-container">
  <div class="section-header">
    <div class="icon-badge">👤</div>
    <h2>Registro e Medições do Usuário</h2>
  </div>

  <div class="tabs">
    <button 
      class:active={activeTab === 'register'} 
      on:click={() => setTab('register')}
    >
      <span class="tab-icon">📋</span>
      Cadastro
    </button>
    <button 
      class:active={activeTab === 'measurements'} 
      on:click={() => setTab('measurements')}
    >
      <span class="tab-icon">📏</span>
      Medidas
    </button>
    <button 
      class:active={activeTab === 'history'} 
      on:click={() => setTab('history')}
    >
      <span class="tab-icon">📊</span>
      Histórico
    </button>
  </div>

  {#if activeTab === 'register'}
    <div class="form-panel" in:fly={{ y: 20, duration: 200 }}>
      <form on:submit|preventDefault={registrarUsuario}>
        <div class="form-title">
          <div class="form-icon">📋</div>
          <h3>Cadastrar Usuário</h3>
        </div>
        
        <div class="form-grid">
          <div class="form-group">
            <label for="nome">Nome</label>
            <input id="nome" type="text" class="form-control" placeholder="Nome completo" bind:value={nome} required />
          </div>
          
          <div class="form-group">
            <label for="anoNascimento">Ano de Nascimento</label>
            <input id="anoNascimento" type="number" class="form-control" min="1900" max={new Date().getFullYear()} placeholder="Ex: 1990" bind:value={anoNascimento} required />
          </div>
          
          <div class="form-group">
            <label for="altura">Altura (cm)</label>
            <input id="altura" type="number" class="form-control" min="100" max="250" placeholder="Ex: 175" bind:value={altura} required />
          </div>
          
          <div class="form-group">
            <label for="sexo">Sexo</label>
            <select id="sexo" class="form-control" bind:value={sexo} required>
              <option value="masculino">Masculino</option>
              <option value="feminino">Feminino</option>
            </select>
          </div>
          
          <div class="form-group">
            <label for="biotipo">Biotipo</label>
            <select id="biotipo" class="form-control" bind:value={biotipo} required>
              <option value="endomorfo">Endomorfo</option>
              <option value="mesomorfo">Mesomorfo</option>
              <option value="ectomorfo">Ectomorfo</option>
            </select>
          </div>
        </div>
        
        <button type="submit" class="btn-primary" disabled={isUserRegistering}>
          {#if isUserRegistering}
            <span class="spinner"></span> Registrando...
          {:else}
            Registrar Usuário
          {/if}
        </button>
      </form>
    </div>
  {/if}

  {#if activeTab === 'measurements'}
    <div class="form-panel" in:fly={{ y: 20, duration: 200 }}>
      <form on:submit|preventDefault={registrarMedida}>
        <div class="form-title">
          <div class="form-icon">📏</div>
          <h3>Registrar Medidas Corporais</h3>
        </div>
        
        <div class="form-grid">
          <div class="form-group">
            <label for="peso">Peso (kg)</label>
            <input id="peso" type="number" class="form-control" step="0.1" min="20" max="300" placeholder="Ex: 70.5" bind:value={peso} required />
          </div>
          
          <div class="form-group">
            <label for="imc">IMC</label>
            <input id="imc" type="number" class="form-control" step="0.1" min="10" max="50" placeholder="Ex: 23.5" bind:value={imc} required />
          </div>
          
          <div class="form-group">
            <label for="gordura">Gordura Corporal (%)</label>
            <input id="gordura" type="number" class="form-control" step="0.1" min="1" max="60" placeholder="Ex: 15" bind:value={gordura} required />
          </div>
          
          <div class="form-group">
            <label for="massaGordura">Massa de Gordura (kg)</label>
            <input id="massaGordura" type="number" class="form-control" step="0.1" min="1" max="150" placeholder="Ex: 12" bind:value={massaGordura} required />
          </div>
          
          <div class="form-group">
            <label for="caloriasBasal">Calorias Basal</label>
            <input id="caloriasBasal" type="number" class="form-control" step="1" min="500" max="5000" placeholder="Ex: 1800" bind:value={caloriasBasal} required />
          </div>
          
          <div class="form-group">
            <label for="dataMedicao">Data da Medição</label>
            <input id="dataMedicao" type="datetime-local" class="form-control" bind:value={dataMedicao} required />
          </div>
        </div>
        
        <button type="submit" class="btn-primary" disabled={isMeasurementRegistering}>
          {#if isMeasurementRegistering}
            <span class="spinner"></span> Registrando...
          {:else}
            Registrar Medida
          {/if}
        </button>
      </form>
    </div>
  {/if}

  {#if activeTab === 'history'}
    <div class="history-panel" in:fly={{ y: 20, duration: 200 }}>
      <div class="actions-bar">
        <button class="btn-action" on:click={exportarMedidas}>
          <span class="action-icon">📤</span>
          Exportar
        </button>
        
        <div class="file-upload">
          <input type="file" id="importFile" accept="application/json" on:change={importarMedidas} style="display: none;" />
          <label for="importFile" class="btn-action">
            <span class="action-icon">📥</span>
            Importar
          </label>
        </div>
        
        <button class="btn-danger" on:click={apagarMedidas}>
          <span class="action-icon">🗑️</span>
          Apagar Medidas
        </button>
        
        <button class="btn-danger" on:click={apagarUsuario}>
          <span class="action-icon">❌</span>
          Apagar Usuário
        </button>
      </div>

      {#if medidas.length}
        <div class="history-grid">
          {#each medidas as medida (medida.data)}
            <div class="history-card" in:fly={{ y: 10, duration: 200 }}>
              <div class="history-date">
                <span class="date-icon">📅</span>
                <span class="date-value">{formatDate(medida.data)}</span>
              </div>
              
              <div class="measurements-grid">
                <div class="measurement-item">
                  <span class="measurement-icon">⚖️</span>
                  <span class="measurement-label">Peso:</span>
                  <span class="measurement-value">{medida.peso} kg</span>
                </div>
                
                <div class="measurement-item">
                  <span class="measurement-icon">📊</span>
                  <span class="measurement-label">IMC:</span>
                  <span class="measurement-value">{medida.imc}</span>
                </div>
                
                <div class="measurement-item">
                  <span class="measurement-icon">💧</span>
                  <span class="measurement-label">Gordura:</span>
                  <span class="measurement-value">{medida.gordura_corporal}%</span>
                </div>
                
                <div class="measurement-item">
                  <span class="measurement-icon">💪</span>
                  <span class="measurement-label">Massa de Gordura:</span>
                  <span class="measurement-value">{medida.massa_gordura} kg</span>
                </div>
                
                <div class="measurement-item">
                  <span class="measurement-icon">🔥</span>
                  <span class="measurement-label">Calorias Basal:</span>
                  <span class="measurement-value">{medida.calorias_basal}</span>
                </div>
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="empty-state">
          <div class="empty-icon">📊</div>
          <p class="empty-message">Nenhuma medida registrada ainda.</p>
          <button class="btn-secondary" on:click={() => setTab('measurements')}>Registrar Primeira Medida</button>
        </div>
      {/if}
    </div>
  {/if}

  {#if resultado}
    <div class="notification success" in:fly={{ y: 20, duration: 200 }}>
      <div class="notification-icon">✅</div>
      <div class="notification-text">{resultado}</div>
    </div>
  {/if}

  {#if erro}
    <div class="notification error" in:fly={{ y: 20, duration: 200 }}>
      <div class="notification-icon">❌</div>
      <div class="notification-text">{erro}</div>
    </div>
  {/if}
</div>

<style>
  .registro-medidas-container {
    width: 100%;
    max-width: 1000px;
    margin: 0 auto;
  }

  .section-header {
    display: flex;
    align-items: center;
    margin-bottom: 1.5rem;
    gap: 0.75rem;
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

  h2, h3 {
    margin: 0;
    color: #333;
    font-weight: 700;
  }

  /* Tabs */
  .tabs {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
    flex-wrap: wrap;
  }

  .tabs button {
    background: white;
    border: none;
    border-radius: 0.5rem;
    padding: 0.75rem 1.25rem;
    font-size: 0.9rem;
    font-weight: 600;
    color: #666;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    transition: all 0.2s ease;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
  }

  .tabs button:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .tabs button.active {
    background: linear-gradient(135deg, #ff0080, #7928ca);
    color: white;
  }

  .tab-icon {
    font-size: 1.1rem;
  }

  /* Form panel */
  .form-panel, .history-panel {
    background: white;
    border-radius: 1rem;
    padding: 2rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    margin-bottom: 1.5rem;
  }

  .form-title {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
  }

  .form-icon {
    font-size: 1.5rem;
  }

  .form-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  label {
    font-size: 0.875rem;
    font-weight: 600;
    color: #555;
    margin-bottom: 0.25rem;
  }

  .form-control {
    padding: 0.75rem;
    border: 1px solid #e0e0e0;
    border-radius: 0.5rem;
    font-size: 1rem;
    transition: border-color 0.2s ease, box-shadow 0.2s ease;
    height: 48px;
    box-sizing: border-box;
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
    font-size: 0.9rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    border: none;
  }

  .btn-primary {
    background: linear-gradient(135deg, #ff0080, #7928ca);
    color: white;
    width: 100%;
    height: 48px;
    margin-top: 0.5rem;
  }

  .btn-primary:hover:not(:disabled), .btn-action:hover, .btn-secondary:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(255, 0, 128, 0.25);
  }

  .btn-primary:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .btn-secondary {
    background: white;
    color: #ff0080;
    border: 1px solid #ff0080;
  }

  .btn-action {
    background: white;
    color: #555;
    border: 1px solid #e0e0e0;
    font-size: 0.8rem;
    padding: 0.5rem 1rem;
  }

  .btn-danger {
    background: white;
    color: #e53935;
    border: 1px solid #e53935;
    font-size: 0.8rem;
    padding: 0.5rem 1rem;
  }

  .btn-danger:hover {
    background: #e53935;
    color: white;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(229, 57, 53, 0.25);
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

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  /* History panel */
  .actions-bar {
    display: flex;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
    flex-wrap: wrap;
  }

  .file-upload {
    position: relative;
  }

  .history-grid {
    display: grid;
    gap: 1rem;
  }

  .history-card {
    background: #f9f9f9;
    border-radius: 0.75rem;
    padding: 1rem;
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 1rem;
    transition: all 0.2s ease;
  }

  .history-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .history-date {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
    padding-right: 1rem;
    border-right: 1px solid #eaeaea;
  }

  .date-icon {
    font-size: 1.25rem;
    color: #ff0080;
  }

  .date-value {
    font-size: 0.75rem;
    color: #666;
    text-align: center;
    white-space: nowrap;
  }

  .measurements-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 0.75rem;
  }

  .measurement-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .measurement-icon {
    font-size: 1rem;
  }

  .measurement-label {
    font-size: 0.8rem;
    font-weight: 600;
    color: #666;
  }

  .measurement-value {
    font-size: 0.9rem;
    color: #333;
  }

  /* Empty state */
  .empty-state {
    text-align: center;
    padding: 3rem 1rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
  }

  .empty-icon {
    font-size: 3rem;
    color: #ccc;
  }

  .empty-message {
    color: #888;
    margin: 0;
  }

  /* Notifications */
  .notification {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 1rem;
    border-radius: 0.5rem;
    margin-top: 1rem;
  }

  .notification.success {
    background-color: #e8f5e9;
    border-left: 4px solid #4caf50;
  }

  .notification.error {
    background-color: #ffebee;
    border-left: 4px solid #e53935;
  }

  .notification-icon {
    font-size: 1.25rem;
  }

  .notification-text {
    color: #333;
  }

  @media (max-width: 768px) {
    .history-card {
      grid-template-columns: 1fr;
    }

    .history-date {
      flex-direction: row;
      border-right: none;
      border-bottom: 1px solid #eaeaea;
      padding-right: 0;
      padding-bottom: 0.5rem;
      margin-bottom: 0.5rem;
    }
  }
</style>