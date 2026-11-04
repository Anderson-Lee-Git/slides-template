-- Beamer-theme behaviour that Markdown alone does not give:
--   * `# Section` -> an "Outline" slide listing every section, current one
--     highlighted (beamerthemeprinceton's \AtBeginSection). `outline: false` in a
--     deck's YAML keeps Quarto's plain section slide instead.
--   * Divs for the theme's three boxes, as in latex/beamerthemeprinceton.sty:
--     ::: block (exampleblock looks the same), ::: alertblock (::: mainblock is
--     the same box, like \mainblock{T}{body}) and ::: boxedblock. Each takes an
--     optional title="..." attribute.
--   * Videos: ![](media/x.mp4){.autoplay .loop .muted} -> <video> with exactly
--     those flags (pandoc's default adds controls and has no autoplay).
--   * _theme/macros.tex is handed to MathJax before it typesets.

local here = pandoc.path.directory(PANDOC_SCRIPT_FILE)

local BLOCKS = { block = 'pblock', exampleblock = 'pblock',
                 alertblock = 'tcbox', mainblock = 'tcbox', boxedblock = 'tcbox' }

function Div(div)
  for cls, kind in pairs(BLOCKS) do
    if div.classes:includes(cls) then
      local title = div.attributes.title
      div.attributes.title = nil
      local content = { pandoc.Div(div.content, { class = kind .. '-body' }) }
      if title and title ~= '' then
        local inlines = pandoc.utils.blocks_to_inlines(pandoc.read(title, 'markdown').blocks)
        table.insert(content, 1, pandoc.Div(pandoc.Plain(inlines), { class = kind .. '-title' }))
      end
      div.content = content
      div.classes:insert(kind)
      return div
    end
  end
end

local VIDEO_FLAGS = { 'autoplay', 'loop', 'muted', 'controls', 'playsinline' }

function Image(img)
  if not img.src:lower():match('%.mp4$') and not img.src:lower():match('%.webm$')
     and not img.src:lower():match('%.mov$') then return nil end
  local attrs, classes = { 'src="' .. img.src .. '"' }, {}
  for _, c in ipairs(img.classes) do
    if c == 'autoplay' then
      table.insert(attrs, 'data-autoplay')      -- reveal.js restarts it on slide entry
    elseif pandoc.List(VIDEO_FLAGS):includes(c) then
      table.insert(attrs, c)
    else
      table.insert(classes, c)
    end
  end
  if img.classes:includes('autoplay') then table.insert(attrs, 'playsinline') end
  if #classes > 0 then table.insert(attrs, 'class="' .. table.concat(classes, ' ') .. '"') end
  local style = {}
  if img.attributes.width then table.insert(style, 'width:' .. img.attributes.width) end
  if img.attributes.height then table.insert(style, 'height:' .. img.attributes.height) end
  if #style > 0 then table.insert(attrs, 'style="' .. table.concat(style, ';') .. '"') end
  return pandoc.RawInline('html', '<video ' .. table.concat(attrs, ' ') .. '></video>')
end

local function outline_slides(blocks)
  local sections = {}
  for _, b in ipairs(blocks) do
    if b.t == 'Header' and b.level == 1 then table.insert(sections, b) end
  end
  local out, n = {}, 0
  for _, b in ipairs(blocks) do
    if b.t == 'Header' and b.level == 1 then
      n = n + 1
      -- RawBlock list so each <li> can carry the current/shaded class.
      local html = { '<div class="outline"><ol>' }
      for i, s in ipairs(sections) do
        local cls = (i == n) and 'current' or 'shaded'
        table.insert(html, '<li class="' .. cls .. '">' ..
          pandoc.write(pandoc.Pandoc({ pandoc.Plain(s.content) }), 'html'):gsub('\n$', '') .. '</li>')
      end
      table.insert(html, '</ol></div>')
      local h = pandoc.Header(2, 'Outline', b.attr)
      h.classes:insert('outline-slide')
      table.insert(out, h)
      table.insert(out, pandoc.RawBlock('html', table.concat(html)))
    else
      table.insert(out, b)
    end
  end
  return out
end

function Pandoc(doc)
  if not FORMAT:match('revealjs') then return nil end
  local meta = doc.meta

  if meta.outline ~= false then doc.blocks = outline_slides(doc.blocks) end

  local f = io.open(pandoc.path.join({ here, 'macros.tex' }))
  if f then
    local tex = f:read('a'):gsub('%%[^\n]*', '')   -- drop LaTeX comments
    f:close()
    local script = '<script>window.PRINCETON_TEX_MACROS = ' .. pandoc.json.encode(tex) .. ';</script>'
    local hi = meta['header-includes'] or pandoc.MetaList({})
    if hi.t ~= 'MetaList' and type(hi) ~= 'table' then hi = pandoc.MetaList({ hi }) end
    table.insert(hi, pandoc.MetaBlocks({ pandoc.RawBlock('html', script) }))
    meta['header-includes'] = hi
  end
  return doc
end
