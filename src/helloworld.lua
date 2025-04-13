-- Define um handler que responde a mensagens com a ação "SayHello"

Handlers.add(
  "SayHello", -- Nome do handler
  Handlers.utils.hasMatchingTag("Action", "SayHello"),
  function(msg)
    print("Recebido de " .. msg.From .. ": " .. (msg.Data or ""))
    Handlers.utils.reply("Hello, " .. (msg.Data or "World") .. "!")(msg)
  end
)

