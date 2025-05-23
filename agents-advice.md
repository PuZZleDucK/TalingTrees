Using AGENTS.md in OpenAI Codex: Recommendations and Best Practices

What is AGENTS.md?

is a specialized Markdown file (similar to a README) that you include in your code repository to guide OpenAI’s Codex agent. It serves as a "developer manual" for the AI, informing it how to navigate the codebase, which commands to run (e.g. tests/build), and how to follow your project’s coding standards. In other words, it’s a place to write down project-specific instructions so the AI behaves more like a knowledgeable team member rather than a generic coder.

Official Guidance and Purpose

OpenAI’s official introduction of Codex highlights that an AGENTS.md can significantly improve the agent’s effectiveness. Like a human developer reading documentation, Codex will read your AGENTS.md to learn project structure, testing procedures, naming/style conventions, and other standard practices. For example, you might specify how to run the test suite, what linter to use, or any architectural norms the AI should respect. Codex agents perform best when given clear guidance and a well-prepared environment – think of AGENTS.md as an AI-focused extension of your documentation. Notably, Codex can still work without this file, but the file helps it align with your expectations and project norms more closely.

Tip: Don’t confuse AGENTS.md with your regular README. Your README might tell human developers how to install or use the software, whereas AGENTS.md tells the AI agent how to contribute to the software. OpenAI insiders have noted that there are things you’d tell an AI that you wouldn’t bother telling a human (and vice versa) – hence a separate file is justified. For example, you might omit trivial setup steps (the agent can infer some things) but include strict coding style rules that a new contributor might otherwise overlook.

How AGENTS.md Files Work (Structure and Hierarchy)

Placement: By default, Codex looks for AGENTS.md in specific locations and merges their contents hierarchically. According to OpenAI, the search order is: (1) a global ~/.codex/AGENTS.md (for user or organization-wide guidance), (2) an AGENTS.md at the repository root, and (3) an AGENTS.md in the current working subdirectory (for module or feature-specific rules). The agent loads all that apply, with deeper (more specific) files overriding or adding to instructions from higher-level ones【14†L118-L122**】. This means you can maintain general guidelines globally and project-wide, and still have folder-specific tweaks when needed. (If needed, you can disable loading these docs with a CLI flag --no-project-doc or env var, but generally you won’t do that in normal use.)

Format: The AGENTS.md itself is just plain Markdown. There’s no strict required structure – the agent will read it like any text – but a clear, logical organization helps both you and the AI. Many developers structure it with headings and bullet points for each topic, similar to a FAQ or checklist for coding in that project. Keeping the tone directive (imperative guidance) is common, e.g. “Use Python 3.10 features when possible” or “Run npm test before committing.” In practice, Codex will parse whatever you write, but concise rules or examples seem to work best (more on that below).

Scope: Codex automatically considers the relevant AGENTS.md content when working on tasks. In fact, when the agent begins a task, it “searches for AGENTS.md files whose scope includes the file(s) it is modifying” and applies those instructions. This scope mechanism means if you have a subfolder with its own AGENTS.md focusing on, say, frontend UI guidelines, those rules kick in only when Codex is working on that UI code, whereas a back-end task might only use the root-level file. The hierarchical design ensures the AI always uses the most specific applicable advice.

Community Feedback and Usage Examples

Early users of Codex have enthusiastically embraced AGENTS.md as a way to customize the AI’s behavior. For instance, one developer described that their AGENTS.md lists the project’s logger utility, preferred design patterns, and testing rules – so Codex will automatically use the correct logger, follow the preferred patterns, and write tests in the expected way. They noted that the agent reads this file “before writing code, so new files follow our style without reminders.” This underscores how AGENTS.md can enforce consistency (the AI won’t, say, introduce a different logging framework if you’ve documented which one to use).

The developer community also highlights the layered usage: e.g. using a global ~/.codex/AGENTS.md for organization-wide norms or personal preferences, plus repository and folder-specific files for granular control. If your company has a standard coding style or Git commit convention, you can put that in the global file so all Codex tasks adhere to it across projects. Then each repo can have its own specifics (like “this project uses Django, here’s how to run it”) and even per-directory instructions for quirky legacy modules.

