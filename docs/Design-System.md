# Joyleebook Design System v1.1

> Design system đa nền tảng cho website Blazor/ASP.NET và ứng dụng Flutter.
>
> Hướng hình ảnh: **Warm Editorial** — ấm, tập trung vào việc đọc lâu, hiện đại nhưng không lạnh lẽo.

Nguồn sự thật trên web: `Theme/JoyleeTheme.cs` (palette MudBlazor) và `wwwroot/css/tokens.css` (semantic `--jl-*`). Bảng trong tài liệu này phải khớp hai file đó; khi đổi token, sửa code và bảng trong cùng một commit. Cấu trúc file Figma và tiến độ dựng thư viện: [Design-Figma.md](Design-Figma.md).

## 1. Product foundation

### Tầm nhìn

Joyleebook là nền tảng đọc, viết và thảo luận truyện chữ. Giao diện cần phục vụ đồng thời ba bối cảnh:

1. **Đọc và khám phá:** nhẹ, yên tĩnh, ưu tiên nội dung.
2. **Sáng tác và quản lý:** rõ ràng, hiệu quả, có trạng thái xuất bản.
3. **Quản trị hệ thống:** nhiều dữ liệu nhưng vẫn cùng ngôn ngữ hình ảnh.

### Nguyên tắc thiết kế

- **Content first:** bìa, tiêu đề, tác giả và nội dung chương luôn có thứ bậc rõ nhất.
- **Calm by default:** hạn chế màu mạnh, bóng đổ và card lồng card; dành màu brand cho hành động chính. Không dùng hover nhấc phần tử (`translateY`).
- **Readable for hours:** typography đọc truyện tách khỏi typography UI; chiều rộng dòng và line-height có giới hạn.
- **Progressive disclosure:** chức năng nâng cao của tác giả/admin chỉ xuất hiện khi đúng ngữ cảnh.
- **Cross-platform semantics:** web và mobile dùng cùng tên token, component state và ý nghĩa hành động.
- **Accessible without exception:** thao tác bàn phím, focus ring, contrast và touch target là yêu cầu nền tảng.

## 2. Brand direction

### Tính cách

- Ấm áp, trí tưởng tượng, đáng tin cậy.
- Có chất biên tập sách nhưng không mô phỏng sách giấy quá mức.
- Trang đọc tối giản; khu vực khám phá có nhiều hình ảnh và nhịp điệu hơn.

### Logo direction

Wordmark **Joyleebook** dùng chữ sans đậm, mềm. Biểu tượng gợi ý là một cuốn sách mở kết hợp tia sáng nhỏ hoặc dấu trang. Không dùng biểu tượng quá chi tiết ở kích thước 20–24 px.

Trên web hiện tại wordmark là Inter 700, 20 px, letter-spacing `-0.05em`, kèm dấu chấm màu `bg/brand` (`.jl-wordmark`, `.jl-wordmark-dot`).

### Màu thương hiệu

- **Plum** là màu nhận diện và hành động chính.
- **Amber** tạo điểm nhấn vui vẻ, dùng cho highlight, thành tích và focus (dark).
- **Paper/Ink** thay thế trắng–đen thuần trong phần lớn bề mặt để giảm chói.

## 3. Design tokens

### 3.1 Primitive colors

Primitive chỉ là nguồn giá trị; component không tham chiếu primitive trực tiếp.

