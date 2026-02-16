# Hướng dẫn xóa Claude khỏi GitHub Contributors

## Nguyên nhân

Claude Code tự động thêm dòng `Co-Authored-By: Claude ...` vào commit message. GitHub đọc dòng này và hiển thị Claude như một Contributor của repo.

---

## Bước 1: Tìm commits có Co-Authored-By

```bash
git log --all --grep="Claude" --format="%h %s"
```

Ghi lại hash của commit **cũ nhất** có chứa Claude (ví dụ: `abc1234`).

## Bước 2: Kiểm tra tags

```bash
for tag in $(git tag); do
  echo "=== $tag ==="
  git log $tag --format="%B" | grep -i "Co-Authored-By.*Claude" && echo "FOUND in $tag"
done
```

## Bước 3: Xóa Co-Authored-By khỏi commit messages

Dùng `filter-branch` để xóa dòng Co-Authored-By từ commit cũ nhất đến HEAD:

```bash
# Stash thay đổi chưa commit (nếu có)
git stash

# Chạy filter-branch
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
  --msg-filter 'sed "/Co-Authored-By.*Claude/d"' \
  -- <commit-cu-nhat>~1..HEAD
```

**Lưu ý:** Nếu gặp lỗi "untracked files would be overwritten", tạm di chuyển các file đó ra ngoài rồi chạy lại.

## Bước 4: Cập nhật tags (nếu có)

Nếu Bước 2 tìm thấy tags có Claude, cần tạo lại tags trỏ đến commit mới:

```bash
# Xem commit cũ và mới
echo "Old tags:"
for tag in $(git tag); do echo "$tag -> $(git rev-parse $tag)"; done

echo "New commits:"
git log --format="%H %s"

# Tạo lại từng tag trỏ đến commit mới tương ứng
git tag -f <tag-name> <new-commit-hash>
```

## Bước 5: Xóa backup refs

```bash
git update-ref -d refs/original/refs/heads/main
```

## Bước 6: Force push

```bash
# Push branch
git push --force origin main

# Push tags (nếu đã cập nhật tags)
git push origin --tags --force
```

## Bước 7: Pop stash

```bash
git stash pop
```

## Bước 8: Kiểm tra

Đợi vài phút rồi kiểm tra:

```bash
# Qua API
curl -s https://api.github.com/repos/<username>/<repo>/contributors | grep login
```

Hoặc vào trang GitHub repo > nhìn phần Contributors.

---

## Phòng ngừa: Cập nhật CLAUDE.md

Thêm dòng sau vào phần **DON'T** trong `CLAUDE.md` của mỗi project:

```markdown
### DON'T
- **NEVER add `Co-Authored-By` line in commit messages** — this causes Claude to appear as a GitHub Contributor
```

Điều này ngăn Claude Code thêm dòng Co-Authored-By trong các lần commit sau.
