-- Importa módulos essenciais
local sqlite = require("lsqlite3")
local json = require("json")

-- Cria banco de dados SQLite em memória
local db = sqlite.open_memory()

-- Criação da tabela de atividades com timestamp
db:exec([[
CREATE TABLE IF NOT EXISTS atividades (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  wallet TEXT,             -- wallet enviada manualmente
  descricao TEXT,
  calorias REAL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
]])

-- Handler 1: Registrar uma nova atividade
Handlers.add("RegistrarAtividade", Handlers.utils.hasMatchingTag("Action", "RegistrarAtividade"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok or type(dados) ~= "table" then
    msg.reply({ Data = json.encode({ erro = "❌ JSON inválido" }) })
    return
  end

  local wallet = dados.wallet
  local descricao = dados.descricao
  local calorias = tonumber(dados.calorias)
  local timestamp = dados.timestamp -- opcional

  if not (wallet and descricao and calorias) then
    msg.reply({ Data = json.encode({ erro = "⚠️ Campos 'wallet', 'descricao' e 'calorias' são obrigatórios" }) })
    return
  end

  local stmt
  if timestamp then
    stmt = db:prepare("INSERT INTO atividades (wallet, descricao, calorias, timestamp) VALUES (?, ?, ?, ?)")
    stmt:bind(1, wallet)
    stmt:bind(2, descricao)
    stmt:bind(3, calorias)
    stmt:bind(4, timestamp)
  else
    stmt = db:prepare("INSERT INTO atividades (wallet, descricao, calorias) VALUES (?, ?, ?)")
    stmt:bind(1, wallet)
    stmt:bind(2, descricao)
    stmt:bind(3, calorias)
  end

  stmt:step()
  stmt:finalize()

  msg.reply({ Data = json.encode({ status = "✅ Atividade registrada com sucesso" }) })
end)

-- Handler 2: Listar atividades por wallet
Handlers.add("ListarPorUsuario", Handlers.utils.hasMatchingTag("Action", "ListarPorUsuario"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok then
    msg.reply({ Data = json.encode({ erro = "❌ JSON inválido" }) })
    return
  end

  local wallet = dados.wallet
  local limite = tonumber(dados.limite) or 5

  if not wallet then
    msg.reply({ Data = json.encode({ erro = "⚠️ Campo 'wallet' é obrigatório" }) })
    return
  end

  local stmt = db:prepare([[
    SELECT descricao, calorias, timestamp
    FROM atividades
    WHERE wallet = ?
    ORDER BY timestamp DESC
    LIMIT ?
  ]])
  stmt:bind(1, wallet)
  stmt:bind(2, limite)

  local resultado = {}
  for row in stmt:nrows() do
    table.insert(resultado, row)
  end
  stmt:finalize()

  msg.reply({
    Data = json.encode({ atividades = resultado }),
    Tags = { { name = "Content-Type", value = "application/json" } }
  })
end)

-- Handler 3: Listar todas as atividades (últimas N)
Handlers.add("ListarGeral", Handlers.utils.hasMatchingTag("Action", "ListarGeral"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok then
    msg.reply({ Data = json.encode({ erro = "❌ JSON inválido" }) })
    return
  end

  local limite = tonumber(dados.limite) or 10

  local stmt = db:prepare([[
    SELECT wallet, descricao, calorias, timestamp
    FROM atividades
    ORDER BY timestamp DESC
    LIMIT ?
  ]])
  stmt:bind(1, limite)

  local resultado = {}
  for row in stmt:nrows() do
    table.insert(resultado, row)
  end
  stmt:finalize()

  msg.reply({
    Data = json.encode({ atividades = resultado }),
    Tags = { { name = "Content-Type", value = "application/json" } }
  })
end)