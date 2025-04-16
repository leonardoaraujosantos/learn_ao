import { writable } from "svelte/store";

export const isConnectedWallet = writable(false);
export const walletAddress = writable<string | null>(null);
export const userInfo = writable<{
  nome: string;
  altura_cm: number;
  sexo: string;
  biotipo: string;
  ano_nascimento: string;
} | null>(null);
