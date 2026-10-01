# 开源上传检查清单

每次把一个项目推到 GitHub 之前，照着走一遍。**任何一步没做完就不要 push。**

---

## 第 0 步：隔离（最重要）

- [ ] 项目是**复制**到 `projects/<项目名>/` 的副本，不是从原工程目录直接操作
- [ ] 复制时只挑需要的文件，不要整目录拖进来
- [ ] 确认复制来源不是未公开的工程目录

> 为什么强调复制：原工程目录里可能混着第三方资料、其他项目代码、个人配置。
> 复制这一步本身就是在做减法。

## 第 1 步：清点内容

- [ ] 逐个看过 `projects/<项目名>/` 下的**每一个文件**（不是扫一眼文件名）
- [ ] 删掉所有编译中间产物、日志、备份文件
- [ ] 删掉与本项目无关的参考资料、他人代码
- [ ] 确认没有 `.env`、密钥、证书、内网地址、真实姓名学号
- [ ] 检查图片：截图里是否露出聊天窗口、邮件、桌面文件名、其他项目名

## 第 2 步：机器扫描

```powershell
# 单项目全量扫描
powershell -ExecutionPolicy Bypass -File tools\leak-scan.ps1 -IncludeUntracked

# 只看某个项目
git grep -i -n -I -E --cached -- ":(literal)projects/项目名"
```

- [ ] 扫描结果 0 项拦截
- [ ] 若出现误报，把该文件加入 `.leakscan/` 的例外处理，并在提交信息里说明原因

## 第 3 步：补充材料

- [ ] `README.md` 按 `_TEMPLATE` 结构写完整（尤其"测试结果"和"遇到的问题"）
- [ ] 关键技术有图：框图、原理图截图、实测波形、实物照片
- [ ] 注明许可证
- [ ] 引用他人代码 / 资料的地方标明出处

## 第 4 步：提交

```powershell
git add projects/<项目名>
git commit -m "feat(<项目名>): 上传 <一句话说明>"
```

- [ ] pre-commit 钩子已自动扫描并通过
- [ ] 提交信息说明了改了什么、为什么

## 第 5 步：发布授权（外部动作，必须逐次确认）

push 之前，AI 必须先向你确认，你也必须自己再确认一遍：

- [ ] 远程仓库的**可见性**符合预期（公开 / 私有）
- [ ] 目标分支正确
- [ ] 此时你已明确同意推送

```powershell
git push origin main
```

---

## 常用命令

```powershell
# 换电脑 / 重新 clone 后，先跑一次（钩子不会被克隆过来）
powershell -ExecutionPolicy Bypass -File tools\setup.ps1

# 全量体检（含未跟踪文件）
powershell -ExecutionPolicy Bypass -File tools\leak-scan.ps1 -IncludeUntracked

# 只扫描暂存区
powershell -ExecutionPolicy Bypass -File tools\leak-scan.ps1 -Staged

# 看本次到底准备了什么
git status
git diff --cached --stat

# 把已 add 的文件撤回（不删文件）
git restore --staged <路径>

# 看看某个文件到底会不会被忽略
git check-ignore -v <路径>

# 确认某个大文件是否已在历史里
git log --all --oneline -- <路径>
```

## 如果已经 push 了敏感内容

顺序不能反：

1. **先吊销凭据**——去对应平台停用或轮换那个 Key
2. 告诉 AI：什么凭据、在哪泄露、影响面多大
3. 再谈清理历史（`git filter-repo` 或 BFG），并强推已授权分支
4. 复查远端、Fork 与缓存

> 改代码不能挽回已经泄露的密钥，吊销才是第一优先级。

## 用 `--no-verify` 跳过扫描

偶尔会遇到误报。跳过时必须：

1. 先看清扫描器报的是哪个文件哪一行
2. 确认那确实是误报，不是真凭据
3. 在提交信息里写明跳过的原因，例如：

```text
chore: 更新文档

leak-scan 对 README 中的示例占位符误报，已确认非真实凭据，本次使用 --no-verify
```

> 别把 `--no-verify` 当成习惯动作。
