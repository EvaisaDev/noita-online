-----------------------------------------------------------
--  FFI
-----------------------------------------------------------
local ffi = require 'ffi'

ffi.cdef [[
  typedef void* CURL;
  typedef int   CODE;

  int  curl_version ();
  void curl_free    (void* p);

  CURL curl_easy_init      ();
  CURL curl_easy_duphandle (CURL handle);
  void curl_easy_cleanup   (CURL handle);
  void curl_easy_reset     (CURL handle);

  CODE curl_easy_perform (CURL handle);
  CODE curl_easy_setopt  (CURL handle, int option, ...);
  CODE curl_easy_getinfo (CURL handle, int info, ...);

  char* curl_easy_escape   (CURL handle, char* url, int length);
  char* curl_easy_unescape (CURL handle, char* url, int length,
                            int* outlength);

  CODE curl_easy_recv (CURL handle, void* buffer,
                       size_t length, size_t* n);
  CODE curl_easy_send (CURL handle, const void* buffer,
                       size_t length, size_t* n);

  const char* curl_easy_strerror (CODE errcode);
]]

local lib = ffi.load 'libcurl.dll'


-----------------------------------------------------------
--  CURL Option Data
-----------------------------------------------------------
local co_long          = { 00000 }
local co_objectpoint   = { 10000 }
local co_functionpoint = { 20000 }
local co_off_t         = { 30000 }

