# CI 配置文档

## Jenkins 凭据配置指南

本文档详细说明了 Jenkins CI 流水线中所需的各种凭据的获取和配置方法。

### 1. 蒲公英平台凭据

#### PGYER_API_KEY 和 PGYER_USER_KEY
- **来源**：蒲公英平台
- **获取步骤**：
  1. 登录 [蒲公英平台](https://www.pgyer.com)
  2. 进入"账号设置" > "API 信息"
  3. `PGYER_API_KEY` 是 "API Key"
  4. `PGYER_USER_KEY` 是 "User Key"
- **用途**：用于将构建的应用上传到蒲公英平台

### 2. Apple Developer 凭据

#### DEVELOPMENT_TEAM
- **来源**：Apple Developer 账号
- **获取步骤**：
  1. 登录 [Apple Developer](https://developer.apple.com)
  2. 点击右上角你的账号
  3. 进入 "Membership" 页面
  4. 找到 "Team ID" 字段（格式类似：`A1B2C3D4E5`）
- **用途**：用于 Xcode 构建时的团队标识

#### PROVISIONING_PROFILE
- **来源**：Apple Developer 账号
- **获取步骤**：
  1. 登录 [Apple Developer](https://developer.apple.com)
  2. 进入 "Certificates, Identifiers & Profiles"
  3. 选择 "Profiles"
  4. 找到你的 Mac Development 配置文件
  5. 下载配置文件
  6. 双击安装到 Mac
- **用途**：用于应用签名和部署

#### CERTIFICATE_P12 和 CERTIFICATE_PASSWORD
- **来源**：Mac 钥匙串中的开发证书
- **获取步骤**：
  1. 打开 Mac 的 "Keychain Access"（钥匙串访问）
  2. 在左侧选择 "login" 钥匙串
  3. 在右侧找到你的 Mac Development 证书
  4. 点击证书左侧的箭头展开，选择证书和私钥
  5. 右键点击，选择 "Export 2 items..."
  6. 选择保存为 .p12 格式
  7. 设置导出密码
  8. 将 .p12 文件转换为 base64：
     ```bash
     base64 -i your_certificate.p12 -o certificate.txt
     ```
- **注意事项**：
  - 如果看不到私钥，需要重新创建证书
  - 证书和私钥必须同时导出
  - 确保使用正确的钥匙串（通常是 "login"）

#### CODE_SIGN_IDENTITY
- **来源**：Mac 钥匙串中的开发证书
- **获取步骤**：
  1. 打开 Mac 的 "Keychain Access"（钥匙串访问）
  2. 在左侧选择 "login" 钥匙串
  3. 在右侧找到你的 Mac Development 证书
  4. 双击打开证书
  5. 在 "Common Name" 字段中，你会看到类似：
     ```
     Apple Development: your.name@example.com (TEAM_ID)
     ```
     或
     ```
     Mac Developer: your.name@example.com (TEAM_ID)
     ```
- **用途**：用于指定代码签名证书

### 3. 证书问题排查

#### 证书匹配验证
当遇到 "No certificate for team matching found" 错误时，需要验证证书和团队 ID 的匹配：

1. 验证团队 ID：
   ```bash
   # 在 Mac 终端中运行
   security find-identity -v -p codesigning
   ```
   输出示例：
   ```
   1) 1234567890ABCDEF1234567890ABCDEF12345678 "Apple Development: your.name@example.com (TEAM_ID)"
   ```
   从输出中提取团队 ID（括号中的部分）

2. 验证 DEVELOPMENT_TEAM 值：
   - 登录 [Apple Developer](https://developer.apple.com)
   - 进入 "Membership" 页面
   - 确认 Team ID 是否与证书中的团队 ID 匹配

3. 验证 CODE_SIGN_IDENTITY 值：
   - 在钥匙串访问中双击证书
   - 查看 "Common Name" 字段
   - 确保完整名称与 Jenkins 中配置的 CODE_SIGN_IDENTITY 完全匹配
   - 特别注意括号中的团队 ID 是否与 DEVELOPMENT_TEAM 匹配

4. 常见问题解决：
   - 如果团队 ID 不匹配：
     1. 确认使用的是同一个 Apple Developer 账号
     2. 检查 DEVELOPMENT_TEAM 值是否正确
     3. 检查 CODE_SIGN_IDENTITY 中的团队 ID 是否正确
   
   - 如果证书名称不匹配：
     1. 在钥匙串访问中确认正确的证书名称
     2. 更新 Jenkins 中的 CODE_SIGN_IDENTITY 值
     3. 确保包含完整的证书名称，包括团队 ID

   - 如果证书不可用：
     1. 检查证书是否在有效期内
     2. 确认证书是否已正确安装到钥匙串
     3. 验证证书的私钥是否可用

#### 无法导出 .p12 格式
如果只能看到 .cer、.pem 或 .p7b 格式，说明只看到了证书文件，没有私钥。解决方案：

1. 检查钥匙串：
   - 确保在正确的钥匙串中（通常是 "login" 或 "System"）
   - 点击证书左侧的箭头展开，查看是否有私钥

2. 如果没有私钥，需要重新创建证书：
   1. 登录 [Apple Developer](https://developer.apple.com)
   2. 进入 "Certificates, Identifiers & Profiles"
   3. 选择 "Certificates"
   4. 点击 "+" 按钮
   5. 选择 "Mac Development"
   6. 按照指示创建证书请求（CSR）
   7. 上传 CSR 文件
   8. 下载新证书
   9. 双击安装到钥匙串

### 4. Jenkins 凭据配置

在 Jenkins 中添加凭据的步骤：
1. 进入 Jenkins > Manage Jenkins > Manage Credentials
2. 选择适当的凭据域
3. 点击 "Add Credentials"
4. 对于每个凭据：
   - Kind: "Secret text"（除了 CERTIFICATE_P12 使用 "Secret file"）
   - Scope: 选择适当的范围
   - Secret: 粘贴对应的值
   - ID: 使用上述凭据名称
   - Description: 添加描述以便识别

### 5. 注意事项

1. 所有凭据都应该来自同一个 Apple Developer 账号
2. 证书和配置文件应该在有效期内
3. 确保 Jenkins 节点有权限访问这些凭据
4. 定期更新证书和配置文件，因为它们会过期
5. 保持凭据的安全性，不要泄露给未授权人员 