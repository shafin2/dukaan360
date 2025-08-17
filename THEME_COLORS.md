# Theme Configuration for Dukaan360
# This file documents all available theme colors and CSS custom properties

## CSS Custom Properties (defined in app/assets/tailwind/application.css)

### Primary Colors
- `--color-primary`: 59 130 246 (blue-500)
- `--color-primary-hover`: 37 99 235 (blue-600)  
- `--color-primary-light`: 219 234 254 (blue-100)

### Secondary Colors
- `--color-secondary`: 100 116 139 (slate-500)
- `--color-secondary-hover`: 71 85 105 (slate-600)
- `--color-secondary-light`: 241 245 249 (slate-100)

### Success Colors
- `--color-success`: 34 197 94 (green-500)
- `--color-success-hover`: 22 163 74 (green-600)
- `--color-success-light`: 220 252 231 (green-100)

### Warning Colors
- `--color-warning`: 245 158 11 (amber-500)
- `--color-warning-hover`: 217 119 6 (amber-600)
- `--color-warning-light`: 254 243 199 (amber-100)

### Danger Colors
- `--color-danger`: 239 68 68 (red-500)
- `--color-danger-hover`: 220 38 38 (red-600)
- `--color-danger-light`: 254 226 226 (red-100)

### Info Colors
- `--color-info`: 14 165 233 (sky-500)
- `--color-info-hover`: 2 132 199 (sky-600)
- `--color-info-light`: 224 242 254 (sky-100)

### Background Colors
- `--color-background`: 255 255 255 (white)
- `--color-background-alt`: 249 250 251 (gray-50)
- `--color-surface`: 255 255 255 (white)

### Text Colors
- `--color-text-primary`: 17 24 39 (gray-900)
- `--color-text-secondary`: 75 85 99 (gray-600)
- `--color-text-muted`: 156 163 175 (gray-400)

### Border Colors
- `--color-border`: 229 231 235 (gray-200)
- `--color-border-light`: 243 244 246 (gray-100)

## Tailwind Classes (Extended Colors in tailwind.config.js)

### Usage Examples:
```html
<!-- Using Tailwind extended colors -->
<div class="bg-primary-500 text-white">Primary Background</div>
<div class="bg-success-100 text-success-800">Success Light Background</div>

<!-- Using custom utility classes -->
<div class="bg-theme text-theme-primary">Themed Background</div>
<div class="border-theme">Themed Border</div>

<!-- Using component classes -->
<button class="btn-primary">Primary Button</button>
<div class="alert-success">Success Alert</div>
```

## Component Classes Available:

### Buttons:
- `.btn-primary`
- `.btn-secondary`
- `.btn-success`
- `.btn-warning`
- `.btn-danger`

### Alerts:
- `.alert-success`
- `.alert-warning`
- `.alert-danger`
- `.alert-info`

### Theme Utilities:
- `.text-theme-primary`
- `.text-theme-secondary`
- `.text-theme-muted`
- `.bg-theme`
- `.bg-theme-alt`
- `.bg-theme-surface`
- `.border-theme`
- `.border-theme-light`

## Dark Mode Support:
Dark mode variables are automatically applied when `prefers-color-scheme: dark` is detected.

## Customization:
To change theme colors, modify the CSS custom properties in `app/assets/tailwind/application.css` and rebuild with:
```bash
bundle exec tailwindcss -i ./app/assets/tailwind/application.css -o ./app/assets/builds/tailwind.css --config tailwind.config.js
```
