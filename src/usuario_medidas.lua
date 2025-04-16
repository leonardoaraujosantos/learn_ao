local sqlite = require("lsqlite3")
local json = require("json")

-- Banco de dados em memória
local db = sqlite.open_memory()

-- Tabela de usuários
db:exec([[
CREATE TABLE IF NOT EXISTS usuarios (
  wallet TEXT PRIMARY KEY,
  nome TEXT,
  ano_nascimento INTEGER,
  altura_cm INTEGER,
  sexo TEXT,
  biotipo TEXT
);
]])

-- Tabela de medidas
db:exec([[
CREATE TABLE IF NOT EXISTS medidas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  wallet TEXT,
  peso REAL,
  imc REAL,
  gordura_corporal REAL,
  massa_gordura REAL,
  data TEXT DEFAULT CURRENT_TIMESTAMP
);
]])

-- Registrar usuário
Handlers.add("RegistrarUsuario", Handlers.utils.hasMatchingTag("Action", "RegistrarUsuario"), function(msg)
  local ok, input = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok or type(input) ~= "table" then
    msg.reply({ Data = json.encode({ erro = "❌ JSON inválido" }) }) return
  end

  local stmt = db:prepare([[
    INSERT OR REPLACE INTO usuarios (wallet, nome, ano_nascimento, altura_cm, sexo, biotipo)
    VALUES (?, ?, ?, ?, ?, ?)
  ]])
  stmt:bind(1, input.wallet)
  stmt:bind(2, input.nome)
  stmt:bind(3, tonumber(input.ano_nascimento))
  stmt:bind(4, tonumber(input.altura_cm))
  stmt:bind(5, input.sexo)
  stmt:bind(6, input.biotipo)
  stmt:step()
  stmt:finalize()

  msg.reply({ Data = json.encode({ status = "✅ Usuário registrado com sucesso" }) })
end)

-- Registrar medida corporal
Handlers.add("RegistrarMedida", Handlers.utils.hasMatchingTag("Action", "RegistrarMedida"), function(msg)
  local ok, m = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok or type(m) ~= "table" then
    msg.reply({ Data = json.encode({ erro = "❌ JSON inválido" }) }) return
  end

  if not m.wallet then
    msg.reply({ Data = json.encode({ erro = "⚠️ 'wallet' é obrigatória" }) }) return
  end

  local stmt = db:prepare([[
    INSERT INTO medidas (wallet, peso, imc, gordura_corporal, massa_gordura, data)
    VALUES (?, ?, ?, ?, ?, ?)
  ]])
  stmt:bind(1, m.wallet)
  stmt:bind(2, tonumber(m.peso))
  stmt:bind(3, tonumber(m.imc))
  stmt:bind(4, tonumber(m.gordura_corporal))
  stmt:bind(5, tonumber(m.massa_gordura))
  stmt:bind(6, m.data or os.date("!%Y-%m-%dT%H:%M:%SZ"))
  stmt:step()
  stmt:finalize()

  msg.reply({ Data = json.encode({ status = "📈 Medida registrada" }) })
end)

-- Listar medidas de um usuário
Handlers.add("ListarMedidas", Handlers.utils.hasMatchingTag("Action", "ListarMedidas"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok or not dados.wallet then
    msg.reply({ Data = json.encode({ erro = "⚠️ JSON inválido ou wallet ausente" }) }) return
  end

  local stmt = db:prepare("SELECT peso, imc, gordura_corporal, massa_gordura, data FROM medidas WHERE wallet = ? ORDER BY data DESC")
  stmt:bind(1, dados.wallet)

  local res = {}
  for row in stmt:nrows() do
    table.insert(res, row)
  end
  stmt:finalize()

  msg.reply({ Data = json.encode({ medidas = res }) })
end)

-- Buscar info do usuário
Handlers.add("InfoUsuario", Handlers.utils.hasMatchingTag("Action", "InfoUsuario"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok or not dados.wallet then
    msg.reply({ Data = json.encode({ erro = "⚠️ JSON inválido ou wallet ausente" }) }) return
  end

  local stmt = db:prepare("SELECT * FROM usuarios WHERE wallet = ?")
  stmt:bind(1, dados.wallet)
  local row = stmt:step() == sqlite.ROW and stmt:get_named_values() or nil
  stmt:finalize()

  msg.reply({ Data = json.encode({ usuario = row }) })
end)

-- Apagar medidas de um usuário
Handlers.add("ApagarMedidas", Handlers.utils.hasMatchingTag("Action", "ApagarMedidas"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok or not dados.wallet then
    msg.reply({ Data = json.encode({ erro = "⚠️ wallet ausente" }) }) return
  end

  local stmt = db:prepare("DELETE FROM medidas WHERE wallet = ?")
  stmt:bind(1, dados.wallet)
  stmt:step()
  stmt:finalize()

  msg.reply({ Data = json.encode({ status = "🗑️ Medidas apagadas" }) })
end)

-- Apagar usuário completamente
Handlers.add("ApagarUsuario", Handlers.utils.hasMatchingTag("Action", "ApagarUsuario"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)
  if not ok or not dados.wallet then
    msg.reply({ Data = json.encode({ erro = "⚠️ wallet ausente" }) }) return
  end

  -- Remove medidas
  local m = db:prepare("DELETE FROM medidas WHERE wallet = ?")
  m:bind(1, dados.wallet)
  m:step()
  m:finalize()

  -- Remove usuário
  local u = db:prepare("DELETE FROM usuarios WHERE wallet = ?")
  u:bind(1, dados.wallet)
  u:step()
  u:finalize()

  msg.reply({ Data = json.encode({ status = "❌ Usuário e medidas apagados" }) })
end)