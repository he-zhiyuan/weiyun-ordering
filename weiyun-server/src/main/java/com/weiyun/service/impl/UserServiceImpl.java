package com.weiyun.service.impl;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.weiyun.constant.MessageConstant;
import com.weiyun.dto.UserLoginDTO;
import com.weiyun.dto.WebUserLoginDTO;
import com.weiyun.entity.User;
import com.weiyun.exception.LoginFailedException;
import com.weiyun.mapper.UserMapper;
import com.weiyun.properties.WeChatProperties;
import com.weiyun.service.UserService;
import com.weiyun.utils.HttpClientUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
public class UserServiceImpl implements UserService {

    // 微信服务接口地址
    public static final String WX_LOGIN = "https://api.weixin.qq.com/sns/jscode2session";

    @Autowired
    private WeChatProperties weChatProperties;
    @Autowired
    private UserMapper userMapper;

    /**
     * 微信登录
     *
     * @param userLoginDTO
     * @return
     */
    public User wxLogin(UserLoginDTO userLoginDTO) {
        String openid = getOpenid(userLoginDTO.getCode());

        // 判断openid是否为空，如果为空表示登录失败，抛出业务异常
        if (openid == null) {
            throw new LoginFailedException(MessageConstant.LOGIN_FAILED);
        }

        // 判断当前用户是否为新用户
        User user = userMapper.getByOpenid(openid);

        // 如果是新用户，自动完成注册
        if (user == null) {
            user = User.builder()
                    .openid(openid)
                    .createTime(LocalDateTime.now())
                    .build();
            userMapper.insert(user);
        }

        // 返回这个用户对象
        return user;
    }

    /**
     * Web端登录（演示用，免验证码，手机号直接登录/注册）
     *
     * @param webUserLoginDTO
     * @return
     */
    public User webLogin(WebUserLoginDTO webUserLoginDTO) {
        String phone = webUserLoginDTO.getPhone();
        if (phone == null || phone.trim().isEmpty()) {
            throw new LoginFailedException("手机号不能为空");
        }

        // 判断当前用户是否为新用户
        User user = userMapper.getByPhone(phone);

        // 如果是新用户，自动完成注册
        if (user == null) {
            user = User.builder()
                    .phone(phone)
                    .name(webUserLoginDTO.getName())
                    .createTime(LocalDateTime.now())
                    .build();
            userMapper.insert(user);
        }

        // 返回这个用户对象
        return user;
    }

    /**
     * 调用微信接口服务，获取微信用户的openid
     *
     * @param code
     * @return
     */
    private String getOpenid(String code) {
        // 调用微信接口服务，获得当前微信用户的openid
        Map<String, String> map = new HashMap<>();
        map.put("appid", weChatProperties.getAppid());
        map.put("secret", weChatProperties.getSecret());
        map.put("js_code", code);
        map.put("grant_type", "authorization_code");
        String json = HttpClientUtil.doGet(WX_LOGIN, map);

        JSONObject jsonObject = JSON.parseObject(json);
        String openid = jsonObject.getString("openid");
        return openid;
    }
}