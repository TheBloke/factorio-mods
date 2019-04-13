--local Entity = require("__stdlib__/stdlib/entity/entity")

local Csv =
  {
    _csvs = {},
    __call = function(self, ...)
      return self.get(...)
    end,
    __index = Csv
  }
setmetatable(Csv, Csv)

function Csv.get(...)
  local filename = ...
  return Csv._csvs[filename] or Csv.new(...)
end

function Csv.new(filename)
  Csv._csvs[filename] = nil
  local CsvFile =
    {
      filename = filename
    }

  function CsvFile.log(item, count)
    game.write_file(CsvFile.filename, item .. "," .. count, true)
  end

  Csv._csvs[filename] = CsvFile
  return CsvFile
end

return Csv

--[[
function Csv.init(entity, state)
  state.filename = ""
  Entity.set_data(entity, state)
end
]]