local curl_opt = {
  file                       = { 001, co_objectpoint   },
  url                        = { 002, co_objectpoint   },
  port                       = { 003, co_long          },
  proxy                      = { 004, co_objectpoint   },
  userpwd                    = { 005, co_objectpoint   },
  proxyuserpwd               = { 006, co_objectpoint   },
  range                      = { 007, co_objectpoint   },
  infile                     = { 009, co_objectpoint   },
  errorbuffer                = { 010, co_objectpoint   },
  writefunction              = { 011, co_functionpoint },
  readfunction               = { 012, co_functionpoint },
  timeout                    = { 013, co_long          },
  infilesize                 = { 014, co_long          },
  postfields                 = { 015, co_objectpoint   },
  referer                    = { 016, co_objectpoint   },
  ftpport                    = { 017, co_objectpoint   },
  useragent                  = { 018, co_objectpoint   },
  low_speed_limit            = { 019, co_long          },
  low_speed_time             = { 020, co_long          },
  resume_from                = { 021, co_long          },
  cookie                     = { 022, co_objectpoint   },
  httpheader                 = { 023, co_objectpoint   },
  httppost                   = { 024, co_objectpoint   },
  sslcert                    = { 025, co_objectpoint   },
  keypasswd                  = { 026, co_objectpoint   },
  crlf                       = { 027, co_long          },
  quote                      = { 028, co_objectpoint   },
  writeheader                = { 029, co_objectpoint   },
  cookiefile                 = { 031, co_objectpoint   },
  sslversion                 = { 032, co_long          },
  timecondition              = { 033, co_long          },
  timevalue                  = { 034, co_long          },
  customrequest              = { 036, co_objectpoint   },
  stderr                     = { 037, co_objectpoint   },
  postquote                  = { 039, co_objectpoint   },
  writeinfo                  = { 040, co_objectpoint   },
  verbose                    = { 041, co_long          },
  header                     = { 042, co_long          },
  noprogress                 = { 043, co_long          },
  nobody                     = { 044, co_long          },
  failonerror                = { 045, co_long          },
  upload                     = { 046, co_long          },
  post                       = { 047, co_long          },
  dirlistonly                = { 048, co_long          },
  append                     = { 050, co_long          },
  netrc                      = { 051, co_long          },
  followlocation             = { 052, co_long          },
  transfertext               = { 053, co_long          },
  put                        = { 054, co_long          },
  progressfunction           = { 056, co_functionpoint },
  progressdata               = { 057, co_objectpoint   },
  autoreferer                = { 058, co_long          },
  proxyport                  = { 059, co_long          },
  postfieldsize              = { 060, co_long          },
  httpproxytunnel            = { 061, co_long          },
  interface                  = { 062, co_objectpoint   },
  krblevel                   = { 063, co_objectpoint   },
  ssl_verifypeer             = { 064, co_long          },
  cainfo                     = { 065, co_objectpoint   },
  maxredirs                  = { 068, co_long          },
  filetime                   = { 069, co_long          },
  telnetoptions              = { 070, co_objectpoint   },
  maxconnects                = { 071, co_long          },
  closepolicy                = { 072, co_long          },
  fresh_connect              = { 074, co_long          },
  forbid_reuse               = { 075, co_long          },
  random_file                = { 076, co_objectpoint   },
  egdsocket                  = { 077, co_objectpoint   },
  connecttimeout             = { 078, co_long          },
  headerfunction             = { 079, co_functionpoint },
  httpget                    = { 080, co_long          },
  ssl_verifyhost             = { 081, co_long          },
  cookiejar                  = { 082, co_objectpoint   },
  ssl_cipher_list            = { 083, co_objectpoint   },
  http_version               = { 084, co_long          },
  ftp_use_epsv               = { 085, co_long          },
  sslcerttype                = { 086, co_objectpoint   },
  sslkey                     = { 087, co_objectpoint   },
  sslkeytype                 = { 088, co_objectpoint   },
  sslengine                  = { 089, co_objectpoint   },
  sslengine_default          = { 090, co_long          },
  dns_use_global_cache       = { 091, co_long          },
  dns_cache_timeout          = { 092, co_long          },
  prequote                   = { 093, co_objectpoint   },
  debugfunction              = { 094, co_functionpoint },
  debugdata                  = { 095, co_objectpoint   },
  cookiesession              = { 096, co_long          },
  capath                     = { 097, co_objectpoint   },
  buffersize                 = { 098, co_long          },
  nosignal                   = { 099, co_long          },
  share                      = { 100, co_objectpoint   },
  proxytype                  = { 101, co_long          },
  accept_encoding            = { 102, co_objectpoint   },
  private                    = { 103, co_objectpoint   },
  http200aliases             = { 104, co_objectpoint   },
  unrestricted_auth          = { 105, co_long          },
  ftp_use_eprt               = { 106, co_long          },
  httpauth                   = { 107, co_long          },
  ssl_ctx_function           = { 108, co_functionpoint },
  ssl_ctx_data               = { 109, co_objectpoint   },
  ftp_create_missing_dirs    = { 110, co_long          },
  proxyauth                  = { 111, co_long          },
  ftp_response_timeout       = { 112, co_long          },
  ipresolve                  = { 113, co_long          },
  maxfilesize                = { 114, co_long          },
  infilesize_large           = { 115, co_off_t         },
  resume_from_large          = { 116, co_off_t         },
  maxfilesize_large          = { 117, co_off_t         },
  netrc_file                 = { 118, co_objectpoint   },
  use_ssl                    = { 119, co_long          },
  postfieldsize_large        = { 120, co_off_t         },
  tcp_nodelay                = { 121, co_long          },
  ftpsslauth                 = { 129, co_long          },
  ioctlfunction              = { 130, co_functionpoint },
  ioctldata                  = { 131, co_objectpoint   },
  ftp_account                = { 134, co_objectpoint   },
  cookielist                 = { 135, co_objectpoint   },
  ignore_content_length      = { 136, co_long          },
  ftp_skip_pasv_ip           = { 137, co_long          },
  ftp_filemethod             = { 138, co_long          },
  localport                  = { 139, co_long          },
  localportrange             = { 140, co_long          },
  connect_only               = { 141, co_long          },
  conv_from_network_function = { 142, co_functionpoint },
  conv_to_network_function   = { 143, co_functionpoint },
  conv_from_utf8_function    = { 144, co_functionpoint },
  max_send_speed_large       = { 145, co_off_t         },
  max_recv_speed_large       = { 146, co_off_t         },
  ftp_alternative_to_user    = { 147, co_objectpoint   },
  sockoptfunction            = { 148, co_functionpoint },
  sockoptdata                = { 149, co_objectpoint   },
  ssl_sessionid_cache        = { 150, co_long          },
  ssh_auth_types             = { 151, co_long          },
  ssh_public_keyfile         = { 152, co_objectpoint   },
  ssh_private_keyfile        = { 153, co_objectpoint   },
  ftp_ssl_ccc                = { 154, co_long          },
  timeout_ms                 = { 155, co_long          },
  connecttimeout_ms          = { 156, co_long          },
  http_transfer_decoding     = { 157, co_long          },
  http_content_decoding      = { 158, co_long          },
  new_file_perms             = { 159, co_long          },
  new_directory_perms        = { 160, co_long          },
  postredir                  = { 161, co_long          },
  ssh_host_public_key_md5    = { 162, co_objectpoint   },
  opensocketfunction         = { 163, co_functionpoint },
  opensocketdata             = { 164, co_objectpoint   },
  copypostfields             = { 165, co_objectpoint   },
  proxy_transfer_mode        = { 166, co_long          },
  seekfunction               = { 167, co_functionpoint },
  seekdata                   = { 168, co_objectpoint   },
  crlfile                    = { 169, co_objectpoint   },
  issuercert                 = { 170, co_objectpoint   },
  address_scope              = { 171, co_long          },
  certinfo                   = { 172, co_long          },
  username                   = { 173, co_objectpoint   },
  password                   = { 174, co_objectpoint   },
  proxyusername              = { 175, co_objectpoint   },
  proxypassword              = { 176, co_objectpoint   },
  noproxy                    = { 177, co_objectpoint   },
  tftp_blksize               = { 178, co_long          },
  socks5_gssapi_service      = { 179, co_objectpoint   },
  socks5_gssapi_nec          = { 180, co_long          },
  protocols                  = { 181, co_long          },
  redir_protocols            = { 182, co_long          },
  ssh_knownhosts             = { 183, co_objectpoint   },
  ssh_keyfunction            = { 184, co_functionpoint },
  ssh_keydata                = { 185, co_objectpoint   },
  mail_from                  = { 186, co_objectpoint   },
  mail_rcpt                  = { 187, co_objectpoint   },
  ftp_use_pret               = { 188, co_long          },
  rtsp_request               = { 189, co_long          },
  rtsp_session_id            = { 190, co_objectpoint   },
  rtsp_stream_uri            = { 191, co_objectpoint   },
  rtsp_transport             = { 192, co_objectpoint   },
  rtsp_client_cseq           = { 193, co_long          },
  rtsp_server_cseq           = { 194, co_long          },
  interleavedata             = { 195, co_objectpoint   },
  interleavefunction         = { 196, co_functionpoint },
  wildcardmatch              = { 197, co_long          },
  chunk_bgn_function         = { 198, co_functionpoint },
  chunk_end_function         = { 199, co_functionpoint },
  fnmatch_function           = { 200, co_functionpoint },
  chunk_data                 = { 201, co_objectpoint   },
  fnmatch_data               = { 202, co_objectpoint   },
  resolve                    = { 203, co_objectpoint   },
  tlsauth_username           = { 204, co_objectpoint   },
  tlsauth_password           = { 205, co_objectpoint   },
  tlsauth_type               = { 206, co_objectpoint   },
  transfer_encoding          = { 207, co_long          },
  closesocketfunction        = { 208, co_functionpoint },
  closesocketdata            = { 209, co_objectpoint   },
  gssapi_delegation          = { 210, co_long          },
  dns_servers                = { 211, co_objectpoint   },
  accepttimeout_ms           = { 212, co_long          },
  tcp_keepalive              = { 213, co_long          },
  tcp_keepidle               = { 214, co_long          },
  tcp_keepintvl              = { 215, co_long          },
  ssl_options                = { 216, co_long          },
  mail_auth                  = { 217, co_objectpoint   },
  sasl_ir                    = { 218, co_long          },
  xferinfofunction           = { 219, co_functionpoint },
  xoauth2_bearer             = { 220, co_objectpoint   },
  dns_interface              = { 221, co_objectpoint   },
  dns_local_ip4              = { 222, co_objectpoint   },
  dns_local_ip6              = { 223, co_objectpoint   },
  login_options              = { 224, co_objectpoint   },
  ssl_enable_npn             = { 225, co_long          },
  ssl_enable_alpn            = { 226, co_long          },
  expect_100_timeout_ms      = { 227, co_long          }
}

