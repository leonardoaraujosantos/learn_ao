-- Utilitário para dividir strings
local function split(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
      table.insert(result, part)
    end
    return result
  end
  
  -- Função principal
  function calcularPesoPerdido(sexo, idade, peso, biotipo, caloriasGastas)
    -- Define o fator base pelo biotipo
    local fator_base
    if biotipo == "endomorfo" then
        fator_base = 8.1
    elseif biotipo == "ectomorfo" then
        fator_base = 7.3
    else -- mesomorfo ou indefinido
        fator_base = 7.7
    end

    -- Ajustes por sexo
    if sexo == "feminino" then
        fator_base = fator_base * 1.05  -- metabolismo mais conservador
    end

    -- Ajustes por idade (após 30 anos, aumenta 0.02 por década)
    if idade > 30 then
        local decadasExtra = math.floor((idade - 30) / 10)
        fator_base = fator_base + (0.02 * decadasExtra)
    end

    -- Calcula os gramas perdidos
    local gramasPerdidos = caloriasGastas / fator_base
    return gramasPerdidos
  end
  
  -- Handler para o AO
  Handlers.add("PesoPerdido", Handlers.utils.hasMatchingTag("Action", "PesoPerdido"), function(msg)
    local dados = split(msg.Data or "", "|")
  
    if #dados < 5 then
      msg.reply({ Data = "⚠️ Entrada incompleta. Use: sexo|idade|peso|biotipo|caloriasGastas" })
      return
    end
  
    local sexo = dados[1]
    local idade = tonumber(dados[2])
    local peso = tonumber(dados[3])
    local biotipo = dados[4]
    local caloriasGastas = tonumber(dados[5])
  
    if not (sexo and idade and peso and biotipo and caloriasGastas) then
      msg.reply({ Data = "⚠️ Dados inválidos." })
      return
    end
  
    local perdido = calcularPesoPerdido(sexo, idade, peso, biotipo, caloriasGastas)
    msg.reply({ Data = string.format("🏃‍♂️ Peso perdido estimado: %.2f gramas", perdido) })
  end)