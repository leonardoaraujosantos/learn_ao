<script lang="ts">
  import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
  import { fly } from 'svelte/transition';
  import { userInfo } from '../stores/blockchainStore';
  import { onMount } from 'svelte';

  let entrada = {
    id: "",
    sexo: "masculino",
    idade: 30,
    peso: 75,
    altura: 175,
    biotipo: "mesomorfo"
  };

  let resultado: any = null;
  let erro: string = "";
  let historico: any[] = [];
  let carregando = false;

  const processId = "Xzr7DID-De_gxf1ORvuOfFVyKmb6O0_CEBezsD2kXWw";

  onMount(() => {
    const unsubscribe = userInfo.subscribe((user) => {
      if (user) {
        entrada.sexo = user.sexo;
        entrada.idade = new Date().getFullYear() - parseInt(user.ano_nascimento, 10);
        entrada.altura = user.altura_cm;
        entrada.biotipo = user.biotipo;
      }
    });

    return () => unsubscribe();
  });

  async function processarCaloriasBasalAO() {
    carregando = true;
    resultado = null;
    erro = "";

    entrada.id = String(crypto.randomUUID());

    try {
      const mensagem = await sendMessageToProcess(entrada, "Calorias", processId);
      const mensagens = await lerResultadoDaMensagem(processId, mensagem);
      const resposta = mensagens?.[0]?.Data;

      if (resposta) {
        resultado = JSON.parse(resposta);
        historico.unshift({ ...entrada, ...resultado, data: new Date().toLocaleTimeString() });
        if (historico.length > 5) historico.pop(); // mantém só os 5 últimos
      } else {
        erro = "✅ Mensagem enviada, mas sem resposta.";
      }
    } catch (err: any) {
      erro = "❌ Erro: " + (err?.message || err);
    }

    carregando = false;
  }
</script>

