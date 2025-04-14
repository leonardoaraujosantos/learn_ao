<script lang="ts">
  import ButtonConnectWallet from './lib/ButtonConnectWallet.svelte';
  import CaloriasBasal from './lib/CaloriasBasal.svelte';
</script>

<main>
  <h1>🔥 ArHealth</h1>
  <p class="subtitulo">
    Acompanhe seu gasto calórico e mantenha sua saúde em dia!
  </p>

  <div class="wallet">
    <ButtonConnectWallet />
  </div>

  <section class="painel">
    <CaloriasBasal />
  </section>
</main>

<style>
  main {
    max-width: 720px;
    margin: 0 auto;
    padding: 2rem 1rem;
    font-family: 'Inter', sans-serif;
    color: #f1f1f1;
    background: #111;
    text-align: center;
  }

  h1 {
    font-size: 2.5rem;
    font-weight: 800;
    margin-bottom: 0.5rem;
    color: #fff;
  }

  .subtitulo {
    font-size: 1.1rem;
    color: #aaa;
    margin-bottom: 1.5rem;
  }

  .wallet {
    margin-bottom: 2rem;
  }

  .painel {
    background: #1c1c1c;
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 0 10px rgba(0,0,0,0.3);
    transition: 0.2s ease;
  }

  @media (max-width: 480px) {
    main {
      padding: 1rem;
    }

    .painel {
      padding: 1rem;
    }

    h1 {
      font-size: 2rem;
    }

    .subtitulo {
      font-size: 1rem;
    }
  }
</style>