| Family | Token | Hex | Mục đích |
|---|---|---:|---|
| Paper | `paper/0` | `#FFFFFF` | Bề mặt sáng nhất |
| Paper | `paper/50` | `#FFFCF7` | Canvas light |
| Paper | `paper/100` | `#FBF5EC` | Surface subtle |
| Paper | `paper/200` | `#F3E8D8` | Hover/selected nhẹ |
| Paper | `paper/300` | `#E8D7C2` | Border ấm |
| Ink | `ink/100` | `#F2ECE8` | Chữ sáng trên dark |
| Ink | `ink/200` | `#E2D9D2` | Border light |
| Ink | `ink/300` | `#C9BDB3` | Secondary text dark |
| Ink | `ink/400` | `#AA9A8F` | Muted text dark |
| Ink | `ink/500` | `#8A7A70` | Disabled text |
| Ink | `ink/600` | `#6D5E56` | Muted text light / strong border dark |
| Ink | `ink/700` | `#574A43` | Secondary text light |
| Ink | `ink/800` | `#3A312D` | Dark subtle surface |
| Ink | `ink/900` | `#2A2421` | Dark surface |
| Ink | `ink/950` | `#1D1917` | Dark canvas / primary text |
| Plum | `plum/50` | `#F8F2FA` | Brand subtle light |
| Plum | `plum/100` | `#F0E2F4` | Selected light |
| Plum | `plum/200` | `#DFC3E7` | Brand text / link dark |
| Plum | `plum/300` | `#C89AD5` | Decorative dark accent |
| Plum | `plum/400` | `#AD72BF` | Dark theme accent |
| Plum | `plum/500` | `#914FA7` | Brand dark / focus light |
| Plum | `plum/600` | `#773B8E` | Brand light |
| Plum | `plum/700` | `#5F2E72` | Brand hover light |
| Plum | `plum/800` | `#492258` | Strong brand |
| Plum | `plum/900` | `#34183F` | Brand subtle dark |
| Amber | `amber/50` | `#FFF8E8` | Accent/warning subtle light |
| Amber | `amber/100` | `#FCEBC2` | Highlight |
| Amber | `amber/200` | `#F8D88F` | Warning text dark |
| Amber | `amber/300` | `#F0BD5A` | Accent dark / focus dark |
| Amber | `amber/400` | `#E5A039` | Accent hover |
| Amber | `amber/500` | `#D58522` | Accent light |
| Amber | `amber/600` | `#B76917` | Strong accent |
| Amber | `amber/700` | `#8F4E13` | Warning text light |
| Amber | `amber/900` | `#49351F` | Accent/warning subtle dark |
| Green | `green/50` | `#EDF8F2` | Success subtle light |
| Green | `green/200` | `#B1E1C7` | Success text dark |
| Green | `green/300` | `#82C9A6` | MudBlazor `Success` dark |
| Green | `green/600` | `#2D7B57` | Success text light |
| Green | `green/900` | `#234333` | Success subtle dark |
| Red | `red/50` | `#FFF0EE` | Danger subtle light |
| Red | `red/300` | `#F0A49D` | Danger text dark |
| Red | `red/600` | `#B74B43` | Danger text light / destructive fill |
| Red | `red/900` | `#542C29` | Danger subtle dark |
| Blue | `blue/50` | `#EEF6FF` | Info subtle light |
| Blue | `blue/300` | `#94BFEF` | Info text dark |
| Blue | `blue/600` | `#3976B8` | MudBlazor `Info` light |
| Blue | `blue/700` | `#2F6399` | Info text light |
| Blue | `blue/900` | `#1F3550` | Info subtle dark |
| Overlay | `black/48` | `rgba(0,0,0,.48)` | Scrim/modal |

### 3.2 Semantic colors

CSS: `var(--jl-color-<group>-<name>)`, ví dụ `color/bg/brand-subtle` → `var(--jl-color-bg-brand-subtle)`.

| Semantic token | Light | Dark | Vai trò |
|---|---:|---:|---|
| `color/bg/canvas` | `#FFFCF7` | `#1D1917` | Nền ứng dụng |
| `color/bg/surface` | `#FFFFFF` | `#2A2421` | Card, panel, input |
| `color/bg/surface-subtle` | `#FBF5EC` | `#3A312D` | Vùng phụ, hover |
| `color/bg/surface-raised` | `#FFFFFF` | `#3A312D` | Popover, elevated panel |
| `color/bg/brand` | `#773B8E` | `#914FA7` | Primary action |
| `color/bg/brand-hover` | `#5F2E72` | `#773B8E` | Hover/pressed |
| `color/bg/brand-subtle` | `#F8F2FA` | `#34183F` | Selected/brand tint |
| `color/bg/accent` | `#D58522` | `#F0BD5A` | Highlight/action phụ |
| `color/bg/accent-subtle` | `#FFF8E8` | `#49351F` | Highlight area |
| `color/bg/success` | `#EDF8F2` | `#234333` | Published/success |
| `color/bg/warning` | `#FFF8E8` | `#49351F` | Draft/attention |
| `color/bg/danger` | `#FFF0EE` | `#542C29` | Error/destructive |
| `color/bg/info` | `#EEF6FF` | `#1F3550` | Thông tin trung tính |
| `color/text/primary` | `#1D1917` | `#FFFCF7` | Tiêu đề, nội dung chính |
| `color/text/secondary` | `#574A43` | `#C9BDB3` | Metadata |
| `color/text/muted` | `#6D5E56` | `#AA9A8F` | Placeholder, chú thích, số thứ tự |
| `color/text/disabled` | `#8A7A70` | `#8A7A70` | Disabled (không áp yêu cầu contrast) |
| `color/text/on-brand` | `#FFFFFF` | `#FFFFFF` | Trên brand fill |
| `color/text/on-accent` | `#1D1917` | `#1D1917` | Trên amber fill |
| `color/text/brand` | `#5F2E72` | `#DFC3E7` | Brand text |
| `color/text/link` | `#773B8E` | `#DFC3E7` | Link |
| `color/text/success` | `#2D7B57` | `#B1E1C7` | Success text |
| `color/text/warning` | `#8F4E13` | `#F8D88F` | Warning text |
| `color/text/danger` | `#B74B43` | `#F0A49D` | Error text |
| `color/text/info` | `#2F6399` | `#94BFEF` | Info text |
| `color/border/default` | `#E2D9D2` | `#574A43` | Border thường |
| `color/border/strong` | `#C9BDB3` | `#6D5E56` | Divider/input border |
| `color/border/brand` | `#773B8E` | `#914FA7` | Brand border |
| `color/border/focus` | `#914FA7` | `#F0BD5A` | Focus ring |
| `color/border/danger` | `#B74B43` | `#F0A49D` | Error field |
| `color/icon/default` | `#574A43` | `#C9BDB3` | = text/secondary |
| `color/icon/muted` | `#6D5E56` | `#AA9A8F` | = text/muted |
| `color/icon/on-brand` | `#FFFFFF` | `#FFFFFF` | Icon trên brand |
| `color/icon/brand` | `#773B8E` | `#DFC3E7` | = text/link |
| `color/icon/success` | `#2D7B57` | `#B1E1C7` | = text/success |
| `color/icon/danger` | `#B74B43` | `#F0A49D` | = text/danger |
| `color/overlay/scrim` | `rgba(0,0,0,.48)` | `rgba(0,0,0,.48)` | Modal/sheet scrim |

