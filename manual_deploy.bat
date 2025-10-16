@echo off
chcp 65001
echo ====================================
echo 手动部署到 gh-pages 分支
echo ====================================
echo.

cd dist

echo [1/4] 初始化 git 仓库...
if exist .git (
    rmdir /s /q .git
)
git init

echo [2/4] 添加所有文件...
git add -A

echo [3/4] 提交...
git commit -m "Deploy: 更新侧边栏菜单，展示5个C++项目"

echo [4/4] 推送到 gh-pages 分支...
git branch -M gh-pages
git remote add origin https://github.com/DaneJoe001/DaneJoe001.github.io.git
git push -f origin gh-pages

cd ..

echo.
echo ====================================
echo 部署完成！
echo ====================================
echo.
echo 网站将在几分钟后更新
echo 访问地址: https://danejoe001.github.io
echo.
pause

