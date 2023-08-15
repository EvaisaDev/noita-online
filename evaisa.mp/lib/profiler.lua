local ffi = require('ffi')

ffi.cdef[[
typedef unsigned long DWORD;
typedef unsigned long long ULONGLONG;

typedef struct _FILETIME {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
} FILETIME;

void GetSystemTimeAsFileTime(FILETIME* lFileTime);

typedef struct _ULARGE_INTEGER {
    union {
        struct {
            DWORD LowPart;
            DWORD HighPart;
        };
        ULONGLONG QuadPart;
    };
} ULARGE_INTEGER;
]]

function gettimeofday()
    local ft = ffi.new("FILETIME")
    ffi.C.GetSystemTimeAsFileTime(ft)

    local ull = ffi.new("ULARGE_INTEGER")
    ull.LowPart = ft.dwLowDateTime
    ull.HighPart = ft.dwHighDateTime

    return tonumber(ull.QuadPart / 10000ULL - 11644473600000ULL)
end

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