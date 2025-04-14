<script lang="ts">
    import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
    import { fly } from 'svelte/transition';
  
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
  
    async function simular() {
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
      } catch (err) {
        erro = "❌ Erro: " + (err?.message || err);
      }
  
      carregando = false;
    }
  </script>
  
  <style>
    input, select {
      padding: 0.5rem;
      margin-bottom: 0.7rem;
      width: 100%;
      border-radius: 6px;
      border: 1px solid #555;
      background-color: #111;
      color: white;
    }
  
    button {
      padding: 0.6rem 1rem;
      background-color: #111;
      border: 1px solid #555;
      border-radius: 8px;
      color: white;
      font-weight: bold;
      cursor: pointer;
    }
  
    .resultado {
      margin-top: 1rem;
      background-color: #222;
      padding: 1rem;
      border-radius: 0.5rem;
      font-size: 1rem;
    }
  
    .historico {
      margin-top: 2rem;
    }
  
    .item {
      background: #1a1a1a;
      margin-bottom: 0.5rem;
      padding: 0.6rem;
      border-radius: 6px;
      font-size: 0.95rem;
    }
  
    .erro {
      margin-top: 1rem;
      color: red;
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
      {carregando ? "Calculando..." : "Enviar mensagem real"}
    </button>
  </form>
  
  {#if resultado}
    <div class="resultado" in:fly={{ y: 20, duration: 300 }}>
      <strong>✅ Resultado:</strong><br />
      Calorias estimadas: <b>{resultado.calorias.toFixed(2)}</b> {resultado.unidade}
    </div>
  {:else if erro}
    <div class="erro">{erro}</div>
  {/if}
  
  {#if historico.length}
    <div class="historico">
      <h3>📜 Histórico recente</h3>
      {#each historico as item (item.id)}
        <div class="item" in:fly={{ y: 10, duration: 200 }}>
          <strong>{item.data}</strong><br />
          Sexo: {item.sexo}, Idade: {item.idade}, Peso: {item.peso}kg, Altura: {item.altura}cm, Biotipo: {item.biotipo}<br />
          🔥 <b>{item.calorias.toFixed(2)} {item.unidade}</b>
        </div>
      {/each}
    </div>
  {/if}