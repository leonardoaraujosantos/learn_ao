Handlers.add(
  "RollDice",
  Handlers.utils.hasMatchingTag("Action", "RollDice"),
  function(msg)
    -- Usa o ID da mensagem como semente pseudoaleatória (como string → número)
    local id = msg.Id or "default"
    local seed = 0
    for i = 1, #id do
      seed = seed + string.byte(id, i)
    end

    math.randomseed(seed)

    -- Gera número de 1 a 6 (como um dado)
    local result = math.random(1, 6)

    msg.reply({ Data = "🎲 Você rolou: " .. result })
  end
)