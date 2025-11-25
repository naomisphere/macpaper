# macpaper Quality of Life Improvements

This document outlines the quality of life improvements and enhancements made to [macpaper](https://github.com/naomisphere/macpaper) - The Wallpaper Manager for macOS.

## Acknowledgments

First and foremost, a huge thank you to [@naomisphere](https://github.com/naomisphere) for creating this amazing wallpaper manager! I use it daily and wanted to contribute some improvements that make the experience even better.

## New Features & Improvements

### Export with Custom Aspect Ratios

**Feature:** Export wallpapers in various device-specific aspect ratios with an interactive crop editor.

**What's New:**
- **Export Options:** Choose between "Original Size" or "Custom Aspect Ratio" when exporting
- **Interactive Crop Editor:** 
  - Visual crop overlay with grid lines (Rule of Thirds)
  - Pan and zoom functionality (1.0x - 3.0x)
  - Sidebar with all available aspect ratios
  - Real-time preview of crop area
  - Precise cropping without image distortion

**Supported Aspect Ratios:**
- **iPhone:** 15 Pro Max, 15 Pro, 14 Pro, 13 Pro, SE
- **iPad:** Pro 12.9", Pro 11"
- **Desktop:** 4K UHD, 1440p, 1080p, Ultrawide 21:9

**How to Use:**
1. Open the Wallpapers tab
2. Click the export button (blue arrow) on any wallpaper
3. Select "Custom Aspect Ratio"
4. Choose your desired device/ratio from the sidebar
5. Adjust the crop area by dragging and zooming
6. Click "Apply" to save

### Browse View Enhancements

**New Feature: Resolution Filter**
- **Filter by Resolution:** Filter wallpapers by their resolution in the Browse tab
- **Available Options:**
  - HD (1280×720)
  - Full HD (1920×1080)
  - WQHD (2560×1440)
  - 4K UHD (3840×2160)
  - All Resolutions (default)
- **Smart Filtering:** Uses pixel count ranges to match similar resolutions
- **Consistent UI:** Uses segmented control like other filters (Category, Purity)
- **Apply on Demand:** Filter is applied when clicking "Apply Filters" button

**How to Use:**
1. Open the Browse tab
2. Click the filter icon (slider icon)
3. Select your desired resolution from the segmented control
4. Click "Apply Filters" to see filtered results

### Enhanced Settings

**Improvements:**
- **Auto-Start:** Automatically launch macpaper when you log in option
- **Export Folder Selection:** Choose a default folder for exported wallpapers (defaults to Pictures folder)
- **Better UI:** Improved layout, spacing, and visual hierarchy (kinda)

### 🎯 Status Bar Menu Improvements

**What's Changed:**
- **Custom Icon:** Now uses the beautiful tear drop logo (`tear.png`) from the artwork folder
- **Better Organization:** 
  - "Open Manager" is prominently placed at the top
  - Wallpapers are organized in a submenu (less clutter)
  - Cleaner, more intuitive structure
- **Improved Labels:** Clearer descriptions for all menu items

###  Dock Integration

**Feature:** The app now appears in the Dock when the Manager window is open.

**Benefits:**
- Easy access to the app from the Dock
- Standard macOS window management
- No need to always use the status bar menu
- Window appears/disappears from Dock automatically

### Localization

**Added:** German (DE) localization support
- All new features are fully localized
- Existing translations maintained (EN, ES, PT-BR)

## Technical Improvements

### Crop Editor
- **Precise Cropping:** Uses Core Graphics for high-quality image processing
- **Aspect Ratio Preservation:** No image stretching or distortion
- **Smart Clamping:** Prevents crop area from going outside image bounds
- **Performance:** Optimized rendering and calculations

### Code Quality
- **Error Handling:** Proper error handling and user feedback

## 📝 Files Modified

### Core Application Files
- `app/main/ManagerApp.swift` - Export functionality, crop editor
- `app/main/macpaper.swift` - Status bar menu, dock integration, icon handling
- `app/main/Settings.swift` - Enhanced settings UI, auto-start, export folder
- `app/main/BrowseView.swift` - Resolution filter functionality


### Localization
- `lang/en.lproj/Localizable.strings` - New strings for all features
- `lang/de.lproj/Localizable.strings` - German translations
- `lang/es.lproj/Localizable.strings` - Spanish translations (updated)
- `lang/pt-BR.lproj/Localizable.strings` - Portuguese (Brazil) translations (updated)

## License

These improvements follow the same GPL-3.0 license as the original macpaper project.

## Credits

- **Original Developer:** [@naomisphere](https://github.com/naomisphere)
- **Project:** [macpaper](https://github.com/naomisphere/macpaper)
- **Support:** [Ko-fi](https://ko-fi.com/naomisphere)

---

**Note:** These improvements are quality of life enhancements that make daily use of macpaper more enjoyable. All changes maintain compatibility with the original codebase and follow the developer's coding style.

