<script lang="ts">
  import ButtonConnectWallet from './lib/ButtonConnectWallet.svelte';
  import CaloriasBasal from './lib/CaloriasBasal.svelte';
</script>

<main>
  <h1>ArHealth</h1>
  <p>
    Vamos monitorar nosso gasto calorico e exercicos no dia a dia!
  </p>
  <div>
    <ButtonConnectWallet />
  </div>

  <div>
    <CaloriasBasal />
  </div>

  
</main>

<style>

</style>
