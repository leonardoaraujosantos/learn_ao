Handlers.add("CheckOS", { Action = "CheckOS" }, function(msg)
    local success, result = pcall(function()
      return os.time()  -- ou os.date()
    end)
  
    local reply = success and ("✅ os.time() = " .. tostring(result)) or "❌ os.time() não está disponível."
    msg.reply({ Data = reply })
  end)