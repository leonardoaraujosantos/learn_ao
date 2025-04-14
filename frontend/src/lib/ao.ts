/* 
Referencias:
* https://github.com/rootMUD/ao-counter
*/
import { createDataItemSigner, message, result, dryrun } from "@permaweb/aoconnect";
type DryRunOptions = {
    processId: string
    action: string
    data?: object | string
    tags?: { name: string; value: string }[]
}

// Envia uma Mensagem
export async function sendMessageToProcess(data: any, action: string, processId:string) {
    // Peca para assinar pela carteira
    const signer = createDataItemSigner(window.arweaveWallet);
  
    const response = await message({
      process: processId,
      signer,
      tags: [{ name: "Action", value: action }],
      data: JSON.stringify(data)
    });
  
    return response;
  }

  // Le uma Mensagem dado um processId/messageId
  export async function lerResultadoDaMensagem(processId: string, messageId: string) {
    const resposta = await result({ process: processId, message: messageId });
    return resposta.Messages;
  }


  // DryRun manda uma mensagem e espera uma resposta (Nao precisa conectar)
  export async function dryrunMessage({ processId, action, data, tags = [] }: DryRunOptions) {
    const payload = typeof data === "string" ? data : JSON.stringify(data || {})
  
    const result = await dryrun({
      process: processId,
      tags: [{ name: "Action", value: action }, ...tags],
      data: payload
    })
  
    // Retorna a mensagem de resposta (se houver)
    return result.Messages?.[0]?.Data || null
  }