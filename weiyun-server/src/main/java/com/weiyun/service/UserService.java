package com.weiyun.service;

import com.weiyun.dto.UserLoginDTO;
import com.weiyun.dto.WebUserLoginDTO;
import com.weiyun.entity.User;

public interface UserService {

    /**
     * 微信登录
     *
     * @param userLoginDTO
     * @return
     */
    User wxLogin(UserLoginDTO userLoginDTO);

    /**
     * Web端登录（演示用，免验证码，手机号直接登录/注册）
     *
     * @param webUserLoginDTO
     * @return
     */
    User webLogin(WebUserLoginDTO webUserLoginDTO);
}