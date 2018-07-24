
local _M = {}

_M.appId = 'wx3189d6b530740b13'
_M.appSecret = 'a2c03aea62a9c156b3e767090f77a46e'

local http = require 'resty.http'
local dkjson = require 'dkjson'
local json = require 'json'
local random = require 'resty.random'
local sha1 = require 'resty.sha1'

function create_nonce_str()
    return random.token(16)
end

function create_timestamp()
    ngx.update_time()
    return ngx.time()
end

function getJsApiTicket()
    local jsapi_ticket = ngx.shared.wechat:get( 'jsapi_ticket' )
    ngx.log(ngx.ERR, "jsapi_ticket：", jsapi_ticket)
    if jsapi_ticket ~= nil then
        return jsapi_ticket
    end

    local httpc = http.new()
    local res, err = httpc:request_uri('https://api.weixin.qq.com/cgi-bin/ticket/getticket', {
        method = 'GET',
        ssl_verify = false,
        query = {
            ['access_token'] =  getAccessToken(),
            ['type'] = 'jsapi'
        }
    })

    if not res then
        -- ngx.say('failed to request: ', err)
        ngx.log(ngx.ERR, 'failed to request: ', err)
        return
    end

    ngx.log(ngx.ERR, 'jsapi_ticket: ', json.encode(res))

    local data = dkjson.decode( res.body )
    ngx.shared.wechat:set( 'jsapi_ticket', data['ticket'], 7000 )
    return data['ticket']
end


function getAccessToken()
    local access_token = ngx.shared.wechat:get( 'access_token' )
    ngx.log(ngx.ERR, access_token)
    if access_token ~= nil then
        return access_token
    end
    ngx.log(ngx.ERR, '111111')
    local httpc = http.new()
    local res, err = httpc:request_uri('https://api.weixin.qq.com/cgi-bin/token', {
        method = 'GET',
        ssl_verify = false,
        query = {
            ['grant_type'] = 'client_credential',
            ['appid'] = _M.appId,
            ['secret'] = _M.appSecret
        }
    })

    ngx.log(ngx.ERR, '222222')

    if not res then
        -- ngx.say('failed to request: ', err)
        ngx.log(ngx.ERR, 'failed to request: ', err)
        return
    end
    ngx.log(ngx.ERR, '3333333')
    ngx.log(ngx.ERR, 'access_token: ', json.encode(res))

    local data = dkjson.decode( res.body )
    ngx.shared.wechat:set( 'access_token', data['access_token'], 7000 )
    return data['access_token']
end

function _M.sign()
    local url = ngx.var.scheme..'://'..ngx.var.host..ngx.var.uri
    local ret = {
        ['nonceStr'] = create_nonce_str(),
        ['jsapi_ticket'] = getJsApiTicket(),
        ['timestamp'] =  create_timestamp(),
        ['url'] = url
    }
    
    local signature = string.lower(to_hex(ngx.sha1_bin( table.concat(ret, '&'))))
    
    ngx.log(ngx.ERR, json.encode(ret))
    ngx.header.content_type = "text/html"
    ngx.header.charset = "utf-8"
    ngx.say(json.encode({["signature"]=signature}))
    ngx.exit( ngx.HTTP_OK )
end

function to_hex(str)
    return ({str:gsub(".", function(c) return string.format("%02X", c:byte(1)) end)})[1]
end

_M.sign()

return _M