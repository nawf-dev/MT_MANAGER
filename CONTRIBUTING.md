# Contributing to MT_MANAGER

First off, thank you for considering contributing to MT_MANAGER! 🎉

The following is a set of guidelines for contributing to this Expert Advisor. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Code Contributions](#code-contributions)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)
- [Community](#community)

---

## Code of Conduct

This project and everyone participating in it is governed by respect and professionalism. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/yourusername/mt_manager/issues) to avoid duplicates.

**How to submit a good bug report:**

1. **Use a clear and descriptive title**
2. **Provide detailed steps to reproduce**
   ```
   1. Open MT5
   2. Attach EA to EURUSD M15
   3. Click SET TP button
   4. See error...
   ```
3. **Describe expected behavior**
4. **Describe actual behavior**
5. **Provide environment details:**
   - MT5 Build number
   - Broker name
   - Operating System
   - EA version
6. **Add screenshots if applicable**
7. **Include relevant log output** from Experts tab

**Example Bug Report:**

```markdown
**Title:** SET TP button doesn't update positions

**Environment:**
- MT5 Build: 3802
- Broker: XM
- OS: Windows 11
- EA Version: 1.0.0

**Steps to Reproduce:**
1. Open 3 BUY positions on EURUSD
2. Type 1.09500 in TP input box
3. Click SET TP button
4. Check position properties

**Expected:** All 3 positions should have TP = 1.09500
**Actual:** Positions unchanged, no error in logs

**Screenshots:** [attach here]
**Logs:**
```
2025.02.07 10:30:45 MT_MANAGER EURUSD,M15: TP telah diset ke: 1.09500
```
```

---

### Suggesting Features

We love feature suggestions! Before creating a feature request:

1. Check the [Roadmap](README.md#roadmap) to see if it's already planned
2. Check [existing feature requests](https://github.com/yourusername/mt_manager/issues?q=label%3Aenhancement)

**How to suggest a feature:**

1. **Use tag:** `[FEATURE REQUEST]` in title
2. **Describe the problem** this feature would solve
3. **Describe the solution** you'd like to see
4. **Provide use cases** (real trading scenarios)
5. **Optional:** Suggest implementation details

**Example Feature Request:**

```markdown
**Title:** [FEATURE REQUEST] Add Break Even automation

**Problem:**
Manually moving SL to entry after profit is time-consuming and easy to forget.

**Proposed Solution:**
Add input parameter:
```mql5
input bool EnableBreakEven = false;
input int BreakEvenPips = 20;  // Move SL to entry after 20 pips profit
```

**Use Cases:**
1. Scalper opens 5 positions, wants zero risk after 15 pips profit
2. Swing trader wants to protect after 50 pips profit
3. News trader wants immediate protection after initial spike

**Benefits:**
- Automated risk management
- Never forget to move SL
- Peace of mind

**Implementation Notes:**
- Check profit on each tick
- Move SL only once (don't keep resetting)
- Add visual indicator when Break Even activated
```

---

## Code Contributions

### Getting Started

1. **Fork the repository**
   ```bash
   # Click "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/mt_manager.git
   cd mt_manager
   ```

3. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

4. **Make your changes**

5. **Test thoroughly** (see [Testing](#testing))

6. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: Break Even automation feature"
   ```

7. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Open Pull Request** on GitHub

---

## Style Guidelines

### MQL5 Code Style

**Naming Conventions:**

```mql5
// Variables: camelCase
int totalPositions = 0;
double currentPrice = 0.0;

// Constants: UPPER_CASE
#define BTN_SET_TP "BtnSetTP"
#define MAX_POSITIONS 100

// Functions: PascalCase
void CalculatePositionData() { ... }
string GetMarketCloseCountdown() { ... }

// Input parameters: PascalCase
input double TargetTP = 0.0;
input bool EnableAutoClose = false;
```

**Comments:**

```mql5
// Single line comment for simple explanations

//--- Section separator (use 3 dashes)
//--- Calculate profit/loss

//+------------------------------------------------------------------+
//| Function header comment block                                    |
//+------------------------------------------------------------------+
void MyFunction()
{
   // Implementation
}
```

**Indentation:**

- Use **3 spaces** (MQL5 standard)
- No tabs

**Braces:**

```mql5
// Opening brace on same line
if(condition)
{
   // code
}

// Function braces on new line
void MyFunction()
{
   // code
}
```

**Line Length:**

- Max 80-100 characters
- Break long lines logically

**Error Handling:**

```mql5
// Always check return values
if(trade.PositionModify(ticket, sl, tp))
{
   Print("Success");
}
else
{
   Print("Error: ", trade.ResultRetcodeDescription());
}
```

---

## Testing

Before submitting a Pull Request, please test:

### Manual Testing Checklist

- [ ] **Compilation:** Code compiles without errors/warnings
- [ ] **Basic functionality:** All buttons work
- [ ] **TP/SL setting:** Correctly modifies positions
- [ ] **Close All:** Closes all positions
- [ ] **Auto-close:** Triggers at specified time
- [ ] **Auto-entry:** Works on Monday open
- [ ] **Display updates:** Info panel shows correct data
- [ ] **Error handling:** Doesn't crash on invalid input
- [ ] **Multiple positions:** Works with 1, 5, 10+ positions
- [ ] **No positions:** Doesn't crash when no positions open

### Test Scenarios

1. **Test with demo account first**
2. **Test on different timeframes** (M1, M5, M15, H1, H4, D1)
3. **Test on different symbols** (EURUSD, GBPUSD, GOLD, etc.)
4. **Test with different brokers** (if possible)
5. **Test edge cases:**
   - No positions open
   - 1 position
   - 50+ positions
   - Invalid TP/SL inputs
   - Weekend mode
   - Market closed

### Backtesting

Not applicable for this EA (position management, not strategy).

### Performance Testing

- EA should not lag chart
- Should handle 100+ positions without slowdown
- Memory usage should be minimal

---

## Pull Request Process

1. **Update documentation** if needed (README.md, CHANGELOG.md)
2. **Add entry to CHANGELOG.md** under [Unreleased]
3. **Ensure all tests pass**
4. **Write clear PR description:**

**PR Template:**

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Enhancement
- [ ] Documentation update

## Changes Made
- Added Break Even automation
- Updated UI to show BE status
- Added new input parameters

## Testing
- [x] Tested on demo account
- [x] Tested with multiple positions
- [x] Tested on M15, H1, D1
- [x] No compilation errors

## Screenshots
[If applicable]

## Related Issues
Closes #123
```

5. **Wait for review**
6. **Address feedback** if requested
7. **Merge** (by maintainer)

---

## Git Commit Messages

**Format:**

```
Type: Short description (max 50 chars)

Longer description if needed (wrap at 72 chars)
Explain what and why, not how.

Closes #issue_number
```

**Types:**

- `Add:` New feature
- `Fix:` Bug fix
- `Update:` Improve existing feature
- `Refactor:` Code restructuring
- `Docs:` Documentation changes
- `Test:` Testing additions
- `Style:` Code formatting (no logic change)

**Examples:**

```
Add: Break Even automation feature

- Added EnableBreakEven input parameter
- Added BreakEvenPips configuration
- Moves SL to entry after specified profit
- Visual indicator when activated

Closes #42
```

```
Fix: Panel text overlapping on small screens

Adjusted spacing between labels in info panel.
Increased lineHeight from 20 to 24 pixels.

Closes #38
```

---

## Community

### Where to Ask Questions

- **GitHub Issues:** Bug reports and feature requests
- **GitHub Discussions:** General questions (if enabled)
- **MQL5 Forum:** Link your thread here

### Where NOT to Ask

- **Pull Requests:** Don't use PRs for questions
- **Email:** Use public channels for public benefit

---

## Recognition

Contributors will be recognized in:

- **README.md** - Acknowledgments section
- **CHANGELOG.md** - Version contributors
- **GitHub Contributors** - Automatic

---

## Development Setup

### Required Tools

1. **MetaTrader 5** - Latest version
2. **MetaEditor** - Included with MT5
3. **Git** - For version control
4. **Text Editor** (optional) - VS Code, Sublime, etc.

### Recommended Extensions (VS Code)

- MQL5 Language Support
- GitLens
- Markdown All in One

---

## Code Review Criteria

Pull requests will be reviewed based on:

- **Functionality:** Does it work as intended?
- **Code Quality:** Clean, readable, maintainable?
- **Performance:** No unnecessary slowdowns?
- **Compatibility:** Works with MT5 builds 3000+?
- **Documentation:** Changes documented?
- **Testing:** Adequately tested?
- **Style:** Follows style guidelines?

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## Questions?

Feel free to open an issue with the tag `question` if you have any doubts about contributing!

---

**Thank you for making MT_MANAGER better! 🚀**
