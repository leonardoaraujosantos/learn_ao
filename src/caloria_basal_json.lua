-- Requer o módulo JSON
local json = require("json")

-- Função principal de cálculo
function calcularCaloriasBasais(sexo, idade, peso, altura, biotipo)
  local TMB
  if sexo == "masculino" then
    TMB = (10 * peso) + (6.25 * altura) - (5 * idade) + 5
  elseif sexo == "feminino" then
    TMB = (10 * peso) + (6.25 * altura) - (5 * idade) - 161
  else
    return nil, "⚠️ Sexo inválido. Use 'masculino' ou 'feminino'."
  end

  local fatorAjuste = 1.0
  if biotipo == "endomorfo" then
    fatorAjuste = 0.95
  elseif biotipo == "ectomorfo" then
    fatorAjuste = 1.05
  end

  return TMB * fatorAjuste
end

-- Handler principal do processo
Handlers.add("Calorias", Handlers.utils.hasMatchingTag("Action", "Calorias"), function(msg)
  local ok, input = pcall(function()
    return json.decode(msg.Data or "{}")
  end)

  if not ok or type(input) ~= "table" then
    msg.reply({
      Data = json.encode({ erro = "❌ Dados JSON inválidos" }),
      Tags = { { name = "Content-Type", value = "application/json" } }
    })
    return
  end

  local sexo = input.sexo
  local idade = tonumber(input.idade)
  local peso = tonumber(input.peso)
  local altura = tonumber(input.altura)
  local biotipo = input.biotipo

  if not (sexo and idade and peso and altura and biotipo) then
    msg.reply({
      Data = json.encode({ erro = "⚠️ Campos obrigatórios ausentes!" }),
      Tags = { { name = "Content-Type", value = "application/json" } }
    })
    return
  end

  local resultado, erro = calcularCaloriasBasais(sexo, idade, peso, altura, biotipo)

  if not resultado then
    msg.reply({
      Data = json.encode({ erro = erro }),
      Tags = { { name = "Content-Type", value = "application/json" } }
    })
    return
  end

  msg.reply({
    Data = json.encode({
      calorias = resultado,
      unidade = "kcal"
    }),
    Tags = { { name = "Content-Type", value = "application/json" } }
  })
end)