Some advanced users even let **Codex help write the **`` itself. The idea is to “groom” the file over time: as Codex’s capabilities grow, you update the file with new rules or have the AI propose additions. According to a Codex team member, “the new hierarchical Agents.md is designed to capture all your instructions to the model and grow as model intelligence grows”, and you can literally ask Codex to draft its own Agents.md as a starting point. This can be a useful trick: for example, you might prompt ChatGPT/Codex with “Analyze my repo and suggest an Agents.md to guide an AI contributor.” Then you can edit its suggestions into a polished guide.

In practice, what do people put in ``? Common themes include: build/test instructions, coding style guidelines, project-specific conventions, and “definition of done” criteria. For instance, a DataCamp tutorial provides an example with sections for Code Style, Testing, and PR instructions. In that sample, Code Style rules included using Black (Python formatter) and avoiding name abbreviations; Testing rules required running pytest and linting (flake8) before PRs; and PR Instructions mandated a specific title format and a “Testing Done” section in descriptions. Another community example suggests including “setup and test commands” (like how to install dependencies or run the dev server) in the file, so the AI knows how to properly initialize or test the app during its tasks.

Overall, community feedback has been that AGENTS.md is a key tool for steering Codex. Projects that invest in a good AGENTS.md see the agent produce results more in line with their expectations (fewer style nits or missing steps to fix later). It effectively turns Codex into a more context-aware junior developer.

Example: Structuring an AGENTS.md File

There’s no one-size-fits-all template for AGENTS.md, but a well-structured file often covers the following areas:

Project Overview / Structure: (Optional) A brief note on the codebase layout or important components. For example, list key directories and their purpose (so the AI knows where things are). E.g. “/src contains core code; /tests has unit tests; /docs has documentation – (the AI typically doesn’t need to edit docs).” This helps Codex navigate unfamiliar repos.

Coding Conventions / Style Guide: Specify language or framework style guidelines. This can include formatting tools (e.g. “Use Black for Python formatting”), naming conventions (“avoid abbreviations in variable names”), or frameworks to prefer. If your project uses specific patterns or architecture (like “use functional React components with hooks” or “prefer repository pattern in data layer”), note those. Essentially, teach the AI your style rules.

Testing and Validation: Instruct how to run tests and other checks. Codex will try to run tests as part of verifying its changes, so tell it the correct commands. For example: “Run pytest tests/ before finalizing” or “All commits must pass flake8 lint checks”. If there are special test instructions (like seeding a database, or a custom test script), include those. This ensures the agent knows what constitutes a passing build.

Build/Run Commands: If applicable, document how to build or run the project. For instance, “Use npm run build to compile the project” or “Execute docker compose up to run the integration tests.” Codex can execute shell commands in its sandbox, so giving it the right incantations here is crucial. This helps avoid the AI guessing incorrectly (which could waste time or resources).

Project-specific Tips: Any particular gotchas or practices. Example: “Use the Logger class from utils/logger.py instead of print statements” (so the AI doesn’t introduce print logs), or “All API calls must use our ApiClient helper.” These are rules that a human developer might learn during code review – by writing them in AGENTS.md, the AI will know up-front.

Pull Request / Commit Guidelines: If you want Codex to format its commits or PRs in a certain way, include that. For example, define a commit message style or PR description template: “PR title should be [Fix] <short description>” or “Include a ‘Testing Done’ section in PR description”. Codex, when creating PRs, can follow these conventions so that its contributions fit in seamlessly with your workflow.

Quality Checks: List any final checks the AI should ensure. For example: “Before proposing a change, run npm run lint && npm run type-check”. In the example template, they show commands for linting, type-checking, and building the project, with a note that “All checks must pass before OpenAI Codex generated code can be merged.”. By listing these, you remind the AI to verify them (and Codex will typically attempt to run these if tests fail or as final steps).

Example snippet: To illustrate, here’s a condensed example inspired by official and community sources:

