<script lang="ts">
    import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
  
    let entrada = {
      id: "", // precisa ser string
      sexo: "masculino",
      idade: 30,
      peso: 75,
      altura: 175,
      biotipo: "mesomorfo"
    };
  
    let resultado: string = "";
    let carregando = false;
  
    const processId = "Xzr7DID-De_gxf1ORvuOfFVyKmb6O0_CEBezsD2kXWw"; // substitua aqui
  
    async function simular() {
      carregando = true;
      resultado = "";
  
      // ⚠️ Gera novo ID como string
      entrada.id = String(crypto.randomUUID());
  
      console.log("🔍 Enviando entrada para AO:", JSON.stringify(entrada, null, 2));
  
      try {
        const mensagem = await sendMessageToProcess(entrada, "Calorias", processId);
        console.log('Resultado envio:', mensagem)
        const mensagens = await lerResultadoDaMensagem(processId, mensagem);
        console.log(mensagens)
  
        resultado = mensagens?.[0]?.Data || "✅ Enviado com sucesso, sem resposta.";
      } catch (err) {
        resultado = "❌ Erro: " + (err?.message || err);
      }
  
      carregando = false;
    }
  </script>
  
  <!-- UI (mantida) -->
  <style>
    input, select {
      padding: 0.4rem;
      margin-bottom: 0.5rem;
      display: block;
    }
  </style>
  
  <h2>🔥 Simulador de Calorias (mensagem real com carteira)</h2>
  
  <form on:submit|preventDefault={simular}>
    <label>Sexo:
      <select bind:value={entrada.sexo}>
        <option value="masculino">Masculino</option>
        <option value="feminino">Feminino</option>
      </select>
    </label>
  
    <label>Idade:
      <input type="number" bind:value={entrada.idade} />
    </label>
  
    <label>Peso (kg):
      <input type="number" bind:value={entrada.peso} />
    </label>
  
    <label>Altura (cm):
      <input type="number" bind:value={entrada.altura} />
    </label>
  
    <label>Biotipo:
      <select bind:value={entrada.biotipo}>
        <option value="endomorfo">Endomorfo</option>
        <option value="mesomorfo">Mesomorfo</option>
        <option value="ectomorfo">Ectomorfo</option>
      </select>
    </label>
  
    <button type="submit" disabled={carregando}>
      {carregando ? "Enviando..." : "Enviar mensagem real"}
    </button>
  </form>
  
  {#if resultado}
    <pre>{resultado}</pre>
  {/if}