Ghi chú:

- Cặp status (`bg/*` + `text/*`) dùng cho badge, alert nền nhẹ: nền tối + chữ sáng ở dark để chữ rõ trên badge.
- MudBlazor `Success`/`Warning`/`Error`/`Info` trong `PaletteDark` (`#82C9A6`, `#F8D88F`, `#F0A49D`, `#94BFEF`) là màu hành động/fill của component Mud, không phải token chữ trên nền subtle. Component sản phẩm như `JoyleeStatusBadge` dùng cặp semantic ở trên.
- Contrast đã tính: `text/muted` light ≈ 6.1:1 trên canvas, ≈ 5.7:1 trên surface-subtle; dark ≈ 6.4:1 trên canvas, ≈ 4.6:1 trên surface-subtle. `text/info` light ≈ 5.7:1 trên `bg/info`.

### 3.3 Spacing and dimensions

Base unit: **4 px**. CSS: `var(--jl-space-4)`, `var(--jl-radius-md)`, `var(--jl-control-m)`, `var(--jl-size-icon-m)`.

| Token | Value | Dùng cho |
|---|---:|---|
| `space/0` | 0 | Reset |
| `space/1` | 4 | Icon gap nhỏ |
| `space/2` | 8 | Inline spacing |
| `space/3` | 12 | Control content |
| `space/4` | 16 | Mobile padding |
| `space/5` | 20 | Card padding |
| `space/6` | 24 | Section gap nhỏ |
| `space/8` | 32 | Section gap |
| `space/10` | 40 | Hero/card group |
| `space/12` | 48 | Desktop section |
| `space/16` | 64 | Desktop page rhythm |

| Token | Value | CSS |
|---|---:|---|
| `radius/none` | 0 | — |
| `radius/sm` | 6 | `--jl-radius-sm` |
| `radius/md` | 10 | `--jl-radius-md` (mặc định MudBlazor) |
| `radius/lg` | 16 | `--jl-radius-lg` |
| `radius/xl` | 24 | `--jl-radius-xl` |
| `radius/full` | 999 | `--jl-radius-full` |
| `size/control/s` | 36 | `--jl-control-s` |
| `size/control/m` | 44 | `--jl-control-m` |
| `size/control/l` | 52 | `--jl-control-l` |
| `size/icon/s` | 16 | `--jl-size-icon-s` |
| `size/icon/m` | 20 | `--jl-size-icon-m` |
| `size/icon/l` | 24 | `--jl-size-icon-l` |
| `size/touch/min` | 44 | = `--jl-control-m` |
| `focus/width` | 2 | `--jl-focus-width` |
| `focus/offset` | 3 | `--jl-focus-offset` |
| `focus/inset` | −2 | `--jl-focus-inset` |
| `width/reader/compact` | 560 | `--jl-reader-compact` |
| `width/reader/comfortable` | 720 | `--jl-reader-comfortable` |

### 3.4 Typography

**Inter** dùng cho UI, navigation, form và dashboard. **Literata** dùng cho nội dung chương, trích dẫn, preview đọc và tiêu đề trên bìa fallback (`JoyleeCover`).

