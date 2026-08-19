You are running **non-interactively** inside a GitHub Actions CI job. There is no
human to answer questions — proceed autonomously.

Your task: use the **appmap-review** skill to review the runtime-behavior change
between two revisions and write the interpreted review report.

Arguments:
- baseline revision: `${BASE_REVISION}`
- head revision: `${HEAD_REVISION}`

Notes:
- The head revision's gold traces were just re-recorded, blessed, and committed by
  the preceding step, so they are present in git history at the head revision.
- If the baseline revision has **no** committed gold traces (first-ever run), say so
  in the report and review what you can (a clean/So-far baseline is a valid report) —
  do not fail.

Follow the skill's review recipe and its **Report format** exactly — the skill is
the sole authority on the report's structure and style. A clean compare is a valid
report; write it rather than writing nothing.

After `appmap-review` has produced its compare report, use the **appmap-comparison**
skill with the same baseline and head revisions. It creates portable
`*.compare.diff.sequence.json` files next to the compare evidence so the action can
upload an interactive before/after artifact. If the installed AppMap CLI does not yet
provide `sequence-diagram-compare`, skip this presentation step without failing the
behavioral review. Do not add artifact plumbing or generation status to the interpreted
review itself; the action publishes the artifact notice separately.

**Write the final Markdown report to this file — nothing else needs to go there:**

    ${REPORT_FILE}

Write ONLY the report to that path (create parent directories if needed). Do not
commit anything; the CI action publishes the report to the PR and job summary.
