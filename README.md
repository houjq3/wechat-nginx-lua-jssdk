# wechat-nginx-lua-jssdk

Nginx+Lua实现微信分享接口 JS-SDK 



## 服务端Nginx

- 建议安装 [OpenResty](http://openresty.org/cn/) 1.13以上版本
- 将 `lua目录` 拖到 `$prefix/conf` 下
- 修改 nginx.conf

**http  {} 新增**

```nginx
lua_package_path '$prefix/conf/lua/?.lua;;';   
lua_code_cache on;
lua_shared_dict wechat 1m;
```

**server {}** 新增

```nginx
location = /wechat/signature { 
    resolver 8.8.8.8;
    access_by_lua_file conf/lua/sign.lua;
}
```

- 修改 lua/sign.lua

```lua
_M.appId = 'your appid'
_M.appSecret = 'your appSecret'
```



## 客户端网页

```html
<script src="http://res.wx.qq.com/open/js/jweixin-1.2.0.js"></script>
<scirpt>
var currUrl = window.location.href.replace(window.location.hash, '');
var share_title = document.title.trim();
var meta = document.getElementsByTagName('meta');
var share_desc = '';
for (i in meta) { if (typeof meta[i].name != "undefined" && meta[i].name.toLowerCase() == "description") { share_desc = meta[i].content.trim(); } }

$.getJSON('/wechat/signature?url=' + encodeURIComponent(currUrl)).done(function (data) {
    wx.config({
        debug: false,
        appId: data.appId,
        timestamp: data.timestamp,
        nonceStr: data.nonceStr,
        signature: data.signature,
        jsApiList: [
            'checkJsApi',
            'onMenuShareTimeline',
            'onMenuShareAppMessage'
        ]
    });
});

wx.ready(function () {
    // 1 判断当前版本是否支持指定 JS 接口，支持批量判断
    wx.checkJsApi({
        jsApiList: [
            'onMenuShareTimeline',
            'onMenuShareAppMessage'
        ],
        success: function (res) {
            // alert(JSON.stringify(res));
        }
    });

    // 2. 分享接口
    // 2.1 监听“分享给朋友”，按钮点击、自定义分享内容及分享结果接口
    wx.onMenuShareAppMessage({
        title: share_title,
        desc: share_desc,
        link: currUrl,
        imgUrl: 'http://houjq.com/author.jpg',
        trigger: function (res) {
            // alert('用户点击发送给朋友');
        },
        success: function (res) {
            // alert('已分享');
        },
        cancel: function (res) {
            // alert('已取消');
        },
        fail: function (res) {
            // alert(JSON.stringify(res));
        }
    });

    // 2.2 监听“分享到朋友圈”按钮点击、自定义分享内容及分享结果接口
    wx.onMenuShareTimeline({
        title: share_title,
        link: currUrl,
        imgUrl: 'http://houjq.com/author.jpg',
        trigger: function (res) {
            // alert('用户点击分享到朋友圈');
        },
        success: function (res) {
            // alert('已分享');
        },
        cancel: function (res) {
        desc: share_desc,
            // alert('已取消');
        },
        fail: function (res) {
            // alert(JSON.stringify(res));
        }
    });

});

wx.error(function (res) {
    // alert(res.errMsg);
});
</script>
```



## 说明

- 分享接口不支持未认证订阅号
- 调试建议使用微信web开发者工具
- 本项目仅支持单机nginx，集群nginx需将 appId、appSecret、lua_shared_dict配置引入redis



## 捐赠

请作者喝杯咖啡吧~

<img title="donationQRcode" src="http://houjq.com/pay.jpg" width="40%">

