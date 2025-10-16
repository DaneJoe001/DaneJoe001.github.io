@echo off
chcp 65001
echo ====================================
echo 博客部署脚本
echo ====================================
echo.

echo [1/3] 清理旧的构建...
if exist dist rmdir /s /q dist

echo [2/3] 构建项目...
call npm run build
if errorlevel 1 (
    echo 构建失败！
    pause
    exit /b 1
)

echo [3/3] 部署到 GitHub Pages...
echo 尝试使用 gh-pages 自动部署...
call npm run deploy
if errorlevel 1 (
    echo.
    echo gh-pages 部署失败，尝试手动部署...
    echo.
    cd dist
    git init
    git add -A
    git commit -m "Deploy blog - %date% %time%"
    git branch -M gh-pages
    git remote add origin git@github.com:DaneJoe001/DaneJoe001.github.io.git
    git push -f origin gh-pages
    cd ..
    
    if errorlevel 1 (
        echo.
        echo 手动部署也失败了。
        echo 请检查网络连接或稍后重试。
        echo.
        echo 提示：
        echo 1. 确保 SSH 密钥已配置
        echo 2. 检查网络代理设置
        echo 3. 尝试使用 VPN
        pause
        exit /b 1
    )
)

echo.
echo ====================================
echo 部署成功！
echo ====================================
echo.
echo 您的博客已部署到 GitHub Pages
echo 访问地址: https://danejoe001.github.io
echo.
echo 注意：GitHub Pages 可能需要几分钟来处理部署
echo.
pause

