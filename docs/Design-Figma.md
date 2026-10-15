# Joyleebook Design System — Figma

> Phần thao tác Figma tách ra từ [Design-System.md](Design-System.md). Spec token/component nằm ở file đó; file này chỉ ghi cấu trúc file Figma và tiến độ dựng thư viện.

Stitch AI: https://stitch.withgoogle.com/projects/18202587658350678725

## Variable collections

Figma Starter chỉ hỗ trợ một mode cho mỗi collection. Vì vậy Joyleebook dùng hai collection song song: `Color · Light` và `Color · Dark`. Tên variable và code syntax trong hai collection giống nhau.

1. `Primitives` — one mode `Value`.
2. `Color · Light` — one mode `Light`.
3. `Color · Dark` — one mode `Dark`.
4. `Dimension` — one mode `Value`.
5. `Typography` — one mode `Value`.

Khi nâng cấp Figma lên Professional, nên hợp nhất hai collection màu thành `Color` với hai mode `Light` và `Dark`, giữ nguyên variable names và code syntax.

## File architecture

```text
00 · Cover
01 · Getting Started
02 · Foundations · Color
03 · Foundations · Typography
04 · Foundations · Spacing & Elevation
---
10 · Component · Button
11 · Component · Icon Button
12 · Component · Text Field & Search
13 · Component · Chip & Badge
14 · Component · Avatar
15 · Pattern · Story Card
16 · Pattern · Chapter Row
17 · Pattern · Reader Toolbar
18 · Pattern · Navigation
19 · Pattern · Feedback & Status
---
20 · Reference · Reader
21 · Reference · Discovery
22 · Reference · Author Studio
23 · Reference · Admin
99 · Changelog
```

## Definition of done (Figma)

- Tất cả component dùng Auto Layout và semantic variables.
- Component state/variant không vượt quá 30 combinations trong một set.
- Không có variable `ALL_SCOPES`, alias hỏng hoặc tên layer mặc định.
- Component có description, usage, do/don't và trạng thái disabled/loading/error khi liên quan.
- Mỗi foundation/component page được kiểm tra bằng metadata và screenshot.

## Implementation status

Đã tạo trong file Figma:

- 5 variable collections.
- 40 primitive color variables.
- 28 dimension variables.
- 17 typography variables.

Cần tiếp tục từ `P1.c` khi Figma MCP Starter cho phép gọi lại:

- Tạo 35 semantic variables cho mỗi collection Light/Dark (cập nhật theo bảng §3.2 mới của Design-System.md, gồm các giá trị dark và cặp `info` mới).
- Tạo text/effect styles.
- Tạo page skeleton, foundations documentation và components.
- Chạy accessibility, naming và unresolved-binding audit.

Continuation instruction:

> Continue Joyleebook design system build, run ID `joyleebook-v1`, Figma file key `BxDsY5EQNOBv19TCquqJqo`. Load `figma-use` and `figma-generate-library`, reconstruct file state, then resume from `P1.c` without duplicating existing tokens.
