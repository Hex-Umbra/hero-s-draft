-- Rouvre chaque .aseprite, decrit ses calques, puis exporte une copie aplatie en PNG.
local f = assert(io.open(app.params.manifest, "r"))
local cards = json.decode(f:read("a"))
f:close()

for _, card in ipairs(cards) do
  local spr = app.open(card.out)
  local names = {}
  for _, layer in ipairs(spr.layers) do
    names[#names + 1] = layer.name
  end
  local mode = (spr.colorMode == ColorMode.INDEXED) and "indexe" or "AUTRE"
  print(app.fs.fileName(card.out) .. " | " .. spr.width .. "x" .. spr.height .. " | " .. mode .. " | " .. table.concat(names, ", "))
  app.command.FlattenLayers{ visibleOnly = false }
  spr:saveCopyAs(card.ref:gsub("_ref%.png$", "_back.png"))
  spr:close()
end
