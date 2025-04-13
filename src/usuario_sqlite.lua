-- Módulos necessários
local json = require("json")
local sqlite = require("lsqlite3")

-- Conecta ao banco local
local db = sqlite.open_memory()

-- Cria a tabela com remetente
db:exec([[
  CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT,
    sexo TEXT,
    email TEXT,
    biotipo TEXT,
    nascimento INTEGER,
    remetente TEXT
  );
]])

-- Handler: Cadastrar usuário
Handlers.add("Cadastrar", Handlers.utils.hasMatchingTag("Action", "Cadastrar"), function(msg)
  local ok, dados = pcall(function() return json.decode(msg.Data or "{}") end)

  if not ok or type(dados) ~= "table" then
    msg.reply({ Data = json.encode({ erro = "❌ JSON inválido" }) })
    return
  end

  local nome = dados.nome
  local sexo = dados.sexo
  local email = dados.email
  local biotipo = dados.biotipo
  local nascimento = tonumber(dados.nascimento)
  local remetente = msg.From or "desconhecido"

  if not (nome and sexo and email and biotipo and nascimento) then
    msg.reply({ Data = json.encode({ erro = "⚠️ Campos obrigatórios ausentes" }) })
    return
  end

  local stmt = db:prepare("INSERT INTO usuarios (nome, sexo, email, biotipo, nascimento, remetente) VALUES (?, ?, ?, ?, ?, ?)")
  stmt:bind(1, nome)
  stmt:bind(2, sexo)
  stmt:bind(3, email)
  stmt:bind(4, biotipo)
  stmt:bind(5, nascimento)
  stmt:bind(6, remetente)
  stmt:step()
  stmt:finalize()

  msg.reply({ Data = json.encode({ status = "✅ Usuário cadastrado com sucesso", de = remetente }) })
end)

-- Handler: Listar usuários
Handlers.add("Listar", Handlers.utils.hasMatchingTag("Action", "Listar"), function(msg)
  local stmt = db:prepare("SELECT id, nome, sexo, email, biotipo, nascimento, remetente FROM usuarios")
  local resultado = {}

  for row in stmt:nrows() do
    table.insert(resultado, row)
  end

  stmt:finalize()

  msg.reply({
    Data = json.encode({ usuarios = resultado }),
    Tags = { { name = "Content-Type", value = "application/json" } }
  })
end)