<div class="calorias-basal-container">
  <div class="section-header">
    <div class="icon-badge">🔥</div>
    <h2>Simulador de Calorias Basais</h2>
  </div>
  
  <div class="content-grid">
    <div class="form-card">
      <form on:submit|preventDefault={processarCaloriasBasalAO}>
        <div class="form-grid">
          <div class="form-group">
            <label for="sexo">Sexo</label>
            <select id="sexo" class="form-control" bind:value={entrada.sexo}>
              <option value="masculino">Masculino</option>
              <option value="feminino">Feminino</option>
            </select>
          </div>
      
          <div class="form-group">
            <label for="idade">Idade</label>
            <input type="number" id="idade" class="form-control" bind:value={entrada.idade} min="1" max="120" />
          </div>
      
          <div class="form-group">
            <label for="peso">Peso (kg)</label>
            <input type="number" id="peso" class="form-control" bind:value={entrada.peso} step="0.1" min="1" />
          </div>
      
          <div class="form-group">
            <label for="altura">Altura (cm)</label>
            <input type="number" id="altura" class="form-control" bind:value={entrada.altura} min="1" />
          </div>
      
          <div class="form-group">
            <label for="biotipo">Biotipo</label>
            <select id="biotipo" class="form-control" bind:value={entrada.biotipo}>
              <option value="endomorfo">Endomorfo</option>
              <option value="mesomorfo">Mesomorfo</option>
              <option value="ectomorfo">Ectomorfo</option>
            </select>
          </div>
        </div>
      
        <button type="submit" class="btn-primary" disabled={carregando}>
          {#if carregando}
            <span class="spinner"></span> Calculando...
          {:else}
            Calcular
          {/if}
        </button>
      </form>
    </div>
    
    <div class="results-card">
      {#if resultado}
        <div class="resultado" in:fly={{ y: 20, duration: 300 }}>
          <div class="result-header">
            <span class="result-icon">✅</span>
            <h3>Resultado</h3>
          </div>
          <div class="result-body">
            <p>Calorias estimadas:</p>
            <div class="calorie-display">
              <span class="calorie-value">{resultado.calorias.toFixed(0)}</span>
              <span class="calorie-unit">{resultado.unidade}</span>
            </div>
          </div>
        </div>
      {:else if erro}
        <div class="erro">
          <div class="erro-icon">❌</div>
          <div class="erro-message">{erro}</div>
        </div>
      {:else}
        <div class="placeholder-message">
          Preencha os campos e clique em "Calcular" para ver o resultado.
        </div>
      {/if}
    </div>
  </div>

  {#if historico.length}
    <div class="historico-section">
      <div class="section-header">
        <div class="icon-badge">📜</div>
        <h3>Histórico recente</h3>
      </div>
      
      <div class="historico-grid">
        {#each historico as item (item.id)}
          <div class="historico-card" in:fly={{ y: 10, duration: 200 }}>
            <div class="historico-time">
              <span class="time-icon">🕒</span>
              <span>{item.data}</span>
            </div>
            
            <div class="historico-details">
              <div class="detail-item">
                <span class="detail-label">Sexo:</span>
                <span class="detail-value">{item.sexo}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Idade:</span>
                <span class="detail-value">{item.idade} anos</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Peso:</span>
                <span class="detail-value">{item.peso} kg</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Altura:</span>
                <span class="detail-value">{item.altura} cm</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Biotipo:</span>
                <span class="detail-value">{item.biotipo}</span>
              </div>
            </div>
            
            <div class="historico-result">
              <span class="result-flame">🔥</span>
              <span class="result-value">{item.calorias.toFixed(0)}</span>
              <span class="result-unit">{item.unidade}</span>
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>

<style>
  .calorias-basal-container {
    width: 100%;
    max-width: 1000px;
    margin: 0 auto;
  }

  .section-header {
    display: flex;
    align-items: center;
    margin-bottom: 2rem;
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

  .content-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
    margin-bottom: 2.5rem;
  }

  @media (max-width: 768px) {
    .content-grid {
      grid-template-columns: 1fr;
    }
  }

  .form-card, .results-card {
    background: white;
    border-radius: 1rem;
    padding: 2rem;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
    height: 100%;
  }

  .form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  @media (max-width: 500px) {
    .form-grid {
      grid-template-columns: 1fr;
    }
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

  .btn-primary {
    background: linear-gradient(135deg, #ff0080, #7928ca);
    color: white;
    border: none;
    border-radius: 0.5rem;
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    height: 48px;
    margin-top: 0.5rem;
  }

  .btn-primary:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(255, 0, 128, 0.25);
  }

  .btn-primary:active:not(:disabled) {
    transform: translateY(0);
  }

  .btn-primary:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

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

  .results-card {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .resultado {
    width: 100%;
    text-align: center;
  }

  .result-header {
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 1.5rem;
    gap: 0.75rem;
  }

  .result-icon {
    font-size: 1.5rem;
  }

  .result-body {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .result-body p {
    margin: 0 0 1rem 0;
    color: #666;
  }

  .calorie-display {
    display: flex;
    align-items: baseline;
    gap: 0.75rem;
  }

  .calorie-value {
    font-size: 3.5rem;
    font-weight: 700;
    background: linear-gradient(90deg, #ff0080, #7928ca);
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .calorie-unit {
    font-size: 1.25rem;
    color: #666;
  }

  .erro {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    background-color: #fff0f0;
    padding: 1.25rem;
    border-radius: 0.5rem;
    border-left: 4px solid #ff4040;
  }

  .erro-icon {
    font-size: 1.25rem;
  }

  .erro-message {
    color: #c00;
    font-weight: 500;
  }

  .placeholder-message {
    color: #999;
    text-align: center;
    padding: 1.5rem;
    font-size: 1rem;
  }

  /* Histórico section */
  .historico-section {
    margin-top: 3rem;
  }

  .historico-grid {
    display: grid;
    gap: 1.5rem;
    margin-top: 1.5rem;
  }

  .historico-card {
    background: white;
    border-radius: 0.75rem;
    padding: 1.5rem;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
    display: grid;
    grid-template-columns: auto 1fr auto;
    gap: 1.5rem;
    align-items: center;
    transition: transform 0.2s ease;
  }

  .historico-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  }

  .historico-time {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
    color: #666;
  }

  .time-icon {
    font-size: 1.25rem;
  }

  .historico-details {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
  }

  .detail-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .detail-label {
    font-size: 0.875rem;
    font-weight: 600;
    color: #666;
  }

  .detail-value {
    font-size: 0.875rem;
    color: #333;
  }

  .historico-result {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
  }

  .result-flame {
    font-size: 1.5rem;
  }

  .result-value {
    font-size: 1.75rem;
    font-weight: 700;
    color: #ff0080;
  }

  .result-unit {
    font-size: 0.875rem;
    color: #666;
  }

  @media (max-width: 768px) {
    .historico-card {
      grid-template-columns: 1fr;
      text-align: center;
    }

    .historico-details {
      justify-content: center;
    }
  }
</style>