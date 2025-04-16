<script lang="ts">
    import { walletAddress } from '../stores/blockchainStore';
    import { sendMessageToProcess, lerResultadoDaMensagem } from '../lib/ao';
    import { get } from 'svelte/store';
  
    const processId = "4z14kjJd0Pjjg1PuYA98bJd4tXKfytIcCD_-Q1z7HLQ";
  
    let nome = "";
    let anoNascimento = 1990;
    let altura = 175;
    let sexo = "masculino";
    let biotipo = "mesomorfo";
  
    let peso = 70;
    let imc = 23.5;
    let gordura = 15;
    let massaGordura = 12;
    let dataMedicao = new Date().toISOString().slice(0, 16);
    let caloriasBasal = 0;
  
    let resultado = "";
    let erro = "";
    let medidas: any[] = [];
  
    async function registrarUsuario() {
      erro = resultado = "";
      const wallet = get(walletAddress);
      if (!wallet) return erro = "Conecte a carteira";
  
      const payload = { wallet, nome, ano_nascimento: anoNascimento, altura_cm:altura, sexo, biotipo };
      console.log("Payload:", payload);
  
      const msg = await sendMessageToProcess(payload, "RegistrarUsuario", processId);
      const resposta = await lerResultadoDaMensagem(processId, msg);
      resultado = resposta?.[0]?.Data || "✅ Usuário registrado.";
    }
  
    async function registrarMedida() {
      erro = resultado = "";
      const wallet = get(walletAddress);
      if (!wallet) return erro = "Conecte a carteira";
  
      const payload = {
        wallet,
        peso,
        imc,
        gordura_corporal: gordura,
        massa_gordura: massaGordura,
        calorias_basal: caloriasBasal,
        data: new Date(dataMedicao).toISOString()
      };
  
      const msg = await sendMessageToProcess(payload, "RegistrarMedida", processId);
      const resposta = await lerResultadoDaMensagem(processId, msg);
      resultado = resposta?.[0]?.Data || "✅ Medida registrada.";
      await listarMedidas();
    }
  
    async function listarMedidas() {
      erro = resultado = "";
      const wallet = get(walletAddress);
      if (!wallet) return erro = "Conecte a carteira";
  
      const msg = await sendMessageToProcess({ wallet }, "ListarMedidas", processId);
      const res = await lerResultadoDaMensagem(processId, msg);
      medidas = JSON.parse(res?.[0]?.Data || "[]").medidas;
    }
  
    async function apagarMedidas() {
      const wallet = get(walletAddress);
      await sendMessageToProcess({ wallet }, "ApagarMedidas", processId);
      medidas = [];
      resultado = "🗑️ Medidas apagadas";
    }
  
    async function apagarUsuario() {
      const wallet = get(walletAddress);
      await sendMessageToProcess({ wallet }, "ApagarUsuario", processId);
      resultado = "🗑️ Usuário apagado";
    }
  
    async function exportarMedidas() {
      const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(medidas));
      const downloadAnchorNode = document.createElement('a');
      downloadAnchorNode.setAttribute("href", dataStr);
      downloadAnchorNode.setAttribute("download", "medidas.json");
      document.body.appendChild(downloadAnchorNode);
      downloadAnchorNode.click();
      downloadAnchorNode.remove();
    }
  
    async function importarMedidas(event: Event) {
      const input = event.target as HTMLInputElement;
      const file = input.files?.[0];
      if (!file) return;
  
      const reader = new FileReader();
      reader.onload = function(e) {
        const result = e.target?.result;
        if (typeof result === 'string') {
          try {
            const importedData = JSON.parse(result);
            medidas = importedData.medidas || [];
            resultado = "✅ Medidas importadas.";
          } catch (error) {
            erro = "❌ Erro ao importar medidas.";
          }
        } else {
          erro = "❌ Erro ao ler o arquivo.";
        }
      };
      reader.readAsText(file);
    }
  
    $: if ($walletAddress) listarMedidas();
  </script>
  
  <h2>👤 Registro e Medições do Usuário</h2>
  
  <form on:submit|preventDefault={registrarUsuario}>
    <h3>📋 Cadastrar Usuário</h3>
    <label for="nome">Nome</label>
    <input id="nome" type="text" placeholder="Nome" bind:value={nome} />
    
    <label for="anoNascimento">Ano Nascimento</label>
    <input id="anoNascimento" type="number" placeholder="Ano Nascimento" bind:value={anoNascimento} />
    
    <label for="altura">Altura (cm)</label>
    <input id="altura" type="number" placeholder="Altura (cm)" bind:value={altura} />
    
    <label for="sexo">Sexo</label>
    <select id="sexo" bind:value={sexo}>
      <option value="masculino">Masculino</option>
      <option value="feminino">Feminino</option>
    </select>
    
    <label for="biotipo">Biotipo</label>
    <select id="biotipo" bind:value={biotipo}>
      <option value="endomorfo">Endomorfo</option>
      <option value="mesomorfo">Mesomorfo</option>
      <option value="ectomorfo">Ectomorfo</option>
    </select>
    
    <button>Registrar Usuário</button>
  </form>
  
  <hr />
  
  <form on:submit|preventDefault={registrarMedida}>
    <h3>📏 Registrar Medidas Corporais</h3>
    <label for="peso">Peso (kg)</label>
    <input id="peso" type="number" step="0.1" placeholder="Peso (kg)" bind:value={peso} />
    
    <label for="imc">IMC</label>
    <input id="imc" type="number" step="0.1" placeholder="IMC" bind:value={imc} />
    
    <label for="gordura">Gordura (%)</label>
    <input id="gordura" type="number" step="0.1" placeholder="% Gordura" bind:value={gordura} />
    
    <label for="massaGordura">Massa de Gordura (kg)</label>
    <input id="massaGordura" type="number" step="0.1" placeholder="Massa de Gordura" bind:value={massaGordura} />
    
    <label for="caloriasBasal">Calorias Basal</label>
    <input id="caloriasBasal" type="number" step="0.1" placeholder="Calorias Basal" bind:value={caloriasBasal} />
    
    <label for="dataMedicao">Data da Medição</label>
    <input id="dataMedicao" type="datetime-local" bind:value={dataMedicao} />
    
    <button>Registrar Medida</button>
  </form>
  
  <div style="margin-top: 1rem;">
    <button on:click={apagarMedidas}>🗑️ Apagar Medidas</button>
    <button on:click={apagarUsuario}>❌ Apagar Usuário</button>
    <button on:click={exportarMedidas}>📤 Exportar Medidas</button>
    <input type="file" accept="application/json" on:change={importarMedidas} style="display:none;" id="importFile" />
    <label for="importFile" style="cursor:pointer;">📥 Importar Medidas</label>
  </div>
  
  {#if resultado}
    <p style="color: limegreen;">{resultado}</p>
  {/if}
  
  {#if erro}
    <p style="color: red;">{erro}</p>
  {/if}
  
  {#if medidas.length}
    <h3>📊 Histórico de Medidas</h3>
    <ul>
      {#each medidas as m}
        <li>
          <b>{new Date(m.data).toLocaleString()}</b><br />
          Peso: {m.peso}kg, IMC: {m.imc}, Gordura: {m.gordura}%, Massa Gordura: {m.massa_gordura}kg, Calorias Basal: {m.calorias_basal}
        </li>
      {/each}
    </ul>
  {/if}
  
  <style>
    input, select {
      display: block;
      margin: 0.5rem 0;
      padding: 0.5rem;
      width: 100%;
      background: #111;
      border: 1px solid #444;
      color: white;
      border-radius: 6px;
    }
  
    button {
      margin-top: 0.5rem;
      padding: 0.6rem 1rem;
      font-weight: bold;
      border-radius: 6px;
      border: 1px solid #555;
      background: #1a1a1a;
      color: white;
      cursor: pointer;
    }
  
    ul {
      list-style: none;
      padding-left: 0;
      margin-top: 1rem;
    }
  
    li {
      margin-bottom: 0.6rem;
      background: #1c1c1c;
      padding: 0.5rem;
      border-radius: 6px;
    }
  
    h2, h3 {
      margin-top: 1.5rem;
    }
  </style>