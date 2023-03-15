function split_string(inputstr, sep)
    sep = sep or "%s"
    local t= {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
end
  
local genomes = {
    content = nil,
    start = function(self)
        self.content = ModTextFileGetContent("data/genome_relations.csv")
    end,
    add = function(self, genome_name, default_relation_ab, default_relation_ba, self_relation, relations)
        local lines = split_string(self.content, "\r\n")
        local output = ""
        local genome_order = {}
        for i, line in ipairs(lines) do
          if i == 1 then
            output = output .. line .. "," .. genome_name .. "\r\n"
          else
            local herd = line:match("([%w_-]+),")
            output = output .. line .. ","..(relations[herd] or default_relation_ba).."\r\n"
            table.insert(genome_order, herd)
          end
        end
        
        local line = genome_name
        for i, v in ipairs(genome_order) do
          line = line .. "," .. (relations[v] or default_relation_ab)
        end
        output = output .. line .. "," .. self_relation
      
        self.content = output
    end,
    finish = function(self)
        ModTextFileSetContent("data/genome_relations.csv", self.content)
    end
}

return genomes