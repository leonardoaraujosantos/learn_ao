<script lang="ts">
  import ButtonConnectWallet from './lib/ButtonConnectWallet.svelte';
    import CaloriasBasalDryrun from './lib/CaloriasBasalDryrun.svelte';
  import CaloriasBasal from './lib/CaloriasBasal.svelte';
</script>

<main>
  <h1>ArHealth</h1>

  <div>
    <ButtonConnectWallet />
  </div>

  <div>
    <CaloriasBasalDryrun />
  </div>

  <div>
    <CaloriasBasal />
  </div>

  <p>
    Vamos monitorar nosso gasto calorico e exercicos no dia a dia!
  </p>
</main>

<style>

</style>
