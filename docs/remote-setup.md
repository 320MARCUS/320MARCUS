# 远程仓库建立指南

这一份记录把本地仓库推上 GitHub 的完整流程，以及其中需要人工决策、人工完成的部分。

---

## 第零步：设置提交身份（最重要）

模板生成的提交，作者是占位符 `Your Name <your-name@users.noreply.github.com>`。
**必须在推送前换掉**，否则推上去之后，提交不会算到你账号名下，也没有头像。

一条命令搞定（会重写全部已有提交的作者）：

```powershell
powershell -ExecutionPolicy Bypass -File tools\set-identity.ps1 `
  -Name "你的名字" `
  -Email "你的ID@users.noreply.github.com"
```

脚本会先列出将被改写的提交，再问一次 `确认继续? (y/N)`，输入 `y` 回车。

**邮箱怎么选**

| 选项 | 说明 |
|------|------|
| GitHub noreply（推荐） | 形如 `12345678+username@users.noreply.github.com`。<br>在 https://github.com/settings/emails 勾选 *Keep my email addresses private* 后，页面上会直接显示这个地址 |
| 真实邮箱 | 会永久写进提交历史，任何 clone 的人都能看到，且无法撤回 |
| 学校邮箱 | 毕业后可能失效，但能体现学生身份，看你取舍 |

> 这一步必须在 push 之前做。推送之后想改作者，本地好改，远程要强制推送，
> 已经被人 clone 或 Fork 的副本也改不掉。

## 一、先做两个决定

### 决定 1：仓库可见性

| 选择 | 适合什么情况 | 代价 |
|------|--------------|------|
| **Public（公开）** | 这就是你建这个仓库的目的：给考研导师、面试官看 | 一旦公开，内容会被搜索引擎和爬虫抓取，**并且可能永久存在于第三方缓存** |
| **Private（私有）** | 先攒着，等作品成熟了再公开 | 需要自己记住哪些内容适合公开，心理负担反而更大 |

**我的建议**：这个仓库就建 **Public**。理由很直接——你是为了给人看才建的。
但配合下面这条纪律：**任何进 `projects/` 的东西，都当作明天就会公开来对待。**
未公开的工程从头到尾就不要复制进来，而不是"先传了再删"。

> 公开后即使删掉，也可能已经进了别人的缓存、Fork 或搜索引擎。
> 所以判断标准是"能不能公开"，而不是"删得快不快"。

### 决定 2：仓库名

建议就叫 `My_GitHub` 或换成更能体现方向的，例如：

```
ee-portfolio          # 电子信息工程作品集
embedded-projects
<你的用户名>.github.io  # 如果以后想搭个人主页
```

## 二、路线 A：在网页上创建（推荐，最省事）

1. 打开 https://github.com/new
2. **Repository name** 填你决定的名字
3. 可见性选 **Public**
4. **不要**勾选 "Add a README file"、"Add .gitignore"、"Choose a license"
   ——本地已经有了，勾了会造成冲突，第一次推送就得先合并
5. 点 **Create repository**
6. 创建完页面会显示一段命令，**不用管它**，往下看本文第三节

## 三、路线 B：装 gh 后由 AI 协助

`gh` 是 GitHub 官方命令行工具。当前这台机器上没装。

如果想让 AI 帮你建仓库和配置，需要先：

1. **你授权安装**（这一步按红线第 4 条，必须你亲口同意）：

   ```powershell
   winget install --id GitHub.cli
   ```

2. **你亲自登录**（我不会、也不能碰你的账号凭据）：

   ```powershell
   gh auth login
   ```

   选 `GitHub.com` → `HTTPS` → `Login with a web browser`，
   浏览器里输入它给的一次性代码即可。

3. 装好并登录之后告诉我，我再接手建仓库和配置。

> **千万不要**把 Personal Access Token 贴给我或写进任何文件。
> 需要凭据时一律由你在本机交互式输入。

## 四、关联远程并首次推送

两种协议，**推荐 SSH**（配一次以后不用再输密码）：

### 方案 1：HTTPS（简单，但推送要输凭据）

```powershell
git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git branch -M main
git push -u origin main
```

密码处需要填 **Personal Access Token**，不是账号密码。
Token 在 https://github.com/settings/tokens 生成，勾 `repo` 权限，生成后**只显示一次**。

### 方案 2：SSH（推荐）

```powershell
# 生成密钥（一路回车即可，passphrase 可留空）
ssh-keygen -t ed25519 -C "<你的GitHub邮箱>"

# 查看公钥，整段复制
Get-Content ~\.ssh\id_ed25519.pub
```

把公钥粘贴到 https://github.com/settings/keys → **New SSH key**，然后：

```powershell
ssh -T git@github.com
# 看到 "Hi <用户名>! You've successfully authenticated" 就成了

git remote add origin git@github.com:<你的用户名>/<仓库名>.git
git branch -M main
git push -u origin main
```

> 私钥文件 `id_ed25519`（**没有 .pub**）永远不要复制、上传、贴给任何人或 AI。
> 仓库的 `.gitignore` 和 `.leakscan` 已经把 `.ssh/` 和 `id_ed25519*` 列为拦截目标。

## 五、推送之后立刻做的三件事

- [ ] 打开仓库页面，肉眼过一遍文件列表，确认没有多余文件
- [ ] 看 **Actions** 标签页，确认「泄漏扫描」工作流是绿色对勾
- [ ] 确认仓库页面上显示的提交作者是你自己（如果显示 `Your Name`，说明占位符没换）

## 六、GitHub 账号安全设置（强烈建议）

- [ ] 开启两步验证：https://github.com/settings/security
- [ ] 在 https://github.com/settings/emails 里勾选
      **Keep my email addresses private**，并记下你的 `noreply` 邮箱
- [ ] 确认 Profile 里展示的是你希望公开的信息

## 七、AI 的授权边界

以下动作我不会自己做，需要你逐次明确同意：

| 动作 | 触发方式 |
|------|----------|
| 安装 `gh` | 你说「可以装」 |
| 创建远程仓库 | 你说「可以建，仓库名 XXX」 |
| `git push` | 每次推送都要单独说 |
| 改仓库可见性 | 你说「改成公开/私有」 |
| 添加协作者 | 你说「加 XXX」 |

说一句「**可以推送**」就够，不用长篇解释。
