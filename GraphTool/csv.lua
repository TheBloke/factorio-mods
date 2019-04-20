--local Entity = require("__stdlib__/stdlib/entity/entity")

local Csv =
  {
    __call = function(self, ...)
      return self.new(...)
    end,
  }
setmetatable(Csv, Csv)

local Csv_meta =
  {
    __index = Csv
  }

function Csv.metatable(CSV)
  if CSV then
    setmetatable(CSV, Csv_meta)
  end
end

function Csv.new(filename, separator)
  local CSV =
    {
      separator = separator or ",",
      filename = filename
    }

  return CSV
end

function Csv:write(items)
  for item, count in pairs(items) do
    game.write_file(self.filename, item .. self.separator .. count, true)
  end
end

return Csv