| Text style | Font | Size / line-height | CSS | Use case |
|---|---|---:|---|---|
| `Display/Brand` | Inter Bold | 48 / 56 | `--jl-type-display-*` | Landing hero |
| `Heading/H1` | Inter Bold | 36 / 44 | `--jl-type-h1-*` | Page title |
| `Heading/H2` | Inter Semi Bold | 28 / 36 | `--jl-type-h2-*` | Section title |
| `Heading/H3` | Inter Semi Bold | 22 / 30 | `--jl-type-h3-*` | Card group/dialog title |
| `Body/Large` | Inter Regular | 18 / 28 | `--jl-type-body-lg-*` | Lead text |
| `Body/Medium` | Inter Regular | 16 / 24 | `--jl-type-body-md-*` | UI body |
| `Body/Small` | Inter Regular | 14 / 20 | `--jl-type-body-sm-*` | Metadata/helper |
| `Label/Medium` | Inter Medium/Semi Bold | 14 / 20 | `--jl-type-label-*` | Button (600), field label (500) |
| `Caption` | Inter Medium | 12 / 16 | `--jl-type-caption-*` | Badge, timestamp |
| `Reader/Mobile` | Literata Regular | 18 / 30 | `--jl-reader-size/leading` (< 600 px) | Nội dung mobile |
| `Reader/Desktop` | Literata Regular | 20 / 34 | `--jl-reader-size/leading` | Nội dung desktop |
| `Reader/Emphasis` | Literata SemiBold | 20 / 34 | — | Nhấn mạnh |
| `Reader/Quote` | Literata Italic | 20 / 34 | — | Trích dẫn |

Mỗi style có cặp biến `-size` và `-leading`, ví dụ `font-size: var(--jl-type-body-md-size); line-height: var(--jl-type-body-md-leading)`.

Brand details:

- Heading H1–H3: letter-spacing `-0.03em` (`--jl-type-heading-tracking`); H1 co giãn `clamp(1.875rem, 4vw, 2.25rem)`.
- Eyebrow (`.jl-eyebrow`): 12 px, 600, letter-spacing `0.15em`, uppercase, màu `text/brand`.
- Button không viết hoa (`text-transform: none`).

Quy tắc đọc:

- Desktop: 56–75 ký tự mỗi dòng, cột nội dung 560–720 px.
- Mobile: padding ngang 20 px, cỡ chữ mặc định 18 px, line-height 30 px.
- Khoảng cách đoạn: 0.75–1 lần line-height; không căn đều hai lề.
- Người dùng được đổi font size, line-height, width và theme nhưng không giảm dưới 16 px. Reader settings chỉ cần ghi đè `--jl-reader-size`, `--jl-reader-leading` và chiều rộng cột.

### 3.5 Elevation and motion

| Style | CSS | Use case |
|---|---|---|
| `Elevation/Sm` | `--jl-shadow-sm` = `0 1px 2px rgba(29,25,23,.08)` | Story card |
| `Elevation/Md` | `--jl-shadow-md` = `0 8px 24px rgba(29,25,23,.12)` | Dropdown/popover, cover hover |
| `Elevation/Lg` | `--jl-shadow-lg` = `0 20px 48px rgba(29,25,23,.18)` | Modal/sheet |

Không dùng `Elevation` của MudBlazor lớn hơn 1 hoặc bóng `rgba(0,0,0,…)` tự viết.

Motion:

| Token | Value | Dùng cho |
|---|---:|---|
| `--jl-motion-fast` | 140ms | Micro interaction: hover, màu, focus |
| `--jl-motion-base` | 220ms | Panel, sheet, dialog |
| `--jl-ease-out` | `cubic-bezier(.2,0,0,1)` | Easing mặc định |

- Không animation cho nội dung văn bản khi chuyển chương.
- Tôn trọng `prefers-reduced-motion` trên web (đã có trong `base.css`) và reduce motion của hệ điều hành trên mobile.

## 4. Responsive system

### Breakpoints

| Name | Range | Behavior |
|---|---:|---|
| Mobile | `< 600` | 1 cột, bottom navigation, modal thành bottom sheet |
| Tablet | `600–1023` | 2 cột, navigation rail khi phù hợp |
| Desktop | `1024–1439` | Header/sidebar, content grid 12 cột |
| Wide | `≥ 1440` | Max content width 1280 px, không kéo giãn reader |

Breakpoint CSS sản phẩm 600/1024/1440 độc lập với breakpoint có sẵn của MudBlazor.

### Grid

- Mobile: 4 columns, margin 16 px, gutter 16 px.
- Tablet: 8 columns, margin 24 px, gutter 20 px.
- Desktop: 12 columns, margin 32–64 px, gutter 24 px.
- Reader không bám grid toàn trang; luôn dùng cột đọc độc lập 560–720 px.
- `.jl-container`: `min(100% - 32/48/64px, 1280px)` theo breakpoint; `.jl-series-grid`: 1/2/3/4 cột.

