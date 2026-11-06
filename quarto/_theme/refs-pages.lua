-- Split the bibliography over as many slides as it needs, like beamer's
-- [allowframebreaks]: "References", "References (cont.)", ...
-- Registered at post-quarto, where Quarto has not run citeproc yet (it runs
-- after all filters). So this filter runs citeproc itself, splits #refs, and sets
-- suppress-bibliography so the later pass only re-formats the citations. A
-- References slide marked {.scrollable} is left alone (one scrolling slide).
--
-- Pagination is estimated from text length: each entry costs
-- ceil(chars / refs-chars-per-line) lines plus a gap, and a slide holds
-- refs-lines lines. Both are deck-level YAML options; the defaults fit the 22px
-- reference font on a 1280x720 slide.

local CHARS_PER_LINE = 125
local LINES_PER_SLIDE = 16.5
local ENTRY_GAP = 0.4

local function entry_lines(entry)
  local n = utf8.len(pandoc.utils.stringify(entry)) or 0
  return math.max(1, math.ceil(n / CHARS_PER_LINE)) + ENTRY_GAP
end

local function greedy(entries, budget)
  local pages, page, used = {}, {}, 0
  for _, e in ipairs(entries) do
    local cost = entry_lines(e)
    if #page > 0 and used + cost > budget then
      table.insert(pages, page)
      page, used = {}, 0
    end
    table.insert(page, e)
    used = used + cost
  end
  if #page > 0 then table.insert(pages, page) end
  return pages
end

-- Fewest slides that fit, then even them out (no lone entry on the last slide).
local function chunk(entries)
  local n = #greedy(entries, LINES_PER_SLIDE)
  local total = 0
  for _, e in ipairs(entries) do total = total + entry_lines(e) end
  local budget = total / n
  while true do
    local pages = greedy(entries, budget)
    if #pages <= n then return pages end
    budget = budget + 0.25
  end
end

function Pandoc(doc)
  local m = doc.meta
  if m["refs-chars-per-line"] then
    CHARS_PER_LINE = tonumber(pandoc.utils.stringify(m["refs-chars-per-line"]))
  end
  if m["refs-lines"] then
    LINES_PER_SLIDE = tonumber(pandoc.utils.stringify(m["refs-lines"]))
  end

  -- only act on a non-scrollable slide that holds #refs
  local wanted = false
  for i, b in ipairs(doc.blocks) do
    if b.t == "Div" and b.identifier == "refs" then
      for j = i - 1, 1, -1 do
        local h = doc.blocks[j]
        if h.t == "Header" then wanted = not h.classes:includes("scrollable"); break end
      end
    end
  end
  if not wanted or not m.bibliography then return nil end

  doc = pandoc.utils.citeproc(doc)
  doc.meta["suppress-bibliography"] = true
  -- Freeze the formatted citations (with their links) as plain spans, or the
  -- later citeproc pass re-formats them without links.
  doc = doc:walk({
    Cite = function(c)
      local keys = {}
      for _, ci in ipairs(c.citations) do table.insert(keys, ci.id) end
      return pandoc.Span(c.content,
        pandoc.Attr("", { "citation" }, { ["data-cites"] = table.concat(keys, " ") }))
    end,
  })

  local blocks = doc.blocks
  for i, b in ipairs(blocks) do
    if b.t == "Div" and b.identifier == "refs" then
      local h, hi = nil, nil
      for j = i - 1, 1, -1 do
        if blocks[j].t == "Header" then h, hi = blocks[j], j; break end
      end

      local pages = chunk(b.content)

      local out, slide_of = {}, {}
      local base = h.identifier ~= "" and h.identifier or "references"
      for k = 1, hi - 1 do table.insert(out, blocks[k]) end
      for p, entries in ipairs(pages) do
        local title = h.content:clone()
        local id = base
        if p > 1 then
          title:extend({ pandoc.Space(), pandoc.Str("(cont.)") })
          id = base .. "-" .. p
        end
        for _, e in ipairs(entries) do
          if e.identifier ~= "" then slide_of[e.identifier] = id end
        end
        table.insert(out, pandoc.Header(h.level, title, pandoc.Attr(id, h.classes, h.attributes)))
        -- keep anything between the header and the refs div on the first slide
        if p == 1 then
          for k = hi + 1, i - 1 do table.insert(out, blocks[k]) end
        end
        local attr = pandoc.Attr("refs-" .. p, b.classes, b.attributes)
        table.insert(out, pandoc.Div(entries, attr))
      end
      for k = i + 1, #blocks do table.insert(out, blocks[k]) end
      doc.blocks = out
      -- reveal.js navigates by slide id, so point each citation link at the
      -- References slide that holds its entry (Quarto turns #x into #/x).
      -- No role="doc-biblioref": Quarto would resolve those through #refs.
      return doc:walk({
        Link = function(l)
          local s = l.target:match("^#(ref%-.+)$")
          if s and slide_of[s] then
            l.target = "#" .. slide_of[s]
            return l
          end
        end,
      })
    end
  end
  return nil
end
