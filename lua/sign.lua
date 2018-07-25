
local _M = {}

_M.appId = 'your appid'
_M.appSecret = 'your appSecret'

_M['wechat'] = {}
_M['wechat'].exptime = 7000
_M['wechat'].gettoken_url = 'https://api.weixin.qq.com/cgi-bin/token'
_M['wechat'].getticket_url = 'https://api.weixin.qq.com/cgi-bin/ticket/getticket'

local http = require 'resty.http'
local dkjson = require 'dkjson'
local json = require 'json'
local resty_random = require 'resty.random'
local resty_sha1 = require 'resty.sha1'
local resty_string = require "resty.string"

function create_nonce_str()
    return resty_random.token(16)
end

function create_timestamp()
    ngx.update_time()
    return ngx.time()
end

function getJsApiTicket()
    local jsapi_ticket = ngx.shared.wechat:get( 'jsapi_ticket' )
    -- ngx.log(ngx.ERR, "jsapi_ticket：", jsapi_ticket)
    if jsapi_ticket ~= nil then
        return jsapi_ticket
    end

    local httpc = http.new()
    local res, err = httpc:request_uri(_M['wechat'].getticket_url, {
        method = 'GET',
        ssl_verify = false,
        query = {
            ['access_token'] =  getAccessToken(),
            ['type'] = 'jsapi'
        }
    })

    if not res then
        ngx.log(ngx.ERR, 'failed to request: ', err)
        return
    end

    local data = dkjson.decode( res.body )
    -- ngx.log(ngx.ERR, 'jsapi_ticket: ', json.encode(data))
    ngx.shared.wechat:set( 'jsapi_ticket', data['ticket'], _M['wechat'].exptime )
    return data['ticket']
end


function getAccessToken()
    local access_token = ngx.shared.wechat:get( 'access_token' )
    -- ngx.log(ngx.ERR, "access_token:", access_token)
    if access_token ~= nil then
        return access_token
    end

    local httpc = http.new()
    local res, err = httpc:request_uri(_M['wechat'].gettoken_url, {
        method = 'GET',
        ssl_verify = false,
        query = {
            ['grant_type'] = 'client_credential',
            ['appid'] = _M.appId,
            ['secret'] = _M.appSecret
        }
    })

    if not res then
        ngx.log(ngx.ERR, 'failed to request: ', err)
        return
    end
    
    local data = dkjson.decode( res.body )
    -- ngx.log(ngx.ERR, 'access_token: ', json.encode(data))
    ngx.shared.wechat:set( 'access_token', data['access_token'], _M['wechat'].exptime )
    return data['access_token']
end

function _M.sign()
    local url = ngx.req.get_uri_args()['url']
    local noncestr = create_nonce_str()
    local timestamp = create_timestamp()
    local jsapi_ticket = getJsApiTicket()

    local args_table = {
        'jsapi_ticket='..jsapi_ticket,
        'noncestr='..noncestr,
        'timestamp='..timestamp,
        'url='..url
    }

    local sha1 = resty_sha1:new()
    sha1:update(table.concat(args_table, "&"))
    local digest = sha1:final()
    local signature = resty_string.to_hex(digest)

    ngx.log(ngx.ERR, json.encode(args_table))
    ngx.log(ngx.ERR, table.concat(args_table, "&"))
    ngx.log(ngx.ERR, signature)

    ngx.header.content_type = "text/html"
    ngx.header.charset = "utf-8"

    local ret = {
        ['appId'] = _M.appId,
        ['signature'] = signature,
        ['nonceStr'] = noncestr,
        ['timestamp'] =  timestamp
    }
    
    ngx.say(json.encode(ret))
    ngx.exit( ngx.HTTP_OK )
end

_M.sign()

return _M