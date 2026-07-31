# markdown-reformatter

*[English](README.md) | Tiếng Việt*

Chạy `markdownlint` (qua `markdownlint-cli2`) trong Docker để tự động reformat/fix
toàn bộ file `.md` trong một thư mục local, không cần cài Node.js trên máy.

## Tiền điều kiện

- **Docker phải được cài đặt và đang chạy**, trên máy nào cũng vậy:
  - Windows / macOS: [Docker Desktop](https://docs.docker.com/get-docker/)
  - Linux: [Docker Engine](https://docs.docker.com/engine/install/)
- **Bash**: có sẵn trên macOS/Linux; trên Windows dùng **Git Bash** (đi kèm
  [Git for Windows](https://git-scm.com/downloads/win)) — `md-lint.cmd`/`run.ps1`
  cũng gọi `bash` bên dưới, nên vẫn cần bước này dù bạn chỉ dùng PowerShell.
- Tất cả script tự kiểm tra Docker và báo lỗi rõ ràng nếu chưa cài.

## Cấu trúc

- `Dockerfile` — image Node.js cài `markdownlint-cli2`.
- `entrypoint.sh` — chạy `--fix` lặp lại tới khi hội tụ (một số rule chỉ fix được
  sau khi rule khác đã sửa xong), rồi in báo cáo các lỗi còn lại (nếu không thể tự fix).
- `.markdownlint-cli2.jsonc.example` — file cấu hình rule mẫu (mặc định bật
  hết, tắt `MD013` line-length, `MD033` inline HTML, `MD040` fenced-code-language,
  và pin `MD060` về style `compact`). **Đã gitignore file `.markdownlint-cli2.jsonc`
  thật** — mỗi người clone về tự có bản copy riêng để tuỳ chỉnh mà không đụng
  vào file mẫu dùng chung (xem [Tuỳ chỉnh rule](#tuỳ-chỉnh-rule)).
- `run.ps1` / `run.sh` — chạy trực tiếp từ thư mục clone (**Cách 1** bên dưới).
- `install.sh` / `install.ps1` — cài lệnh `md-lint` dùng toàn cục (**Cách 2** bên dưới).
- `uninstall.sh` / `uninstall.ps1` — gỡ những gì `install.sh`/`install.ps1` đã cài (xem [Gỡ cài đặt](#gỡ-cài-đặt)).
- `md-lint/md-lint` (+ `md-lint/md-lint.cmd`) — mã nguồn của lệnh `md-lint`,
  được `install.sh`/`install.ps1` copy ra thư mục cài đặt của từng người dùng.

## Cách 1 — Chạy trực tiếp từ thư mục clone

Không cần cài gì thêm, chỉ cần `git clone` về rồi chạy ngay.

### Cách 1 — Bash (Git Bash trên Windows / macOS / Linux)

```bash
git clone <repo-url> markdown-reformatter
cd markdown-reformatter
chmod +x run.sh

# Tự động fix
./run.sh /absolute/path/to/markdown/folder

# Chỉ kiểm tra, không sửa
./run.sh /absolute/path/to/markdown/folder --check
```

### Cách 1 — PowerShell (Windows)

```powershell
git clone <repo-url> markdown-reformatter
cd markdown-reformatter

# Tự động fix
.\run.ps1 -Path "C:\path\to\markdown\folder"

# Chỉ kiểm tra lỗi, không sửa
.\run.ps1 -Path "C:\path\to\markdown\folder" -Check
```

`run.sh`/`run.ps1` tự dùng thư mục chứa chính nó làm Docker build context, nên
gọi bằng đường dẫn tương đối/tuyệt đối từ bất kỳ đâu cũng được, không nhất
thiết phải `cd` vào đúng thư mục clone trước.

## Cách 2 — Cài `md-lint` dùng toàn cục

Chạy 1 lần để cài lệnh `md-lint`, sau đó gọi được ở **bất kỳ thư mục nào**, kể
cả sau khi đã xoá thư mục clone.

### Cách 2 — Bash (Git Bash trên Windows / macOS / Linux)

```bash
git clone <repo-url> markdown-reformatter
cd markdown-reformatter
chmod +x install.sh
./install.sh
```

### Cách 2 — PowerShell (Windows)

```powershell
git clone <repo-url> markdown-reformatter
cd markdown-reformatter
.\install.ps1
```

Script cài đặt sẽ:

1. Copy các file cần cho Docker (`Dockerfile`, `entrypoint.sh`, `package.json`,
   `.markdownlint-cli2.jsonc.example`) vào `~/.md-lint` (`%USERPROFILE%\.md-lint`
   trên Windows) — đây là bản build context độc lập, không phụ thuộc thư mục clone.
   Nếu chưa có config thật, nó tự tạo `~/.md-lint/.markdownlint-cli2.jsonc` từ
   file mẫu (không đè lên config đã tuỳ chỉnh nếu chạy lại install).
2. Copy `md-lint` (+ `md-lint.cmd` trên Windows) vào một thư mục `bin` — ưu
   tiên thư mục đã có sẵn trong `PATH` (`~/bin` hoặc `~/.local/bin`), nếu chưa
   có `PATH` nào phù hợp thì tạo `~/bin` và in hướng dẫn thêm vào `PATH`
   (khác nhau theo bash/zsh/Windows, script tự phát hiện).

Sau khi cài (và mở terminal mới nếu vừa thêm `PATH`):

```bash
# Git Bash / macOS / Linux — fix thư mục hiện tại
md-lint ./

# Chỉ định thư mục khác, hoặc chỉ kiểm tra
md-lint /path/to/other/folder
md-lint ./ --check
```

```powershell
# PowerShell — tương đương (md-lint.cmd tự gọi bash bên dưới)
md-lint .\
md-lint .\ --check
```

Không truyền path thì mặc định dùng thư mục hiện tại (`.`).

## Tuỳ chỉnh rule

Sửa file `.markdownlint-cli2.jsonc`:

- **Cách 1** (chạy từ thư mục clone): file nằm ngay tại gốc repo. Lần chạy đầu
  tiên `run.sh`/`run.ps1` sẽ tự tạo nó từ `.markdownlint-cli2.jsonc.example`
  nếu chưa có — cứ sửa thoải mái, file này đã gitignore nên không bị commit/ghi
  đè khi `git pull`.
- **Cách 2** (`md-lint` toàn cục): sửa `~/.md-lint/.markdownlint-cli2.jsonc`
  (`%USERPROFILE%\.md-lint\.markdownlint-cli2.jsonc` trên Windows).

Danh sách rule đầy đủ: [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md).
Không cần build lại thủ công — `run.sh`/`run.ps1`/`md-lint` đều tự
`docker build` (có cache, chỉ mất ~1s nếu không đổi gì) trước mỗi lần chạy.

## Gỡ cài đặt

- **Cách 1** (chạy từ thư mục clone): không cài gì vào máy ngoài image Docker,
  nên chỉ cần xoá thư mục clone. Muốn dọn luôn image đã build:

  ```bash
  docker rmi markdown-reformatter
  ```

- **Cách 2** (`md-lint` toàn cục): chạy `uninstall.sh`/`uninstall.ps1` từ
  thư mục clone (hoặc tải riêng 2 file này về nếu đã xoá clone) — gỡ đúng những
  gì `install.sh`/`install.ps1` đã tạo: xoá `~/.md-lint`, xoá `md-lint`/`md-lint.cmd`
  khỏi thư mục `bin`, xoá khỏi `PATH` nếu install từng tự thêm, và xoá luôn
  Docker image. An toàn khi chạy nhiều lần (không có gì để gỡ thì chỉ báo vậy).

  ```bash
  ./uninstall.sh
  ```

  ```powershell
  .\uninstall.ps1
  ```

  Nếu bạn tự thêm dòng `export PATH=...` vào `~/.bashrc`/`~/.zshrc` theo hướng
  dẫn lúc cài, script không tự xoá dòng đó — cần tự gỡ thủ công.

## Lưu ý

- Container chỉ ghi đè các file trong thư mục được mount (`/data`), không đụng tới file nào khác.
- Nên chạy thử với `--check` trước khi fix thật nếu thư mục markdown chưa được backup/commit.
- Một số lỗi (ví dụ `MD040` fenced-code-language khi chưa tắt rule) không thể
  tự động fix vì tool không đoán được ngôn ngữ code block — các lỗi này sẽ
  được in ra ở cuối để bạn tự sửa tay.
- Trên Windows/Git Bash: các script tự chuyển path sang dạng `C:/...` (qua
  `cygpath -m`) trước khi mount vào Docker — path dạng MSYS (`/c/...`) khiến
  Docker Desktop mount nhầm vào thư mục rỗng.
