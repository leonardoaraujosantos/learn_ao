<script lang="ts">
  import ButtonConnectWallet from './lib/ButtonConnectWallet.svelte';
  import CaloriasBasal from './lib/CaloriasBasal.svelte';
  import RegistrarAtividade from './lib/RegistrarAtividade.svelte';
  import RegistroUsuarioMedidas from './lib/RegistroUsuarioMedidas.svelte';
  import { userInfo, lastMeasurement } from './stores/blockchainStore';

  let activeSection = 'Home';
  let userInfoLocal = $userInfo;
  let ultimaMedida = $lastMeasurement;

  userInfo.subscribe(value => {
    userInfoLocal = value;
    console.log(userInfoLocal);
  });

  lastMeasurement.subscribe(value => {
    ultimaMedida = value;
    console.log(ultimaMedida);
  });

  function setActive(section: string) {
    activeSection = section;
  }
</script>

<main>
  <div class="app-container">
    <nav class="navbar">
      <div class="logo-section">
        <h1>ArHealth</h1>
      </div>
      <ul class="nav-links">
        <li>
          <button 
            class:active={activeSection === 'Calorias Basal'} 
            on:click={() => setActive('Calorias Basal')}
          >
            Calorias Basal
          </button>
        </li>
        <li>
          <button 
            class:active={activeSection === 'Registrar Atividade'} 
            on:click={() => setActive('Registrar Atividade')}
          >
            Registrar Atividade
          </button>
        </li>
        <li>
          <button 
            class:active={activeSection === 'Medidas'} 
            on:click={() => setActive('Medidas')}
          >
            Medidas
          </button>
        </li>
      </ul>
      <div class="wallet-section">
        <ButtonConnectWallet />
      </div>
    </nav>

    <header class="hero-section">
      <div class="heart-container">
        <div class="heart-icon">❤️</div>
      </div>
      <h2 class="tagline">Se conhecer faz bem.</h2>
      <p class="description">
        Acompanhe seu gasto calórico, organize informações importantes sobre sua saúde
        e mantenha seu bem-estar em um só lugar.
      </p>
      
      {#if userInfoLocal && ultimaMedida}
        <div class="user-data-container">
          <div class="data-card user-info">
            <h3>Dados Pessoais</h3>
            <div class="info-grid">
              <div class="info-item">
                <span class="info-icon">👤</span>
                <span class="info-label">Nome:</span>
                <span class="info-value">{userInfoLocal.nome}</span>
              </div>
              <div class="info-item">
                <span class="info-icon">📏</span>
                <span class="info-label">Altura:</span>
                <span class="info-value">{userInfoLocal.altura_cm} cm</span>
              </div>
              <div class="info-item">
                <span class="info-icon">🧬</span>
                <span class="info-label">Sexo:</span>
                <span class="info-value">{userInfoLocal.sexo}</span>
              </div>
              <div class="info-item">
                <span class="info-icon">🧠</span>
                <span class="info-label">Biotipo:</span>
                <span class="info-value">{userInfoLocal.biotipo}</span>
              </div>
              <div class="info-item">
                <span class="info-icon">🎂</span>
                <span class="info-label">Nascimento:</span>
                <span class="info-value">{userInfoLocal.ano_nascimento}</span>
              </div>
            </div>
          </div>

          <div class="data-card measurements">
            <h3>Medidas Atuais</h3>
            <div class="info-grid">
              <div class="info-item">
                <span class="info-icon">⚖️</span>
                <span class="info-label">Peso:</span>
                <span class="info-value">{ultimaMedida.peso} kg</span>
              </div>
              <div class="info-item">
                <span class="info-icon">📊</span>
                <span class="info-label">IMC:</span>
                <span class="info-value">{ultimaMedida.imc}</span>
              </div>
              <div class="info-item">
                <span class="info-icon">💧</span>
                <span class="info-label">Gordura Corporal:</span>
                <span class="info-value">{ultimaMedida.gordura_corporal}%</span>
              </div>
              <div class="info-item">
                <span class="info-icon">💪</span>
                <span class="info-label">Massa Gordura:</span>
                <span class="info-value">{ultimaMedida.massa_gordura} kg</span>
              </div>
              <div class="info-item">
                <span class="info-icon">📅</span>
                <span class="info-label">Data:</span>
                <span class="info-value">{new Date(ultimaMedida.data).toLocaleDateString('pt-BR')}</span>
              </div>
            </div>
          </div>
        </div>
      {/if}
    </header>

    <div class="content-section">
      {#if activeSection === 'Medidas'}
        <div class="panel">
          <RegistroUsuarioMedidas />
        </div>
      {/if}

      {#if activeSection === 'Calorias Basal'}
        <div class="panel">
          <CaloriasBasal />
        </div>
      {/if}

      {#if activeSection === 'Registrar Atividade'}
        <div class="panel">
          <RegistrarAtividade />
        </div>
      {/if}
    </div>
  </div>
</main>

<style>
  /* Base Styles */
  :global(body) {
    font-family: 'Inter', 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
    margin: 0;
    padding: 0;
    background-color: #f5f7fa;
    color: #333;
    line-height: 1.6;
  }

  .app-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1rem;
  }

  /* Navigation */
  .navbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1rem 0;
    border-bottom: 1px solid #eaeaea;
    margin-bottom: 2rem;
  }

  .logo-section h1 {
    font-size: 2rem;
    font-weight: 800;
    color: #333;
    margin: 0;
    background: linear-gradient(90deg, #ff0080, #7928ca);
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .nav-links {
    display: flex;
    list-style: none;
    margin: 0;
    padding: 0;
    gap: 1rem;
  }

  .nav-links button {
    background: none;
    border: none;
    font-size: 1rem;
    color: #666;
    cursor: pointer;
    padding: 0.5rem 1rem;
    border-radius: 0.5rem;
    transition: all 0.2s ease;
  }

  .nav-links button:hover {
    background-color: #f0f0f0;
    color: #333;
  }

  .nav-links button.active {
    background-color: #ff0080;
    color: white;
    font-weight: 600;
  }

  /* Hero Section */
  .hero-section {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    padding: 2rem 0;
  }

  .heart-container {
    background: linear-gradient(135deg, #ff0080, #7928ca);
    width: 60px;
    height: 60px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 1rem;
    box-shadow: 0 4px 12px rgba(255, 0, 128, 0.25);
  }

  .heart-icon {
    font-size: 2rem;
  }

  .tagline {
    font-size: 2rem;
    font-weight: 700;
    margin: 0.5rem 0;
    color: #333;
  }

  .description {
    max-width: 600px;
    color: #666;
    margin-bottom: 2rem;
  }

  /* User Data Cards */
  .user-data-container {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
    width: 100%;
    max-width: 900px;
    margin-bottom: 2rem;
  }

  @media (max-width: 768px) {
    .user-data-container {
      grid-template-columns: 1fr;
    }
  }

  .data-card {
    background: white;
    border-radius: 1rem;
    padding: 1.5rem;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
  }

  .data-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 20px rgba(0, 0, 0, 0.08);
  }

  .data-card h3 {
    margin-top: 0;
    font-size: 1.25rem;
    color: #333;
    position: relative;
    padding-bottom: 0.5rem;
    margin-bottom: 1rem;
  }

  .data-card h3::after {
    content: '';
    position: absolute;
    left: 0;
    bottom: 0;
    width: 50px;
    height: 3px;
    background: linear-gradient(90deg, #ff0080, #7928ca);
    border-radius: 3px;
  }

  .info-grid {
    display: grid;
    gap: 0.75rem;
  }

  .info-item {
    display: grid;
    grid-template-columns: auto auto 1fr;
    align-items: center;
    gap: 0.5rem;
  }

  .info-icon {
    font-size: 1.25rem;
  }

  .info-label {
    font-weight: 600;
    color: #666;
  }

  .info-value {
    color: #333;
  }

  /* Content Section */
  .content-section {
    margin: 2rem 0;
  }

  .panel {
    background: white;
    border-radius: 1rem;
    padding: 2rem;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  }

  /* Wallet Button (assuming your component has these classes) */
  :global(.wallet-button) {
    background: linear-gradient(135deg, #ff0080, #7928ca);
    color: white;
    padding: 0.75rem 1.25rem;
    border-radius: 0.5rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    border: none;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  :global(.wallet-button:hover) {
    box-shadow: 0 4px 12px rgba(255, 0, 128, 0.25);
    transform: translateY(-2px);
  }
</style>