## 5. Core component contracts

### Trạng thái triển khai web

| Contract | Component web | Trạng thái | Còn thiếu |
|---|---|---|---|
| 5.1 Button | `Shared/JoyleeButton` | Implemented | — |
| 5.2 Icon Button / Toggle | `Shared/JoyleeIconButton` | Partial | Toggle state (bookmark, follow) |
| 5.3 Text Field / Search | `Shared/JoyleeSearchField` | Partial | Loading state, phím tắt `/` |
| 5.4 Chip / Badge | `Shared/JoyleeStatusBadge` | Partial | Filter Chip dùng chung |
| 5.5 Avatar | `Shared/JoyleeAvatar` (Profile, menu tài khoản); `MudAvatar` trong Admin/Studio | Partial | Thay `MudAvatar` còn lại trong Admin/Studio/Comment bằng `JoyleeAvatar` |
| 5.6 Story Card | `Shared/Series/SeriesCard`, `JoyleeCover`, `SeriesSkeleton` | Partial | Variant List/Compact, rating, bookmark |
| 5.7 Chapter Row | `Shared/ChapterItem` | Partial | Author mode (drag handle, publish status) |
| 5.8 Reader Toolbar | `Pages/Chapter/Read` | Partial | Settings bottom sheet, auto-hide mobile |
| 5.9 Navigation | `Layout/Header`, `NavMenu`, `AdminLayout`, `AuthorStudioLayout` | Partial | Bottom navigation mobile |
| 5.10 Feedback | `Shared/JoyleeFeedback`, `JoyleeDialog` | Partial | Toast pattern, report flow |
| Stat Card (mở rộng) | `Shared/JoyleeStatCard` (Profile, Thống kê đọc) | Implemented | Thay tile `user-stat` ở Admin Users |

`Shared/ReadingBookCard` không theo contract (Elevation 3, style inline, bìa không 2:3). Không dùng cho màn hình mới; sẽ thay bằng variant của `SeriesCard`.

### 5.1 Button

- Variants: `Primary` (Filled), `Secondary` (Outlined), `Ghost` (Text), `Danger`.
- Sizes: `S=36`, `M=44`, `L=52`; trên mobile `S` nâng lên 44.
- States: `Default`, `Hover`, `Pressed`, `Focus`, `Disabled`, `Loading` (`aria-busy`, spinner trước label).
- Properties: label text, leading icon, trailing icon, full-width.
- Mobile sử dụng tối thiểu 44 px; nút chính trong form mobile mặc định full-width.
- Mỗi màn hình chỉ có một hành động `Primary` nổi trội trong cùng vùng.

### 5.2 Icon Button / Toggle

- Visual size 20–24 px trong touch target tối thiểu 44 × 44 px.
- Variants: `Ghost`, `Subtle`, `Brand`.
- Toggle states cho bookmark, like/reaction, follow và theme; dùng `aria-pressed`.
- Luôn có tooltip trên web và semantic label trên Flutter.

### 5.3 Text Field / Search

- Anatomy: label, input, optional leading icon, optional trailing action, helper/error.
- States: default, hover, focus, filled, disabled, error.
- Control height 44 px; textarea min-height 120 px.
- Search có clear action, loading state và keyboard shortcut trên desktop.
- Không dùng placeholder thay cho label ở form đăng ký/đăng nhập/chỉnh sửa.

### 5.4 Chip / Badge

- `Filter Chip`: selectable (`aria-pressed`); dùng cho genre và filter. Selected: nền `bg/brand-subtle`, chữ `text/brand`, viền `border/brand`.
- `Status Badge`: non-interactive; `Draft`, `Published`, `Locked`, `Banned`, `New`.
- `Tag`: metadata ngắn; không dùng quá ba tag trên Story Card.
- Height 28–32 px, radius full, Caption 12/16 weight 600.

`JoyleeStatusBadge` trên web:

| `Tone` | Nền | Chữ | Ví dụ |
|---|---|---|---|
| `neutral` (mặc định) | `bg/surface-subtle` | `text/secondary` | Đã đọc |
| `brand` | `bg/brand-subtle` | `text/brand` | Đang đọc, Đang tiến hành |
| `success` | `bg/success` | `text/success` | Hoàn thành, Hoạt động |
| `warning` | `bg/warning` | `text/warning` | Chưa xuất bản |
| `danger` | `bg/danger` | `text/danger` | Đã khóa |
| `info` | `bg/info` | `text/info` | Thông tin |

Tham số `Icon` (tùy chọn) thêm icon 16 px trước label; dùng khi badge đứng cạnh badge khác cùng màu hoặc khi trạng thái quan trọng.