--  Aliases
curl_opt.xferinfodata            = curl_opt.progressdata
curl_opt.server_response_timeout = curl_opt.ftp_response_timeout
curl_opt.writedata               = curl_opt.file
curl_opt.readdata                = curl_opt.infile
curl_opt.headerdata              = curl_opt.writeheader
curl_opt.rtspheader              = curl_opt.httpheader


-----------------------------------------------------------
--  CURL Info Data
-----------------------------------------------------------
local ci_string = { 0x100000, 'char* [1]', ffi.string }
local ci_long   = { 0x200000, 'long  [1]', tonumber   }
local ci_double = { 0x300000, 'double[1]', tonumber   }
local ci_slist  = { 0x400000, 'slist [1]', tostring   }

local curl_info = {
  effective_url           = { 01, ci_string },
  response_code           = { 02, ci_long   },
  total_time              = { 03, ci_double },
  namelookup_time         = { 04, ci_double },
  connect_time            = { 05, ci_double },
  pretransfer_time        = { 06, ci_double },
  size_upload             = { 07, ci_double },
  size_download           = { 08, ci_double },
  speed_download          = { 09, ci_double },
  speed_upload            = { 10, ci_double },
  header_size             = { 11, ci_long   },
  request_size            = { 12, ci_long   },
  ssl_verifyresult        = { 13, ci_long   },
  filetime                = { 14, ci_long   },
  content_length_download = { 15, ci_double },
  content_length_upload   = { 16, ci_double },
  starttransfer_time      = { 17, ci_double },
  content_type            = { 18, ci_string },
  redirect_time           = { 19, ci_double },
  redirect_count          = { 20, ci_long   },
  private                 = { 21, ci_string },
  http_connectcode        = { 22, ci_long   },
  httpauth_avail          = { 23, ci_long   },
  proxyauth_avail         = { 24, ci_long   },
  os_errno                = { 25, ci_long   },
  num_connects            = { 26, ci_long   },
  ssl_engines             = { 27, ci_slist  },
  cookielist              = { 28, ci_slist  },
  lastsocket              = { 29, ci_long   },
  ftp_entry_path          = { 30, ci_string },
  redirect_url            = { 31, ci_string },
  primary_ip              = { 32, ci_string },
  appconnect_time         = { 33, ci_double },
  certinfo                = { 34, ci_slist  },
  condition_unmet         = { 35, ci_long   },
  rtsp_session_id         = { 36, ci_string },
  rtsp_client_cseq        = { 37, ci_long   },
  rtsp_server_cseq        = { 38, ci_long   },
  rtsp_cseq_recv          = { 39, ci_long   },
  primary_port            = { 40, ci_long   },
  local_ip                = { 41, ci_string },
  local_port              = { 42, ci_long   },
  tls_session             = { 43, ci_slist  }
}


