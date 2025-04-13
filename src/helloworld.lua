-- Define um handler que responde a mensagens com a ação "SayHello"

Handlers.add(
  "SayHello", -- Nome do handler
  Handlers.utils.hasMatchingTag("Action", "SayHello"),
  function(msg)
    print("Recebido de " .. msg.From .. ": " .. (msg.Data or ""))
    Handlers.utils.reply("Hello, " .. (msg.Data or "World") .. "!")(msg)
  end
)

Handlers.add(
  "GetPrice",
  Handlers.utils.hasMatchingTag("Action", "GetPrice"),
  function(msg)
    local price = http.get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")
    print("Recebido de " .. msg.From .. ": " .. (msg.Data or ""))
    Handlers.utils.reply("BTC price: " .. price.body)(msg)
  end
)