### 5.5 Avatar

- Sizes: 24, 32, 40, 64, 96 px.
- Fallback initials trên nền brand-subtle.
- Có status ring cho creator/admin khi thật sự cần; không dùng decoration mặc định.

### 5.6 Story Card

- Variants: `Grid`, `List`, `Compact`.
- Cover ratio: **2:3** (`JoyleeCover`; ảnh lỗi hiển thị fallback Literata).
- Anatomy: cover, title tối đa 2 dòng, author, rating, genres, chapter count/update time, bookmark toggle.
- `Grid`: khám phá/home; `List`: search/history; `Compact`: sidebar/recommendation.
- Reading progress dùng progress bar 4 px và label chương gần nhất.
- Không đặt cả description dài, genres, rating và nhiều button cùng lúc trên card mobile.
- Hover chỉ đổi bóng của cover (`--jl-shadow-md`) và màu tiêu đề; không dịch chuyển card.

### 5.7 Chapter Row

- Anatomy: chapter number/title, status, update time, optional lock icon, overflow menu.
- Author mode thêm drag handle, publish status và reorder affordance.
- Reader mode nhấn toàn hàng để mở chương; chapter đã đọc dùng text secondary; chương đang đọc nền `bg/brand-subtle`.
- Chương mới (≤ 72 giờ) có chấm `bg/accent` kèm `aria-label`.
- Locked chapter phải giải thích lý do khi người dùng tương tác.

### 5.8 Reader Toolbar

- Desktop: thanh sticky gọn ở top hoặc cạnh cột đọc.
- Mobile: top app bar tối giản; settings mở bottom sheet.
- Controls: previous/next chapter, chapter list, bookmark, theme, font size, line-height, content width.
- Auto-hide chỉ trên mobile khi cuộn xuống; xuất hiện lại khi cuộn lên hoặc chạm màn hình.
- Progress được lưu âm thầm; chỉ hiện toast khi lỗi đồng bộ.

### 5.9 Navigation

- Web reader: logo, Discover, Library, Write, Search, Notifications, Profile.
- Web author/admin: left sidebar; không nhồi chức năng quản trị vào header đọc truyện.
- Mobile bottom navigation: `Khám phá`, `Tìm kiếm`, `Thư viện`, `Cá nhân`; action `Viết` nằm ở profile/creator entry hoặc FAB có ngữ cảnh.
- Badge notification dùng số tối đa `99+`.
- Link đang chọn: chữ `text/link`, gạch dưới 2 px `bg/brand`.

### 5.10 Feedback and status

- Toast: success/info không chặn; 4–6 giây.
- Dialog: xác nhận delete, unpublish, ban/unban.
- Bottom sheet: reader settings, mobile filters, chapter actions.
- Empty state: một minh họa đơn giản, title, mô tả, tối đa một CTA chính.
- Error state (`JoyleeFeedback Error`): `role="alert"`, mô tả không lộ chi tiết kỹ thuật, nút `Thử lại` dạng Secondary.
- Skeleton giữ đúng kích thước Story Card/Chapter Row để tránh layout shift.
- Report comment là flow riêng có reason, optional detail và confirmation.

### Extension components

Sau v1 nên bổ sung `Comment Item`, `Reaction Bar`, `Tabs` (hiện có dạng riêng `.cl-tabs` trong danh sách chương), `Pagination`, `Stat Card`, `Data Table`, `Dropdown`, `Checkbox`, `Switch`, `File/Cover Upload` và `Rich Text Chapter Editor`.

## 6. Information architecture

| Domain | Screens / flows |
|---|---|
| Authentication | Sign in, Sign up, Forgot/Reset password, Change password |
| Discovery | Home, Genres, Search results, Story detail |
| Reading | Chapter reader, Chapter list, Reading progress, History, Bookmarks |
| Profile/social | Profile, Edit profile, Stories, Comments, Followers, Following, Reading statistics |
| Author Studio | Dashboard, Create/Edit story, Chapter list, Chapter editor, Reorder, Publish/Unpublish, Lock/Unlock |
| Community | Chapter comments, Edit/Delete comment, Reactions, Report flow |
| Notifications | Notification list, unread filter, mark all seen |
| Admin | System statistics, Users, Create/Update/Delete/Ban user, Genres CRUD |

## 7. Reference screen set

Design system nên được kiểm chứng bằng các màn hình sau:

