-- contador persistente no estado do processo
count = count or 0

-- Handler que será chamado periodicamente pelo CRON
Handlers.add("Cron", Handlers.utils.hasMatchingTag("Action", "Cron"), function(msg)
  count = count + 1
  print("⏱️ Tick recebido. Novo valor:", count)
end)

-- Handler manual para consultar o valor atual
Handlers.add("Valor", Handlers.utils.hasMatchingTag("Action", "Valor"), function(msg)
  msg.reply({ Data = "🔢 Valor atual do contador: " .. tostring(count) })
end)