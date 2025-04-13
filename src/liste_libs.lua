Handlers.add(
  "ListGlobals",
  Handlers.utils.hasMatchingTag("Action", "ListGlobals"),
  function(msg)
    local output = {}

    for k, _ in pairs(_G) do
      table.insert(output, k)
    end

    -- Concatena os nomes em uma string, separados por vírgula
    local lista = table.concat(output, ", ")

    msg.reply({ Data = "🌍 Variáveis globais disponíveis:\n" .. lista })
  end
)