1. **Discover/Home — desktop:** hero nhỏ, continue reading, trending stories, genres.
2. **Search — desktop/mobile:** search field, filter chips, sort, Story Card list/grid.
3. **Story Detail — desktop/mobile:** cover, metadata, rating, bookmark, chapter list.
4. **Reader — desktop/mobile:** cột Literata, reader toolbar, progress và comment entry.
5. **Library — mobile:** reading list, bookmarks, history tabs.
6. **Profile — desktop/mobile:** profile header, stats, stories/comments/follow graph.
7. **Author Studio — desktop:** sidebar, stories table/cards, status và analytics.
8. **Chapter Editor — desktop:** title, editor, autosave state, publish action.
9. **Notifications — mobile:** grouped list, unread states.
10. **Admin Dashboard — desktop:** stat cards, chart placeholders, users/genres tables.

Stitch Story Detail tham chiếu: screen `e236f699291141949fa852aa12a16553`, project `18202587658350678725`. Chỉ triển khai phần có dữ liệu Series; không thêm nội dung giả cho các service chưa tích hợp.

## 8. Feature behavior rules

- Publish/unpublish, delete, ban/unban là hành động có hậu quả; luôn xác nhận và mô tả tác động.
- Reorder chapter dùng drag-and-drop trên desktop, drag handle rõ ràng trên mobile; có nút save/cancel hoặc autosave status.
- Rating dùng thang 1–5; người dùng thấy rating của mình và có thể cập nhật.
- Follow/bookmark/reaction là optimistic UI, nhưng rollback và báo lỗi nếu API thất bại.
- Notification unread dùng cả dot + font weight, không chỉ màu.
- Progress đọc cập nhật theo chapter và vị trí; đồng bộ đa thiết bị nhưng không làm gián đoạn việc đọc.

## 9. Accessibility

- Contrast text thường tối thiểu 4.5:1; text lớn tối thiểu 3:1.
- Focus indicator: `outline: var(--jl-focus-width) solid var(--jl-color-border-focus)`, tương phản 3:1 với vùng xung quanh.
  - Control độc lập (button, link, input): `outline-offset: var(--jl-focus-offset)`.
  - Hàng trong danh sách và tab (phần tử chạm mép container có `overflow: hidden`): `outline-offset: var(--jl-focus-inset)`.
  - Field MudBlazor outlined: `box-shadow: 0 0 0 var(--jl-focus-width) var(--jl-color-border-focus)`.
- Touch target tối thiểu 44 × 44 px.
- Không dùng màu làm tín hiệu trạng thái duy nhất; thêm icon/label.
- Reader hỗ trợ zoom, đổi font size, line-height, theme và reduced motion.
- Web có skip link, landmark đúng và thứ tự tab hợp lý.
- Flutter thêm `Semantics`, tooltip và label cho icon-only controls.
- Cover image có alt text dạng `Bìa truyện {title}`; decorative artwork dùng alt rỗng.

## 10. Code mapping

### Naming convention

| Layer | Figma | CSS / Blazor | Flutter |
|---|---|---|---|
| Semantic color | `color/bg/canvas` | `var(--jl-color-bg-canvas)` | `context.colors.bgCanvas` (`AppColors.bgCanvas`) |
| Spacing | `space/4` | `var(--jl-space-4)` | `AppDimensions.space4` |
| Radius | `radius/md` | `var(--jl-radius-md)` | `AppDimensions.radiusMd` |
| Typography | `Body/Medium` | `var(--jl-type-body-md-size)` / `-leading` | `Theme.of(context).textTheme.bodyMedium` (chưa có class type riêng) |
| Elevation | `Elevation/Md` | `var(--jl-shadow-md)` | Chưa có token; `Card` dùng `elevation: 0` + viền `borderDefault` |
| Motion | `motion/fast` | `var(--jl-motion-fast)` | Chưa có token |

### Blazor theme strategy

- `Theme/JoyleeTheme.cs` định nghĩa `PaletteLight`/`PaletteDark` và typography cho `MudThemeProvider`. `InitialPaletteCss` sinh cùng palette dưới dạng `html[data-theme='light'|'dark']` cho first paint trước khi circuit kết nối.
- `wwwroot/css/tokens.css` ánh xạ `--jl-*` sang `--mud-palette-*` khi có, và khai báo các token không có trong MudBlazor (brand-subtle, status subtle, info, spacing, type, motion, focus). Giá trị dark ghi đè trong `html[data-theme='dark']`.
- Theme Sáng/Tối/Hệ thống đồng bộ `data-theme` tại `html` với `MudThemeProvider`; preference lưu local trên trình duyệt.
- Component và page chỉ dùng semantic variable, không tham chiếu primitive hay hex trực tiếp, không dùng `style=""` cho màu/spacing.
- Thứ tự stylesheet: `tokens.css` → `base.css` → `layout.css` → `mud-overrides.css` → `site.css` → scoped CSS.
- State class thống nhất: `.is-hovered`, `.is-pressed`, `.is-selected`, `.is-disabled`, `.is-loading`, `.is-current`, `.is-read` khi state không thể biểu diễn bằng pseudo-class.
- Ưu tiên component MudBlazor gốc; wrapper `Joylee*` chỉ thêm default sản phẩm. Chi tiết chạy và kiểm tra: README của repo frontend web.