-----------------------------------------------------------
--  Function Wrapping
-----------------------------------------------------------
local opt_utils = {}

local function version()
  return lib.curl_version()
end

local function easy_init()
  local handle = lib.curl_easy_init()
  if handle ~=nil then
    ffi.gc(handle, lib.curl_easy_cleanup)
    return handle
  end
  return false
end

local function easy_duphandle(handle)
  local duplicate = lib.curl_easy_duphandle(handle)
  if handle ~=nil then
    ffi.gc(handle, lib.curl_easy_cleanup)
    return handle
  end
  return false
end

local function easy_reset(handle)
  lib.curl_easy_reset(handle)
end

local function easy_perform(handle)
  return lib.curl_easy_perform(handle);
end

local function easy_setopt(handle, key, val)
  local data = curl_opt[key]
  if data then
    local opt_code = data[2][1] + data[1]
    local opt_util = opt_utils[key]

    if opt_util then
      val = opt_util(handle, val)
    end

    return lib.curl_easy_setopt(handle, opt_code, val)
  end
end

local function easy_getinfo(handle, key)
  local data = curl_info[key]
  if data then
    local info_code = data[2][1] + data[1]
    local info_type = data[2][2]
    local cast_func = data[2][3]

    local result = ffi.new(info_type)
    lib.curl_easy_getinfo(handle, info_code, result)
    if result[0] ~= nil then
      return cast_func(result[0])
    end
  end
