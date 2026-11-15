-- Exporte chaque calque d'un .aseprite en PNG RGBA pleine taille, du bas vers le haut (00.png,
-- 01.png...), avec la liste de leurs noms dans calques.json. C'est ce qu'il faut pour reprendre un
-- fichier deja fait, retouches a la main comprises, sans repartir de ses sources.
local spr = app.open(app.params.file)
app.command.ChangePixelFormat{ format = "rgb" }
local names = {}
for i, layer in ipairs(spr.layers) do
  local img = Image(spr.width, spr.height, ColorMode.RGB)
  local cel = layer:cel(1)
  if cel then
    img:drawImage(cel.image, cel.position)
  end
  img:saveAs(app.params.out .. "/" .. string.format("%02d", i - 1) .. ".png")
  names[#names + 1] = layer.name
end
local f = assert(io.open(app.params.out .. "/calques.json", "w"))
f:write(json.encode(names))
f:close()
spr:close()
