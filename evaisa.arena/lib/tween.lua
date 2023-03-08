local Tween = {}

function Tween.basic(start_value, end_value, num_frames, callback)
    local self = {
        update = function(self)
            self.frame = self.frame + 1
            if self.frame > self.num_frames then
                self.callback(self.end_value)
                return true
            end
            local value = self.start_value + (self.end_value - self.start_value) * (self.frame / self.num_frames)
            self.callback(value)
            return false
        end
    }
    setmetatable(self, Tween)
    self.start_value = start_value
    self.end_value = end_value
    self.num_frames = num_frames
    self.callback = callback
    self.frame = 0

    return self
end

function Tween.vector(start_value, end_value, num_frames, callback)
    local self = {
        update = function(self)
            self.frame = self.frame + 1
            if self.frame > self.num_frames then
                self.callback(self.end_value)
                return true
            end
            local value = self.start_value:lerp(self.end_value, self.frame / self.num_frames)
            self.callback(value)
            return false
        end
    }
    setmetatable(self, Tween)
    self.start_value = start_value
    self.end_value = end_value
    self.num_frames = num_frames
    self.callback = callback
    self.frame = 0

    return self
end

return Tween