Code Style: Use Black for Python code formatting; follow PEP8 conventions. Avoid abbreviations in variable names.

Testing: Always run pytest on the tests/ directory before concluding a task. Ensure all tests pass and run the linter (flake8) with no errors.

Build/Run: Use pnpm install to install dependencies and npm run build to compile the project (do this if new dependencies are added). Use npm start to run the development server.

Logging & Debugging: Use the shared Logger utility (src/utils/logger.js) for logging instead of console.log. Handle exceptions with the custom ErrorHandler class.

Pull Requests: Name branches like feature/<short-name> for new features. PR titles should begin with a tag (e.g. [Fix], [Feature]). Include a one-line summary of changes and a “Testing Done” section in every PR description.

Environment: Codex runs in a sandbox – ensure any setup scripts (e.g., seeding DB) are run via setup.sh. (If environment variables or secrets are needed to run tests, instruct how to load dummy values.)

The above is just an example. You should tailor your AGENTS.md to what you would tell a new developer joining the project. Be specific but concise. Below, we summarize some best practices to achieve this.

Best Practices for Writing AGENTS.md

When creating or updating your AGENTS.md, keep these best practices in mind:

Keep it Focused and Concise: This file should be short and relevant – not an encyclopedia of your project. Include information that directly impacts how code is written or tested. Avoid lengthy prose; use bullet points or brief paragraphs for clarity. Remember, the agent has a large context window, but clarity helps it pinpoint the important guidelines.

Use Clear, Actionable Instructions: Write rules as commands or clear statements. For example, “Use X format” or “Run Y test command” instead of vague suggestions. The agent is more likely to follow concrete directives. If certain patterns are preferred or discouraged, state that plainly (e.g. “Do not use global variables,” “Prefer functional components over classes”).

Mirror Your Established Conventions: The content of AGENTS.md should reflect practices you actually follow. If your team has a coding style guide or CI checks, encode those here. This ensures the AI’s contributions align with what your human reviewers expect (minimizing nitpicks in code review). Essentially, treat the AI like a junior dev – tell it exactly what standards to follow.

Include Testing and Build Steps: One of the most important sections is how to validate changes. Providing the test command (and any build or deploy checks) is highly recommended. Codex will automatically try to run tests; giving it the correct commands (and any setup needed) makes its job easier and results more deterministic. For example, if your project uses pnpm instead of npm, note that. A common mistake is not specifying the right test command, causing the agent to guess or run a default (which could waste time or miss issues).

Leverage Hierarchy for Maintainability: If you work across multiple projects or a large monorepo, consider using the layered approach. Put universal rules (like company code style, license headers, etc.) in the global ~/.codex/AGENTS.md so you don’t repeat them in every repo. Then confine project-specific details to the repo’s own file, and any highly specific component instructions to a folder-level file. This keeps each file lean and focused on its level of context.

Store it in Version Control: Treat AGENTS.md as part of your codebase – check it into your repository so that others (and your future self) can update it alongside code changes. Because Codex will read whatever is in the repo, you want the file to evolve with the project. (For example, if you adopt a new test framework, update AGENTS.md accordingly.) Keeping it version-controlled also means collaborators can propose changes to it via PRs, just like any documentation.

Update and “Groom” it Over Time: Don’t write AGENTS.md once and forget it. Pay attention to Codex’s output – if it repeatedly makes a certain mistake or omission, that’s a clue to add a note in AGENTS.md to address it. Over time, you’ll build a more comprehensive guide that preempts common issues. As one article put it, “the Agents.md is designed to capture all your instructions to the model and grow as model intelligence grows.”. You might even occasionally ask Codex or ChatGPT to suggest improvements for the file (it can be surprisingly good at identifying missing pieces).

Use Standard Markdown Structuring: For readability, use headings, subheadings, and lists in a logical order (as demonstrated earlier). This not only helps any human collaborators understand the file, but it likely helps the AI parse the information better too. A recommended pattern is to start broad (project overview, key conventions) and then drill down (specific tools, specific workflows).