end

local function easy_escape(handle, url)
  local i_cstr = ffi.new('char[?]', #url, url)
  local o_cstr = lib.curl_easy_escape(handle, i_cstr, #url)

  local str = ffi.string(o_cstr)
  lib.curl_free(o_cstr)
  return str
end

local function easy_unescape(handle, url)
  local out_n  = ffi.new('int[1]') -- int*
  local i_cstr = ffi.new('char[?]', #url, url)
  local o_cstr = lib.curl_easy_unescape(handle, i_cstr, #url, out_n)

  local str = ffi.string(o_cstr)
  lib.curl_free(o_cstr)
  return str
end

local function easy_strerror(code)
  local cstr = lib.curl_easy_strerror(code)
  return ffi.string(cstr)
end


-----------------------------------------------------------
--  OOP Wrapper
-----------------------------------------------------------
local wrapper_mt = {}

wrapper_mt.__index = wrapper_mt

local function wrap(handle)
  local wrapper = {
    handle = handle
  }
  return setmetatable(wrapper, wrapper_mt)
end

local function init()
  return wrap(easy_init())
end

function wrapper_mt:reset()
  easy_reset(self.handle)
end

function wrapper_mt:clone()
  return wrap(easy_duphandle(self.handle))
end

function wrapper_mt:options(options)
  local e = {}
  for key, val in pairs(options) do
   local err = easy_setopt(self.handle, key, val)
  end
end

function wrapper_mt:perform(options)
  self:options(options)
  return easy_perform(self.handle)
end

function wrapper_mt:escape(url)
  return easy_escape(self.handle, url)
end

function wrapper_mt:unescape(url)
  return easy_unescape(self.handle, url)
end


info_mt = {}

function info_mt:__index(key)
  return easy_getinfo(self.handle, key)
end

function wrapper_mt:info()
  local info = {
    handle = self.handle
  }
  return setmetatable(info, info_mt)
end


-----------------------------------------------------------
--  Option Utils
-----------------------------------------------------------
function opt_utils.postfields(handle, post_data)
  if type(post_data) == 'string' then
    return post_data
  end
  if type(post_data) == 'table' then
    local fields = {}
    for k,v in pairs(post_data) do
      fields[#fields + 1] = k .. '=' .. v
    end
    return table.concat(fields, '&')
  end
  return ''
end

function opt_utils.writefunction(handle, callback)
  local type = 'size_t (*)(char*, size_t, size_t, void*)'
  return ffi.cast(type, callback)
end

function opt_utils.readfunction(handle, callback)
  local type = 'size_t (*)(void*, size_t, size_t, void*)'
  return ffi.cast(type, callback)
end

function opt_utils.headerfunction(handle, callback)
  local type = 'size_t (*)(void*, size_t, size_t, void*)'
  return ffi.cast(type, callback)
end

function opt_utils.progressfunction(handle, callback)
  local type = 'size_t (*)(void*, double, double, double, double)'
  return ffi.cast(type, callback)
end


-----------------------------------------------------------
--  Interface
-----------------------------------------------------------
return {
  version = version;
  init    = init;
}
