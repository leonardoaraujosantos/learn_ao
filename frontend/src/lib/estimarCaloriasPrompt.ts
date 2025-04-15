// src/lib/calorias.ts

export async function estimarCaloriasPorPrompt(prompt: string): Promise<number | null> {
    try {
      const descricaoEncoded = encodeURIComponent(prompt);
      // Funcao Edge no Supabase
      const url = `https://ofjtwzqbzzbxyylvecst.supabase.co/functions/v1/calorias_prompt?prompt=${descricaoEncoded}`;
  
      const res = await fetch(url);
      const data = await res.json();
  
      if (data?.calorias != null) {
        return data.calorias;
      } else {
        console.error("Resposta inesperada:", data);
        return null;
      }
    } catch (e) {
      console.error("Erro ao estimar calorias:", e);
      return null;
    }
  }