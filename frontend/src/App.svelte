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
  <nav class="navbar">
    <div class="nav-container">
      <h1>ArHealth</h1>
      <ul>
        <li><a href="#" class={activeSection === 'Calorias Basal' ? 'active' : ''} on:click={() => setActive('Calorias Basal')}>Calorias Basal</a></li>
        <li><a href="#" class={activeSection === 'Registrar Atividade' ? 'active' : ''} on:click={() => setActive('Registrar Atividade')}>Registrar Atividade</a></li>
        <li><a href="#" class={activeSection === 'Medidas' ? 'active' : ''} on:click={() => setActive('Medidas')}>Medidas</a></li>
      </ul>
      <div class="wallet-button">
        <ButtonConnectWallet />
      </div>
    </div>
  </nav>

  <header>
    <div class="icon-container">
      <div class="app-icon">
        <div class="heart-icon">❤️</div>
      </div>
    </div>
    <h2>Se conhecer faz bem.</h2>
    <p class="subtitulo">
      Acompanhe seu gasto calórico, organize informações importantes sobre sua saúde
      e mantenha seu bem-estar em um só lugar.
    </p>
      {#if userInfoLocal}
        <div class="usuario-box">
          <p><strong>👤 Nome:</strong> {userInfoLocal.nome}</p>
          <p><strong>📏 Altura:</strong> {userInfoLocal.altura_cm} cm</p>
          <p><strong>🧬 Sexo:</strong> {userInfoLocal.sexo}</p>
          <p><strong>🧠 Biotipo:</strong> {userInfoLocal.biotipo}</p>
          <p><strong>🎂 Nascimento:</strong> {userInfoLocal.ano_nascimento}</p>
        </div>
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
  </header>

  <div class="content-container">
    {#if activeSection === 'Medidas'}
      <div class="panel-container">
        <RegistroUsuarioMedidas />
      </div>
    {/if}

    {#if activeSection === 'Calorias Basal'}
      <div class="panel-container">
        <CaloriasBasal />
      </div>
    {/if}

    {#if activeSection === 'Registrar Atividade'}
      <div class="panel-container">
        <RegistrarAtividade />
      </div>
    {/if}
  </div>
</main>

<style>
  
</style>