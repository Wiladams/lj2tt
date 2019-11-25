local names = require("namelist")

local function genTable()
    for i, name in ipairs(names) do 
        print(string.format("[%d] = '%s';", i-1, name))
    end
end

genTable()
