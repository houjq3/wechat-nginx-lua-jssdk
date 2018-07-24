# lua-nginx-wechat-jssdk



### 待办

sha1加密问题



http

```nginx
    lua_package_path '/home/mdxdd/soft/openresty/nginx/wechat-jssdk/?.lua;;';   
    lua_code_cache on;
    lua_shared_dict wechat 10m;
```

server

```nginx
location = /wechat/signature { 
	resolver 8.8.8.8;
	access_by_lua_file /home/mdxdd/soft/openresty/nginx/wechat-jssdk/sign.lua;
}
```

