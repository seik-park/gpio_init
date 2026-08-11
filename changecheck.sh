REPO="/c/work/github-clone-check/GPIO_INT_20260811_182517"

cd "$REPO" || exit 1

echo "===== Git 상태 ====="
git status --short

echo
echo "===== 변경 내용 ====="
git diff

echo
echo "===== 절대경로 검사 ====="

if git diff -- .project .cproject GCC/.project GCC/.cproject 2>/dev/null \
    | grep -Ei 'C:/|file:/C:/|C:\\' >/dev/null; then

    echo "[STOP] .project 또는 .cproject에 Windows 절대경로 변경이 있습니다."
    echo "[STOP] 이 상태로는 GitHub에 Push하지 않는 것을 권장합니다."
    echo
    git diff -- .project .cproject GCC/.project GCC/.cproject
else
    echo "[OK] 프로젝트 설정 변경에서 Windows 절대경로를 찾지 못했습니다."

    if [ -z "$(git status --porcelain)" ]; then
        echo "[OK] Git에 반영할 변경사항이 없습니다."
    else
        echo
        echo "===== Commit ====="

        git add .

        git status --short

        git commit -m "build: update NuEclipse build configuration"

        echo
        echo "===== Push ====="

        git push

        echo
        echo "[OK] GitHub Push 완료"
    fi
fi
