import { writable } from "svelte/store";

export const isConnectedWallet = writable(false);
export const walletAddress = writable<string | null>(null);
