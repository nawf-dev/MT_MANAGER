# Changelog

All notable changes to MT_MANAGER will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-02-07

### Added
- **Core Position Management**
  - Unified TP/SL setting for all positions on current symbol
  - Interactive input boxes with Enter key support
  - Auto-detection of existing TP/SL from positions on startup
  - One-click Close All button

- **Real-Time Monitoring**
  - Live profit/loss tracking in account currency (USD/EUR/etc)
  - Profit/loss calculation in pips
  - Total positions count display
  - Total lot size display
  - Real-time spread monitoring in pips
  - Candle close countdown (HH:MM:SS format)
  - Market close countdown (until Friday 23:59)
  - Market open countdown (during weekends until Monday 00:00)

- **Automation Features**
  - Auto Close at Time: Close all positions at specified time daily
  - Auto Entry After Weekend: Open position when market reopens Monday
  - Smart entry execution (waits for price to reach entry level)

- **User Interface**
  - Clean borderless panel design
  - Dual panel layout (controls left, info right)
  - Color-coded information (green=profit, red=loss, yellow=alerts)
  - Non-intrusive display

- **Documentation**
  - Comprehensive README.md
  - MIT License file
  - Changelog file
  - Installation guide
  - Usage scenarios
  - FAQ section

### Technical Details
- Language: MQL5
- Platform: MetaTrader 5
- Lines of Code: ~1,250
- Dependencies: Trade.mqh (standard library)

### Configuration Options
- TargetTP: Default TP price (default: 0.0 = auto-detect)
- TargetSL: Default SL price (default: 0.0 = auto-detect)
- EnableAutoClose: Enable auto-close feature (default: false)
- AutoCloseTime: Time to close all positions (default: "23:00")
- EnableAutoEntry: Enable auto-entry feature (default: false)
- EntryType: BUY or SELL (default: ORDER_TYPE_BUY)
- EntryPrice: Target entry price (default: 0.0)
- EntryLot: Lot size for auto-entry (default: 0.01)
- EntryTPPips: TP in pips from entry (default: 30)
- EntrySLPips: SL in pips from entry (default: 20)

### Known Issues
- None reported

---

## [Unreleased]

### Planned for v2.0
- Break Even automation
- Trailing Stop
- Partial Close functionality
- Magic Number filtering
- Account info panel
- One-click trading
- Session time indicator
- Max drawdown protection
- Sound alerts
- Email/Telegram notifications
- Daily statistics
- Correlation monitor

---

## Version History Summary

- **v1.0.0** (2025-02-07) - Initial stable release with core features

---

**Note:** For detailed information about each version, see the [README](README.md) roadmap section.
