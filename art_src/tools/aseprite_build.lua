-- Assemble les fichiers .aseprite decrits par le manifeste : un calque par PNG,
-- puis passage en mode indexe sur la palette exacte de l'image. Un fichier marque « rgb » reste
-- en couleurs libres : sa palette n'est alors qu'un nuancier pour la retouche.
local f = assert(io.open(app.params.manifest, "r"))
local cards = json.decode(f:read("a"))
f:close()

for _, card in ipairs(cards) do
  local spr = Sprite(card.w, card.h, ColorMode.RGB)
  local pal = Palette(#card.palette + 1)
  pal:setColor(0, Color{ r = 0, g = 0, b = 0, a = 0 })
  for i, c in ipairs(card.palette) do
    pal:setColor(i, Color{ r = c[1], g = c[2], b = c[3], a = 255 })
  end
  spr:setPalette(pal)
  for i, L in ipairs(card.layers) do
    local layer = (i == 1) and spr.layers[1] or spr:newLayer()
    layer.name = L.name
    spr:newCel(layer, 1, Image{ fromFile = L.png }, Point(0, 0))
  end
  if not card.rgb then
    app.command.ChangePixelFormat{ format = "indexed", dithering = "none" }
  end
  spr:saveAs(card.out)
  print(card.out .. "  " .. #spr.layers .. " calques, " .. #spr.palettes[1] .. " couleurs")
  spr:close()
end