### Flutter theme strategy

Nguồn sự thật trên mobile: `lib/ui/core/themes/app_colors.dart`, `app_dimensions.dart`, `app_theme.dart`. Chi tiết triển khai: [Flutter-Mobile-Design-System.md](Flutter-Mobile-Design-System.md).

- `AppColors extends ThemeExtension<AppColors>`, có `AppColors.light` và `AppColors.dark` với cùng field names, đăng ký qua `extensions: [colors]` trong `AppTheme.light` / `AppTheme.dark` (Material 3).
- Widget đọc màu bằng extension `context.colors` (= `Theme.of(context).extension<AppColors>()`, fallback `AppColors.light`).
- `AppDimensions` (abstract final class, hằng `double`) chứa spacing, radius và kích thước control.
- Không đặt hex trực tiếp trong widget nghiệp vụ.

Ánh xạ field `AppColors` sang semantic token:

| `AppColors` | Semantic token | Ghi chú |
|---|---|---|
| `bgCanvas` | `color/bg/canvas` | |
| `bgSurface` | `color/bg/surface` | |
| `bgSurfaceSubtle` | `color/bg/surface-subtle` | |
| `primaryBrand` | `color/bg/brand` | |
| `primaryBrandDark` | `color/bg/brand-hover` | |
| `accent` | `color/bg/accent` | |
| `textPrimary` | `color/text/primary` | |
| `textSecondary` | `color/text/secondary` | |
| `textDisabled` | `color/text/disabled` | |
| `textOnBrand` | `color/text/on-brand` | |
| `borderDefault` | `color/border/default` | |
| `borderFocus` | `color/border/focus` | |
| `success` | `color/text/success` | Dark đang dùng `#82C9A6` (MudBlazor `Success`) thay vì `#B1E1C7` |
| `warning` | `color/text/warning` | |
| `danger` | `color/text/danger` | |

`AppDimensions`: `space1`–`space6`, `space8` (= `space/1`–`space/8`), `radiusSm`, `radiusMd`, `radiusLg`, `radiusFull`, `controlHeight` (44 = `size/control/m`), `minTouchTarget` (48, chuẩn Material 3, lớn hơn `size/touch/min` 44).

Chưa có trên mobile, bổ sung khi feature cần: các token `bg/brand-subtle`, `bg/accent-subtle`, `bg/success|warning|danger|info`, `text/muted`, `text/brand`, `text/link`, `text/info`, `border/strong`, `space/10`+, `radius/xl`, typography Inter/Literata, elevation và motion. Khi thêm field mới vào `AppColors`, cập nhật đồng thời `light`, `dark`, `copyWith`, `lerp` và bảng trên.

## 11. Definition of done (web)

- Build và test component thành công.
- Kiểm tra browser light/dark, keyboard/focus, mobile (< 600 px), ảnh lỗi, loading/empty/error và dữ liệu thật qua gateway.
- Không có hex, `rgba(0,0,0,…)` hay `style=""` mới trong page/component; token mới có trong `tokens.css` và bảng §3.
- Reader desktop/mobile đạt width, type scale và contrast đã định nghĩa.
- Mapping CSS/Flutter có cùng ý nghĩa và naming ổn định.
- Cập nhật bảng trạng thái §5 khi thêm hoặc hoàn thiện component.

## 12. Changelog

### v1.1 — 2026-10-07

- Đồng bộ bảng §3.2 với code: giá trị dark của status, `accent-subtle`, `text/link`, `border/danger`, `icon/*`; `text/disabled` light `#8A7A70`.
- `text/muted` tách khỏi `text/secondary`: light `#6D5E56`, dark `#AA9A8F`.
- Thêm primitive `amber/900`, `green/200|300|900`, `red/300|900`, `blue/300|700|900`; thêm cặp `bg/info` + `text/info`.
- Thêm token CSS: type scale `--jl-type-*`, `--jl-shadow-lg`, motion, focus, icon size, reader size/leading.
- `JoyleeStatusBadge` dùng cặp semantic status thay vì màu `MudChip`; thêm tone `info` và tham số `Icon`.
- Bảng trạng thái triển khai component (§5), quy tắc focus ring (§9), brand details (§3.4).
- Tách cấu trúc file Figma, DoD Figma và tiến độ sang `docs/Design-Figma.md`.

### v1.0

- Phiên bản đầu: foundations, component contracts, IA, reference screens.
