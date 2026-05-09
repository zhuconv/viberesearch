---
name: code-review
description: Review recent code changes for correctness, maintainability, security, and experiment reproducibility.
---

Review the selected files or recent git diff.

Focus on:
- correctness bugs,
- hidden assumptions,
- failed edge cases,
- reproducibility issues,
- risky dependencies or secrets,
- unnecessary complexity.

Return:
1. blocking issues,
2. non-blocking improvements,
3. suggested patch plan.
