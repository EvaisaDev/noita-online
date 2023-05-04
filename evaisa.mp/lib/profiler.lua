local profiler = {}
profiler.__index = profiler

function profiler.new()
    local self = setmetatable({}, profiler)
    self.startTime = 0
    self.stopTime = 0
    return self
end

function profiler:start()
    self.startTime = gettimeofday()
end

function profiler:stop()
    self.stopTime = gettimeofday()
end

function profiler:time()
    return self.stopTime - self.startTime
end

return profiler