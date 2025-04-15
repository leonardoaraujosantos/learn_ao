// src/lib/uploadArweave.ts
import Arweave from 'arweave';
import { WebBundlr } from "@bundlr-network/client";

// Inicializa o Arweave
const arweave = Arweave.init({
  host: "arweave.net",
  port: 443,
  protocol: "https"
});

export async function uploadFileToArweave(file: File): Promise<string> {
  const provider = window.arweaveWallet;

  // Autenticando com ArConnect
  await provider.connect(["ACCESS_ADDRESS", "SIGN_TRANSACTION", "SIGNATURE"]);
  const address = await provider.getActiveAddress();

  // Inicializa o bundlr com ArConnect
  const bundlr = new WebBundlr("https://node1.bundlr.network", "arweave", provider, {
    providerUrl: "https://arweave.net"
  });

  await bundlr.ready();

  const reader = new FileReader();

  return new Promise((resolve, reject) => {
    reader.onload = async () => {
      const buffer = reader.result as ArrayBuffer;

      try {
        const tx = bundlr.createTransaction(buffer, {
          tags: [{ name: "Content-Type", value: file.type }]
        });

        await tx.sign();
        const response = await tx.upload();

        resolve(`https://arweave.net/${tx.id}`);
      } catch (err) {
        reject(err);
      }
    };

    reader.onerror = () => reject(reader.error);
    reader.readAsArrayBuffer(file);
  });
}