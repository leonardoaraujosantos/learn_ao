function calcularCaloriasBasais(sexo, idade, peso, altura, biotipo)
    local TMB
    if sexo == "masculino" then
      TMB = (10 * peso) + (6.25 * altura) - (5 * idade) + 5
    elseif sexo == "feminino" then
      TMB = (10 * peso) + (6.25 * altura) - (5 * idade) - 161
    else
      return "⚠️ Sexo inválido. Use 'masculino' ou 'feminino'."
    end
  
    local fatorAjuste = 1.0
    if biotipo == "endomorfo" then
      fatorAjuste = 0.95
    elseif biotipo == "ectomorfo" then
      fatorAjuste = 1.05
    elseif biotipo ~= "mesomorfo" then
      fatorAjuste = 1.0
    end
  
    return TMB * fatorAjuste
  end
  
  -- Função auxiliar para dividir string por '|'
  local function split(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
      table.insert(result, part)
    end
    return result
  end
  
  Handlers.add("Calorias", Handlers.utils.hasMatchingTag("Action", "Calorias"), function(msg)
    local dados = split(msg.Data or "", "|")
  
    if #dados < 5 then
      msg.reply({ Data = "⚠️ Entrada incompleta. Use: sexo|idade|peso|altura|biotipo" })
      return
    end
  
    local sexo = dados[1]
    local idade = tonumber(dados[2])
    local peso = tonumber(dados[3])
    local altura = tonumber(dados[4])
    local biotipo = dados[5]
  
    if not (sexo and idade and peso and altura and biotipo) then
      msg.reply({ Data = "⚠️ Dados inválidos." })
      return
    end
  
    local resultado = calcularCaloriasBasais(sexo, idade, peso, altura, biotipo)
    msg.reply({ Data = "🔥 Calorias de manutenção: " .. tostring(resultado) .. " kcal" })
  end)