Avoid Irrelevant or Sensitive Info: Don’t clutter the file with information the AI doesn’t need. For instance, you usually don’t need to paste large chunks of code or actual config file contents into AGENTS.md – the agent can read your codebase directly if needed. Focus on guidelines around the code, not the code itself. Also, do not include secrets or confidential info here (the Codex sandbox shouldn’t leak it, but it’s good practice to treat this like any public-facing doc).

Common Pitfalls to Avoid

Developers new to Codex’s AGENTS.md have encountered a few common snags. Being aware of these can save you time:

Misplacing or Misnaming the File: Ensure the file is named exactly AGENTS.md (all caps) and is in the correct location. For repository-wide guidance, the file should live in the repo root. Placing it in a subdirectory won’t help global rules (unless that subdirectory is the only place you work with the agent). Conversely, if you put a file in a subfolder expecting it to apply globally, Codex might not see it. Use the hierarchy as intended.

Overloading with Environment Setup: Some developers try to use AGENTS.md to fix environment issues (for example, telling Codex how to install system dependencies or update package lockfiles). Remember that AGENTS.md is read by the AI, not executed as a script. It’s fine to include build/test commands and prerequisite steps, but if your environment isn’t prepared (e.g., necessary libraries aren’t available in the sandbox), just writing that in AGENTS.md won’t magically install them. In other words, use it to instruct the agent what to do, but you may still need to ensure the sandbox or CI pipeline has the proper setup. One forum discussion noted that AGENTS.md is not intended to carry exhaustive environment configuration details – don’t treat it like a Dockerfile or shell script.

Too Much Unfocused Detail: A very long AGENTS.md that rambles through design documentation or project history can be counterproductive. If the AI has to sift through paragraphs of irrelevant info, it might miss the key points. Stick to actionable guidance. If you find the file getting huge, consider whether some content belongs in regular docs instead. A good rule of thumb: If it doesn’t influence how code should be written or tested right now, it might not belong in AGENTS.md.

Stale Instructions: An outdated AGENTS.md can confuse the AI. For instance, if it says “use library X” but your project has since moved to library Y, the AI might reintroduce X or spend time doing the wrong thing. Make it part of your workflow to revise AGENTS.md when your tooling or standards change. This also applies to CI commands – if you change how tests are run, update the file so Codex knows about the new process.

Expecting Miracles Without It: On the flip side, a pitfall is not using an AGENTS.md at all. Codex will attempt to infer project context on its own (it might look at your README, package.json, etc.), but you’re missing an opportunity to guide it. As one Hacker News commenter observed, it’s unclear exactly how Codex configures its environment when no AGENTS.md or Dockerfile is present – presumably it guesses from common patterns. That guesswork might be fine for simple cases, but for anything non-trivial, you’ll get better results by explicitly providing context. In short, don’t skip AGENTS.md if you care about the quality of the AI’s output.

Not Utilizing the Hierarchy: Some users forget that the multi-level approach exists and end up putting everything (even very specific hacks) into one global file or duplicating common rules in every repo. This is a maintenance headache. Take advantage of the merge behavior: use a global file for broad rules and refine per project as needed. This avoids conflicts too – e.g., your global might say “use Python 3.11”, but one older project still uses 3.8, so its local AGENTS.md can note that exception. Codex will follow the more specific (project-level) instruction in that context.

Conclusion

The introduction of AGENTS.md in OpenAI’s Cloud Codex is a powerful way to align AI-generated code with your project’s needs. By providing clear instructions on structure, style, testing, and workflows, you essentially train the agent on your “internal company handbook” for coding. Official recommendations encourage treating it like a living document – concise, structured, and updated as your project evolves【16†L122-L124**】. Early community adopters report that a good AGENTS.md can make Codex feel like an onboarded team member rather than an outsider.

In summary, to make the most of Codex with AGENTS.md: document what matters, organize it clearly, keep it current, and integrate it into your development routine. With that in place, Codex can reliably run your tests, follow your coding standards, and contribute code that fits right into your codebase’s style. Treat the AGENTS.md as a crucial piece of project documentation whenever you’re working with AI agents – it’s where you tell the AI how to best help you.
