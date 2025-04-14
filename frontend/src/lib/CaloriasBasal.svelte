<script lang="ts">
    import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
  
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
    let carregando = false;
  
    const processId = "Xzr7DID-De_gxf1ORvuOfFVyKmb6O0_CEBezsD2kXWw";
  
    async function simular() {
      carregando = true;
      resultado = null;
      erro = "";
  
      entrada.id = String(crypto.randomUUID());
      console.log("🔍 Enviando entrada para AO:", JSON.stringify(entrada, null, 2));
  
      try {
        const mensagem = await sendMessageToProcess(entrada, "Calorias", processId);
        const mensagens = await lerResultadoDaMensagem(processId, mensagem);
        const resposta = mensagens?.[0]?.Data;
  
        if (resposta) {
          resultado = JSON.parse(resposta);
        } else {
          erro = "✅ Mensagem enviada, mas sem resposta.";
        }
      } catch (err) {
        erro = "❌ Erro: " + (err?.message || err);
      }
  
      carregando = false;
    }
  </script>
  
  <style>
    input, select {
      padding: 0.4rem;
      margin-bottom: 0.5rem;
      display: block;
    }
    .resultado {
      margin-top: 1rem;
      padding: 1rem;
      background-color: #222;
      border-radius: 0.5rem;
      font-size: 1.1rem;
    }
    .erro {
      color: red;
      font-weight: bold;
      margin-top: 1rem;
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
    <div class="resultado">
      ✅ Resultado da simulação:
      <ul>
        <li><strong>Calorias:</strong> {resultado.calorias.toFixed(2)} kcal</li>
        <li><strong>Unidade:</strong> {resultado.unidade}</li>
      </ul>
    </div>
  {:else if erro}
    <div class="erro">{erro}</div>
  {/if}