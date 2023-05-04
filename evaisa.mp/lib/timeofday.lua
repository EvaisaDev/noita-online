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